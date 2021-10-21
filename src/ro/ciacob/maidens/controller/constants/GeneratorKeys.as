package ro.ciacob.maidens.controller.constants {

	public final class GeneratorKeys {
		public static const ALL_GENERATION_DONE:String = 'allGenerationDone';
		public static const AUTHOR_EMAIL:String = 'generatorAuthorEmail';
		public static const AUTHOR_NAME:String = 'generatorAuthorName';
		public static const AUTHOR_SITE:String = 'generatorAuthorSite';
		public static const AVAILABLE_GENERATORS_LIST:String = 'availableGeneratorsList';
		public static const CONFIGURATION_DATA:String = 'configurationData';
		public static const COPYRIGHT:String = 'generatorCopyright';
		public static const DESCRIPTION:String = 'generatorDescription';

		public static const GEN_CFG_DATASET:String = 'genCfgDataset';
		public static const GEN_CFG_UI_BLUEPRINT:String = 'genCfgUiBlueprint';
		public static const GEN_CFG_WINDOW_CLOSE:String = 'genCfgWindowClose';
		public static const GEN_CFG_WINDOW_COMMIT:String = 'genCfgWindowCommit';
		public static const GLOBAL_UID:String = 'generatorGlobalUid';
		public static const UNRECOGNIZED_GENERATOR:String = 'The current project contains an unknown generator "%s" that could not be initialized.';
		public static const INITIALIZED_GENERATOR:String = 'initializedGenerator';
		public static const INITIALIZED_GENERATORS_LIST:String = 'initializedGeneratorsList';
		public static const INPUTS_DESCRIPTION:String = 'generatorInputsDescription';
		public static const INPUT_CONNECTIONS:String = 'generatorInputConnections';
		public static const MAIN_CLASS : String = 'generatorMainClass';
		public static const CONFIGURATION_UI_CLASS : String = 'generatorCfgUiClass';
		public static const NAME:String = 'generatorFriendlyName';
		public static const NEED_GEN_CFG:String = 'needGenCfg';
		public static const NEED_GEN_CFG_FORCE_CLOSED:String = 'needGenCfgForceClosed';
		public static const GENERATOR_BINDING_REQUEST:String = 'needGenDefaultData';
		public static const NEED_GEN_EXECUTION:String = 'needGenExecution';
		public static const NEED_GEN_OUTPUT_TARGETS:String = 'needGenOutputTargets';
		public static const NEED_GEN_PROMPT:String = 'needGenPrompt';
		public static const NEED_GEN_DIALOG:String = 'needGenDialog';
		public static const NONE:String = 'none';
		public static const OUTPUTS_DESCRIPTION:String = 'generatorOutputsDescription';
		public static const OUTPUT_CONNECTIONS:String = 'generatorOutputConnections';
		public static const OUTPUT_TARGETS:String = 'outputTargets';
		public static const PROJECT_GENERATORS_READY:String = 'projectGeneratorsReady';
		public static const QUEUE_EXHAUSTED:String = 'queueExhausted';
		public static const QUEUE_POSITION_EXHAUSTED:String = 'queuePositionExhausted';
		public static const RELEASE_DATE:String = 'generatorReleaseDate';
		public static const REQUIRED_GENERATORS_LIST:String = 'requiredGeneratorsList';
		public static const SLOT_DATA_TYPE:String = 'slotDataType';
		public static const SLOT_NAME:String = 'slotName';
		public static const TARGETS_INFO:String = '$targetsInfo';
		public static const VERSION:String = 'generatorVersion';
		public static const NEED_GEN_UIDS:String = 'needGenUids';
		public static const GEN_UIDS_LIST_READY : String = 'genUidsListReady';
		public static const STATUS_CHANGED : String = 'statusChanged';
		public static const GEN_ABORT_REQUESTED : String = 'genAbortRequested';
		public static const GEN_MINIMIZE_REQUESTED : String = 'genMinimizeRequested';
		public static const UI_GENERATOR_CONFIG : String = 'uiGeneratorConfig';
		public static const ANIMATED_PARAMETER_UIDS : String = 'animatedParameterUids';
		public static const PARAMETERS : String = 'generatorParameters';
		public static const ANIMATED_PARAMETERS : String = 'animatedParameters';
		
		public static const SECTION_TARGETS:String = 'Score Sections';
		public static const GENERATION_STATUS_TEMPLATE:String = 'Generation %s';
		public static const GENERATION_IN_PROGRESS : String = '%s is producing content. Please wait...';
		public static const GENERATION_COMPLETED : String = 'Execution of %s completed normally.';
		public static const GENERATION_ABORTED : String = '%s halted execution on user request.';
		public static const GENERATION_ERROR : String = '%s encountered an error.';
	}
}
