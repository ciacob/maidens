package ro.ciacob.maidens.model {
import avmplus.getQualifiedClassName;

import ro.ciacob.desktop.data.DataElement;
import ro.ciacob.desktop.data.constants.DataKeys;
import ro.ciacob.desktop.data.exporters.IExporter;
import ro.ciacob.desktop.data.exporters.PlainObjectExporter;
import ro.ciacob.desktop.data.importers.IImporter;
import ro.ciacob.desktop.data.importers.PlainObjectImporter;
import ro.ciacob.maidens.controller.constants.GeneratorKeys;
import ro.ciacob.maidens.generators.constants.BarTypes;
import ro.ciacob.maidens.model.constants.DataFields;
import ro.ciacob.maidens.model.constants.DataFormats;
import ro.ciacob.maidens.model.constants.StaticFieldValues;
import ro.ciacob.maidens.model.exporters.AudioABCExporter;
import ro.ciacob.maidens.model.exporters.PrintABCExporter;
import ro.ciacob.maidens.model.exporters.ScreenABCExporter;
import ro.ciacob.maidens.model.exporters.TreeDataProviderExporter;
import ro.ciacob.utils.Time;

public class ProjectData extends DataElement {

    /**
     * - accidental: a musical accidental, defined by its type ("flat", "natural",
     *   "sharp", "double flat", "double sharp"), pitch ("C", "D", "E", etc.), and
     *   the object it attaches to, be it a note, or a measure. Accidentals, which
     *   attach to measures become key signatures or key signature changes, based on
     *   whether they attach to the first measure or not.
     */
    private static function get accidentalDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.ACCIDENTAL;
        data[DataKeys.CONTENT][DataFields.ACCIDENTAL_TYPE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PITCH_NAME] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.ATTACHE_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - accidentals: this is merely a container for all accidentals used in the
     *   score.
     *
     *   Beside the actual objects, this container also holds an index, which
     *   lists them by their attachment, to speed up the reverse look-up process.
     */
    private static function get accidentalsDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.ACCIDENTALS_CONTAINER;
        data[DataKeys.CONTENT][DataFields.INDEX_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - articulation: musical articulation, such as "staccato", "tenuto",
     *   "accented", etc. Note that MAIDEN lists the "fermata" as a tempo
     *   alteration, since this is the actual playing employed (slow down tempo,
     *   so that the note with fermata appears to be "held", then back up again).
     *   Articulations are defined by their type, the object they attach to, and
     *   the object they detach from, if should be the case. For instance, a
     *   slur or tie need both. Articulations only attach to clusters having
     *   at least one note.
     */
    private static function get articulationDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.ARTICULATION;
        data[DataKeys.CONTENT][DataFields.ARTICULATION_TYPE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.ATTACHE_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.DETTACHE_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - articulations: this is merely a container for all articulations used in the
     *   score.
     *
     *   Beside the actual objects, this container also holds an index, which
     *   lists them by their attachment, to speed up the reverse look-up process.
     */
    private static function get articulationsDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.ARTICULATIONS_CONTAINER;
        data[DataKeys.CONTENT][DataFields.INDEX_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - clef: musical clefs, such as the violine or bass clef; they are defined
     *   by type ("G", "C", "F", "G-8", etc.) and the object they attach to, be
     *   it a cluster, or a voice. Attaching clefs to clusters allows us to
     *   change the clef mid-measure.
     */
    private static function get clefDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.CLEF;
        data[DataKeys.CONTENT][DataFields.CLEF_TYPE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.ATTACHE_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - clefs: this is merely a container for all clefs used in the score.
     *
     *   Beside the actual objects, this container also holds an index, which
     *   lists them by their attachment, to speed up the reverse look-up process.
     */
    private static function get clefsDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.CLEFS_CONTAINER;
        data[DataKeys.CONTENT][DataFields.INDEX_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - cluster: a cluster is either a single note, or several notes (a chord)
     *   or no note (a silence, or rest). A cluster is defined by its duration
     *   (expressed by a ratio, such as "1/4" for a quarter), division type (such
     *   as "regular", "tripplet", etc.) and dot type (such as "double", "simple"
     *   or "none").
     */
    private static function get clusterDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.CLUSTER;
        data[DataKeys.CONTENT][DataFields.CLUSTER_DURATION_FRACTION] = StaticFieldValues.DEFAULT_CLUSTER_DURATION;
        data[DataKeys.CONTENT][DataFields.DOT_TYPE] = StaticFieldValues.DEFAULT_CLUSTER_DOT_TYPE;
        data[DataKeys.CONTENT][DataFields.CHILD_TYPE] = DataFields.NOTE;

        // TUPLET_DEFINITION
        data[DataKeys.CONTENT][DataFields.STARTS_TUPLET] = false;
        data[DataKeys.CONTENT][DataFields.TUPLET_ROOT_ID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.TUPLET_SRC_NUM_BEATS] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.TUPLET_TARGET_NUM_BEATS] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.TUPLET_BEAT_DURATION] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - dynamic: both dynamic marks ("ppp", "pp", "p", "mp", "mf", "f", "ff",
     *   "fff", "mb", "sf", "sfz") and dynamic gradual alterations ("cresc.",
     *   "desc.", "<", ">") fill this category. See previous note. Dynamic marks
     *   only attach to clusters having at least one note.
     */
    private static function get dynamicDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.DYNAMIC_INSTRUCTION;
        data[DataKeys.CONTENT][DataFields.DYNAMIC_INSTRUCTION_TYPE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.ATTACHE_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.DETTACHE_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - dynamics: this is merely a container for all dynamic instructions used in the
     *   score.
     *
     *   Beside the actual objects, this container also holds an index, which
     *   lists them by their attachment, to speed up the reverse look-up process.
     */
    private static function get dynamicsDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.DYNAMIC_INSTRUCTIONS_CONTAINER;
        data[DataKeys.CONTENT][DataFields.INDEX_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     *  Generator: this is a proxy (or "façade") to uniquely refer to an actual
     *  generator instance which is included in the project;
     *
     *     FIELD DETAILS
     *   -------------
     *
     *     There are three type of fields used by the generator node type:
     *   a) legacy fields, needed to conform the data model used by MAIDENS (DataFields.DATA_TYPE,
     *      DataFields.CONNECTION_ID);
     *   b) fields meant to be set by means which are external to the Generator (
     *        GeneratorKeys.GLOBAL_UID, GeneratorKeys.INPUT_CONNECTIONS, GeneratorKeys.OUTPUT_CONNECTIONS);
     *   c) fields which mirror the data provided by the Generator;
     *
     *
     *    (a) - self explanatory;
     *
     *  (b)
     *  GeneratorKeys.GLOBAL_UID
     *  A globally unique string, reverse domain style ID to represent this generator; set at initialization
     *  time.
     *
     *  GeneratorKeys.OUTPUT_CONNECTIONS
     *  The actual connections the end-user has wired from this generator's outputs. Set by the user, from
     *  within the `GeneratorUI` interface.
     *
     *  GeneratorKeys.CONFIGURATION_DATA
     *  The dataset representing the end-user's configuration preferences. These are set from within the
     *  GeneratorBasicConfiguration interface.
     *
     *  (c)
     *  GeneratorKeys.NAME;
     *  GeneratorKeys.VERSION;
     *  GeneratorKeys.RELEASE_DATE;
     *  GeneratorKeys.COPYRIGHT;
     *  GeneratorKeys.DESCRIPTION;
     *  GeneratorKeys.AUTHOR_NAME;
     *  GeneratorKeys.AUTHOR_EMAIL;
     *  GeneratorKeys.AUTHOR_SITE;
     *  GeneratorKeys.OUTPUTS_DESCRIPTION;
     */
    private static function get generatorDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.GENERATOR;

        data[DataKeys.CONTENT][DataFields.CONNECTION_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.GLOBAL_UID] = DataFields.VALUE_NOT_SET;

        data[DataKeys.CONTENT][GeneratorKeys.MAIN_CLASS] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.CONFIGURATION_UI_CLASS] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.CONFIGURATION_DATA] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.INPUT_CONNECTIONS] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.INPUTS_DESCRIPTION] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.OUTPUT_CONNECTIONS] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.OUTPUTS_DESCRIPTION] = DataFields.VALUE_NOT_SET;

        data[DataKeys.CONTENT][GeneratorKeys.NAME] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.VERSION] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.RELEASE_DATE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.COPYRIGHT] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.DESCRIPTION] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.AUTHOR_NAME] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.AUTHOR_EMAIL] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][GeneratorKeys.AUTHOR_SITE] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - generators: this is merely a container for all generators used in
     *   the project.
     */
    private static function get generatorsDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.GENERATORS;
        data[DataKeys.CONTENT][DataFields.CHILD_TYPE] = DataFields.GENERATOR;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - index: this is a sub-container all containers above have. It lists unique ids
     *   of specific objects (e.g., accidentals, clefs) by the respective unique ids of
     *   the objects (e.g., measures, notes) they were attached to. This, the index
     *   defines by a variable number of unique ids, each containing an array filled with
     *   one or more unique ids. Neither of these are known ahead of time, so we cannot
     *   create a blueprint for them within `get indexDefault()`.
     */
    private static function get indexDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.INDEX_CONTAINER;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - measure: a musical measure; measure spans in MAIDENS are logically
     *   defined by one or more fractions (such as "6/8", or "3/8,3/8,2/8";
     *   all computations will use the 4620 internal time units per quarter base,
     *   e.g., the measure of "3/4" will thus accept 3 * 4620 = 13860 units within its
     *   boundaries), by bar type, a repetition first jump target, and a repetition
     *   second jump target. MAIDEN will only play a repetead section at most twice.
     *   If you need something more complex, please write it out "in extenso".
     */
    private static function get measureDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.MEASURE;
        data[DataKeys.CONTENT][DataFields.BAR_TYPE] = BarTypes.AUTO_BAR;
        data[DataKeys.CONTENT][DataFields.TIME_FRACTION] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.BEATS_NUMBER] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.BEAT_DURATION] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.REPETITION_FIRST_JUMP_TARGET_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.REPETITION_SECOND_JUMP_TARGET_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CHILD_TYPE] = DataFields.VOICE;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * NOTE
     * ----
     * A musical note, defined by:
     * - pitch name (such as "C", "D", "E", etc.);
     * - pitch alteration (such as `0`, `1`, `-1`, `2`, `-2`);
     * - octave index, such as `4` for middle C (261Hz, or MIDI note 60). In MAIDENS,
     *   octave indexes range from `-1` (sub-sub contra octave) to `9` (6-line octave).
     *   Octave at index `-1` is accounted for, but never used.
     */
    private static function get noteDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.NOTE;
        data[DataKeys.CONTENT][DataFields.PITCH_NAME] = StaticFieldValues.DEFAULT_PITCH;
        data[DataKeys.CONTENT][DataFields.PITCH_ALTERATION] = StaticFieldValues.DFAULT_PITCH_ALTERATION;
        data[DataKeys.CONTENT][DataFields.OCTAVE_INDEX] = StaticFieldValues.DEFAULT_OCTAVE_INDEX;
        data[DataKeys.CONTENT][DataFields.TIES_TO_NEXT_NOTE] = false;
        data[DataKeys.CONTENT][DataFields.FLAGGED] = false;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - part: a part defines a choir section (SATB) or musical instrument
     *   playing in the same musical score (not necesarily together with all
     *   the others). A part is defined by its name, number of staves required,
     *   type of bracket, transposition, an array of clefs and a concert pitch range.
     *   MAIDENS only provides the instruments in the contemporary symphonic orchestra,
     *   plus some jazz instruments. It maps automatically these names to MIDI patches
     *   when playing, and can map several patches to a single name if needed,
     *   e.g., it can map strings, strings pizzicato and strings tremolo to the
     *   name of "violins".
     */
    private static function get partDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.PART;
        data[DataKeys.CONTENT][DataFields.PART_NAME] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.ABBREVIATED_PART_NAME] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PART_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PART_ORDINAL_INDEX] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PART_NUM_STAVES] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PART_OWN_BRACKET_TYPE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PART_TRANSPOSITION] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PART_CLEFS_LIST] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CONCERT_PITCH_RANGE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CHILD_TYPE] = DataFields.MEASURE;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - performance: performance instructions, such as "pizz.", or "arco", or
     *   "dolce". They are identical to articulations from a user point of view,
     *   but are handled differently by MAIDENS when playing back the score.
     *   Performance instructions attach to measures or clusters, includding
     *   empty ones.
     */
    private static function get performanceDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.PERFORMANCE_INSTRUCTION;
        data[DataKeys.CONTENT][DataFields.PERFORMANCE_INSTRUCTION_TYPE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.ATTACHE_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.DETTACHE_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - performances: this is merely a container for all performance instructions
     *   used in the score.
     *
     *   Beside the actual objects, this container also holds an index, which
     *   lists them by their attachment, to speed up the reverse look-up process.
     */
    private static function get performancesDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.PERFORMANCE_INSTRUCTIONS_CONTAINER;
        data[DataKeys.CONTENT][DataFields.INDEX_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * A `project` contains the sections `score` and `settings`. A project is defined by
     * the project name, the creation and last modification timestamps, the composer name,
     * a copyright note, and a `custom notes` field. A project also contains suplementary
     * fields, which provide quicker access to its contained children.
     */
    private static function get projectDefault():Object {
        // Define structure
        var data:Object = {};

        // This will become the root element, therefore we also provide its
        // metadata
        data[DataKeys.METADATA] = {};
        data[DataKeys.METADATA][DataKeys.PARENT] = null;
        data[DataKeys.METADATA][DataKeys.LEVEL] = 0;
        data[DataKeys.METADATA][DataKeys.INDEX] = 0;
        data[DataKeys.METADATA][DataKeys.ROUTE] = '-1';

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.PROJECT;
        data[DataKeys.CONTENT][DataFields.PROJECT_NAME] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CREATION_TIMESTAMP] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.MODIFICATION_TIMESTAMP] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.COMPOSER_NAME] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.COPYRIGHT_NOTE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CUSTOM_NOTES] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PROJECT_SCORE_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PROJECT_SETTINGS_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - relationalAssets: this is merely a container for all the assets that
     *   aren't hierarchically disposed within the data structure, rather linked to
     *   relevant objects that need them (mostly measures and clusters).
     */
    private static function get relationalAssetsDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.RELATIONAL_ASSETS_CONTAINER;
        data[DataKeys.CONTENT][DataFields.ACCIDENTALS_CONTAINER_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CLEF_CONTAINER_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.TIME_SIGNATURES_CONTAINER_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.ARTICULATIONS_CONTAINER_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.PERFORMANCE_INSTRUCTIONS_CONTAINER_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.DYNAMIC_INSTRUCTIONS_CONTAINER_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.TEMPO_INSTRUCTIONS_CONTAINER_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * A `score` contains `sections`, `parts`, `measures`, `voices`, `clusters`,
     * `notes`, `accidentals`, clefs`, `times`, `articulations`, `performances`,
     * `dynamics`, `tempos`.
     *
     * All these are partly relationized, partly hierarchically nested,
     * to obtain the best ballance between speed during queries and friendliness
     * when rendering the datastructure to humans. Relationized items feature
     * indexes, to aid with reverse look-up (e.g., finding which accidental is
     * attached to a specific note).
     *
     * The hierarchic structure of `score` is rendered below.
     *
     * score
     *   |
     *   +-section1
     *   |  |
     *   |  +-part1
     *   |     |
     *   |     +-measure1
     *   |     |  |
     *   |     |  +-voice1
     *   |     |       |
     *   |     |       +-cluster1
     *   |     |       |    |
     *   |     |       |    +-note1
     *   |     |       |    |
     *   |     |       |    +-note2
     *   |     |       |
     *   |     |       +-cluster2
     *   |     |            |
     *   |     |            +-note1
     *   |     +-measure2
     *   |        |
     *   |        +-...
     *   |
     *   +-section2...
     *   |
     *   +-relationalAssets
     *       |
     *       +-accidentals
     *       |   |
     *       |   +-index
     *       |   |   |
     *       |   |   +-indexData...
     *       |   |
     *       |   +-accidental1
     *       |   |
     *       |   +-accidental2
     *       |   |
     *       |   +-...
     *       |
     *       +-clefs...
     *       |
     *       +-times...
     *       |
     *       +-articulations...
     *       |
     *       +-performances...
     *       |
     *       +-dynamics...
     *       |
     *       +-tempos...
     */
    private static function get scoreDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.SCORE;
        data[DataKeys.CONTENT][DataFields.RELATIONAL_ASSETS_CONTAINER_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CHILD_TYPE] = DataFields.SECTION;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - section: a musical section; sections are represented by MAIDENS
     *   using a flat structure rather a hierarchical one. Use meaningful
     *   naming (such as section A1.1 to suggest hierarchy, if you need it).
     *   A sesion is defined by a unique name.
     */
    private static function get sectionDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.SECTION;
        data[DataKeys.CONTENT][DataFields.UNIQUE_SECTION_NAME] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CONNECTION_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.CHILD_TYPE] = DataFields.PART;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - tempo: both fixed tempo marks ("adagio", "adagieto", "moderato", "vivace",
     *   "presto", "prestissimo") and gradual tempo alterations ("rall.", "accel.",
     *   "a tempo") fill this category. See the previous note. Instead of defining
     *   a tempo by its type, you can define it by the fraction of a unit and the number
     *   of units to be played per minute, e.g., "1/4=40" is how "adagio" is internally
     *   defined. Tempos attach to clusters or measures.
     */
    private static function get tempoDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.TEMPO_INSTRUCTION;
        data[DataKeys.CONTENT][DataFields.TEMPO_INSTRUCTION_TYPE] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.ATTACHE_UID] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.DETTACHE_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - tempos: this is merely a container for all tempo instructions used in the
     *   score.
     *
     *   Beside the actual objects, this container also holds an index, which
     *   lists them by their attachment, to speed up the reverse look-up process.
     */
    private static function get temposDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.TEMPO_INSTRUCTIONS_CONTAINER;
        data[DataKeys.CONTENT][DataFields.INDEX_UID] = DataFields.VALUE_NOT_SET;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    /**
     * - voice: a "division" within a part, which can be rendered either on the same
     *   staff, or on a different one. A voice is defined by the index of the
     *   staff it is rendered onto (because some instruments/parts, such as piano,
     *   use more than a single staff by default) and the order it is to be rendered
     *   in (this can be used to properly draw
     *   note stems, i.e., upward or downward).
     */
    private static function get voiceDefault():Object {
        // Define structure
        var data:Object = {};

        // Provide default content
        data[DataKeys.CONTENT] = {};
        data[DataKeys.CONTENT][DataFields.DATA_TYPE] = DataFields.VOICE;
        data[DataKeys.CONTENT][DataFields.STAFF_INDEX] = DataFields.VALUE_NOT_SET;
        data[DataKeys.CONTENT][DataFields.VOICE_INDEX] = StaticFieldValues.DEFAULT_VOICE_INDEX;
        data[DataKeys.CONTENT][DataFields.CHILD_TYPE] = DataFields.CLUSTER;

        // Provide children storage space
        data[DataKeys.CHILDREN] = [];

        // Output structure
        return data;
    }

    public function ProjectData(initialMetadata:Object = null, initialContent:Object =
            null) {
        super(initialMetadata, initialContent);
    }

    override public function exportToFormat(format:String, resources:* = null):* {
        var exporter:IExporter;
        switch (format) {
            case DataFormats.PLAIN_OBJECT:
                exporter = new PlainObjectExporter;
                return exporter.export(this);
            case DataFormats.TREE_DATA_PROVIDER:
                exporter = new TreeDataProviderExporter;
                return exporter.export(this);
            case DataFormats.SCREEN_ABC_DATA_PROVIDER:
                exporter = new ScreenABCExporter;
                return exporter.export(this);
            case DataFormats.PRINT_ABC_DATA_PROVIDER:
                exporter = new PrintABCExporter;
                return exporter.export(this);
            case DataFormats.AUDIO_ABC_DATA_PROVIDER:
                exporter = new AudioABCExporter;
                return exporter.export(this);
        }
        throw(new Error(getQualifiedClassName(this) + ' - exportToFormat(): format `' +
                format + '` is not known to this class.'));
    }

    override public function importFromFormat(format:String, content:*):void {
        var importer:IImporter;
        switch (format) {
            case DataFormats.PLAIN_OBJECT:
                importer = new PlainObjectImporter;
                importer.importData(content, this);
                return;
        }
        throw(new Error(getQualifiedClassName(this) + ' - importFromFormat(): format `' +
                format + '` is not known to this class.'));
    }

    /**
     * This is useful for creating new items. Based on criteria, such as the new
     * item's depth, different type of default content might be loaded into
     * the newly created item.
     *
     * @see ro.ciacob.desktop.data.ProjectData
     */
    override public function populateWithDefaultData(details:* = null):void {
        var dataType:String = details[DataFields.DATA_TYPE];
        switch (dataType) {
            case DataFields.PROJECT:
                // Default project will contain an empty generators recipient and an empty score.
                var project:Object = projectDefault;
                project[DataKeys.CONTENT][DataFields.CREATION_TIMESTAMP] = Time.timestamp;
                project[DataKeys.CONTENT][DataFields.MODIFICATION_TIMESTAMP] = Time.timestamp;
                var generators:Object = generatorsDefault;
                (project[DataKeys.CHILDREN] as Array).push(generators);
                var score:Object = scoreDefault;
                (project[DataKeys.CHILDREN] as Array).push(score);
                importFromFormat(DataFormats.PLAIN_OBJECT, project);
                break;
            case DataFields.GENERATOR:
                importFromFormat(DataFormats.PLAIN_OBJECT, generatorDefault);
                break;
            case DataFields.SECTION:
                importFromFormat(DataFormats.PLAIN_OBJECT, sectionDefault);
                break;
            case DataFields.PART:
                importFromFormat(DataFormats.PLAIN_OBJECT, partDefault);
                break;
            case DataFields.MEASURE:
                importFromFormat(DataFormats.PLAIN_OBJECT, measureDefault);
                break;
            case DataFields.VOICE:
                importFromFormat(DataFormats.PLAIN_OBJECT, voiceDefault);
                break;
            case DataFields.CLUSTER:
                importFromFormat(DataFormats.PLAIN_OBJECT, clusterDefault);
                break;
            case DataFields.NOTE:
                importFromFormat(DataFormats.PLAIN_OBJECT, noteDefault);
                break;
        }
    }
}
}
