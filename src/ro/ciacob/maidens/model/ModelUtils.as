package ro.ciacob.maidens.model {
import ro.ciacob.ciacob;
import ro.ciacob.desktop.data.constants.DataKeys;
import ro.ciacob.desktop.filebrowser.constants.FieldNames;
import ro.ciacob.maidens.controller.MusicUtils;
import ro.ciacob.maidens.controller.constants.GeneratorKeys;
import ro.ciacob.maidens.generators.constants.parts.PartAbbreviatedVoiceNames;
import ro.ciacob.maidens.generators.constants.parts.PartEnsembleSizes;
import ro.ciacob.maidens.generators.constants.parts.PartEnsembleTypes;
import ro.ciacob.maidens.generators.constants.parts.PartFamilies;
import ro.ciacob.maidens.generators.constants.parts.PartVoiceNames;
import ro.ciacob.maidens.model.constants.DataFields;
import ro.ciacob.maidens.model.constants.StaticTokens;
import ro.ciacob.maidens.model.constants.Voices;
import ro.ciacob.maidens.view.constants.ViewKeys;
import ro.ciacob.utils.Arrays;
import ro.ciacob.utils.Objects;
import ro.ciacob.utils.Patterns;
import ro.ciacob.utils.Strings;
import ro.ciacob.utils.constants.CommonStrings;

public final class ModelUtils {

    public static const ABC_NAME_KEY:String = 'name';
    public static const ABC_UID_KEY:String = 'uid';
    public static const MUST_SHOW_ORDINAL_NUMBER:String = 'mustShowOrdinalNumber';
    public static const PART_UIDS_POOL:Object = {};
    public static const PART_UID_LENGTH:int = 3;
    public static const STAFF_ORDERING_INDEX:String = 'staffOrderingIndex';

    private static const ADDITIONS_BASE_INDEX:int = 2147473647;
    private static const ENSEMBLE_NAME:String = 'ensembleName';
    private static const RELEVANCE:String = 'relevance';
    private static const NO_QUANTIZER:String = 'noQuantizer';

    private static const INDEX_PADDING:int = 1000;
    private static const LOOKS_LIKE_THRESHOLD:Number = 0.5;
    private static const EXACT_MATCH_THRESHOLD:Number = 1;

    private static var _groupsToEnsemblesMap:Object = {};
    private static var _partsPerSection:Object = {};
    private static var _partsUidsToNodesMap:Object = {};
    private static var _sectionsOrderedList:Array = [];
    private static var _unifiedPartsList:Array = [];

    /**
     * DISABLED
     * TO DO: Re-evaluate for recycling as a macro.
     *
     * Rearranges Voices in all Measures of the given Part, so that (1) there is no  staff
     * that is left without two Voices, and (2) as few as possible of the existing Voices
     * get hidden. Only needed when changing the instrument of a part.
     *
     * NOTES:
     * ======
     *
     * When a Part that has music in it changes, we need to revisit every Measure, to make sure that
     * there are two Voices for every staff of that Part.
     * This may involve adding new Voices (because, for instance, switching from a "Flute" to an "Organ"
     * adds two staves), relocating existing Voices or hiding existing voices (for instance, when switching
     * an "Organ" part to a "Flute").
     *
     * (1) when the *source part voices* could fit within the *target part staves* by employing the second
     * voice, we do so, rather than hiding them;
     * (2) since the ABC translator ignores those voices with an index that is greater than
     * `Voices.NUM_VOICES_PER_STAFF`, we simply set the indices of all exceeding voices
     * to values higher than `Voices.NUM_VOICES_PER_STAFF` in order to hide them.
     */

    /*
    public static function adaptVoicesToStavesNumberIn(part:ProjectData):void {

        // Define all vars outside loops for maximum performance
        var i : int = 0;
        var j : int = 0;
        var k : int = 0;
        var i2 : int=0;
        var i3 : int=0;
        var i4 : int=0;
        var measureVoices:Array=[];
        var numMeasureVoices:int=0;
        var voicesDelta:int=0;
        var measure:ProjectData=null;
        var voice:ProjectData=null;
        var details:Object={};
        var numPartStaves:int=getPartNumStaves(part);
        var partMeasures:Array=getChildrenOfType(part, DataFields.MEASURE);
        var numMeasures:int=partMeasures.length;

        // Variables dealing with "layering", aka the "voice two" option. Note that, nowhere in this function
        // are we hardcoding the limitation of a staff accepting at most `two` voices; instead, this limit is
        // set by the `Voices.NUM_VOICES_PER_STAFF` constant.
        var exceedingVoiceCounter:uint;
        var layeredVoicesDelta:int=0;
        var numLayeredVoiceSlots:int=0;
        var layeredVoiceIndex:int=0;
        var layeredStaffIndex:int=0;

        // Loop through all the measures in the part and make changes as needed.
        // NOTE: staff indices are 1-based.
        details[DataFields.DATA_TYPE]=DataFields.VOICE;
        for (i=0; i < numMeasures; i++)
        {
            measure=(partMeasures[i] as ProjectData);
            measureVoices=getChildrenOfType(measure, DataFields.VOICE);
            measureVoices.sort(sortVoicesByStaffAndIndex);
            numMeasureVoices=measureVoices.length;
            voicesDelta=(numPartStaves - numMeasureVoices);

            // Case 1: there are fewer voices than staves or as many voices as staves, without considering
            // "voice two" as an option; we need to add one voice per staff, and set it up accordingly.
            // Also, we need to make sure that existing voices are mapped correctly (one voice per staff).
            if (voicesDelta >= 0)
            {
                for (i3=0; i3 < numPartStaves; i3++)
                {

                    // Existing voice, set it up
                    if (i3 < numMeasureVoices)
                    {
                        voice=(measureVoices[i3] as ProjectData);
                        voice.setContent(DataFields.VOICE_INDEX, 1);
                        voice.setContent(DataFields.STAFF_INDEX, i3 + 1);
                    }
                    else
                    {

                        // Needed voice, create and setup
                        voice=new ProjectData;
                        voice.populateWithDefaultData(details);
                        voice.setContent(DataFields.VOICE_INDEX, 1);
                        voice.setContent(DataFields.STAFF_INDEX, i3 + 1);
                        ProjectData(measure).addDataChild(voice);
                    }
                }
            }

            // Case 2: there are more voices than staves.
            else if (voicesDelta < 0)
            {
                numLayeredVoiceSlots=(numPartStaves * Voices.NUM_VOICES_PER_STAFF);
                layeredVoicesDelta=(numLayeredVoiceSlots - numMeasureVoices);

                // 2.a Voices could fit if we take "voice two" as an option, so that
                // several voices can be shown on the same staff
                if (layeredVoicesDelta >= 0)
                {
                    layeredVoiceIndex=0;
                    for (i4=0; i4 < numLayeredVoiceSlots; i4++)
                    {
                        if (layeredVoiceIndex >= Voices.NUM_VOICES_PER_STAFF)
                        {
                            layeredVoiceIndex=0;
                        }
                        layeredVoiceIndex++; // 1-based
                        layeredStaffIndex=((Math.floor(i4 * 0.5) as int) + 1); // 1-based

                        // Existing voice, set it up
                        if (i4 < numMeasureVoices)
                        {
                            voice=(measureVoices[i4] as ProjectData);
                            voice.setContent(DataFields.VOICE_INDEX, layeredVoiceIndex);
                            voice.setContent(DataFields.STAFF_INDEX, layeredStaffIndex);
                        }
                        else
                        {

                            // Needed voice, set it up; observe that we only set up *one voice*
                            // on empty staves: there is no reason to layer several empty
                            // voices on the same staff.
                            if (layeredVoiceIndex != 1)
                            {
                                continue;
                            }
                            voice=new ProjectData;
                            voice.populateWithDefaultData(details);
                            voice.setContent(DataFields.VOICE_INDEX, 1);
                            voice.setContent(DataFields.STAFF_INDEX, layeredStaffIndex);
                            ProjectData(measure).addDataChild(voice);
                        }
                    }
                }

                // 2.b Voices couldn't fit, even if we use the "voice two" option.
                // We need to hide exceeding voices. NOTE: (voice) children indexing is 0-based.
                else
                {
                    for (k=numLayeredVoiceSlots; k < numMeasureVoices; k++)
                    {
                        voice=(measureVoices[k] as ProjectData);
                        voice.setContent(DataFields.STAFF_INDEX, numPartStaves);
                        exceedingVoiceCounter=(k - numLayeredVoiceSlots);
                        voice.setContent(DataFields.VOICE_INDEX, ++exceedingVoiceCounter + Voices.NUM_VOICES_PER_STAFF);
                    }
                }
            }
        }
    }
    */

    /**
     * Adds or removes voices, so that each staff of the given part has the maximum permitted number of voices assigned.
     */
    public static function ensureMaxVoicesPerStaff(part:ProjectData):void {

        var measure:ProjectData = null;
        var voice:ProjectData = null;
        var absDelta:int = 0;
        var remainder:int = 0;
        var numVoicesToAdd:int = 0;
        var staffIndexStart:int = 0;
        var staffIndexEnd:int = 0;
        var staffIndex:int = 0;
        var voiceIndex:int = 0;
        var i:int;
        var j:int = 0;
        var numMeasureVoices:int = 0;
        var voicesDelta:int = 0;
        var measureVoices:Array = [];
        var deletionList:Array = [];
        var details:Object = {};
        var numPartStaves:int = getPartNumStaves(part);
        var expectedNumVoices:int = numPartStaves * Voices.NUM_VOICES_PER_STAFF;
        var partMeasures:Array = getChildrenOfType(part, DataFields.MEASURE);
        var numMeasures:int = partMeasures.length;
        var deletionIndexStart:int = numPartStaves + 1;

        for (i = 0; i < numMeasures; i++) {
            measure = (partMeasures[i] as ProjectData);
            measureVoices = getChildrenOfType(measure, DataFields.VOICE);
            numMeasureVoices = measureVoices.length;
            voicesDelta = (numMeasureVoices - expectedNumVoices);

            // Case 1: we need to add voices. To maintain (some sort of) backward compatibility,
            // we will not attempt to supplement existing staves that only have one voice (this should
            // not be the case for documents created in 1.5. anyway). Instead, we will only populate
            // the newly added staves with the correct number of voices.
            if (voicesDelta < 0) {
                details[DataFields.DATA_TYPE] = DataFields.VOICE;
                absDelta = Math.abs(voicesDelta);
                remainder = absDelta % Voices.NUM_VOICES_PER_STAFF;
                numVoicesToAdd = (absDelta - remainder);
                staffIndexStart = (expectedNumVoices - numVoicesToAdd) / Voices.NUM_VOICES_PER_STAFF + 1;
                staffIndexEnd = staffIndexStart + numVoicesToAdd / Voices.NUM_VOICES_PER_STAFF - 1;
                for (staffIndex = staffIndexStart; staffIndex <= staffIndexEnd; staffIndex++) {
                    for (voiceIndex = 1; voiceIndex <= Voices.NUM_VOICES_PER_STAFF; voiceIndex++) {
                        voice = new ProjectData;
                        voice.populateWithDefaultData(details);
                        voice.setContent(DataFields.VOICE_INDEX, voiceIndex);
                        voice.setContent(DataFields.STAFF_INDEX, staffIndex);
                        measure.addDataChild(voice);
                    }
                }
            }

            // Case 2: we need to remove voices. This is a potentially destructive operation
            else if (voicesDelta > 0) {
                for (j = 0; j < numMeasureVoices; j++) {
                    voice = measureVoices[j] as ProjectData;
                    staffIndex = voice.getContent(DataFields.STAFF_INDEX) as int;
                    if (staffIndex >= deletionIndexStart) {
                        deletionList.push(voice);
                    }
                }
                while (deletionList.length > 0) {
                    measure.removeDataChild(deletionList.pop() as ProjectData);
                }
            }
        }
    }

    public static function compareVoiceNodes(voiceA:ProjectData, voiceB:ProjectData):int {
        var voiceAMark:String = [voiceA.getContent(DataFields.STAFF_INDEX), voiceA.getContent(DataFields.VOICE_INDEX)].join('');
        var voiceBMark:String = [voiceB.getContent(DataFields.STAFF_INDEX), voiceB.getContent(DataFields.VOICE_INDEX)].join('');
        return (voiceAMark < voiceBMark) ? -1 : (voiceAMark > voiceBMark) ? 1 : 0;
    }

    /**
     * Produces an "abbreviated voice label" for a given staff of a given Part that is currently being displayed on
     * a given number of staves. Uses PartAbbreviatedVoiceNames class to extract the actual labels to use. Returns
     * the resulting string, retaining annotation if it was originally present. Returns `null` if this part does not
     * use custom voice labels.
     */
    public static function compileVoiceAbbreviatedLabel(partName:String, numStaves:int, staffIndex:int):String {
        var annotation:String;
        if (partName.indexOf(CommonStrings.BROKEN_VERTICAL_BAR) != -1) {
            var tokens:Array = partName.split(CommonStrings.BROKEN_VERTICAL_BAR);
            annotation = tokens[0];
            partName = tokens[1];
        }
        if (staffIndex >= 0 && staffIndex < numStaves) {
            var names:Array = PartAbbreviatedVoiceNames.getNames(partName, numStaves);
            if (names != null) {
                var label:String = names[staffIndex];
                if (annotation) {
                    label = annotation.concat(CommonStrings.BROKEN_VERTICAL_BAR, label);
                }
                return label;
            }
        }
        return null;
    }

    /**
     * Produces a "voice label" for a given staff of a given Part that is currently being displayed on a given
     * number of staves. Uses PartVoiceNames class to extract the actual labels to use. Returns the resulting
     * string, retaining annotation if it was originally present. Returns `null` if this part does not use custom
     * voice labels.
     */
    public static function compileVoiceLabel(partName:String, numStaves:int, staffIndex:int):String {
        var annotation:String;
        if (partName.indexOf(CommonStrings.BROKEN_VERTICAL_BAR) != -1) {
            var tokens:Array = partName.split(CommonStrings.BROKEN_VERTICAL_BAR);
            annotation = tokens[0];
            partName = tokens[1];
        }
        if (staffIndex >= 0 && staffIndex < numStaves) {
            var names:Array = PartVoiceNames.getNames(partName, numStaves);
            if (names != null) {
                var label:String = names[staffIndex];
                if (annotation) {
                    label = annotation.concat(CommonStrings.BROKEN_VERTICAL_BAR, label);
                }
                return label;
            }
        }
        return null;
    }

    public static function countChildrenOfType(parent:ProjectData, childType:String):int {
        return getChildrenOfType(parent, childType).length;
    }

    public static function getAllPartNamesInScore(score:ProjectData):Array {
        var allPartNames:Object = {};
        var allSections:Array = getChildrenOfType(score, DataFields.SECTION);
        for (var j:int = 0; j < allSections.length; j++) {
            var section:ProjectData = (allSections[j] as ProjectData);
            var allPartNodes:Array = getChildrenOfType(section, DataFields.PART);
            for (var i:int = 0; i < allPartNodes.length; i++) {
                var part:ProjectData = (allPartNodes[i] as ProjectData);
                var partName:String = getPartEquivalentSignature(part);
                allPartNames[partName] = partName;
            }
        }
        return Objects.getKeys(allPartNames);
    }

    public static function getChildrenOfType(parent:ProjectData, childType:String):Array {
        var matchingChildren:Array = [];
        for (var i:int = 0; i < parent.numDataChildren; i++) {
            var child:ProjectData = ProjectData(parent.getDataChildAt(i));
            if (matchesType(child, childType)) {
                matchingChildren.push(child);
            }
        }
        return matchingChildren;
    }

    public static function getDescendantsOfType(parent:ProjectData, childType:String):Array {
        var elements:Array = [];
        var walker:Function = function (element:ProjectData):void {
            var elType:String = element.getContent(DataFields.DATA_TYPE) as String;
            if (elType == childType) {
                elements.push(element);
            }
        };
        parent.walk(walker);
        return elements;
    }

    public static function getClosestAscendantByType(child:ProjectData, parentType:String):ProjectData {
        if (matchesType(child, parentType)) {
            return child;
        }
        var parent:ProjectData = ProjectData(child.dataParent);
        while (parent != null && !matchesType(parent, parentType)) {
            parent = ProjectData(parent.dataParent);
        }
        if (parent != null && matchesType(parent, parentType)) {
            return parent;
        }
        return null;
    }

    /**
     * Returns a suitable ensemble name based on given `partNames` Array.
     */
    public static function getInstrumentationLabel(partNames:Array):String {

        // Parts not fully set up do not count.
        partNames = removeValueNotSet(partNames);

        // If the score is not empty, try to match or determine a descriptive ensemble name
        if (partNames && partNames.length > 0) {
            var mustUseGenericName:Boolean = false;
            var mustAddQuantizer:Boolean = true;
            var nameTokens:Array = [];

            // If there is a single part in the score, add its name.
            if (partNames.length == 1) {
                nameTokens.push(removeOrdinalIndex(partNames[0]) as String);
            }

            // Otherwise, match score parts to known ensembles.
            else {
                var closestMatch:Object = getMostLikelyEnsembleFor(partNames);
                if (closestMatch) {
                    var relevance:Number = ((closestMatch != null) ? (closestMatch[RELEVANCE] as Number) : 0);

                    // IF the current formula matches a "stock" ensemble, do not add a quantizer, as the
                    // matched nme likely includes or implies one.
                    if (relevance == EXACT_MATCH_THRESHOLD) {
                        mustAddQuantizer = false;
                    }

                    // If a rather solid match was found to one of the ensembles, "prettify" its name and use it.
                    if (relevance >= LOOKS_LIKE_THRESHOLD) {

                        // If the current formula matches an "unquantifiable" ensemble, do not add a quantizer.
                        if ((NO_QUANTIZER in closestMatch) && (closestMatch[NO_QUANTIZER])) {
                            mustAddQuantizer = false;
                        }
                        var ensembleName:String = (closestMatch[ENSEMBLE_NAME] as String);
                        ensembleName = Strings.fromAS3ConstantCase(ensembleName);
                        ensembleName = Strings.capitalize(ensembleName, false);
                        nameTokens.push(ensembleName);
                    }

                    // If the match is weak, do not use it; instead, a generic name shall be used,
                    else {
                        mustUseGenericName = true;
                    }
                } else {
                    mustUseGenericName = true;
                }
            }

            // Add a quantizer, such as "Trio" or "Chamber". Not used for "stock" ensembles.
            if (mustAddQuantizer) {
                var sizeNaming:String = PartEnsembleSizes.getNameBySize(partNames.length);
                var mustPrepend:Boolean = (sizeNaming.charAt(0) == CommonStrings.DOLLAR_SIGN);
                sizeNaming = Strings.remove(sizeNaming, CommonStrings.DOLLAR_SIGN);
                sizeNaming = Strings.fromAS3ConstantCase(sizeNaming);
                sizeNaming = Strings.capitalize(sizeNaming);
                if (mustPrepend) {
                    nameTokens.unshift(sizeNaming);
                } else {
                    nameTokens.push(sizeNaming);
                }
            }

            // If we need to use a generic name, add "ensemble" from ten instruments onward.
            if (mustUseGenericName) {
                if (partNames.length > PartEnsembleSizes.NONET$) {
                    nameTokens.push(StaticTokens.ENSEMBLE);
                }
            }

            // Export the resulting ensemble name
            var finalName:String = nameTokens.join(CommonStrings.SPACE);
            finalName = finalName.toLowerCase();
            finalName = Strings.capitalize(finalName);
            return finalName;
        }

        // If there's no instrument in the score, return the string "empty".
        return StaticTokens.EMPTY;
    }

    /**
     * Returns an object with information about the ensemble name most closely matching
     * the given Array of `partNames`. Can return `null` if an instrument is not listed in any ensemble.
     */
    public static function getMostLikelyEnsembleFor(partNames:Array):Object {
        var matchInfo:Object = {};
        partNames = removeValueNotSet(partNames);
        partNames = _canonicalizeParts(partNames);
        partNames.sort();
        var groupSignature:String = (partNames.join('').toLowerCase());
        if (!(groupSignature in _groupsToEnsemblesMap)) {
            var partialMatchHits:Array = [];
            var allEnsembles:Array = PartEnsembleTypes.getAllEnsembles();
            for (var i:int = 0; i < allEnsembles.length; i++) {
                var ensembleName:String = (allEnsembles[i] as String);
                var isExactMatchTarget:Boolean = Strings.beginsWith(ensembleName, CommonStrings.DOLLAR_SIGN);
                var ensembleContent:Array = (PartEnsembleTypes[ensembleName] as Array).concat();
                ensembleContent.sort();

                // If the ensemble name begins with a dollar sign, then it must be either completely matched or
                // completely dropped.
                if (isExactMatchTarget) {
                    var ensembleSignature:String = ensembleContent.join('').toLowerCase();

                    // If we find a perfect match, we stop any further searching and discard
                    // any (partial) matches found so far.
                    if (groupSignature == ensembleSignature) {
                        matchInfo[RELEVANCE] = 1;
                        matchInfo[ENSEMBLE_NAME] = ensembleName;
                        partialMatchHits.length = 0;
                        partialMatchHits.push(matchInfo);
                        break;
                    }
                } else {

                    // If the ensemble does NOT begin with a dollar sign, it can be partially matched. In the
                    // end, we'll choose the ensemble with the highest partial match score.
                    var ensembleSize:int = ensembleContent.length;
                    Arrays.removeDuplicates(partNames);
                    var matches:Array = [];
                    var missMatches:Array = [];
                    for (var j:int = 0; j < partNames.length; j++) {
                        var partName:String = (partNames[j] as String);
                        var matchIndex:int = ensembleContent.indexOf(partName);
                        if (matchIndex != -1) {
                            matches.push(partName);
                            ensembleContent.splice(matchIndex, 1);
                        } else {
                            missMatches.push(partName);
                        }
                    }
                    var numMatches:int = Math.max(0, matches.length - missMatches.length);
                    if (numMatches > 0) {
                        var relevance:Number = (numMatches / ensembleSize);
                        matchInfo[RELEVANCE] = relevance;
                        matchInfo[ENSEMBLE_NAME] = ensembleName;
                        partialMatchHits.push(matchInfo);
                    }
                }
            }
            partialMatchHits.sort(_byRelevance);
            partialMatchHits.reverse();

            if (partialMatchHits && partialMatchHits.length) {
                // Retain only the partial match that has the highest score.
                var greatestScore:Object = (partialMatchHits[0] as Object);

                // Prepare the information for export:
                // - flag non-quantizable ensembles (their name ends in "$");
                // - remove any "$" chars, as these need not display to the end-user;
                if (Strings.endsWith(greatestScore[ENSEMBLE_NAME], CommonStrings.DOLLAR_SIGN)) {
                    greatestScore[NO_QUANTIZER] = true;
                }
                if (Strings.contains(greatestScore[ENSEMBLE_NAME], CommonStrings.DOLLAR_SIGN)) {
                    greatestScore[ENSEMBLE_NAME] = Strings.remove(greatestScore[ENSEMBLE_NAME],
                            CommonStrings.DOLLAR_SIGN);
                }
                _groupsToEnsemblesMap[groupSignature] = greatestScore;
            }
        }
        return (_groupsToEnsemblesMap[groupSignature] as Object);
    }

    /**
     * Removes the trailing ordinal index if present, then sorts all names.
     * @param    parts
     *            A list of parts.
     * @return    A canonical list of paths.
     */
    private static function _canonicalizeParts(parts:Array):Array {
        var partNames:Array = [];
        for (var i:int = 0; i < parts.length; i++) {
            var partName:String = (parts[i] as String);
            partName = removeOrdinalIndex(partName);
            partNames.push(partName);
            partNames.sort();
        }
        return partNames;
    }

    /**
     * Compares score objects by their `relevance` fields, numeric, scending.
     *
     * @param    scoreA
     *            First object to compare.
     *
     * @param    scoreB
     *            Second object to compare.
     *
     * @return    An integer showing the proper order. See documentation of
     *            `Array.sort` method for details.
     */
    private static function _byRelevance(scoreA:Object, scoreB:Object):int {
        var matchA:Number = (scoreA[RELEVANCE] as Number);
        var matchB:Number = (scoreB[RELEVANCE] as Number);
        var delta:Number = (matchA - matchB);
        var intVal:int = (delta * 100000);
        return intVal;
    }

    public static function getNodeLabel(node:ProjectData):String {
        var dataType:String = node.getContent(DataFields.DATA_TYPE);
        var label:String = dataType;
        switch (dataType) {
            case DataFields.PROJECT:
                label = label.concat(': "', node.getContent(DataFields.PROJECT_NAME), '"');
                break;
            case DataFields.SCORE:
                label = label.concat(' (', getInstrumentationLabel(getAllPartNamesInScore(node)), ')');
                break;
            case DataFields.SECTION:
                label = (node.getContent(DataFields.CONNECTION_UID) as String).concat(CommonStrings.SPACE, label, CommonStrings.COLON_SPACE, CommonStrings.QUOTES, node.getContent(DataFields.UNIQUE_SECTION_NAME), CommonStrings.QUOTES);
                break;
            case DataFields.GENERATOR:
                label = (node.getContent(DataFields.CONNECTION_UID) as String).concat(CommonStrings.SPACE, label, CommonStrings.COLON_SPACE, node.getContent(GeneratorKeys.NAME));
                break;
            case DataFields.PART:
                var partName:String = (node.getContent(DataFields.PART_NAME) as String);
                var partOrdinalIndex:int = ((node.getContent(DataFields.PART_ORDINAL_INDEX) as int) + 1);
                label = StaticTokens.PART_LABEL.replace('%s', partName).replace('%d', partOrdinalIndex);
                break;
            case DataFields.VOICE:
                label = label.concat(' ', node.getContent(DataFields.VOICE_INDEX), ' ', getVoiceInfo(node));
                break;
            case DataFields.CLUSTER:
                var duration:String = (node.getContent(DataFields.CLUSTER_DURATION_FRACTION) as String);
                var numNotes:int = node.numDataChildren;
                label = StaticTokens.CLUSTER_LABEL.replace('%s', (duration != DataFields.VALUE_NOT_SET) ? CommonStrings.SPACE.concat(duration) : '').replace('%s', (numNotes >= 2) ? StaticTokens.CHORD : (numNotes >= 1) ? StaticTokens.NOTE : StaticTokens.REST);
                break;
            case DataFields.NOTE:
                label = StaticTokens.NOTE_TEMPLATE.replace('%s', MusicUtils.noteToString(node));
                break;
        }
        return label;
    }

    public static function getParentPart(item:ProjectData):ProjectData {
        return getClosestAscendantByType(item, DataFields.PART);
    }

    /**
     * Produces a string of form "Flute1", "Flute2", etc., meant to equate
     * two technically different `part` nodes, found in two different section nodes.
     * In reality, the music contained by the two different nodes would be
     * played by the same human player, so there must be a way to tell that they
     * "mean the same thing".
     *
     * @param    partNode
     *            A `part` node to obtain a signature from.
     *
     * @return    The rsulting signature.
     */
    public static function getPartEquivalentSignature(partNode:ProjectData):String {
        var name:String = (partNode.getContent(DataFields.PART_NAME) as String);
        var ordIndex:String = (partNode.getContent(DataFields.PART_ORDINAL_INDEX) as Object).toString();
        return name.concat(ordIndex);
    }

    public static function getPartNumStaves(part:ProjectData):int {
        return part.getContent(DataFields.PART_NUM_STAVES);
    }

    public static function getVoiceByPlacement(parentMeasure:ProjectData, staffIndex:int, voiceIndex:int):ProjectData {
        var allVoices:Array = getChildrenOfType(parentMeasure, DataFields.VOICE);
        allVoices.sort(sortVoicesByStaffAndIndex);
        return (allVoices.filter(function (item:ProjectData, ...etc):Boolean {
            return (((item.getContent(DataFields.STAFF_INDEX) as int) == staffIndex) && ((item.getContent(DataFields.VOICE_INDEX) as int) == voiceIndex));
        })[0] as ProjectData);
    }

    public static function getVoiceInfo(voice:ProjectData):String {
        var info:String = '';
        var staffIndex:int = voice.getContent(DataFields.STAFF_INDEX);
        if (!isNaN(staffIndex)) {
            if (staffIndex > 0) {
                info = info.concat('(staff ', staffIndex);
                var part:ProjectData = ProjectData(ModelUtils.getClosestAscendantByType(voice, DataFields.PART));
                var voiceLabel:String = ModelUtils.getVoiceLabel(part, staffIndex);
                if (!Strings.isEmpty(voiceLabel)) {
                    info = info.concat(', ', voiceLabel);
                }
                info = info.concat(')');
            } else {
                info = info.concat('(no staff)');
            }
        }
        return info;
    }

    public static function getVoiceLabel(part:ProjectData, staffIndex:int):String {
        var partName:String = part.getContent(DataFields.PART_NAME);
        var numStaves:int = getPartNumStaves(part);
        staffIndex -= 1;
        return compileVoiceLabel(partName, numStaves, staffIndex);
    }

    public static function haveSameType(elementA:ProjectData, elementB:ProjectData):Boolean {
        return (elementA.getContent(DataFields.DATA_TYPE) == elementB.getContent(DataFields.DATA_TYPE));
    }

    public static function isCluster(item:ProjectData):Boolean {
        return matchesType(item, DataFields.CLUSTER);
    }

    public static function isFirstChildOfItsType(child:ProjectData):Boolean {
        var kind:String = child.getContent(DataFields.DATA_TYPE);
        var parent:ProjectData = ProjectData(child.dataParent);
        if (parent != null) {
            var childrenOfSameType:Array = getChildrenOfType(parent, kind);
            if (childrenOfSameType.length > 0) {
                return (ProjectData(childrenOfSameType[0]).route == child.route);
            }
        }
        return false;
    }

    public static function isGenerator(item:ProjectData):Boolean {
        return matchesType(item, DataFields.GENERATOR);
    }

    public static function isGenerators(item:ProjectData):Boolean {
        return matchesType(item, DataFields.GENERATORS);
    }

    public static function isLastChildOfItsType(child:ProjectData):Boolean {
        var kind:String = child.getContent(DataFields.DATA_TYPE);
        var parent:ProjectData = ProjectData(child.dataParent);
        if (parent != null) {
            var childrenOfSameType:Array = getChildrenOfType(parent, kind);
            if (childrenOfSameType.length > 0) {
                return (ProjectData(childrenOfSameType[childrenOfSameType.length - 1]).route == child.route);
            }
        }
        return false;
    }

    /**
     * Returns `true` if given measure is the last one in the entire score.
     */
    public static function isLastMeasure(measure:ProjectData):Boolean {
        if (isLastMeasureInSection(measure)) {
            var section:ProjectData = getClosestAscendantByType(measure, DataFields.SECTION);
            return (section.index == _sectionsOrderedList.length - 1);
        }
        return false;
    }

    /**
     * Returns `true` if given measure is the last one in its section.
     */
    public static function isLastMeasureInSection(measure:ProjectData):Boolean {
        return (measure.index == measure.dataParent.numDataChildren - 1);
    }

    public static function isMeasure(item:ProjectData):Boolean {
        return matchesType(item, DataFields.MEASURE);
    }

    /**
     * Tests whether given string is a legal "mirror UID".
     *
     * We use UUIDs for this kind of information, and only for referring to Parts nodes. Unlike "route"
     * UIDs, which point to a specific Part node, within a specific Section node, a "mirror" UID
     * transcends sections, and is shared by all Part nodes with the same name and ordinal index
     * (e.g., "the first violin in all sections").
     */
    public static function isMirrorUid(uid:String):Boolean {
        return uid && uid.charAt(0) != CommonStrings.DASH && Patterns.UUID_CASE_INSENSITIVE.test(uid);
    }

    public static function isNote(item:ProjectData):Boolean {
        return matchesType(item, DataFields.NOTE);
    }

    public static function isPart(item:ProjectData):Boolean {
        return matchesType(item, DataFields.PART);
    }

    public static function isProject(item:ProjectData):Boolean {
        return matchesType(item, DataFields.PROJECT);
    }

    public static function isScore(item:ProjectData):Boolean {
        return matchesType(item, DataFields.SCORE);
    }

    public static function isSection(item:ProjectData):Boolean {
        return matchesType(item, DataFields.SECTION);
    }

    public static function isVoice(item:ProjectData):Boolean {
        return matchesType(item, DataFields.VOICE);
    }

    public static function matchesType(item:ProjectData, kind:String):Boolean {
        return (item.getContent(DataFields.DATA_TYPE) == kind);
    }

    public static function get partsPerSection():Object {
        return _partsPerSection;
    }

    public static function get partsUidsToNodesMap():Object {
        return _partsUidsToNodesMap;
    }

    public static function projectHasScore(project:ProjectData):Boolean {
        if (isProject(project)) {
            var numScoreItems:int = countChildrenOfType(project, DataFields.SCORE);
            return (numScoreItems > 0);
        }
        return false;
    }

    /**
     * Removes the ordinal index part from a part name, if present.
     *
     * @param    partName
     *            The part name to alter.
     *
     * @return    The part name, changed or not.
     */
    public static function removeOrdinalIndex(partName:String):String {
        partName = Strings.trim(partName.replace(/\d/g, ''));
        return partName;
    }

    /**
     * Removes the substring `value not set` if present.
     * @param    strings
     *            An Array of strings.
     *
     * @return    An Array of strings with all the occurences of the `value not set`
     *            subtring removed.
     */
    public static function removeValueNotSet(strings:Array):Array {
        var ret:Array = [];
        for (var i:int = 0; i < strings.length; i++) {
            var str:String = (strings[i] as String);
            if (str.indexOf(DataFields.VALUE_NOT_SET) == -1) {
                ret.push(str);
            }
        }
        return ret;
    }

    public static function scoreHasASingleSection(score:ProjectData):Boolean {
        if (isScore(score)) {
            var numSectionItems:int = countChildrenOfType(score, DataFields.SECTION);
            return (numSectionItems == 1)
        }
        return false;
    }

    public static function get sectionsOrderedList():Array {
        return _sectionsOrderedList;
    }

    public static function sortStavesByPartOrder(staves:Array):void {
        if (_unifiedPartsList != null) {

            // By default, the order of the staves is given by the child indices of the Part nodes
            var ensembleMembers:Array = [];
            for (var i:int = 0; i < _unifiedPartsList.length; i++) {
                var partData:Object = (_unifiedPartsList[i] as Object);
                var partName:String = (partData[DataFields.PART_NAME] as String).split(CommonStrings.BROKEN_VERTICAL_BAR).pop();
                ensembleMembers[partData[ViewKeys.PART_CHILD_INDEX]] = partName;
            }

            // The logic is as follows:
            //
            // 1. Search the part within the ensemble. If found, use that as base
            //    index for ordering.
            //
            // 2. Otherwise, check the ensemble for a OTHER_INSTRUMENTS placeholder.
            //    If found, use that as a base index for ordering.
            //
            // 3. Otherwise, construct a safe base index toward the upper limit of the
            //    integer type range.
            //
            // 4. Once we have a base index, construct a staff index from the part's
            //    staff uid (which has a numeric part, that reflect the part's instance
            //    index, and the staff index, e.g.: 'Pno11' means the treble staff of the
            //    first piano playing in the score.
            //
            // 5. Add the base index to the specific index, and this is the index we use
            //    for sorting.
            var haveIndex:Boolean = false;
            var additionsOffset:int = 0;
            var mustSuplementOffset:Boolean = false;
            for (var j:int = 0; j < staves.length; j++) {
                var staffData:Object = (staves[j] as Object);
                var staffName:String = staffData[ABC_NAME_KEY].split(CommonStrings.BROKEN_VERTICAL_BAR).pop();

                staffName = removeOrdinalIndex(staffName);
                var baseIndex:int = ensembleMembers.indexOf(staffName);
                haveIndex = (baseIndex >= 0);
                if (haveIndex) {
                    baseIndex *= INDEX_PADDING;
                } else {
                    var placeHolderIndex:int = (ensembleMembers.indexOf(PartFamilies.ciacob::OTHER_INSTRUMENTS));
                    haveIndex = (placeHolderIndex >= 0);
                    if (haveIndex) {
                        placeHolderIndex *= INDEX_PADDING;
                        baseIndex = (placeHolderIndex + additionsOffset);
                        mustSuplementOffset = true;
                    } else {
                        baseIndex = (ADDITIONS_BASE_INDEX + additionsOffset);
                        mustSuplementOffset = true;
                    }
                }
                var staffUid:String = (staffData[ABC_UID_KEY] as String);
                var match:Array = staffUid.match(/\d+$/);
                var staffIndex:int = ((match != null) ? parseInt(match[0] as String) : 0);
                if (mustSuplementOffset) {
                    mustSuplementOffset = false;
                    additionsOffset += Math.max(staffIndex, 1);
                }
                staffData[STAFF_ORDERING_INDEX] = (baseIndex + staffIndex);
            }
            staves.sort(_compareStavesByOrderingIndex);
        }
    }

    /**
     * Note: possible dupplicate of: `compareVoiceNodes()`. To investigate.
     */
    public static function sortVoicesByStaffAndIndex(voiceA:ProjectData, voiceB:ProjectData):int {
        var voiceAStaffIndex:int = (voiceA.getContent(DataFields.STAFF_INDEX) as int);
        var voiceBStaffIndex:int = (voiceB.getContent(DataFields.STAFF_INDEX) as int);
        var staffDelta:int = (voiceAStaffIndex - voiceBStaffIndex);
        if (staffDelta) {
            return staffDelta;
        }
        var voiceAIndex:int = (voiceA.getContent(DataFields.VOICE_INDEX) as int);
        var voiceBIndex:int = (voiceB.getContent(DataFields.VOICE_INDEX) as int);
        return (voiceAIndex - voiceBIndex);
    }

    public static function get unifiedPartsList():Array {
        return _unifiedPartsList;
    }

    /**
     * End point for compiling an unified list of parts, used across the entire
     * piece (as each section can use its own parts, or reuse a subset of the
     * existing ones).
     *
     * @param    project
     *            The project to extract information from.
     *
     *
     * @return    An array with objects, each describing a staff of a part.
     */
    public static function updateUnifiedPartsList(project:ProjectData):void {
        _partsPerSection = {};
        _partsUidsToNodesMap = {};
        _sectionsOrderedList = [];
        _unifiedPartsList = [];
        var havePartListChanges:Boolean = false;
        project.walk(function (element:ProjectData):void {
            if (ModelUtils.isPart(element)) {
                _updatePartsTableWith(element);
                havePartListChanges = true;
            }
        });
        if (havePartListChanges) {
            _unifiedPartsList = _exportUnifiedPartsList();
        }
    }

    private static function _compareStavesByOrderingIndex(staffA:Object, staffB:Object):int {
        var orderingIndexA:int = (staffA[STAFF_ORDERING_INDEX] as int);
        var orderingIndexB:int = (staffB[STAFF_ORDERING_INDEX] as int);
        return (orderingIndexA - orderingIndexB);
    }

    /**
     * Creates a list of objects, each having information suitable for properly
     * populating the `V:` ABC header fields; this creates the staves needed
     * for all parts, across the whole piece.
     *
     * @return    A list with objects, each containing information for populating one
     *            `V:` ABC header field.
     */
    private static function _exportUnifiedPartsList():Array {
        var unifDict:Object = {};
        for (var sectionName:String in _partsPerSection) {
            var partsInCurrSect:Object = _partsPerSection[sectionName];
            for (var partName:String in partsInCurrSect) {
                if (!(partName in unifDict)) {
                    unifDict[partName] = [];
                }
                // There may be, i.e., several violins playing in a certain section;
                // Will call this a `part instance`; each new playing violin is an
                // `instance` of the abstract Violin part.
                var partInstancesInSection:Array = partsInCurrSect[partName];
                for (var partInstanceIdx:int = 0; partInstanceIdx < partInstancesInSection.length; partInstanceIdx++) {
                    var instanceUid:String = partInstancesInSection[partInstanceIdx];
                    var partInstance:ProjectData = _partsUidsToNodesMap[instanceUid];
                    var partInstanceData:Object = partInstance.getContentMap();
                    partInstanceData[DataKeys.ROUTE] = partInstance.route;
                    partInstanceData[ViewKeys.PART_CHILD_INDEX] = partInstance.index;

                    var unifListOfCurrentPart:Array = (unifDict[partName] as Array);
                    // However, if two violines play in the first section, and three
                    // in the second section, we'll build a score for three violins;
                    // conversely, if two violins play in first section, and only one in
                    // the second, we'll build a score for two violins.
                    var havePartInstanceAtCurrentIndex:Boolean = (unifListOfCurrentPart[partInstanceIdx] !== undefined);
                    if (!havePartInstanceAtCurrentIndex) {
                        unifListOfCurrentPart[partInstanceIdx] = partInstanceData;
                    } else {
                        // We also must provide a meaningfull view of the number of staves
                        // the parts use. If we have a harp using only one staff in the
                        // first section, but two in the second, we'll setup a two-staves
                        // harp score.
                        var currentNumStaves:int = (unifListOfCurrentPart[partInstanceIdx][DataFields.PART_NUM_STAVES] as int);
                        var newNumStaves:int = (partInstanceData[DataFields.PART_NUM_STAVES] as int);
                        if (newNumStaves > currentNumStaves) {
                            unifListOfCurrentPart[partInstanceIdx][DataFields.PART_NUM_STAVES] = newNumStaves;
                        }
                    }
                }
            }
        }
        var unifPartsList:Array = [];
        for (var key:String in unifDict) {
            var value:Array = (unifDict[key] as Array);
            // We need to show the `ordinal number` next to the part name, i.e.
            // `Violin 1` instead of `Violin` if there are several violins playing
            // in the piece (even if a single violin is playing in one of the sections).
            if (value.length > 1) {
                for (var i:int = 0; i < value.length; i++) {
                    var partDefinition:Object = (value[i]);
                    partDefinition[MUST_SHOW_ORDINAL_NUMBER] = true;
                }
            }
            unifPartsList = unifPartsList.concat(value);
        }
        unifPartsList.sort (_byChildIndex);
        return unifPartsList;
    }

    /**
     * Sorting function, used by Array.sort() inside `_exportUnifiedPartsList()` to ensure parts are exported in a
     * consistent order. Sorts parts ascending by the child index they respectivelly have in the data model..
     */
    private static function _byChildIndex (partDataA : Object, partDataB : Object) : int {
        return (partDataA.partChildIndex - partDataB.partChildIndex);
    }

    /**
     * Helps creating a (non-unified) table with all parts used by every section,
     * across the entire piece. When run against a given part, this table is updated,
     * and the respective part properly indexed.
     *
     * @param    part
     *            A part to update the table with.
     */
    private static function _updatePartsTableWith(part:ProjectData):void {
        var section:ProjectData = ProjectData(part.dataParent);
        var sectionName:String = section.getContent(DataFields.UNIQUE_SECTION_NAME);
        if (!(sectionName in _partsPerSection)) {
            _partsPerSection[sectionName] = {};
            _sectionsOrderedList.push(sectionName);
        }
        var partName:String = part.getContent(DataFields.PART_NAME);
        if (!(partName in _partsPerSection[sectionName])) {
            _partsPerSection[sectionName][partName] = [];
        }
        var partUid:String = part.getContent(DataFields.PART_UID);
        if (partUid == DataFields.VALUE_NOT_SET) {
            partUid = Strings.generateUniqueId(PART_UIDS_POOL, PART_UID_LENGTH);
            ProjectData(part).setContent(DataFields.PART_UID, partUid);
        }
        _partsUidsToNodesMap[partUid] = part;
        var partOrdinalIndex:int = (_partsPerSection[sectionName][partName] as Array).indexOf(partUid);
        if (partOrdinalIndex == -1) {
            (_partsPerSection[sectionName][partName] as Array).push(partUid);
            partOrdinalIndex = ((_partsPerSection[sectionName][partName] as Array).length - 1);
            ProjectData(part).setContent(DataFields.PART_ORDINAL_INDEX, partOrdinalIndex);
        }
    }
}
}
