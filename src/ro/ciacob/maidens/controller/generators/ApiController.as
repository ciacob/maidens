package ro.ciacob.maidens.controller.generators {
	import flash.utils.getQualifiedClassName;
	
	import ro.ciacob.desktop.signals.PTT;
	import ro.ciacob.maidens.controller.QueryEngine;
	import ro.ciacob.maidens.controller.constants.CoreApiArguments;
	import ro.ciacob.maidens.controller.constants.CoreApiNames;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.StaticTokens;
	import ro.ciacob.maidens.view.constants.PromptKeys;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.utils.NumberUtil;
	import ro.ciacob.utils.Strings;

	public final class ApiController {

		// --------------
		// Public methods
		// --------------
		public function ApiController(master:GeneratorUtils) {
			_master = master;
		}

		/**
		 * "Visits" the given API, optionally executing it with given arguments (optional as well).
		 *
		 * Sends the visit's result to a callback function. If the argument `mustExecute` is true,
		 * this result contains the actual output of the associated function; otherwise, it is
		 * `true` if an API named `apiName` exists, and `false` otherwise.
		 *
		 * @param	apiName
		 * 			The name of an API to execute, or check if existing.
		 *
		 * @param	resultCallback
		 * 			A function to receive the result of the operation performed (executing
		 * 			the API, or checking for its existence).
		 *
		 * @param	mustExecute
		 * 			Optional, defaults to `false`. Whether the API is to be executed (`true`) or
		 * 			merely looked up (`false`).
		 *
		 * @param	arguments
		 * 			Optional, defaults to null. The arguments to be sent to de API while executing, if
		 * 			`mustExecute` was true.
		 *
		 * @throws If `mustExecute` was true, but there is no API named by the value of `apiName`.
		 */
		public function touchApi(apiName:String, resultCallback:Function, mustExecute:Boolean =
			false, arguments:Array = null):void {
			var apiResult:Object = null;
			switch (apiName) {
				case CoreApiNames.SHOW_MESSAGE:
					if (mustExecute) {
						_assertProperArguments(apiName, arguments, CoreApiArguments.SHOW_MESSAGE);
						apiResult = _core_showMessage.apply (this, arguments);
						resultCallback(apiName, apiResult);
					}
					break;
				
				case CoreApiNames.REPORT_GENERATION_PROGRESS:
					if (mustExecute) {
						_assertProperArguments (apiName, arguments, CoreApiArguments.REPORT_GENERATION_PROGRESS);
						apiResult = _core_reportGenerationProgress.apply (this, arguments);
						resultCallback (apiName, apiResult);
					}
					break;
				
				case CoreApiNames.GET_GREATEST_DURATION_OF:
					if (mustExecute) {
						_assertProperArguments(apiName, arguments, CoreApiArguments.GET_GREATEST_DURATION_OF);
						apiResult = _core_getGreatestDurationOf.apply (this, arguments);
						resultCallback(apiName, apiResult);
					}
					break;
				
				case CoreApiNames.GET_SECTIONS_BY_NAMES:
					if (mustExecute) {
						_assertProperArguments (apiName, arguments, CoreApiArguments.GET_SECTIONS_BY_NAMES);
						apiResult = _core_getSectionsByName.apply (this, arguments);
						resultCallback (apiName, apiResult);
					}
					break;
				

				default:
					// If we reach down here, this means that there was no match for the
					// requested API name.
					// TODO: support API extensions provided by generator modules.
					if (mustExecute) {
						throw(new Error(StaticTokens.NO_SUCH_API.replace('%s', apiName).
							replace('%s', _master.currentlyGeneratingModuleUid)));
					} else {
						resultCallback(false);
					}
					break;
			}
		}
		
		
		// -----------------
		// Private constants
		// -----------------
		private static const INT_TYPE : String = 'int';
		private static const UINT_TYPE : String = 'uint';
		private static const NUMBER_TYPE : String = 'Number';
		
		
		// -----------------
		// Private variables
		// -----------------
		private var _master:GeneratorUtils;


		// ---------------
		// Private methods
		// ---------------
		/**
		 * TODO: Document
		 */
		private function _assertProperArguments(apiName:String, actual:Array, expected:Array):void {
			var numGiven:int = actual.length;
			var minArgs:int = (expected[0] as int);
			var maxArgs:int = (expected.length - 1);
			var allRequired:Boolean = (minArgs == allRequired);
			if (allRequired && numGiven != maxArgs) {
				throw(new Error(StaticTokens.API_WRONG_ARGUMENTS_NUMBER.replace('%s',
					apiName).replace('%d', maxArgs).replace('%d', numGiven)));
				return;
			}
			if (numGiven < minArgs || numGiven > maxArgs) {
				throw(new Error(StaticTokens.API_WRONG_ARGUMENTS_RANGE.replace('%s',
					apiName).replace('%d', minArgs).replace('%d', maxArgs).replace('%d',
					numGiven)));
				return;
			}
			for (var i:int = 0; i < numGiven; i++) {
				var actualType:String = getQualifiedClassName(actual[i]);
				// The first position in the `expected` Array is reserved, and we must skip it.
				var expectedType:String = getQualifiedClassName(expected[i + 1]);
				if (actualType != expectedType && !_bothTypesAreNumeric(actualType, expectedType)) {
					throw(new Error(StaticTokens.API_WRONG_ARGUMENT_TYPE.replace('%s',
						apiName).replace('%s', NumberUtil.ordinalise(i + 1)).replace('%s',
						expectedType).replace('%s', actualType)));
					return;
				}
			}
		}
		
		/**
		 * Returns `true` if both given types are one of `int`, `uint` or `Number`; returns `false`
		 * otherwise.
		 */
		private function _bothTypesAreNumeric (typeA : String, typeB : String) : Boolean {
			return Strings.isAny(typeA, INT_TYPE, UINT_TYPE, NUMBER_TYPE) &&
				Strings.isAny (typeB, INT_TYPE, UINT_TYPE, NUMBER_TYPE);
		}

		/**
		 * Shows a general purpose dialog. Resulting prompt is clearely marked as being related to
		 * (and having been produced by) a generator.
		 *
		 * @param	message
		 * 			The message to display.
		 *
		 * @param	type
		 * 			The type of message (one of "promptTypeBlank", "promptTypeYesNo", "promptTypeOkCancel",
		 * 			"promptTypeOk"). Defaults to "promptTypeBlank".
		 *
		 * @param	confirmCallback
		 * 			A callback to trigger when a "OK" or "Yes" button is clicked.
		 */
		private function _core_showMessage (message:String, type:String = PromptKeys.PROMPT_TYPE_BLANK, confirmCallback : Function = null) : void {
			_master.showGeneratorPrompt (_master.currentlyGeneratingModuleUid.fqn, message, type, confirmCallback);
		}
		
		/**
		 * Shows a dialog dedicated to monitoring the current Generator's progress.
		 * 
		 * @param	info
		 * 			An Object describing the Generator's current status and completion percent.
		 * 
		 * @param	pipe
		 * 			A dedicated PTT instance to use for communicating with the Generator. Especially
		 * 			usefull for allowing the user to abort the generation process.
		 */
		private function _core_reportGenerationProgress (info : Object, pipe : PTT) : void {
			_master.showGeneratorProgress (_master.currentlyGeneratingModuleUid.fqn, info, pipe);
		}
		
		/**
		 * Computes and returns the greatest musical duration of all given sections (represented by their
		 * unique section name).
		 * 
		 * @param	sectionNames
		 * 			An Array containing unique section names.
		 * 
		 * @return	The greatest duration, as a stringified Fraction (e.g., "2/1" for two wholes).
		 */
		private function _core_getGreatestDurationOf (sectionNames : Array):String {
			var duration : Fraction = Fraction.ZERO;
			var qEngine : QueryEngine = _master.controller.model.queryEngine;
			for (var i:int = 0; i < sectionNames.length; i++) {
				var sectionName : String = (sectionNames[i] as String);
				var section : ProjectData = qEngine.getSectionByName (sectionName);
				var sectionDuration : Fraction = qEngine.computeSectionNominalDuration (section);
				if (sectionDuration.greaterThan(duration)) {
					duration = sectionDuration;
				}
			}
			return duration.toString();
		}
		
		/**
		 * Resolves given Section names to actual Section datasets and returns them in the same order.
		 * Usefull when the Generator needs to execute advanced calculations on its own, based on the
		 * musical area that is to be filled.
		 * 
		 * @param	sectionNames
		 * 			A Vector of Strings containing unique section names.
		 * 
		 * @return 	A Vector of ProjectData instances respectivelly pointing to matching Section datasets.
		 */
		private function _core_getSectionsByName (sectionNames : Vector.<String>) : Vector.<ProjectData> {
			var sections : Vector.<ProjectData> = new Vector.<ProjectData>;
			var qEngine : QueryEngine = _master.controller.model.queryEngine;
			for (var i:int = 0; i < sectionNames.length; i++) {
				var sectionName : String = (sectionNames[i] as String);
				sections[i] = qEngine.getSectionByName (sectionName);
			}
			return sections;
		}
	}
}
