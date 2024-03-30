package ro.ciacob.maidens.model.exporters {
import eu.claudius.iacob.synth.sound.map.NoteAttackInfo;
import eu.claudius.iacob.synth.sound.map.NoteTrackObject;
import eu.claudius.iacob.synth.sound.map.ScoreItemAnnotation;
import eu.claudius.iacob.synth.sound.map.Timeline;
import eu.claudius.iacob.synth.sound.map.Track;
import eu.claudius.iacob.synth.utils.PresetDescriptor;
import eu.claudius.iacob.synth.utils.TrackDescriptor;

import ro.ciacob.desktop.ui.utils.CommonStrings;
import ro.ciacob.maidens.generators.constants.duration.TimeSignature;
import ro.ciacob.maidens.generators.constants.parts.PartMidiPatches;
import ro.ciacob.maidens.legacy.ModelUtils;
import ro.ciacob.maidens.legacy.ProjectData;
import ro.ciacob.maidens.legacy.constants.DataFields;

import ro.ciacob.math.Fraction;
import ro.ciacob.utils.Strings;

/**
 * Translator class that takes a MAIDENS project as "input" and produces a Timeline instance that can be read into
 * synthesizer low-level instructions (e.g., "note on", "note off", etc.).
 */
public class SynthTracksProducer {

    public static const DEFAULT_UNIT_TIME_NORM:uint = 4000;

    private static const SECTION_COLUMN:uint = 2;
    private static const PART_COLUMN:uint = 3;
    private static const MEASURE_COLUMN:uint = 4;
    private static const VOICE_COLUMN:uint = 5;
    private static const ANNOTATION_SUFFIX:String = '_annotation';

    private var _source:ProjectData;
    private var _startLabel:String;
    private var _endLabel:String;
    private var _solos:Vector.<TrackDescriptor>;
    private var _mutes:Vector.<TrackDescriptor>;
    private var _timeLine:Timeline;
    private var _unitTimeNorm:uint;
    private var _presetDescriptors:Vector.<PresetDescriptor>;

    /**
     * The MAIDENS project to produce tracks from.
     */
    public function get source():ProjectData {
        return _source;
    }

    public function set source(value:ProjectData):void {
        _source = value;
    }

    /**
     * A label to start reading the internally created Timeline from. This would most likely be the `_route` of a
     * "cluster" or measure. If `null`, reading will start at the very beginning of the Timeline.
     */
    public function get startLabel():String {
        return _startLabel;
    }

    public function set startLabel(value:String):void {
        _startLabel = value;
    }

    /**
     * A label to start reading the created Timeline from. This would most likely be the `_route` of a "cluster" or
     * measure.
     */
    public function get endLabel():String {
        return _endLabel;
    }

    public function set endLabel(value:String):void {
        _endLabel = value;
    }

    /**
     * The Tracks to "solo" in the internally build Timeline before "reading" it.
     */
    public function get solos():Vector.<TrackDescriptor> {
        return _solos;
    }

    public function set solos(value:Vector.<TrackDescriptor>):void {
        _solos = value;
    }

    /**
     * The Tracks to "mute" in the internally build Timeline before "reading" it.
     */
    public function get mutes():Vector.<TrackDescriptor> {
        return _mutes;
    }

    public function set mutes(value:Vector.<TrackDescriptor>):void {
        _mutes = value;
    }

    /**
     * Returns the Timeline instance that was last built internally. Returns null if `compile` or `produce` were never
     * run.
     * @see eu.claudius.iacob.synth.sound.map.Timeline
     */
    public function get timeline():Timeline {
        return _timeLine;
    }

    /**
     * How many milliseconds long is a "whole note" suppose to be, notionally (i.e., ignoring any tempo instructions).
     * We need a fixed time norm in order to be able to correctly align the musical time events reliably, with respect
     * to one another; once all the events are in place on their respective Timeline tracks, we can implement tempo
     * control by simply playing the timeline at different speeds.
     */
    public function get unitTimeNorm():uint {
        return _unitTimeNorm;
    }

    /**
     * A Vector of PresetDescriptor instances (needed for preloading sound fonts).
     * @see PresetDescriptor
     */
    public function get presetDescriptors():Vector.<PresetDescriptor> {
        return _presetDescriptors;
    }

    /**
     * Translator class that takes a MAIDENS project as "input" and produces a Timeline instance that can be read into
     * synthesizer low-level instructions (e.g., "note on", "note off", etc.).
     *
     * @param   unitTimeNorm
     *          How many milliseconds long is a "whole note" supposed to be, notionally (i.e., ignoring any tempo
     *          instructions). We need a fixed time norm in order to be able to correctly align the musical time events
     *          reliably, with respect to one another; once all the events are in place on their respective Timeline
     *          tracks, we can implement tempo control by simply playing the timeline at different speeds.
     *
     *          This value trades time resolution for CPU processing power (the greater the value, the more precise
     *          musical events' start and stop times are, and the more processing power is needed).
     *
     *          Optional. Defaults to the value of the DEFAULT_UNIT_TIME_NORM constant.
     */
    public function SynthTracksProducer(unitTimeNorm:uint = 0) {
        if (!unitTimeNorm) {
            unitTimeNorm = DEFAULT_UNIT_TIME_NORM;
        }
        _unitTimeNorm = unitTimeNorm;
        _presetDescriptors = new Vector.<PresetDescriptor>;
    }

    /**
     * Compiles the `source` MAIDENS project into a Timeline, and "reads" it into a collection of "tracks" (ordered
     * low-level instructions for the synth).
     *
     * @return  The resulting "tracks".
     */
    public function produce():Array {
        var trackBluePrints:TrackBluePrints = _makeTrackBluePrints(_source);
        _updatePresetDescriptors(trackBluePrints);
        _timeLine = _buildTimeLine(trackBluePrints);
        return _readTimeline(_timeLine);
    }

    /**
     * Compiles the `source` MAIDENS project into a Timeline, but does not "read" it into a collection of "tracks". Also,
     * does not return a value.
     *
     * To access the Timeline that was internally built (and its Tracks), use the `timeline` getter.
     *
     * Useful if you need to externally work on the Timeline before sending it to playback. To do this, call `read()`
     * after you have externally changed the Timeline (instead of calling `produce()`, which builds the Timeline on
     * each call, thus overwriting your changes).
     */
    public function compile():void {
        var trackBluePrints:TrackBluePrints = _makeTrackBluePrints(_source);
        _updatePresetDescriptors(trackBluePrints);
        _timeLine = _buildTimeLine(trackBluePrints);
    }

    /**
     * "Reads" the Timeline that was internally built into a collection of ordered low-level instructions for the synth,
     * and returns them. DOES NOT rebuild the Timeline, thus allowing you to externally work on it before sending it to
     * playback.
     *
     * @return  The resulting "tracks". You MUST run `compile()` (or `produce()`) prior to calling this method, or it
     *          would return `null`.
     *
     * NOTE: the typical course of action for using this method is:
     * (1) call `compile()`;
     * (2) access the compiled timeline via the `timeline` getter, and do whatever changes you need;
     * (3) call `read` and feed the resulting tracks into the synth, which will retain your external changes.
     */
    public function read():Array {
        return _readTimeline(_timeLine);
    }

    /**
     * Constructs a Timeline instance and adds it one or more prepopulated Track instances, based on the given
     * `trackBluePrints`.
     *
     * @param   trackBluePrints
     *          A TrackBluePrints to use for building the TimeLine.
     *
     * @return  A properly populated Timeline instance.
     */
    private function _buildTimeLine(trackBluePrints:TrackBluePrints):Timeline {
        var timeline:Timeline = new Timeline;
        _plotTracks(trackBluePrints, timeline, _unitTimeNorm);
        return timeline;
    }

    /**
     * Reads given Timeline instance into a collection of ordered low-level instructions for the synth, and returns them.
     *
     * @param   timeline
     *          The Timeline to be "read".
     *
     * @return  A collection of ordered low-level instructions for the synth; you normally feed this information into
     *          the synth's `preRenderAudio()` method.
     */
    private function _readTimeline(timeline:Timeline):Array {
        if (timeline) {

            // Apply the label to start reading from; default to reading the entire timeline.
            if (!_startLabel || !timeline.setReadStartLabel(_startLabel)) {
                timeline.setFullRead();
            }

            // Apply solos if given; default to no solos.
            if (!_solos || !_solos.length || !timeline.applySolos(_solos)) {
                timeline.setNoSolos();
            }

            // Apply mutes if given; default to no mutes.
            if (!_mutes || !_mutes.length || !timeline.applyMutes(_mutes)) {
                timeline.setNoMutes();
            }

            // Actually "read" the timeline.
            return timeline.readOn();
        }
        return null;
    }

    /**
     * Uses given `bluePrints` to construct (or update) a Vector of PresetDescriptor instances (needed for preloading
     * sound fonts). The output of this function is cached and made available via the global "presetDescriptors" getter.
     *
     * @param   bluePrints
     *          A TrackBluePrints instance to compile a Vector of PresetDescriptor instances from.
     */
    private function _updatePresetDescriptors(bluePrints:TrackBluePrints):void {
        _presetDescriptors.length = 0;
        var presetsExported:Array = [];
        bluePrints.forEach(function (blueprintUid:String, blueprint:TrackBluePrint, index:uint):void {
            var presetNumber:int = blueprint.presetNumber;
            if (presetsExported.indexOf(presetNumber) == -1) {
                presetsExported.push(presetNumber);
                _presetDescriptors.push(new PresetDescriptor(presetNumber, blueprint.partLabel))
            }
        });
    }

    /**
     * Translates given MAIDENS `project` into a helper, intermediate format, where Voice objects are grouped by their
     * parent Part and "index" number (e.g., 1st voice comes before the 2nd voice), and are sorted by parent Section and
     * Measure; also, they have their start time computed based on both parent Measure's time signature and child
     * Clusters' cumulated duration (the later overriding the former).
     *
     * @param   project
     *          The MAIDENS project containing the Parts, Measures, etc. to build an organized audio mapping from.
     *
     * @return  An helper format to be internally used for building the actual Track instances of a Timeline.
     */
    private function _makeTrackBluePrints(project:ProjectData):TrackBluePrints {

        // Roughly group Voice objects by their own index, and by their parent Part index.
        var trackBluePrints:TrackBluePrints = new TrackBluePrints;
        var allVoiceNodes:Array = ModelUtils.getDescendantsOfType(project, DataFields.VOICE);
        var numVoiceNodes:uint = allVoiceNodes.length;
        var i:int;
        var voice:ProjectData;
        var route:String;
        var routeTokens:Array;
        var trackId:String;
        var parentPartId:String;
        var parentPartRoute:String;
        var parentPart:ProjectData;
        var parentPartName:String;
        var midiPatch:int;
        var voiceId:String;
        var firstBluePrint:TrackBluePrint;
        var currBluePrint:TrackBluePrint;
        var currVoiceInfo:VoiceInfo;
        var currStartTime:Fraction = Fraction.ZERO;
        var lastTimeSignature:Fraction = TimeSignature.COMMON_TIME;
        var measureTimeSignature:Fraction;
        var firstVoiceInfos:Vector.<VoiceInfo>;
        var numFirstVoiceObjects:int;
        var currRawVoice:ProjectData;
        var currParentMeasure:ProjectData;
        var beatsNumberSetting:Object;
        var beatsDurationSetting:Object;
        var prevVoiceInfo:VoiceInfo;
        var voiceStartsNewSection:Boolean;
        for (i = 0; i < numVoiceNodes; i++) {
            voice = (allVoiceNodes[i] as ProjectData);
            route = voice.route;
            routeTokens = route.split(CommonStrings.UNDERSCORE);
            parentPartId = (routeTokens[PART_COLUMN] as String);
            voiceId = (routeTokens[VOICE_COLUMN] as String);
            trackId = (parentPartId + voiceId);
            if (!(currBluePrint = trackBluePrints.get(trackId))) {
                parentPartRoute = routeTokens.slice(0, PART_COLUMN + 1).join(CommonStrings.UNDERSCORE);
                parentPart = (project.getElementByRoute(parentPartRoute) as ProjectData);
                parentPartName = parentPart.getContent(DataFields.PART_NAME);
                midiPatch = (PartMidiPatches[Strings.toAS3ConstantCase(parentPartName)] as int);
                trackBluePrints.add(trackId, (currBluePrint = new TrackBluePrint(parentPartName, midiPatch)));
            }
            currVoiceInfo = new VoiceInfo(routeTokens.map(__toIntegers), voice);
            currBluePrint.voiceObjects.push(currVoiceInfo);
        }

        // Ensure proper "Voice objects" sequence by sorting them by Section and by Measure.
        trackBluePrints.forEach(function (uid:String, blueprint:TrackBluePrint, i:uint):void {
            blueprint.voiceObjects.sort(__bySectionThenByMeasure);
        });

        // Compute the start time of each of the "Voice objects"; store the information in the "Voice objects"
        // themselves, in fraction format (e.g., 4 1/2, or "four wholes and a half").
        firstBluePrint = trackBluePrints.getFirst();
        firstVoiceInfos = firstBluePrint.voiceObjects;
        numFirstVoiceObjects = firstVoiceInfos.length;
        for (i = 0; i < numFirstVoiceObjects; i++) {
            currVoiceInfo = (firstVoiceInfos[i] as VoiceInfo);
            currRawVoice = currVoiceInfo.rawVoiceData;
            if (i > 0) {
                prevVoiceInfo = firstVoiceInfos[i - 1];
                voiceStartsNewSection = (currVoiceInfo.indicesMap[SECTION_COLUMN] !=
                        prevVoiceInfo.indicesMap[SECTION_COLUMN]);
            }
            currParentMeasure = (currRawVoice.dataParent as ProjectData);
            beatsNumberSetting = currParentMeasure.getContent(DataFields.BEATS_NUMBER) as Object;
            beatsDurationSetting = currParentMeasure.getContent(DataFields.BEAT_DURATION) as Object;
            if (!beatsNumberSetting || !beatsDurationSetting ||
                    (beatsNumberSetting == DataFields.VALUE_NOT_SET) ||
                    (beatsDurationSetting == DataFields.VALUE_NOT_SET)) {

                // If this Voice object starts a new Section, then "lastTimeSignature" must be reset to the default
                // (i.e., TimeSignature.COMMON_TIME), because time signatures do not inherit across sections.
                if (voiceStartsNewSection) {
                    lastTimeSignature = TimeSignature.COMMON_TIME;
                }
                measureTimeSignature = lastTimeSignature;
            } else {
                measureTimeSignature = new Fraction(beatsNumberSetting, beatsDurationSetting);
                lastTimeSignature = measureTimeSignature;
            }

            // Update all the Voice objects having the same index, across all track blueprints.
            currStartTime = _setObjectsStartTime(trackBluePrints, i, currStartTime, measureTimeSignature);
        }
        return trackBluePrints;
    }

    /**
     * Updates the start times of all objects in the given `collection`, based on their given `index`.
     * Returns the start time to be used on the next index, as side effect.
     *
     * @param   trackBluePrints
     *          A TrackBluePrints instance, containing several TrackBluePrint instances, indexed by their uid.
     *
     * @param   index
     *          The index, inside the nested Arrays, the elements to be updated live at.
     *
     * @param   startTime
     *          The start time to set, in musical format (i.e., as a fraction, e.g., `1/2` means half of a "common time"
     *          measure.
     *
     * @param   minAdvanceTime
     *          The minimum amount to add to given `startTime` before returning it. If the total duration of
     *          sub-elements (i.e., "Clusters") in either of the elements (i.e., "Voices") living at the given `index`
     *          is larger, that duration will be added instead (because in MAIDENS musical measures are flexible, and
     *          their time signature is merely an indicator of their MINIMUM capacity).
     *
     * @return  SIDE EFFECT: returns given `startTime` plus either the given `minAdvanceTime` or the larger value of the
     *          subjacent elements' total duration, if applicable (in other words, if the Clusters in a given Voice
     *          overflow their parent measure's time signature, the overflown duration is used instead of the measure's
     *          "nominal" duration).
     */
    private function _setObjectsStartTime(trackBluePrints:TrackBluePrints, index:int, startTime:Fraction,
                                          minAdvanceTime:Fraction):Fraction {
        var currVoiceInfo:VoiceInfo;
        var currRawVoice:ProjectData;
        var currCluster:ProjectData;
        var currClusterId:String;
        var clusterStartsTuplet:Boolean;
        var currTupletRootId:String;
        var tupletBeatDurationSetting:String;
        var tupletRootId:String;
        var clustersToCommit:Vector.<ClusterInfo>;
        var $:Object = {
            currTupletClusters: new Vector.<ClusterInfo>,
            currTupletNumBeats: 0,
            currTupletBeatDuration: Fraction.ZERO,
            currTupletTargetNumBeats: 0,
            actualAdvanceTime: Fraction.ZERO,
            maxActualAdvanceTime: Fraction.ZERO
        };

        // Internal callback to commit/flush tuplet cache if any.
        var flushTupletCache:Function = function (currBluePrint:TrackBluePrint, startTime:Fraction):void {
            if ($.currTupletClusters && $.currTupletClusters.length > 0) {
                $.actualAdvanceTime = $.actualAdvanceTime.add(
                        _commitTupletClusters($.currTupletNumBeats, $.currTupletBeatDuration,
                                $.currTupletTargetNumBeats, $.currTupletClusters,
                                currBluePrint.clusterObjects,
                                startTime.add($.actualAdvanceTime) as Fraction)
                ) as Fraction;
                $.currTupletClusters.length = 0;
                $.currTupletClusters = null;
            }
        }

        // Go through all the track blueprints
        trackBluePrints.forEach(function (trackId:String, currBluePrint:TrackBluePrint,
                                          ...args):void {

            // Mark the start time at Voice level
            currVoiceInfo = currBluePrint.voiceObjects[index];
            currVoiceInfo.startTime = startTime;

            // Compute and mark start time at Cluster level
            $.currTupletClusters = new Vector.<ClusterInfo>;
            $.currTupletNumBeats = 0;
            $.currTupletBeatDuration = Fraction.ZERO;
            $.currTupletTargetNumBeats = 0;
            $.actualAdvanceTime = Fraction.ZERO;
            currRawVoice = (currVoiceInfo.rawVoiceData as ProjectData);
            var i:int;
            var numClusters:uint = currRawVoice.numDataChildren;
            for (i = 0; i < numClusters; i++) {
                currCluster = (currRawVoice.getDataChildAt(i) as ProjectData);
                currClusterId = currCluster.route;
                clusterStartsTuplet = (currCluster.getContent(DataFields.STARTS_TUPLET) as Boolean);
                if (clusterStartsTuplet) {

                    // If we are starting a new tuplet while still observing another one, commit that one first, because
                    // MAIDENS does not support nested tuplets.
                    flushTupletCache(currBluePrint, startTime);
                    $.currTupletNumBeats = (currCluster.getContent(DataFields.TUPLET_SRC_NUM_BEATS) as uint);
                    $.currTupletTargetNumBeats = (currCluster.getContent(DataFields.TUPLET_TARGET_NUM_BEATS) as uint);
                    tupletBeatDurationSetting = (currCluster.getContent(DataFields.TUPLET_BEAT_DURATION) as String);
                    if ($.currTupletNumBeats && $.currTupletTargetNumBeats &&
                            tupletBeatDurationSetting != DataFields.VALUE_NOT_SET) {
                        $.currTupletBeatDuration = Fraction.fromString(tupletBeatDurationSetting);
                        currTupletRootId = currClusterId;
                        $.currTupletClusters = new <ClusterInfo>[ClusterInfo.fromCluster(currCluster)];
                    }
                } else {

                    // If we are continuing a tuplet, we must add its subsequent tuplet durations to the same storage.
                    // We DO NOT commit these durations yet, as we will be translating and committing them in bulk.
                    tupletRootId = (currCluster.getContent(DataFields.TUPLET_ROOT_ID) as String);
                    if (tupletRootId == currTupletRootId) {
                        $.currTupletClusters.push(ClusterInfo.fromCluster(currCluster));
                    }

                            // Otherwise we landed on a portion of regular clusters (i.e., not tuplets). We must commit the
                    // buffered tuplet clusters, if any, and then commit the current cluster itself.
                    else {
                        flushTupletCache(currBluePrint, startTime);
                        clustersToCommit = new Vector.<ClusterInfo>;
                        clustersToCommit.push(ClusterInfo.fromCluster(currCluster));
                        $.actualAdvanceTime = $.actualAdvanceTime.add(
                                _commitClusters(clustersToCommit, currBluePrint.clusterObjects,
                                        startTime.add($.actualAdvanceTime) as Fraction)) as Fraction;
                    }
                }
            }

            // There is also the chance of having a tuplet that leads into the end of a measure. If this is the case, we
            // must commit its buffered durations before moving on to the next measure (and to the next Voice object).
            flushTupletCache(currBluePrint, startTime);
            if ($.actualAdvanceTime.greaterThan($.maxActualAdvanceTime)) {
                $.maxActualAdvanceTime = $.actualAdvanceTime;
            }
        });
        return (startTime.add(minAdvanceTime.greaterThan($.maxActualAdvanceTime) ?
                minAdvanceTime : $.maxActualAdvanceTime) as Fraction);
    }

    /**
     * Converts given tuplet durations to real durations based on given tuplet definition and stores them in given
     * storage. Returns the cumulated value of these real duration as a side effect.
     * @see _getTupletRealDurations();
     * @see _commitClusters();
     */
    private static function _commitTupletClusters(tupletNumBeats:uint, tupletBeatDuration:Fraction,
                                                  tupletTargetNumBeats:uint,
                                                  tupletClusters:Vector.<ClusterInfo>,
                                                  storage:Vector.<ClusterInfo>,
                                                  startTime:Fraction):Fraction {

        var translatedClusters:Vector.<ClusterInfo> = _getTupletRealDurations(tupletNumBeats, tupletBeatDuration,
                tupletTargetNumBeats, tupletClusters);
        return _commitClusters(translatedClusters, storage, startTime);
    }

    /**
     * Stores given ClusterInfo instances in given storage, and returns their accumulated duration as a side effect.
     *
     * @param   clusters
     *          The cluster information to be stored and computed the total duration of.
     *
     * @param   storage
     *          The storage to deposit cluster information into.
     *
     * @param   startOffset
     *          A point in time, in musical format (i.e., a Fraction instance) to start counting from.
     *
     * @return  The computed total duration, as a Fraction object.
     */
    private static function _commitClusters(clusters:Vector.<ClusterInfo>,
                                            storage:Vector.<ClusterInfo>, startOffset:Fraction):Fraction {

        var durationSoFar:Fraction = Fraction.ZERO;
        var i:int;
        var numClusters:uint = clusters.length;
        var clusterInfo:ClusterInfo;
        for (i = 0; i < numClusters; i++) {
            clusterInfo = clusters[i];
            clusterInfo.startTime = (durationSoFar.add(startOffset) as Fraction);
            storage.push(clusterInfo);
            durationSoFar = (durationSoFar.add(clusterInfo.duration) as Fraction);
        }
        return durationSoFar;
    }

    /**
     * Converts given tuplet conventional durations into actual durations, e.g., converts the "1/4" and "1/8" of an
     * uneven eights triplet into "1/6" and "1/12" respectively. Returns the converted values in the same order as
     * the original ones.
     *
     * @param   tupletNumBeats
     *          The "put" portion of the tuplet definition; e.g., in "put 3 eights for 2" (a classic eight triplet),
     *          that would be "3".
     *
     * @param   tupletBeatDuration
     *          The "duration" portion of the tuplet definition; e.g., in "put 3 eights for 2" (a classic eight triplet),
     *          that would be "eights", i.e., "1/8".
     *
     * @param   tupletTargetNumBeats
     *          The "for" portion of the tuplet definition; e.g., in "put 3 eights for 2" (a classic eight triplet),
     *          that would be "2".
     *
     * @param   tupletClusters
     *          The duration involved in the tuplet, in their naturally occurring order; e.g., in a classic eight triplet,
     *          that would be "1/8, 1/8, 1/8". In an uneven eights triplet consisting of a quarter note and an eighth
     *          note, that would be "1/4 1/8".
     *
     * @return  Returns the translated tuplet durations, i.e., the actual fractions representing the real duration of
     *          each of the notes involved in a tuplet; e.g., in a classic eight triplet, that would be
     *          "1/12, 1/12, 1/12". In an uneven eights triplet consisting of a quarter note and an eighth note, that
     *          would be "1/6 1/12". The new values are packed in ClusterInfo instances that are, otherwise, identical
     *          to the original ones.
     */
    private static function _getTupletRealDurations(tupletNumBeats:uint, tupletBeatDuration:Fraction,
                                                    tupletTargetNumBeats:uint,
                                                    tupletClusters:Vector.<ClusterInfo>):Vector.<ClusterInfo> {

        // Express the "for" as a fraction and put it in simplest form.
        var tupletRealSpan:Fraction = (tupletBeatDuration.multiply(new Fraction(tupletTargetNumBeats)) as Fraction);

        // Divide the simplified fraction by the number of tuplet beats, i.e., the "put" portion of the definition. That
        // gives the real duration of the nominal value of the tuplet (i.e., the "1/8" in a eights triplet is actually
        // a "1/12").
        var tupletRealNominalVal:Fraction = (tupletRealSpan.divide(new Fraction(tupletNumBeats)) as Fraction);

        // For each of the given tuplet durations, compute its ratio to the tuplet beat duration, and multiply that with the
        // real duration of the tuplet nominal value to get the real duration of that respective tuplet duration (e.g., in an
        // uneven triplet of "1/4 and 1/8", the ratios to the nominal tuplet duration are "2 and 1" respectively, which,
        // multiplied by the real duration of "1/12" of the triplet "eight" give "1/6 and 1/12" respectively, after
        // putting the fractions to simplest form).
        var translatedClusters:Vector.<ClusterInfo> = new Vector.<ClusterInfo>;
        var i:int;
        var numTupletDurations:uint = tupletClusters.length;
        var tupletClusterInfo:ClusterInfo;
        var tupletClusterDuration:Fraction;
        var tupletRealDuration:Fraction;
        var nominalDurationFactor:Fraction;
        for (i = 0; i < numTupletDurations; i++) {
            tupletClusterInfo = tupletClusters[i];
            tupletClusterDuration = tupletClusterInfo.duration;
            nominalDurationFactor = (tupletClusterDuration.divide(tupletBeatDuration) as Fraction);
            tupletRealDuration = (tupletRealNominalVal.multiply(nominalDurationFactor) as Fraction);
            translatedClusters.push(
                    new ClusterInfo(tupletClusterInfo.uid, tupletRealDuration, tupletClusterInfo.pitches)
            );
        }
        return translatedClusters;
    }

    /**
     * Take the given `trackBluePrints` intermediate format and use it to construct, populate and add actual Track
     * instances to the given `timeline`. Use the given `unitTimeNorm` as a base to convert fraction start time and
     * duration into milliseconds.
     *
     * @param   trackBluePrints
     *          TrackBluePrints instance to use for building and populating actual Track instances from.
     *
     * @param   timeline
     *          Timeline instance to add built Tracks to.
     *
     * @param   unitTimeNorm
     *          How many milliseconds long is a "whole note" supposed to be. See the `unitTimeNorm` getter for more
     *          info.
     */
    private function _plotTracks(trackBluePrints:TrackBluePrints, timeline:Timeline, unitTimeNorm:uint):void {
        trackBluePrints.forEach(function (uid:String, blueprint:TrackBluePrint, index:uint):void {

            // For each track blueprint, create a Track to hold the actual notes to be played, and another one to hold
            // the annotations for highlighting the notes in the score a they are played.
            var baseTrackUid:String = (blueprint.partLabel + CommonStrings.UNDERSCORE + uid); // Ex.: Piano_00...
            var preset:uint = blueprint.presetNumber;
            var notesTrack:Track = new Track(baseTrackUid, preset, baseTrackUid);
            timeline.addTrack(notesTrack);
            var annotationTrackUid:String = (baseTrackUid + ANNOTATION_SUFFIX);
            var annotationsTrack:Track = new Track(annotationTrackUid, preset, annotationTrackUid);
            timeline.addTrack(annotationsTrack);

            // For each registered ClusterInfo, add a NoteTrackObject, an AnnotationTrackObject, and a start label.
            var i:int;
            var clusters:Vector.<ClusterInfo> = blueprint.clusterObjects;
            var numClusters:uint = clusters.length;
            var cluster:ClusterInfo;
            var clusterAnnotation:ScoreItemAnnotation;
            var clusterNote:NoteTrackObject;
            var nextIndex:uint;
            var hasNextCluster:Boolean;
            var nextCluster:ClusterInfo;
            var clusterStart:uint;
            var clusterDuration:uint;
            var clusterNoteAttacks:Vector.<NoteAttackInfo>;
            var j:int;
            var clusterPitches:Vector.<NoteInfo>;
            var numClusterPitches:uint;
            var clusterPitch:NoteInfo;
            for (i = 0; i < numClusters; i++) {
                cluster = clusters[i];
                clusterStart = Math.floor(cluster.startTime.floatValue * unitTimeNorm);
                clusterDuration = Math.floor(cluster.duration.floatValue * unitTimeNorm);

                // Add a start label
                timeline.setLabel(cluster.uid, clusterStart);

                // Add a ScoreItemAnnotation instance
                clusterAnnotation = new ScoreItemAnnotation(cluster.uid);
                annotationsTrack.addObject(clusterAnnotation, clusterStart, clusterDuration);

                // Add a NoteTrackObject containing NoteAttackInfo instances
                nextIndex = (i + 1);
                nextCluster = null;
                hasNextCluster = (clusters.length > nextIndex);
                if (hasNextCluster) {
                    nextCluster = clusters[nextIndex];
                }
                ClusterInfo.proofTies(cluster, nextCluster);

                clusterNoteAttacks = new Vector.<NoteAttackInfo>;
                clusterPitches = cluster.pitches;
                numClusterPitches = clusterPitches.length;
                for (j = 0; j < numClusterPitches; j++) {
                    clusterPitch = clusterPitches[j];
                    clusterNoteAttacks.push(new NoteAttackInfo(clusterPitch.midiPitch, 1, 0, 0, 1,
                            clusterPitch.tiesLeft, clusterPitch.tiesRight));
                }
                clusterNote = new NoteTrackObject(clusterNoteAttacks);
                notesTrack.addObject(clusterNote, clusterStart, clusterDuration);
            }
        });
    }

    /**
     * Used as `Array.map()` callback to convert all Strings in an Array into their respective integers.
     */
    private static function __toIntegers(item:String, ...ignore):int {
        return (parseInt(item) as int);
    }

    /**
     * Sorting callback to be used when sorting all the "voice objects" stored under a given "track id".
     * Sorts ascending by section index, and then by measure index, effectively ensuring all "voice
     * objects" are listed chronologically per each "track blueprint".
     *
     * @see Array.sort
     */
    private static function __bySectionThenByMeasure(vInfoA:VoiceInfo, vInfoB:VoiceInfo):int {
        var imA:Array = vInfoA.indicesMap;
        var imB:Array = vInfoB.indicesMap;
        var sectionDelta:int = (imA[SECTION_COLUMN] as int) - (imB[SECTION_COLUMN] as int);
        if (sectionDelta == 0) {
            return ((imA[MEASURE_COLUMN] as int) - (imB[MEASURE_COLUMN] as int));
        }
        return sectionDelta;
    }

}
}
