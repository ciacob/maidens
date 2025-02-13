package ro.ciacob.maidens.controller {
import eu.claudius.iacob.maidens.constants.StaticTokens;

import ro.ciacob.ciacob;

import ro.ciacob.maidens.controller.editor.nudge.NudgingTools;
import ro.ciacob.maidens.generators.MusicEntry;
import ro.ciacob.maidens.generators.constants.GeneratorKeys;
import ro.ciacob.maidens.generators.constants.duration.DotTypes;
import ro.ciacob.maidens.generators.constants.duration.DurationFractions;
import ro.ciacob.maidens.generators.constants.parts.PartAbbreviatedNames;
import ro.ciacob.maidens.generators.constants.parts.PartDefaultBrackets;
import ro.ciacob.maidens.generators.constants.parts.PartDefaultClefs;
import ro.ciacob.maidens.generators.constants.parts.PartDefaultStavesNumber;
import ro.ciacob.maidens.generators.constants.parts.PartNames;
import ro.ciacob.maidens.generators.constants.parts.PartRanges;
import ro.ciacob.maidens.generators.constants.parts.PartTranspositions;
import ro.ciacob.maidens.generators.constants.pitch.IntervalsSize;
import ro.ciacob.maidens.generators.constants.pitch.PitchAlterationTypes;
import ro.ciacob.maidens.legacy.ModelUtils;
import ro.ciacob.maidens.legacy.MusicUtils;
import ro.ciacob.maidens.legacy.ProjectData;
import ro.ciacob.maidens.legacy.constants.DataFields;
import ro.ciacob.maidens.legacy.constants.StaticFieldValues;
import ro.ciacob.maidens.legacy.constants.Voices;
import ro.ciacob.maidens.legacy.exporters.TupletMarker;
import ro.ciacob.maidens.model.GeneratorInstance;

import ro.ciacob.math.Fraction;
import ro.ciacob.utils.Arrays;
import ro.ciacob.utils.ConstantUtils;
import ro.ciacob.utils.Objects;
import ro.ciacob.utils.Strings;
import ro.ciacob.utils.constants.CommonStrings;

use namespace ciacob;

/**
 *
 * @author ciacob
 */
public class QueryEngine {

    private var _cache:Object = {};

    public function resetCache():void {
        _cache = {};
    }

    public function QueryEngine(projectData:ProjectData) {
        _dataSource = projectData;
    }

    public var lastEnteredDuration:String;
    public var lastEnteredPitch:int = -1;
    public var usingNotesRatherThanRests:Boolean = true;
    private var _dataSource:ProjectData;
    private var _fullToShortUidsMap:Object = {};
    private var _generatorsByConnectionUids:Object = {};
    private var _generatorsNode:ProjectData;
    private var _measureNumberToUidMap:Object;
    private var _measuresCount:int = 0;
    private var _projectNode:ProjectData;
    private var _scoreNode:ProjectData;
    private var _sectionsByConnectionUids:Object = {};
    private var _shortToFullUidsMap:Object = {};
    private var _uidToMeasureNumberMap:Object;
    private var _uidsMapCounter:uint = 0;
    private var _lastTupletMarker:TupletMarker;

    /**
     * Adds a musical entry to a given measure, on a given staff, in a given voice.
     *
     * @param    entry
     *            A ro.ciacob.maidens.generators::MusicEntry instance, defining,
     *            essentially, a pitch and duration. Two nested nodes, a `cluster`
     *            and `note` will be created to represent it.
     *
     * @param    measure
     *            The `measure` node to create the new content in. Note: this
     *            function assumes that the new content fits, and does nothing
     *            to prevent it from overflowing.
     *
     * @param    staffVoiceIndices
     *            An Array containing two integers, which represent, respectively,
     *            the staff index and voice index where the new content is to be created.
     */
    public function addEntryToMeasure(entry:MusicEntry, measure:ProjectData, staffVoiceIndices:Array):void {
        var staffIndex:int = (staffVoiceIndices[0] as int);
        var voiceIndex:int = (staffVoiceIndices[1] as int);
        var targetVoice:ProjectData = findVoice(measure, staffIndex, voiceIndex);
        if (targetVoice == null) {
            targetVoice = _createVoiceOf(measure);
            targetVoice.setContent(DataFields.STAFF_INDEX, staffIndex);
            targetVoice.setContent(DataFields.VOICE_INDEX, voiceIndex);
        }
        var cluster:ProjectData = _createClusterOf(targetVoice, true);
        var annotation:String = entry.annotation;
        var splitValues:Array = _splitCompositeDuration(entry.duration);
        var duration:Fraction = splitValues[0];
        var dotValue:Fraction = splitValues[1];
        cluster.setContent(DataFields.CLUSTER_DURATION_FRACTION, duration.toString());
        cluster.setContent(DataFields.DOT_TYPE, dotValue.toString());
        cluster.setContent(DataFields.DEBUG_ANNOTATION, annotation);

        // TODO: support tuplets
        if (entry.pitch != 0) {
            var note:ProjectData = MusicUtils.midiNumberToNote(entry.pitch);
            note.setContent(DataFields.TIES_TO_NEXT_NOTE, entry.tie);
            ciacob::forciblyAddExistingChild(cluster, note);
        }
    }

    /**
     * Removes all voices, keeping only one per staff, and removes all clusters from
     * the remaining voices.
     *
     * @param    measure
     *            The measure whose content is to be cleared.
     *
     * @param    addWholeRest
     *            Optional, defaults to false. Whether to add one whole rest to
     *            each of the remaining voices, after their content has been removed.
     */
    public function clearMeasureContent(measure:ProjectData, addWholeRest:Boolean = false):void {

        var voices:Array = ModelUtils.getChildrenOfType(measure, DataFields.VOICE);
        voices.sort(ModelUtils.compareVoiceNodes);
        for (var i:int = 0; i < voices.length; i++) {
            var voice:ProjectData = (voices[i] as ProjectData);
            voice.empty();
            if (addWholeRest) {
                var cluster:ProjectData = _createClusterOf(voice);
                cluster.setContent(DataFields.CLUSTER_DURATION_FRACTION, DurationFractions.WHOLE.toString());
                cluster.setContent(DataFields.DOT_TYPE, DotTypes.NONE);
            }
        }
    }

    /**
     * Returns the measure `duration`, which is given by the greatest of the sum of
     * durations contained in each of that measure's voices.
     *
     * @param    measure
     *            A measure to compute the duration of.
     *
     * @return
     */
    public function computeMeasureDuration(measure:ProjectData):Fraction {
        var measureDuration:Fraction = Fraction.ZERO;
        var voice:ProjectData = null;
        var voiceDuration:Fraction = null;
        for (var i:int = 0; i < measure.numDataChildren; i++) {
            voice = ProjectData(measure.getDataChildAt(i));
            voiceDuration = computeVoiceDuration(voice as ProjectData);
            if (voiceDuration.greaterThan(measureDuration)) {
                measureDuration = voiceDuration;
            }
        }
        return measureDuration;
    }

    /**
     * Returns the greatest of a measure's time signature value and its effective
     * duration (where `effective duration` is defined as the greatest duration of one
     * of the measure's voices).
     *
     * @param    measure
     *            The measure whose span is to be computed.
     * @return
     */
    public function computeMeasureSpan(measure:ProjectData):Fraction {
        var timeFraction:Fraction = getOwnOrInheritedTimeFraction(measure);
        var duration:Fraction = computeMeasureDuration(measure);
        if (duration.greaterThan(timeFraction)) {
            return duration;
        }
        return timeFraction;
    }

    public function computeSectionNominalDuration(section:ProjectData):Fraction {
        var duration:Fraction = Fraction.ZERO;
        var lastTimeSignature:Fraction = Fraction.ZERO;
        var sectionNumMeasures:int = getSectionNumMeasures(section);
        var sectionTimeSignatures:Object = getTimeFractionsInSection(section);
        for (var i:int = 0; i < sectionNumMeasures; i++) {
            lastTimeSignature = ((sectionTimeSignatures[i] as Fraction) || lastTimeSignature);
            duration = duration.add(lastTimeSignature) as Fraction;
        }
        return duration;
    }

    /**
     * Sums up the durations of all clusters in a given voice.
     *
     * NOTE:
     * The voice duration needs to be amended, because the music theory allows
     * for a lone whole rest to be used to denote silent measures, REGARDLESS of
     * the measure's nominal value (or `time signature`).
     * Therefore, if the voice has a single empty cluster, and its computed duration
     * is a `whole` (1/1), we substitute that for the measure's nominal value.
     *
     * @param    voice
     *            The voice whose duration is to be computed.
     *
     * @return    The voice's computed duration, as a Fraction.
     */
    public function computeVoiceDuration(voice:ProjectData):Fraction {


        // Shortcut. Deliver from cache, if available
        var voiceUid:String = voice.route;

        if (!('cachedVoiceDuration' in _cache)) {
            _cache.cachedVoiceDuration = {};
        }
        if (voiceUid in _cache.cachedVoiceDuration) {
            return _cache.cachedVoiceDuration[voiceUid];
        }

        // Otherwise, process and cache result
        var test:Object = null;
        var cluster:ProjectData = null;
        var clusterDuration:Fraction = null;
        var voiceDuration:Fraction = Fraction.ZERO;
        var dotType:Fraction;
        var dotValue:Fraction;
        var j:int;
        var startsTuplet:Boolean;
        var tupletSrcNumBeatsRaw:int;
        var tupletTargetNumBeatsRaw:int;
        var tupletBeatsDurationRaw:String;
        var tupletTargetNumBeats:Fraction = Fraction.ZERO;
        var tupletBeatsDuration:Fraction;
        var intrinsicTupletSpan:Fraction;
        var tupletMarkerResponse:int;
        var tupletRootDuration:Fraction;

        for (j = 0; j < voice.numDataChildren; j++) {
            cluster = ProjectData(voice.getDataChildAt(j));

            // If the current cluster starts a tuplet, obtain the (regular) duration
            // that the tuplet is supposed to replace, and use that in the calculation.
            // Also, make ready to consume as many of the subsequent Clusters as can fit.
            startsTuplet = cluster.getContent(DataFields.STARTS_TUPLET) as Boolean;
            if (startsTuplet) {

                // Source number of beats. If not given, set default
                tupletSrcNumBeatsRaw = (cluster.getContent(DataFields.TUPLET_SRC_NUM_BEATS) as int);
                if (tupletSrcNumBeatsRaw <= 0) {
                    tupletSrcNumBeatsRaw = StaticFieldValues.DEFAULT_TUPLET_SRC_BEATS;
                    cluster.setContent(DataFields.TUPLET_SRC_NUM_BEATS, tupletSrcNumBeatsRaw);
                }

                // Target number of beats. Use given or assume default
                tupletTargetNumBeatsRaw = (cluster.getContent(DataFields.TUPLET_TARGET_NUM_BEATS) as int);
                if (tupletTargetNumBeatsRaw <= 0) {
                    tupletTargetNumBeatsRaw = StaticFieldValues.DEFAULT_TUPLET_TARGET_BEATS;
                    cluster.setContent(DataFields.TUPLET_TARGET_NUM_BEATS, tupletTargetNumBeatsRaw);
                }
                tupletTargetNumBeats.setValue(tupletTargetNumBeatsRaw, 1);

                // Beats duration. Use given or assume current Cluster duration
                tupletBeatsDurationRaw = (cluster.getContent(DataFields.TUPLET_BEAT_DURATION) as String);
                if (tupletBeatsDurationRaw == DataFields.VALUE_NOT_SET) {
                    tupletBeatsDurationRaw = (cluster.getContent(DataFields.CLUSTER_DURATION_FRACTION) as String);
                    cluster.setContent(DataFields.TUPLET_BEAT_DURATION, tupletBeatsDurationRaw);
                }
                tupletBeatsDuration = Fraction.fromString(tupletBeatsDurationRaw);
                clusterDuration = tupletTargetNumBeats.multiply(tupletBeatsDuration) as Fraction;
                voiceDuration = voiceDuration.add(clusterDuration) as Fraction;

                // Prepare to consume as many of the subsequent Clusters as can fit
                var haveTuplet:Boolean = (tupletSrcNumBeatsRaw != tupletTargetNumBeatsRaw);
                if (haveTuplet) {
                    intrinsicTupletSpan = tupletBeatsDuration.multiply(new Fraction(tupletSrcNumBeatsRaw)) as Fraction;
                    _lastTupletMarker = new TupletMarker(cluster.route, intrinsicTupletSpan, tupletSrcNumBeatsRaw, tupletTargetNumBeatsRaw);
                    tupletRootDuration = Fraction.fromString(cluster.getContent(DataFields.CLUSTER_DURATION_FRACTION) as String);
                    tupletMarkerResponse = _lastTupletMarker.accountFor(tupletRootDuration);

                    // Take into account the (single or double) augmentation dot of the tuplet root
                    test = cluster.getContent(DataFields.DOT_TYPE);
                    if (test != DataFields.VALUE_NOT_SET) {
                        dotType = Fraction.fromString(test.toString());
                        if (!dotType.equals(Fraction.ZERO)) {
                            dotValue = tupletRootDuration.multiply(dotType) as Fraction;
                            tupletMarkerResponse = _lastTupletMarker.accountFor(dotValue);
                        }
                    }
                    if (tupletMarkerResponse != TupletMarker.UNDERFULL) {
                        _lastTupletMarker = null;
                    }
                }
            }

            // Otherwise, we either deal with a tuplet Cluster or a regular Cluster
            else {
                test = cluster.getContent(DataFields.CLUSTER_DURATION_FRACTION);
                if (test !== DataFields.VALUE_NOT_SET) {
                    clusterDuration = Fraction.fromString(test.toString());

                    // This may be a tuplet Cluster
                    if (_lastTupletMarker) {
                        tupletMarkerResponse = _lastTupletMarker.accountFor(clusterDuration);

                        // Take into account the (single or double) augmentation dot of the tuplet Cluster
                        test = cluster.getContent(DataFields.DOT_TYPE);
                        if (test != DataFields.VALUE_NOT_SET) {
                            dotType = Fraction.fromString(test.toString());
                            if (!dotType.equals(Fraction.ZERO)) {
                                dotValue = clusterDuration.multiply(dotType) as Fraction;
                                tupletMarkerResponse = _lastTupletMarker.accountFor(dotValue);
                            }
                        }
                        if (tupletMarkerResponse == TupletMarker.UNDERFULL) {
                            cluster.setContent(DataFields.TUPLET_ROOT_ID, _lastTupletMarker.rootId);
                            continue;
                        } else if (tupletMarkerResponse == TupletMarker.FULL) {
                            cluster.setContent(DataFields.TUPLET_ROOT_ID, _lastTupletMarker.rootId);
                            _lastTupletMarker = null;
                            continue;
                        } else {
                            // The `tupletMarkerResponse` is "TupletMarker.OVERFULL". If the current Cluster
                            // does not begin a new tuplet and cannot fit the last known tuplet either, then
                            // we deal with the situation of an incomplete tuplet. We cease collecting tuplet
                            // members and we will treat the current Cluster as "regular", instead.
                            _lastTupletMarker = null;
                        }
                    }

                    // If we reach down here, then this is just a regular Cluster
                    voiceDuration = voiceDuration.add(clusterDuration) as Fraction;

                    // Take into account the (single or double) augmentation dot of the regular Cluster
                    test = cluster.getContent(DataFields.DOT_TYPE);
                    if (test != DataFields.VALUE_NOT_SET) {
                        dotType = Fraction.fromString(test.toString());
                        if (!dotType.equals(Fraction.ZERO)) {
                            dotValue = clusterDuration.multiply(dotType) as Fraction;
                            voiceDuration = voiceDuration.add(dotValue) as Fraction;
                        }
                    }
                }
            }
        }
        _cache.cachedVoiceDuration[voiceUid] = voiceDuration;

        // Safety measure: discard any existing TupletMarker before (possibly) moving on to next voice
        _lastTupletMarker = null;
        return voiceDuration;
    }

    public function createChildOf(parent:ProjectData):ProjectData {
        var parentType:String = parent.getContent(DataFields.DATA_TYPE);
        switch (parentType) {

                // There can only be one score, therefore we do not provide a `parent` argument here
            case DataFields.SCORE:
                return _createSection();

                // All generator nodes reside in the same place, therefore we do not provide a `parent` argument here
            case DataFields.GENERATORS:
                return _createGenerator();
            case DataFields.SECTION:
                return _createPartFrom(parent);
            case DataFields.PART:
                return _createMeasureOf(parent);
            case DataFields.VOICE:
                return _createClusterOf(parent);
            case DataFields.CLUSTER:
                return _createNoteOf(parent);
        }
        return null;
    }

    /**
     * Creates a `part` node as a child of the given `section`; populates the newly created
     * part according to given part name; returns the new node.
     *
     * @param    partName
     *            The (unique) name of the part to create. Accepts one of the constants defined by
     *            the class `PartNames`. No part will be created and the function will return null if
     *            an unknown value is provided.
     *
     * @param    section
     *            A `section` node the new `part` is to be set as a child of.
     *
     * @return    The newly created part.
     */
    public function createPartByName(partName:String, section:ProjectData):ProjectData {
        if (ConstantUtils.hasName(PartNames, partName)) {
            var part:ProjectData = _createPartFrom(section);
            part.setContent(DataFields.PART_NAME, partName);
            part.setContent(DataFields.ABBREVIATED_PART_NAME, PartAbbreviatedNames[partName]);
            part.setContent(DataFields.PART_NUM_STAVES, PartDefaultStavesNumber[partName]);
            part.setContent(DataFields.PART_OWN_BRACKET_TYPE, PartDefaultBrackets[partName]);
            part.setContent(DataFields.PART_TRANSPOSITION, PartTranspositions[partName]);
            part.setContent(DataFields.PART_CLEFS_LIST, PartDefaultClefs[partName]);
            part.setContent(DataFields.CONCERT_PITCH_RANGE, PartRanges[partName]);
        }
        return part;
    }

    /**
     * When removing a measure, also remove the corresponding measure from all
     * parts in the current section. By corresponding measure, we mean the
     * measure having the same index.
     */
    public function deleteElement(element:ProjectData):ProjectData {

        if (ModelUtils.isSection(element)) {
            _unbindSection(element);
            // Fallthrough
        }

        if (ModelUtils.isMeasure(element)) {
            return _deleteMeasureElement(element);
        }

        // Deleting a Note requires extra processing because:
        // (1)	we need to keep track of user's current preference, i.e.,
        // 		whether he'd rather enter notes or rests.
        // (2)	we need to make sure that the remainder siblings form a
        //		contiguous and properly sorted set
        var isNoteDeletion:Boolean = ModelUtils.isNote(element);
        var parentCluster:ProjectData;
        if (isNoteDeletion) {
            parentCluster = element.dataParent as ProjectData;
            usingNotesRatherThanRests = false;
        }
        var replacement:ProjectData = _deleteOrdinaryElement(element);
        if (isNoteDeletion) {
            orderChildNotesByPitch(parentCluster);
        }
        return replacement;
    }

    /**
     * Finds and returns a `voice` node found within a given `measure` node and
     * having set a given staff and voice indices.
     *
     * @param    parentMeasure
     *            The `measure` node to search inside of.
     *
     * @param    staffIndex
     *            The staff index value to look for.
     *
     * @param    voiceIndex
     *            The voice index value to look for.
     *
     * @return    The matching `voice` node, if found, or null otherwise.
     */
    public function findVoice(parentMeasure:ProjectData, staffIndex:int, voiceIndex:int):ProjectData {
        for (var i:int = 0; i < parentMeasure.numDataChildren; i++) {
            var currVoice:ProjectData = (parentMeasure.getDataChildAt(i) as ProjectData);
            var currStaffIndex:int = (currVoice.getContent(DataFields.STAFF_INDEX) as int);
            var currVoiceIndex:int = (currVoice.getContent(DataFields.VOICE_INDEX) as int);
            if (currStaffIndex == staffIndex && currVoiceIndex == voiceIndex) {
                return currVoice;
            }
        }
        return null;
    }

    public function getAllConnectionUids():Array {
        return getSectionConnectionUids().concat(getGeneratorConnectionUids());
    }

    public function getAllGeneratorNodes():Array {
        var generatorsParent:ProjectData = getGeneratorsParentNode();
        return ModelUtils.getChildrenOfType(generatorsParent, DataFields.GENERATOR);
    }

    public function getAllSectionNames():Array {
        var allSections:Array = getAllSectionNodes();
        var allSectionNames:Array = [];
        for (var i:int = 0; i < allSections.length; i++) {
            var section:ProjectData = allSections[i];
            allSectionNames.push(section.getContent(DataFields.UNIQUE_SECTION_NAME));
        }
        return allSectionNames;
    }

    public function getAllSectionNodes():Array {
        var score:ProjectData = getScoreNode();
        return ModelUtils.getChildrenOfType(score, DataFields.SECTION);
    }

    /**
     * Retrieves the TIME FRACTION (NOT time signature), which is closest to given
     * measure. This can be the measure's own (self defined) time fraction, where
     * applicable, or the inherited one otherwise.
     *
     * NOTE: as opposed to `time signature`, which reflects the number of beats in a
     * measure and their duration, the `time fraction` reflects the mathematical
     * proportion of a measures number to their duration. The two are in some cases
     * identical, but in most, not, e.g.:
     *
     * - a common time measure has the time signature of 4/4 and the time fraction 1/1;
     * - a six eights measure has the time signature 6/8, and the time fraction 3/4;
     *
     * in other words, the mathematical fraction is put into standard form, while the
     * time signature is not.
     *
     * @param    measureUid
     *            The unique ID of the measure to consider
     *
     * @return    A Fraction object
     */
    public function getClosestTimeFractionTo(measureUid:String):Fraction {
        var search_for_time_fraction:Function = function (currentSibling:ProjectData):* {
            if (ModelUtils.isMeasure(currentSibling)) {
                var val:String = currentSibling.getContent(DataFields.TIME_FRACTION);
                if (!Strings.isEmpty(val) && val != DataFields.VALUE_NOT_SET) {
                    return Fraction.fromString(val);
                }
            }
            return undefined;
        }
        // We always refer to the measures of the first part in the current
        // section when requesting data that relates to a measure
        var referenceMeasure:ProjectData = _getReferenceMeasureFor(measureUid);
        if (referenceMeasure != null) {
            var ret:Object = _backwardWalkSiblingsOf(referenceMeasure, search_for_time_fraction);
            return ((ret || null) as Fraction);
        }
        return null;
    }

    /**
     * Retrieves the TIME SIGNATURE (NOT time fraction), which is closest to given
     * measure. This can be the measure's own (self defined) time fraction, where
     * applicable, or the inherited one otherwise.
     * @see    getClosestTimeFractionTo
     *
     * @param    measureUid
     *            The unique ID of the measure to consider.
     *
     * @return    An Array with two integers: the number of beats at index 0, and the
     *            duration of each beat at index 1.
     */
    public function getClosestTimeSignatureTo(measureUid:String):Array {

        // Nested function used as a filter for `_backwardWalkSiblingsOf`
        var search_for_time_signature:Function = function (currentSibling:ProjectData):* {
            return getMeasureTimeSignature(currentSibling) || undefined;
        }
        // We always refer to the measures of the first part in the current
        // section when requesting data that relates to a measure
        var referenceMeasure:ProjectData = _getReferenceMeasureFor(measureUid);
        if (referenceMeasure != null) {
            var ret:Object = _backwardWalkSiblingsOf(referenceMeasure, search_for_time_signature);
            return ((ret || null) as Array);
        }
        return null;
    }

    public function getConnectionUidType(uid:String):String {
        var sectConnUids:Array = getSectionConnectionUids();
        if (sectConnUids.indexOf(uid) >= 0) {
            return DataFields.SECTION;
        }
        var genConnUids:Array = getGeneratorConnectionUids();
        if (genConnUids.indexOf(uid) >= 0) {
            return DataFields.GENERATOR;
        }
        return null;
    }

    /**
     * @see "getShortUidFor()"
     */
    public function getFullUidFor(shortUID:String):String {
        if (shortUID in _shortToFullUidsMap) {
            return _shortToFullUidsMap[shortUID];
        }
        return null;
    }

    public function getGeneratorByConnectionUid(uid:String):ProjectData {
        if (uid in _generatorsByConnectionUids) {
            return (_generatorsByConnectionUids[uid] as ProjectData);
        }
        var generators:Array = getAllGeneratorNodes();
        for (var i:int = 0; i < generators.length; i++) {
            var generator:ProjectData = (generators[i] as ProjectData);
            if (generator.getContent(DataFields.CONNECTION_UID) == uid) {
                _generatorsByConnectionUids[uid] = generator;
                return generator;
            }
        }
        return null;
    }

    public function getGeneratorConnectionUids():Array {
        var _generatorConnectionUids:Array = [];
        var allGenerators:Array = getAllGeneratorNodes();
        for (var j:int = 0; j < allGenerators.length; j++) {
            var generator:ProjectData = allGenerators[j];
            _generatorConnectionUids.push(generator.getContent(DataFields.CONNECTION_UID));
        }
        return _generatorConnectionUids;
    }

    /**
     * Retrieves and returns the full dataset of a Generator node.
     */
    public function getGeneratorNodeData(generatorId:GeneratorInstance):ProjectData {
        var generatorNodes:Array = getAllGeneratorNodes();
        for (var i:int = 0; i < generatorNodes.length; i++) {
            var generatorNode:ProjectData = (generatorNodes[i] as ProjectData);
            var generatorUid:String = generatorNode.getContent(GeneratorKeys.GLOBAL_UID) as String;
            var generatorConnection:String = generatorNode.getContent(DataFields.CONNECTION_UID);
            if (generatorUid == generatorId.fqn && generatorConnection == generatorId.link) {
                return generatorNode;
            }
        }
        return null;
    }

    public function getGeneratorsParentNode():ProjectData {
        if (_generatorsNode != null) {
            return _generatorsNode;
        }
        if (ModelUtils.isGenerators(_dataSource)) {
            _generatorsNode = _dataSource;
        } else if (ModelUtils.isProject(_dataSource)) {
            var res:Array = ModelUtils.getChildrenOfType(_dataSource, DataFields.GENERATORS);
            _generatorsNode = (res[0] || null);
        }
        return _generatorsNode;
    }

    /**
     * Returns a measure's own, or "explicit" time signature (i.e., not looking for
     * "inherited" time signatures). Returns null if given measure does not have a
     * time signature set.
     *
     * @param    measure
     *            A measure to retrieve the time signature of.
     *
     * @return    An array with to integers, the number of beats at index 0 and the beat
     *            duration at index 1 or null.
     */
    public function getMeasureTimeSignature(measure:ProjectData):Array {
        var test:Object = null;
        var numBeats:int = 0;
        var beatDuration:int = 0;
        if (ModelUtils.isMeasure(measure)) {
            // Query the number of beats
            test = measure.getContent(DataFields.BEATS_NUMBER);
            if (test && test != DataFields.VALUE_NOT_SET) {
                numBeats = (test as int);
            }
            // Query the duration of each beat
            test = measure.getContent(DataFields.BEAT_DURATION);
            if (test && test != DataFields.VALUE_NOT_SET) {
                beatDuration = (test as int);
            }
            if (numBeats > 0 && beatDuration > 0) {
                return [numBeats, beatDuration];
            }
        }
        return null;
    }

    public function getNewSectionName():String {
        var allSectionNames:Array = getAllSectionNames();
        return _getUniqueIndexedName(allSectionNames, StaticTokens.SECTION.concat(CommonStrings.SPACE));
    }

    public function getNextEmptyStaffVoiceIndices(measure:ProjectData):Array {
        var voices:Array = ModelUtils.getChildrenOfType(measure, DataFields.VOICE);
        voices.sort(ModelUtils.compareVoiceNodes);
        for (var i:int = 0; i < voices.length; i++) {
            var voice:ProjectData = (voices[i] as ProjectData);
            if (voice.numDataChildren == 0) {
                var staffIndex:int = (voice.getContent(DataFields.STAFF_INDEX) as int);
                var voiceIndex:int = (voice.getContent(DataFields.VOICE_INDEX) as int);
                return [staffIndex, voiceIndex];
            }
        }
        return null;
    }

    public function getNumAvailableStavesForVoice(voice:ProjectData):int {
        var measure:ProjectData = ProjectData(voice.dataParent);
        if (measure != null) {
            var part:ProjectData = ProjectData(measure.dataParent);
            if (part != null) {
                return part.getContent(DataFields.PART_NUM_STAVES);
            }
        }
        return -1;
    }

    /**
     * Returns the TIME FRACTION (NOT time signature) to be considered for the given
     * measure. This will be (a) the time fraction explicitly set, if applicable,
     * (2) the one inherited from the last measure that has a time fraction set, if
     * missing, or (3) the whole fraction (equivalent of common time), as a last
     * resort.
     *
     * @see getClosestTimeFractionTo
     *
     * @param    measure
     *            The measure to determine the time signature of.
     *
     * @return    A Fraction object
     *
     */
    public function getOwnOrInheritedTimeFraction(measure:ProjectData):Fraction {
        var measureTimeFraction:Object = (measure.getContent(DataFields.TIME_FRACTION) as Object);
        if (measureTimeFraction != DataFields.VALUE_NOT_SET) {
            return Fraction.fromString(measureTimeFraction as String);
        }
        var inheritedFraction:Fraction = getClosestTimeFractionTo(measure.route);
        if (inheritedFraction != null) {
            return inheritedFraction;
        }
        return Fraction.WHOLE;
    }

    /**
     * Returns the TIME SIGNATURE (NOT time fraction) to be considered for the given
     * measure. This will be (a) the time signature explicitly set, if applicable,
     * (b) the one inherited from the last measure that has a time signature set, if
     * missing, or (c) the common time (4/4), as a last resort.
     *
     * @see getClosestTimeSignatureTo
     *
     * @param    measure
     *            The measure to determine the time signature of.
     *
     * @return    An Array with two integers, representing the number of beats in the
     *            measure at index 0 and the duration of each beat at index 1
     */
    public function getOwnOrInheritedTimeSignature(measure:ProjectData):Array {
        var timeSig:Array = getMeasureTimeSignature(measure);
        if (timeSig) {
            return timeSig;
        }
        var closestTimeSigDefinition:Array = getClosestTimeSignatureTo(measure.route);
        return closestTimeSigDefinition || [4, 4];
    }

    /**
     * Finds and returns a `part` node, within a given `section` node, based on a
     * given part name.
     *
     * @param    parentSection
     *            The section holding the parts to search through.
     *
     * @param    name
     *            The name of the part, in the format "[Part Name] [part ordinal index]",
     *            with the "ordinal index" being 1-based.
     *
     * @return    The `part` node, if found, null otherwise.
     */
    public function getPartByName(parentSection:ProjectData, name:String):ProjectData {
        var match:Array = name.match(/(.+)\s(\d+)/);
        if (match != null) {
            var partName:String = Strings.trim(match[1]);
            var ordinalIndex:int = ((parseInt(match[2]) as int) - 1);
            if (!Strings.isEmpty(partName) && !isNaN(ordinalIndex)) {
                for (var i:int = 0; i < parentSection.numDataChildren; i++) {
                    var currPart:ProjectData = (parentSection.getDataChildAt(i) as ProjectData);
                    var currPartName:String = (currPart.getContent(DataFields.PART_NAME) as String);
                    var currPartOrdIndex:int = (currPart.getContent(DataFields.PART_ORDINAL_INDEX) as int);
                    if (currPartName == partName && currPartOrdIndex == ordinalIndex) {
                        return currPart;
                    }
                }
            }
        }
        return null;
    }

    public function getProjectName():String {
        if (_projectNode == null) {
            _projectNode = getProjectNode();
        }
        var _projectName:String = _projectNode.getContent(DataFields.PROJECT_NAME);
        return _projectName;
    }

    public function getProjectNode():ProjectData {
        if (_projectNode != null) {
            return _projectNode;
        }
        _projectNode = ProjectData(ModelUtils.getClosestAscendantByType(_dataSource, DataFields.PROJECT));
        return _projectNode;
    }

    public function getScoreNode():ProjectData {
        if (_scoreNode != null) {
            return _scoreNode;
        }
        if (ModelUtils.isScore(_dataSource)) {
            _scoreNode = _dataSource
        } else if (ModelUtils.isProject(_dataSource)) {
            var result:Array = ModelUtils.getChildrenOfType(_dataSource, DataFields.SCORE);
            _scoreNode = (result[0] || null);
        } else {
            _scoreNode = ProjectData(ModelUtils.getClosestAscendantByType(_dataSource, DataFields.SCORE));
        }
        return _scoreNode;
    }

    public function getSectionByConnectionUid(uid:String):ProjectData {
        if (uid in _sectionsByConnectionUids) {
            return (_sectionsByConnectionUids[uid] as ProjectData);
        }
        var sections:Array = getAllSectionNodes();
        for (var i:int = 0; i < sections.length; i++) {
            var section:ProjectData = (sections[i] as ProjectData);
            if (section.getContent(DataFields.CONNECTION_UID) == uid) {
                _sectionsByConnectionUids[uid] = section;
                return section;
            }
        }
        return null;
    }

    public function getSectionByName(searchName:String):ProjectData {
        var allSections:Array = getAllSectionNodes();
        for (var i:int = 0; i < allSections.length; i++) {
            var section:ProjectData = (allSections[i] as ProjectData);
            var sectionName:String = (section.getContent(DataFields.UNIQUE_SECTION_NAME) as String);
            if (sectionName == searchName) {
                return section;
            }
        }
        return null;
    }

    public function getSectionConnectionUids():Array {
        var _sectionConnectionUids:Array = [];
        var allSections:Array = getAllSectionNodes();
        for (var i:int = 0; i < allSections.length; i++) {
            var section:ProjectData = allSections[i];
            _sectionConnectionUids.push(section.getContent(DataFields.CONNECTION_UID));
        }
        return _sectionConnectionUids;
    }

    public function getSectionNumMeasures(section:ProjectData):int {
        var allParts:Array = ModelUtils.getChildrenOfType(section, DataFields.PART);
        if (allParts.length > 0) {
            var firstPart:ProjectData = allParts[0];
            return firstPart.numDataChildren;
        }
        return 0;
    }

    public function getSectionPartsList(section:ProjectData):Array {
        var list:Array = [];
        var allParts:Array = ModelUtils.getChildrenOfType(section, DataFields.PART);
        for (var i:int = 0; i < allParts.length; i++) {
            var partNode:ProjectData = (allParts[i] as ProjectData);
            var name:String = partNode.getContent(DataFields.PART_NAME);
            var ord:Number = parseInt(partNode.getContent(DataFields.PART_ORDINAL_INDEX));
            if (!isNaN(ord)) {
                // PART_ORDINAL_INDEX is `0` based.
                name = name.concat(CommonStrings.SPACE, ord + 1);
            }
            list.push(name);
        }
        return list;
    }

    /**
     * Retrieves (and creates, if needed) a shorter UID for elements in the model.
     * Especially useful for annotating the printed score (annotation is the
     * procedure we use for figuring out where a certain element in the model has been
     * drawn on the score).
     */
    public function getShortUidFor(fullUID:String):String {
        if (!(fullUID in _fullToShortUidsMap)) {
            _registerShortUidFor(fullUID);
        }
        return (_fullToShortUidsMap[fullUID] as String);
    }

    public function getTimeFractionsInSection(section:ProjectData):Object {
        var table:Object = {};
        var allParts:Array = ModelUtils.getChildrenOfType(section, DataFields.PART);
        if (allParts.length > 0) {
            var firstPart:ProjectData = allParts[0];
            for (var i:int = 0; i < firstPart.numDataChildren; i++) {
                var measure:ProjectData = (firstPart.getDataChildAt(i) as ProjectData);
                table[i] = getOwnOrInheritedTimeFraction(measure);
            }
        }
        return table;
    }

    public function hasKnownDuration(entry:MusicEntry):Boolean {
        var allKnownDurations:Array = MusicUtils.getCommonFractionsList(true, true);
        var entryDuration:Fraction = entry.duration;
        for (var i:int = 0; i < allKnownDurations.length; i++) {
            var knownDuration:Fraction = (allKnownDurations[i] as Fraction);
            if (entryDuration.equals(knownDuration)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Looks up a given section name in the current datasource.
     *
     * @param    sectionName
     *            The section name to look up.
     *
     * @return    True if such a section name exists, false otherwise.
     */
    public function haveSectionName(sectionName:String):Boolean {
        var allSectionNames:Array = getAllSectionNames();
        return (allSectionNames.indexOf(sectionName) >= 0);
    }

    public function measureNumberToUid(measureNumber:int):String {
        if (_measureNumberToUidMap != null && (measureNumber in _measureNumberToUidMap)) {
            return _measureNumberToUidMap[measureNumber];
        }
        var allSections:Array = getAllSectionNodes();
        for (var i:int = 0; i < allSections.length; i++) {
            var someSection:ProjectData = allSections[i];
            var allPartsInSection:Array = ModelUtils.getChildrenOfType(someSection, DataFields.PART);
            if (allPartsInSection.length == 0) {
                continue;
            }
            var referencePart:ProjectData = allPartsInSection[0];
            var numMeasuresInPart:int = referencePart.numDataChildren;
            if (numMeasuresInPart < measureNumber) {
                measureNumber -= numMeasuresInPart;
            } else {
                var uid:String = referencePart.getDataChildAt(measureNumber - 1).route;
                if (_measureNumberToUidMap == null) {
                    _measureNumberToUidMap = {};
                }
                _measureNumberToUidMap[measureNumber] = uid;
                return uid;
            }
        }
        return null;
    }

    public function nudgeElementDown(element:ProjectData, nudgeLock:Boolean):ProjectData {
        return NudgingTools.nudgeElement(element, 1, nudgeLock);
    }

    public function nudgeElementUp(element:ProjectData, nudgeLock:Boolean):ProjectData {
        return NudgingTools.nudgeElement(element, -1, nudgeLock);
    }

    /**
     * Transfers one or more "note streams" to a given `part`, rebaring the
     * music as needed.
     *
     * A "note stream" is a fancy term for an Array containing instances of
     * the ro.ciacob.maidens.generators::MusicEntry class. Generators return one
     * or more of such "streams", grouped by their destination `part` and
     * `voice`.
     *
     * @param    part
     *            The target `part` node. Its `measure` nodes will receive
     *            the given "note stream", after rebaring it and converting it
     *            into MAIDENS format.
     *
     * @param    notesStream
     *            A possibly empty Array containing ro.ciacob.maidens.generators::MusicEntry
     *            instances.
     *
     * @param    staffVoiceIndices
     *            Optional. Determines the staff, and the voice within that staff,
     *            that will receive the given "note stream". If given, this must be
     *            an Array with two integers, representing staff index and voice index,
     *            respectively.
     *
     *            By default, all the available staves and voices are occupied,
     *            in order, and then additional, "orphaned" voices are created to
     *            hold the music that did not fit elsewhere.
     *
     *            The order is: firstly staves, and then voices. Assuming that the
     *            part has two staves available, and that there are four streams to
     *            allocate, the order will be:
     *            1) 1st voice of 1st staff;
     *            2) 1st voice of 2nd staff;
     *            3) 2nd voice of 1st staff;
     *            4) 2nd voice of 2nd staff.
     *
     * @param    numMeasures
     *            Optional. The number of measures the given "note stream" is to be
     *            fitted in. By default, the existing number of measures is used, with
     *            remaining music being trimmed. Measures are cleared out before
     *            writing new content to it, and any unfilled space is padded with
     *            rests.
     *
     * @param    numStartMeasure
     *            TODO: implement
     *            Optional. The number of the measure, within the current section,
     *            where to start overriding the existing content. This value is zero
     *            based.
     *
     * @param    timeSignatures
     *            Optional. An object having integers as keys and instances of the class
     *            ro.ciacob.math::Fraction as values. Defines the time signature changes
     *            within our target measures, with index 0 representing the first
     *            `measure`, of the `part` node, and so on. By default, the existing
     *            time signatures are used.
     */
    public function putIntoMeasures(part:ProjectData, notesStream:Array, staffVoiceIndices:Array = null,
                                    numMeasures:int = -1, numStartMeasure:int = 0, timeSignatures:Object = null):void {
        var parentSection:ProjectData = (part.dataParent as ProjectData);
        if (numMeasures == -1) {
            numMeasures = getSectionNumMeasures(parentSection);
        }
        if (timeSignatures == null) {
            timeSignatures = getTimeFractionsInSection(parentSection);
        }
        for (var i:int = 0; i < numMeasures; i++) {
            var measure:ProjectData = (part.getDataChildAt(i) as ProjectData);
            if (staffVoiceIndices == null) {
                staffVoiceIndices = getNextEmptyStaffVoiceIndices(measure);
                if (staffVoiceIndices == null) {
                    break;
                }
            }
            var availableDuration:Fraction = null;
            var filledDuration:Fraction = new Fraction(0);
            var measureDuration:Fraction = (timeSignatures[i] as Fraction);
            while (filledDuration.lessThan(measureDuration) && notesStream.length > 0) {
                var entry:MusicEntry = (notesStream.shift() as MusicEntry);
                var entryDuration:Fraction = entry.duration;
                availableDuration = measureDuration.subtract(filledDuration) as Fraction;
                var isLess:Boolean = entryDuration.lessThan(availableDuration);
                var isEqual:Boolean = entryDuration.equals(availableDuration);
                var fits:Boolean = (isLess || isEqual);
                if (!fits) {
                    var splitEntry:MusicEntry = new MusicEntry(entry.pitch, availableDuration, true);
                    var remainderEntry:MusicEntry = new MusicEntry(entry.pitch, entryDuration.subtract(availableDuration) as Fraction, entry.tie);
                    notesStream.unshift(remainderEntry);
                    entry = splitEntry;
                }
                if (!hasKnownDuration(entry)) {
                    var transcription:Array = transcribeIntoKnownDurations(entry);
                    entry = transcription.shift();
                    if (transcription.length > 0) {
                        notesStream = transcription.concat(notesStream);
                    }
                }
                addEntryToMeasure(entry, measure, staffVoiceIndices);
                filledDuration = filledDuration.add(entry.duration) as Fraction;
            }
            // Fill with rests any remaining duration in the last measure(s). Do not fill, however, second voice
            // where it is not used.
            var isSecondVoice:Boolean = (staffVoiceIndices && (staffVoiceIndices[1] == 2));
            var isEmptyMeasure:Boolean = filledDuration.equals(Fraction.ZERO);
            var mustSkip:Boolean = (isSecondVoice && isEmptyMeasure);
            if (!mustSkip && filledDuration.lessThan(measureDuration)) {
                var durationToFill:Fraction = (filledDuration.equals(Fraction.ZERO) ? Fraction.WHOLE : measureDuration.subtract(filledDuration) as Fraction);
                var compositeRestEntry:MusicEntry = new MusicEntry(0, durationToFill);
                var splitRestEntries:Array = transcribeIntoKnownDurations(compositeRestEntry);
                splitRestEntries.reverse();
                while (splitRestEntries.length > 0) {
                    var splitRestEntry:MusicEntry = (splitRestEntries.shift() as MusicEntry);
                    addEntryToMeasure(splitRestEntry, measure, staffVoiceIndices);
                }
            }
        }
    }

    public function splitIntoCommonFractions(fraction:Fraction, useComposites:Boolean = false):Array {
        var values:Array = [];
        var commonFractions:Array = MusicUtils.getCommonFractionsList(true, useComposites).concat();
        commonFractions.reverse();
        for (var i:int = 0; i < commonFractions.length; i++) {
            var commonFraction:Fraction = (commonFractions[i] as Fraction);
            do {
                if (fraction.equals(Fraction.ZERO)) {
                    break;
                }
                var isGreater:Boolean = fraction.greaterThan(commonFraction);
                var isEqual:Boolean = fraction.equals(commonFraction);
                var commonFractionFits:Boolean = (isGreater || isEqual);
                if (!commonFractionFits) {
                    break;
                }
                values.push(commonFraction);
                fraction = fraction.subtract(commonFraction) as Fraction;
            } while (true);
        }
        return values;
    }

    /**
     * TODO: rewrite to use `splitIntoCommonFractions()` instead.
     */
    public function transcribeIntoKnownDurations(entry:MusicEntry):Array {
        var transcription:Array = [];
        var zero:Fraction = new Fraction(0);
        var entryDuration:Fraction = entry.duration;
        var entryPitch:int = entry.pitch;
        var entryTie:Boolean = entry.tie;
        var commonFractions:Array = MusicUtils.getCommonFractionsList(true, true).concat();
        commonFractions.reverse();
        for (var i:int = 0; i < commonFractions.length; i++) {
            var commonFraction:Fraction = (commonFractions[i] as Fraction);
            do {
                if (entryDuration.equals(zero)) {
                    break;
                }
                var isGreater:Boolean = entryDuration.greaterThan(commonFraction);
                var isEqual:Boolean = entryDuration.equals(commonFraction);
                var knownDurationFits:Boolean = (isGreater || isEqual);
                if (!knownDurationFits) {
                    break;
                }
                var transcribedEntry:MusicEntry = new MusicEntry(entryPitch, commonFraction, true);
                transcription.push(transcribedEntry);
                entryDuration = entryDuration.subtract(commonFraction) as Fraction;
            } while (true);
        }
        if (transcription.length > 0) {
            var lastEntry:MusicEntry = (transcription[transcription.length - 1] as MusicEntry);
            lastEntry.tie = entryTie;
        }

        // We make the sound assumption that any composite musical duration is
        // representable as a sum of several simple (or "known") musical durations.
        // That being the case, the above process should have consumed
        // `entryDuration` completely, and its value should be 0 by now.
        return transcription;
    }

    public function uidToMeasureNumber(measureUid:String):int {
        if (_uidToMeasureNumberMap != null && (measureUid in _uidToMeasureNumberMap)) {
            return _uidToMeasureNumberMap[measureUid];
        }
        var referenceMeasure:ProjectData = _getReferenceMeasureFor(measureUid);
        if (referenceMeasure != null) {
            var localMeasureNumber:int = (referenceMeasure.index + 1);
            var currentSection:ProjectData = ProjectData(referenceMeasure.dataParent.dataParent);
            if (currentSection.index == 0) {
                if (_uidToMeasureNumberMap == null) {
                    _uidToMeasureNumberMap = {};
                }
                _uidToMeasureNumberMap[measureUid] = localMeasureNumber;
                return localMeasureNumber;
            }
            _resetMeasuresCounting();
            _backwardWalkSiblingsOf(currentSection, _countMeasuresInSection);
            var globalMeasureNumber:Number = (_getMeasuresCountingResult() + localMeasureNumber);
            if (_uidToMeasureNumberMap == null) {
                _uidToMeasureNumberMap = {};
            }
            _uidToMeasureNumberMap[measureUid] = globalMeasureNumber;
            return globalMeasureNumber;
        }
        return 0;
    }

    /**
     * Modifies content of an element from a map of new values. The element is to be
     * looked up by its `route`. Changing only occurs if the set of keys in the map
     * exactly matches the set of keys in the element to be modified.
     *
     * @param    elementUID
     *            The route to the element to be updated content of.
     *
     * @param    newValues
     *            A map of new keys and values to apply to the element.
     *
     * @return    True if the update operation has succeeded, false otherwise (the
     *            element wasn't found, or the set of keys do not match).
     */
    public function updateContentOf(elementUID:String, newValues:Object):Boolean {
        var targetEl:ProjectData = ProjectData(_dataSource.getElementByRoute(elementUID));
        if (targetEl != null) {
            var targetKeys:Array = targetEl.getContentKeys();
            var srcKeys:Array = Objects.getKeys(newValues, true);
            if (Arrays.sortAndTestForIdenticPrimitives(targetKeys, srcKeys)) {
                for (var key:String in newValues) {
                    var value:Object = newValues[key];
                    targetEl.setContent(key, value);
                }
                return true;
            }
        }
        return false;
    }

    ciacob function forciblyAddExistingChild(parent:ProjectData, child:ProjectData, index:int = -1):void {
        if (index == -1) {
            index = parent.numDataChildren;
        }
        parent.addDataChildAt(child, index);
    }

    private function $(identifier:Object):ProjectData {
        if (identifier is ProjectData) {
            return ProjectData(identifier);
        }
        if (identifier is String) {
            return ProjectData(_dataSource.getElementByRoute(identifier as String));
        }
        return null;
    }

    private static function _backwardWalkSiblingsOf(element:ProjectData, callback:Function):Object {
        if (element != null) {
            var parent:ProjectData = ProjectData(element.dataParent);
            if (parent != null) {
                var index:int = (element.index - 1);
                while (index >= 0) {
                    var sibling:ProjectData = ProjectData(parent.getDataChildAt(index));
                    if (ModelUtils.haveSameType(sibling, element)) {
                        var result:* = callback(sibling);
                        if (result !== undefined) {
                            return result;
                        }
                    }
                    index--;
                }
            }
        }
        return undefined;
    }

    private function _countMeasuresInSection(section:ProjectData):void {
        _measuresCount += getSectionNumMeasures(section);
    }

    private function _createClusterOf(voice:ProjectData, bypassAutomation:Boolean = false):ProjectData {
        var cluster:ProjectData = new ProjectData;
        var details:Object = {};
        details[DataFields.DATA_TYPE] = DataFields.CLUSTER;
        cluster.populateWithDefaultData(details);
        if (!bypassAutomation) {
            if (lastEnteredDuration != null) {
                cluster.setContent(DataFields.CLUSTER_DURATION_FRACTION, lastEnteredDuration);
            }
        }
        voice.addDataChild(cluster);
        if (!bypassAutomation && usingNotesRatherThanRests) {
            return _createNoteOf(cluster);
        }
        return cluster;
    }

    private function _createGenerator():ProjectData {
        var generator:ProjectData = new ProjectData;
        var details:Object = {};
        details[DataFields.DATA_TYPE] = DataFields.GENERATOR;
        generator.populateWithDefaultData(details);
        var connIDs:Array = getAllConnectionUids();
        var connId:String = _getUniqueIndexedName(connIDs, StaticTokens.DEFAULT_CONNECTION_PREFIX);
        generator.setContent(DataFields.CONNECTION_UID, connId);
        var generators:ProjectData = getGeneratorsParentNode();
        generators.addDataChild(generator);
        return generator;
    }

    /**
     * Creates a Measure node inside the given Part node. The created Measure contains two
     * Voice nodes per each staff used.
     */
    private static function _createMeasureOf(part:ProjectData):ProjectData {
        if (!part) {
            return null;
        }
        var currSection:ProjectData = ProjectData(part.dataParent);
        var partsInCurrSection:Array = ModelUtils.getChildrenOfType(currSection, DataFields.PART);
        var measureAddedInCurrentPart:ProjectData = null;
        for (var i:int = 0; i < partsInCurrSection.length; i++) {
            var somePart:ProjectData = ProjectData(partsInCurrSection[i]);
            var measure:ProjectData = new ProjectData;
            if (somePart === part) {
                if (measureAddedInCurrentPart == null) {
                    measureAddedInCurrentPart = ProjectData(measure);
                }
            }
            var details:Object = {};
            details [DataFields.DATA_TYPE] = DataFields.MEASURE;
            measure.populateWithDefaultData(details);
            somePart.addDataChild(measure);

            // Create needed voices for each staff of the part
            _addVoicesToMeasure(measure);
        }
        return (measureAddedInCurrentPart || part);
    }

    /**
     * Creates the maximum permitted number of Voices inside the given Measure, considering
     * each staff of the parent Part. Also, sets them to show in the correct slot and on the
     * correct staff.
     *
     * NOTE: Both voice order and staff indices are 1-based (first index is `1`, not `0`).
     */
    private static function _addVoicesToMeasure(measure:ProjectData):Array {
        var parentPart:ProjectData = ProjectData(measure.dataParent);
        var numPartStaves:int = ModelUtils.getPartNumStaves(parentPart);
        var j:int;
        var k:int;
        var voice:ProjectData;
        var output:Array = [];
        for (j = 0; j < numPartStaves; j++) {
            for (k = 0; k < Voices.NUM_VOICES_PER_STAFF; k++) {
                voice = _createVoiceOf(measure);
                voice.setContent(DataFields.VOICE_INDEX, k + 1);
                voice.setContent(DataFields.STAFF_INDEX, j + 1);
                output.push(voice);
            }
        }
        return output;
    }

    private function _createNoteOf(cluster:ProjectData):ProjectData {
        usingNotesRatherThanRests = true;
        var note:ProjectData = new ProjectData;
        var details:Object = {};
        details[DataFields.DATA_TYPE] = DataFields.NOTE;
        note.populateWithDefaultData(details);

        // If the parent Cluster is empty, the current note will replicate either the default pitch, or the last
        // entered pitch (if available), in an attempt to ease entering melodic passages. If the Cluster is NOT
        // empty, the new note will be added above or below existing notes (depending on voice) in an attempt to
        // ease entering harmonies.
        // @see _avoidPitchCollisions()
        if (cluster.numDataChildren == 0) {
            if (lastEnteredPitch != -1) {
                var tmpNote:ProjectData = MusicUtils.midiNumberToNote(lastEnteredPitch);
                note.setContent(DataFields.PITCH_NAME, tmpNote.getContent(DataFields.PITCH_NAME));
                note.setContent(DataFields.PITCH_ALTERATION, tmpNote.getContent(DataFields.PITCH_ALTERATION));
                note.setContent(DataFields.OCTAVE_INDEX, tmpNote.getContent(DataFields.OCTAVE_INDEX));
            }
        } else {
            var parentVoice:ProjectData = (cluster.dataParent as ProjectData);
            var voiceIndex:int = parentVoice.getContent(DataFields.VOICE_INDEX);
            var refNote:ProjectData = ((voiceIndex == 1) ?
                    cluster.getDataChildAt(cluster.numDataChildren - 1) :
                    cluster.getDataChildAt(0)) as ProjectData;
            note.setContent(DataFields.PITCH_NAME, refNote.getContent(DataFields.PITCH_NAME));
            note.setContent(DataFields.PITCH_ALTERATION, refNote.getContent(DataFields.PITCH_ALTERATION));
            note.setContent(DataFields.OCTAVE_INDEX, refNote.getContent(DataFields.OCTAVE_INDEX));
        }

        // While musically legit, unisons (multiple headed notes on same pitch) cause technical issues in
        // MAIDENS, and will be avoided, at least for the time being.
        note = _avoidPitchCollisions(note, cluster);
        cluster.addDataChild(note);
        orderChildNotesByPitch(cluster);
        return note;
    }

    /**
     * Checks if the current pitch of the given `note` would cause a pitch collision with one of the pitches of the
     * other Notes currently in the given `parentCluster`. Starting with v.1.5, we do not support same voice unisons
     * anymore.
     */
    public function causesPitchCollision(note:ProjectData, parentCluster:ProjectData):Boolean {
        var notePitch:int = MusicUtils.noteToMidiNumber(note);
        var pitchesInCluster:Array = [];
        for (var i:int = 0; i < parentCluster.numDataChildren; i++) {
            var tmpNote:ProjectData = (parentCluster.getDataChildAt(i) as ProjectData);
            if (tmpNote.route != note.route) {
                pitchesInCluster.push(MusicUtils.noteToMidiNumber(tmpNote));
            }
        }
        var pitchExists:Boolean = (pitchesInCluster.indexOf(notePitch) != -1);
        return pitchExists;
    }

    /**
     * Alters given note's pitch if it would overlap another note in the given parentCluster that has the same
     * pitch. Shifts the existing pitch diatonicaly by a third or fourth, until it finds an open spot to settle.
     * Notes in first voice shift up, notes in second voice shift down.
     */
    public function _avoidPitchCollisions(note:ProjectData, parentCluster:ProjectData):ProjectData {
        while (causesPitchCollision(note, parentCluster)) {
            var parentVoice:ProjectData = (parentCluster.dataParent as ProjectData);
            var voiceIndex:int = parentVoice.getContent(DataFields.VOICE_INDEX);
            var direction:int = ((voiceIndex == 1) ? 1 : -1);
            var notePitch:int = MusicUtils.noteToMidiNumber(note, true);
            notePitch += (IntervalsSize.MAJOR_THIRD * direction);
            var tmpNote:ProjectData = MusicUtils.midiNumberToNote(notePitch);
            note.setContent(DataFields.PITCH_NAME, tmpNote.getContent(DataFields.PITCH_NAME));
            note.setContent(DataFields.PITCH_ALTERATION, PitchAlterationTypes.NATURAL);
            note.setContent(DataFields.OCTAVE_INDEX, tmpNote.getContent(DataFields.OCTAVE_INDEX));
        }
        return note;
    }

    /**
     * Makes sure all Notes in the given parent cluster match their natural ordering
     * (index, route) with their pitch ordering (from lowest to highest). This is required
     * by external limitations found both in the ABC notation design (one cannot annotate
     * individual notes in a chord) and the ABC parser library (it orders all chord pitches
     * as a matter of fact, and depends on that). This step prevents misalignment
     * when selecting individual notes of a chord from the score.
     *
     * As a side effect, observes given `noteToObserve` (which must be a child of `parentCluster`) and outputs the
     * equivalent one, should reordering had affected its route. This can help maintain selection in certain
     * scenarios.
     */
    public function orderChildNotesByPitch(parentCluster:ProjectData, noteToObserve:ProjectData = null):ProjectData {
        if (parentCluster.numDataChildren > 1) {
            if (noteToObserve) {
                noteToObserve.setContent(DataFields.FLAGGED, true);
            }
            var sortedNotes:Array = parentCluster._children.concat();
            sortedNotes.sort(_compareNoteChildren);
            for (var noteIdx:int = 0; noteIdx < sortedNotes.length; noteIdx++) {
                var note:ProjectData = (sortedNotes[noteIdx] as ProjectData);
                if (note.index != noteIdx) {
                    note.enforceIndex(noteIdx, true, true);
                    if (note.getContent(DataFields.FLAGGED)) {
                        note.setContent(DataFields.FLAGGED, false);
                        noteToObserve = note;
                    }
                    note.resetIntrinsicMeta();
                }
            }
        }
        return noteToObserve;
    }

    /**
     * Used as an argument to Array.sort() to order notes in a cluster by their pitch.
     */
    private static function _compareNoteChildren(noteA:ProjectData, noteB:ProjectData):int {
        return MusicUtils.noteToMidiNumber(noteB) - MusicUtils.noteToMidiNumber(noteA);
    }

    /**
     * LOCAL Part creation is a facade for GLOBAL part creation. Whenever we are explicitly
     * requested to create a Part in a specific Section, we need to ensure that it also exists
     * in all the other Sections. This behavior is also replicated when updating and deleting
     * Parts.
     */
    private function _createPartFrom(anchorSection:ProjectData):ProjectData {
        __beingCreatedPartUuid = Strings.UUID;
        var partNodeToReturn:ProjectData = null;
        var allSections:Array = getAllSectionNodes();
        for (var i:int = 0; i < allSections.length; i++) {
            var someSection:ProjectData = (allSections[i] as ProjectData);
            var allPartsInSection:Array = ModelUtils.getChildrenOfType(someSection, DataFields.PART);
            var matchingParts:Array = allPartsInSection.filter(__partsByUuid);
            if (matchingParts.length == 0) {
                var createdPart:ProjectData = _createPartChildOfSectionNode(someSection, __beingCreatedPartUuid);
                if (someSection === anchorSection) {
                    partNodeToReturn = createdPart;
                }
            }
        }
        __beingCreatedPartUuid = null;
        return partNodeToReturn;
    }

    /**
     * @volatile
     * Only used while creating part nodes. Do not employ anywhere else.
     */
    private var __beingCreatedPartUuid:String;

    /**
     * @filter
     * Only used as a filter function to retrieve Part nodes having a specific uid. Do not employ in other
     * scenarios.
     */
    private function __partsByUuid(part:ProjectData, ...ignore):Boolean {
        return (part.getContent(DataFields.PART_MIRROR_UID) === __beingCreatedPartUuid);
    }

    /**
     * Creates a Part node as a child of a Section node, and stamps it with a unique ID,
     * so that we can transparently maintain global settings across all the nodes that represent
     * the same musical Part, but in different Sections. See also the note on `_createPartFrom()`.
     *
     * @param sectionNode
     *          The Section note to place the new Part node under.
     *
     * @param uuid
     *          The universally unique ID to be applied to the Part node being created.
     *
     * @returns
     *         The new Part node.
     *
     * NOTE: When creating a Part, we must also automatically create a number of Measures,
     * as many as there already are within the first part -- if there is such a part.
     * If there isn't (because the part we are creating IS the first part of the
     * section) then only one measure will automatically be created.
     */
    private static function _createPartChildOfSectionNode(sectionNode:ProjectData, uuid:String):ProjectData {
        if (!uuid) {
            throw (new Error('`_createPartChildOfSectionNode()` requires a non-nul part UUID'));
        }
        var partsInCurrentSection:Array = ModelUtils.getChildrenOfType(sectionNode, DataFields.PART);
        var notFirstPartInScore:Boolean = (partsInCurrentSection.length > 0);

        var part:ProjectData = new ProjectData;
        var details:Object = {};
        details[DataFields.DATA_TYPE] = DataFields.PART;
        part.populateWithDefaultData(details);
        part.setContent(DataFields.PART_MIRROR_UID, uuid);
        sectionNode.addDataChild(part);

        // If this is not the first Part of this Section, we must populate it with Measures, so that
        // every Part node in the current Section has the same number of Measures.
        if (notFirstPartInScore) {
            var srcPart:ProjectData = ProjectData(partsInCurrentSection[0]);
            for (var i:int = 0; i < srcPart.numDataChildren; i++) {
                var srcMeasure:ProjectData = ProjectData(srcPart.getDataChildAt(i));
                var srcMeasureAttributes:Object = srcMeasure.getContentMap();
                var measure:ProjectData = new ProjectData;
                details = {};
                details[DataFields.DATA_TYPE] = DataFields.MEASURE;
                measure.populateWithDefaultData(details);
                for (var srcKey:String in srcMeasureAttributes) {
                    var srcValue:Object = srcMeasureAttributes[srcKey];
                    measure.setContent(srcKey, srcValue);
                }
                part.addDataChild(measure);

                // Create needed voices for each staff of the part
                _addVoicesToMeasure(measure);
            }
        } else {

            // If this is the first Part of the Score, we still need to add one
            // Measure to it, because otherwise, the Part will not draw in the
            // music sheet.
            _createMeasureOf(part);
        }
        return part;
    }

    private function _createSection():ProjectData {
        var section:ProjectData = new ProjectData;
        var details:Object = {};
        details[DataFields.DATA_TYPE] = DataFields.SECTION;
        section.populateWithDefaultData(details);
        section.setContent(DataFields.UNIQUE_SECTION_NAME, getNewSectionName());
        var connectionIDs:Array = getAllConnectionUids();
        var connectionId:String = _getUniqueIndexedName(connectionIDs, StaticTokens.DEFAULT_CONNECTION_PREFIX);
        section.setContent(DataFields.CONNECTION_UID, connectionId);
        var score:ProjectData = getScoreNode();
        score.addDataChild(section);
        _copyExistingPartsToSection(section);
        return section;
    }

    private function _copyExistingPartsToSection(section:ProjectData):void {
        var score:ProjectData = getScoreNode();
        var firstSection:ProjectData = (score.getDataChildAt(0) as ProjectData);
        var allPartsInFirstSection:Array = ModelUtils.getChildrenOfType(firstSection, DataFields.PART);
        var partClone:ProjectData = null;
        allPartsInFirstSection.forEach(function (part:ProjectData, ...etc):void {
            partClone = part.clone() as ProjectData;
            partClone.empty();
            partClone.setContent(DataFields.PART_UID, DataFields.VALUE_NOT_SET);
            section.addDataChild(partClone);
        });
        // This actually creates a measure stack, i.e., one measure for each current part
        _createMeasureOf(partClone);
    }

    private static function _createVoiceOf(measure:ProjectData):ProjectData {
        var voice:ProjectData = new ProjectData;
        var details:Object = {};
        details[DataFields.DATA_TYPE] = DataFields.VOICE;
        voice.populateWithDefaultData(details);
        // If this is the first voice in the parent measure, we also set it
        // as the first voice of the first staff
        if (measure.numDataChildren == 0) {
            voice.setContent(DataFields.VOICE_INDEX, 1);
            voice.setContent(DataFields.STAFF_INDEX, 1);
        }
        measure.addDataChild(voice);
        return voice;
    }

    /**
     * Removes given `section` from all generator bindings where it might be used.
     * @param section - A section to unbind.
     */
    private function _unbindSection (section:ProjectData):void {
        var connectionUid : String;
        if ((connectionUid = section.getContent(DataFields.CONNECTION_UID)) != DataFields.VALUE_NOT_SET) {
            var generators : Array = getAllGeneratorNodes();
            for each (var generator : ProjectData in generators) {
                var generatorOutputs : Array = generator.getContent(GeneratorKeys.OUTPUT_CONNECTIONS) as Array;
                if (generatorOutputs && generatorOutputs.length) {
                    var matchIndex : int = generatorOutputs.indexOf(connectionUid);
                    if (matchIndex != -1) {
                        generatorOutputs.removeAt(matchIndex);
                    }
                }
            }
        }
    }

    private static function _deleteMeasureElement(measureToDelete:ProjectData):ProjectData {
        var currentPart:ProjectData = ProjectData(measureToDelete.dataParent);
        var currentSection:ProjectData = ProjectData(currentPart.dataParent);
        var allPartsInCurrentSection:Array = ModelUtils.getChildrenOfType(currentSection, DataFields.PART);
        var indexToDelete:int = measureToDelete.index;
        var currentReplacement:ProjectData = null;
        for (var i:int = 0; i < allPartsInCurrentSection.length; i++) {
            var somePart:ProjectData = ProjectData(allPartsInCurrentSection[i]);
            if (somePart == currentPart) {
                if (indexToDelete > 0) {
                    currentReplacement = ProjectData(somePart.getDataChildAt(indexToDelete - 1));
                } else if (somePart.numDataChildren > 1) {
                    currentReplacement = ProjectData(somePart.getDataChildAt(indexToDelete + 1));
                } else {
                    currentReplacement = somePart;
                }
            }
            somePart.removeDataChildAt(indexToDelete);
        }
        return ProjectData(currentReplacement);
    }

    private static function _deleteOrdinaryElement(element:ProjectData):ProjectData {
        var parent:ProjectData = ProjectData(element.dataParent);
        var elType:String = element.getContent(DataFields.DATA_TYPE);
        var relevantChildren:Array = ModelUtils.getChildrenOfType(parent, elType);
        var numRelevantChildren:int = relevantChildren.length;
        var replacement:ProjectData;
        var elRelevantIndex:int = relevantChildren.indexOf(element);
        if (elRelevantIndex > 0) {
            replacement = relevantChildren[elRelevantIndex - 1];
        } else if (numRelevantChildren > 1) {
            replacement = relevantChildren[elRelevantIndex + 1];
        } else {
            replacement = parent;
        }
        parent.removeDataChild(element);
        return ProjectData(replacement);
    }

    private function _getMeasuresCountingResult():int {
        return _measuresCount;
    }

    private function _getReferenceMeasureFor(someMeasure:*):ProjectData {
        var givenMeasure:ProjectData = $(someMeasure);
        if (givenMeasure != null) {
            var givenMeasureIndex:int = givenMeasure.index;
            if (givenMeasureIndex >= 0) {
                var currentPart:ProjectData = ProjectData(givenMeasure.dataParent);
                var currentSection:ProjectData = ProjectData(currentPart.dataParent);
                var allPartsInCurrentSection:Array = ModelUtils.getChildrenOfType(currentSection, DataFields.PART);
                var referencePart:ProjectData = ProjectData(allPartsInCurrentSection[0]);
                return ProjectData(referencePart.getDataChildAt(givenMeasureIndex));
            }
        }
        return null;
    }

    private static function _getUniqueIndexedName(namesPool:Array, prefix:String = null, suffix:String = null):String {
        var testName:String;
        var count:int = 1;
        while (namesPool.indexOf(testName = ((prefix || '') as String).concat(count).concat(suffix || '')) >= 0) {
            count++;
        }
        return testName;
    }

    /**
     * @see "getShortUidFor()"
     */
    private function _registerShortUidFor(fullElementUID:String):void {
        var stem:uint = _uidsMapCounter++;
        var _shortUid:String = stem.toString().concat(CommonStrings.BROKEN_VERTICAL_BAR);
        _fullToShortUidsMap[fullElementUID] = _shortUid;
        _shortToFullUidsMap[_shortUid] = fullElementUID;
    }

    private function _resetMeasuresCounting():void {
        _measuresCount = 0;
    }

    /**
     * Splits a single or double dotted note duration into the original duration
     * and the dot value.
     *
     * @param    compositeDuration
     *           The duration to split
     *
     * @return    An Array containing two instances of ro.ciacob.math::Fraction,
     *            the first representing the simple (original duration), and
     *            the second the value of the dot.
     *
     *            If there was not a simple, nor double dot used, the first value
     *            is the given (composite) duration, and the second is a fraction
     *            equivalent to 0.
     */
    private static function _splitCompositeDuration(compositeDuration:Fraction):Array {
        var knownDotValues:Array = [DotTypes.SINGLE, DotTypes.DOUBLE];
        var knownSimpleDurations:Array = ConstantUtils.getAllValues(DurationFractions);
        for (var i:int = 0; i < knownDotValues.length; i++) {
            var dotValue:Fraction = Fraction.fromString(knownDotValues[i] as String);
            var multiplier:Fraction = dotValue.add(new Fraction(1)) as Fraction;
            var simpleDuration:Fraction = compositeDuration.divide(multiplier) as Fraction;
            for (var j:int = 0; j < knownSimpleDurations.length; j++) {
                var knownDuration:Fraction = (knownSimpleDurations[j] as Fraction);
                if (knownDuration.equals(simpleDuration)) {
                    return [simpleDuration, dotValue];
                }
            }

        }
        return [compositeDuration, new Fraction(0)];
    }
}
}
