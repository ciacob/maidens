package ro.ciacob.maidens.controller.constants {
import flash.net.registerClassAlias;
import flash.utils.getQualifiedClassName;

import ro.ciacob.maidens.generators.constants.GeneratorKeys;

import ro.ciacob.maidens.generators.constants.GeneratorSupportedTypes;
import ro.ciacob.maidens.legacy.ProjectData;
import ro.ciacob.maidens.legacy.constants.DataFields;
import ro.ciacob.maidens.model.adaptors.HarmonyGeneratorFacade;
import ro.ciacob.maidens.view.components.GeneratorAdvancedConfiguration;
import ro.ciacob.maidens.view.components.GeneratorBasicConfiguration;

/**
 * Starting with version 1.5., MAIDENS support for user installed generators
 * has been dropped. All generators are now built-in, and are provided as
 * statically linked libraries.
 *
 * All available generators are statically defined in the list below.
 */
public final class GeneratorsTable {

    public static function get LIST():Array {
        var list:Array = [];
        var data:Object;
        var details:Object;
        var outSlots:Array;
        var slotInfo:Object;
        var classFqn:String;

        // -----------------------------
        // AtonalLine (legacy generator)
        // -----------------------------
        data = {};

        // Define generic information
        data[GeneratorKeys.GLOBAL_UID] = 'ro.ciacob.maidens.generators.builtin.atonalline.legacy';
        data[GeneratorKeys.NAME] = 'Atonal Line (legacy)';
        data[GeneratorKeys.VERSION] = '1.0.2';
        data[GeneratorKeys.RELEASE_DATE] = '2020/04/29';
        data[GeneratorKeys.COPYRIGHT] = 'Claudius Tiberiu Iacob';
        data[GeneratorKeys.DESCRIPTION] = 'Legacy implementation of a Generator that aims to produce a freely atonal melodic line, entirely replacing the selected Part\'s content in all Sections chosen as output. To use, nudge the target Part to the top position in the score.';
        data[GeneratorKeys.AUTHOR_NAME] = 'Claudius Tiberiu Iacob';
        data[GeneratorKeys.AUTHOR_EMAIL] = 'claudius.iacob@gmail.com';
        data[GeneratorKeys.AUTHOR_SITE] = 'https://claudius-iacob.eu';

        // Define entry point
        classFqn = getQualifiedClassName(AtonalLine);
        registerClassAlias(classFqn, AtonalLine);
        data[GeneratorKeys.MAIN_CLASS] = classFqn;

        // Define configuration UI
        classFqn = getQualifiedClassName(GeneratorBasicConfiguration);
        registerClassAlias(classFqn, GeneratorBasicConfiguration);
        data[GeneratorKeys.CONFIGURATION_UI_CLASS] = classFqn;

        // Outputs
        outSlots = [];
        slotInfo = {};
        slotInfo[GeneratorKeys.SLOT_NAME] = 'out';
        slotInfo[GeneratorKeys.SLOT_DATA_TYPE] = GeneratorSupportedTypes.OBJECT;
        outSlots.push(slotInfo);
        data[GeneratorKeys.OUTPUTS_DESCRIPTION] = outSlots;

        // Compile and export data
        var atonalLine:ProjectData = new ProjectData;
        details = {};
        details[DataFields.DATA_TYPE] = DataFields.GENERATOR;
        atonalLine.populateWithDefaultData(details);
        atonalLine.importContent(data);


        // --------------------------------
        // AtonalHarmony (legacy generator)
        // --------------------------------
        data = {};

        // Define generic information
        data[GeneratorKeys.GLOBAL_UID] = 'ro.ciacob.maidens.generators.builtin.atonalharmony.legacy';
        data[GeneratorKeys.NAME] = 'Atonal Harmony (legacy)';
        data[GeneratorKeys.VERSION] = '1.0.1';
        data[GeneratorKeys.RELEASE_DATE] = '2020/04/29';
        data[GeneratorKeys.COPYRIGHT] = 'Claudius Tiberiu Iacob';
        data[GeneratorKeys.DESCRIPTION] = 'Legacy implementation of a Generator that aims to produce a freely atonal (thus, possibly consonant) choral section, entirely replacing the selected Part\'s content in all Sections chosen as output. To use, nudge the target Part to the top position in the score, and set its "Number of staves" property to be at least "2".';
        data[GeneratorKeys.AUTHOR_NAME] = 'Claudius Tiberiu Iacob';
        data[GeneratorKeys.AUTHOR_EMAIL] = 'claudius.iacob@gmail.com';
        data[GeneratorKeys.AUTHOR_SITE] = 'https://claudius-iacob.eu';

        // Define entry point
        classFqn = getQualifiedClassName(AtonalHarmony);
        registerClassAlias(classFqn, AtonalHarmony);
        data[GeneratorKeys.MAIN_CLASS] = classFqn;

        // Define configuration UI
        classFqn = getQualifiedClassName(GeneratorBasicConfiguration);
        registerClassAlias(classFqn, GeneratorBasicConfiguration);
        data[GeneratorKeys.CONFIGURATION_UI_CLASS] = classFqn;

        // Outputs
        outSlots = [];
        slotInfo = {};
        slotInfo[GeneratorKeys.SLOT_NAME] = 'out';
        slotInfo[GeneratorKeys.SLOT_DATA_TYPE] = GeneratorSupportedTypes.OBJECT;
        outSlots.push(slotInfo);
        data[GeneratorKeys.OUTPUTS_DESCRIPTION] = outSlots;

        // Compile and export data
        var atonalHarmony:ProjectData = new ProjectData;
        details = {};
        details[DataFields.DATA_TYPE] = DataFields.GENERATOR;
        atonalHarmony.populateWithDefaultData(details);
        atonalHarmony.importContent(data);


        // ------------------
        // MultilineGenerator
        // ------------------
        data = {};

        // Define generic information
        data[GeneratorKeys.GLOBAL_UID] = 'eu.claudiusiacob.maidens.multiline';
        data[GeneratorKeys.NAME] = 'Multiline Generator';
        data[GeneratorKeys.VERSION] = '1.0.0';
        data[GeneratorKeys.RELEASE_DATE] = '2021/02/01';
        data[GeneratorKeys.COPYRIGHT] = 'Claudius Tiberiu Iacob';
        data[GeneratorKeys.DESCRIPTION] = 'Second iteration generator, able to produce structures of varying number of concurrent musical events.\n\nProvides advanced features, such as animated (i.e., evolving) parameter values, multicriterial decision making, preset management, progress reporting and improved control panels.\n\nCan be used to generate isolated lines, polyphony, isomorphic (homophonic) chorals and anything in between.';
        data[GeneratorKeys.AUTHOR_NAME] = 'Claudius Tiberiu Iacob';
        data[GeneratorKeys.AUTHOR_EMAIL] = 'claudius.iacob@gmail.com';
        data[GeneratorKeys.AUTHOR_SITE] = 'https://claudius-iacob.eu';

        // Define entry point
        classFqn = getQualifiedClassName(HarmonyGeneratorFacade);
        registerClassAlias(classFqn, HarmonyGeneratorFacade);
        data[GeneratorKeys.MAIN_CLASS] = classFqn;

        // Define configuration UI
        classFqn = getQualifiedClassName(GeneratorAdvancedConfiguration);
        registerClassAlias(classFqn, GeneratorAdvancedConfiguration);
        data[GeneratorKeys.CONFIGURATION_UI_CLASS] = classFqn;

        // Outputs
        outSlots = [];
        slotInfo = {};
        slotInfo[GeneratorKeys.SLOT_NAME] = 'out';
        slotInfo[GeneratorKeys.SLOT_DATA_TYPE] = GeneratorSupportedTypes.OBJECT;
        outSlots.push(slotInfo);
        data[GeneratorKeys.OUTPUTS_DESCRIPTION] = outSlots;

        // Compile and export data
        var multilineGenerator:ProjectData = new ProjectData;
        details = {};
        details[DataFields.DATA_TYPE] = DataFields.GENERATOR;
        multilineGenerator.populateWithDefaultData(details);
        multilineGenerator.importContent(data);

        // Export the list of generators
        list.push(multilineGenerator);
        list.push(atonalHarmony);
        list.push(atonalLine);
        return list;
    }
}
}