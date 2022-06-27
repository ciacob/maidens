package ro.ciacob.maidens.model.adaptors {
	import flash.utils.getQualifiedClassName;
	
	import eu.claudius.iacob.music.knowledge.instruments.InstrumentFactory;
	import eu.claudius.iacob.music.knowledge.instruments.interfaces.IMusicalInstrument;
	import eu.claudius.iacob.music.knowledge.timesignature.TimeSignatureFactory;
	import eu.claudius.iacob.music.knowledge.timesignature.helpers.TimeSignatureEntry;
	import eu.claudius.iacob.music.knowledge.timesignature.helpers.TimeSignatureMap;
	import eu.claudius.iacob.music.knowledge.timesignature.interfaces.ITimeSignatureDefinition;
	import eu.claudius.iacob.music.knowledge.timesignature.interfaces.ITimeSignatureEntry;
	import eu.claudius.iacob.music.knowledge.timesignature.interfaces.ITimeSignatureMap;
	
	import ro.ciacob.desktop.data.constants.DataKeys;
	import ro.ciacob.desktop.signals.PTT;
	import ro.ciacob.maidens.controller.constants.CoreApiNames;
	import ro.ciacob.maidens.controller.constants.GeneratorKeys;
	import ro.ciacob.maidens.controller.constants.GeneratorPipes;
	import ro.ciacob.maidens.generators.GeneratorBase;
	import ro.ciacob.maidens.generators.MusicEntry;
	import ro.ciacob.maidens.generators.constants.GeneratorBaseKeys;
	import ro.ciacob.maidens.generators.core.MusicRequest;
	import ro.ciacob.maidens.generators.core.SettingsList;
	import ro.ciacob.maidens.generators.core.abstracts.AbstractGeneratorModule;
	import ro.ciacob.maidens.generators.core.constants.CoreOperationKeys;
	import ro.ciacob.maidens.generators.core.interfaces.IMusicPitch;
	import ro.ciacob.maidens.generators.core.interfaces.IMusicRequest;
	import ro.ciacob.maidens.generators.core.interfaces.IMusicUnit;
	import ro.ciacob.maidens.generators.core.interfaces.IMusicalBody;
	import ro.ciacob.maidens.generators.core.interfaces.IParameter;
	import ro.ciacob.maidens.generators.core.interfaces.IParametersList;
	import ro.ciacob.maidens.generators.core.interfaces.IPitchAllocation;
	import ro.ciacob.maidens.generators.core.interfaces.ISettingsList;
	import ro.ciacob.maidens.generators.core.ui.ParameterUI;
	import ro.ciacob.maidens.generators.core.ui.PointTools;
	import ro.ciacob.maidens.generators.harmony.HarmonyGenerator;
	import ro.ciacob.maidens.model.ModelUtils;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.maidens.view.constants.ViewKeys;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.math.IFraction;
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.Time;
	import ro.ciacob.utils.constants.CommonStrings;
	
	/**
	 * Translator class that enables the second iteration `HarmonyGenerator` to interact
	 * with the first iteration generators client that is built into MAIDENS. We chose this
	 * approach in order to support the legacy generators without changes.
	 */
	public class HarmonyGeneratorFacade extends GeneratorBase {
		
		private static const START_DELAY : int = 1;
		private static const TYPE_ARRAY : uint = CoreOperationKeys.TYPE_ARRAY;
		private static const DATA_PROVIDER_NAME : String = 'value';
		private static const CUSTOM_COMPONENT_FQN : String = getQualifiedClassName (ParameterUI)
			.replace (CommonStrings.DOUBLE_COLON, CommonStrings.DOT);
		
		private var _generator : HarmonyGenerator;
		private var _generatedMusic : IMusicalBody;
		private var _parameters : IParametersList;
		private var _request : IMusicRequest;
		
		/**
		 * Translator class that enables the second iteration `HarmonyGenerator` to interact
		 * with the first iteration generators client that is built into MAIDENS. We chose this
		 * approach in order to support the legacy generators without changes.
		 * @constructor
		 */
		public function HarmonyGeneratorFacade() {
			_generator = new HarmonyGenerator;
			_generator.callback = _onProcessUpdate;
			_parameters = _generator.parametersList;
		}
		
		/**
		 * Called by the MAIDENS application when the end-user clicks the "Generate" button inside the Editor UI.
		 * @see `GeneratorBase.$generate()`
		 */
		override public function $generate() : void {
			
			// We report progress start earlier than it actually occurs, for the progress window
			// to have time to draw.
			var dummyStatus : Object = {
				state : AbstractGeneratorModule.STATUS_IN_PROGRESS,
				percentComplete : 0
			};
			_onProcessUpdate (dummyStatus);
			Time.delay (START_DELAY, function() : void {
				_request = _buildRequest ($targetsInfo);
				$pipe.subscribe (GeneratorKeys.GEN_ABORT_REQUESTED, _onAbortRequest);
				_generator.generate (_request);			
			});
		}
		
		/**
		 * Called by MAIDENS after this Generator signals that it has new output available.
		 * Distributes available pitches to available instrument/voices, based on the pitch
		 * allocation table produced by the Generator.
		 * @see `GeneratorBase.$getOutput()`
		 */
		override public function $getOutput() : Object {
			
			// Prepare root data container
			var ret : Object = {};
			var noteStreams : Array = [];
			ret[GeneratorBaseKeys.NOTE_STREAMS] = noteStreams;
			
			// Prepare instrument and voice stream data containers. The idea is for us to be able to 
			// access these "streams" in a reliable, NON SEQUENTIAL WAY, based on UIDs rather than
			// relative indices, which can be prone to error if interpreted in the wrong context.
			const INSTRUMENT_STREAMS_REGISTRY : Object = {};
			const VOICE_STREAMS_REGISTRY : Object = {};
			var instruments : Vector.<IMusicalInstrument> = _request.instruments;
			var i1 : int;
			var instrument : IMusicalInstrument;
			var instrumentStream : Array;
			var numInstruments : uint = instruments.length;
			var voiceStream : Array;
			var i2 : int;
			var voiceUid : String;
			var maxTheoreticalVoices : int;
			for (i1 = 0; i1 < numInstruments; i1++) {
				instrument = instruments[i1];

				// Theoretically, each staff can hold two voices. Despite the fact that few instruments
				// can play a second voice, we need these slots in place, as the algorithm for "evening out"
				// the voices can produce arrangements where each instrument staff contain a single voice,
				// therefore the incoming voice indices will be something like: [0, 2] instead of [0, 1],
				// so we need that a slot exists by the index of "2".
				maxTheoreticalVoices = (instrument.stavesNumber * 2);
				instrumentStream = [];
				INSTRUMENT_STREAMS_REGISTRY[instrument.uid] = instrumentStream;
				noteStreams.push (instrumentStream);
				for (i2 = 0; i2 < maxTheoreticalVoices; i2++) {
					voiceStream = [];
					voiceUid = (instrument.uid + i2);
					VOICE_STREAMS_REGISTRY[voiceUid] = voiceStream;
					instrumentStream.push (voiceStream);
				}
			}
			
			// Populate the data structure initialized above. The pitch allocation tables have all the information we
			// need.
			var i3 : uint = 0;
			var unit : IMusicUnit = null;
			var duration : IFraction;
			var midiNote : int;
			var tieNext : Boolean;
			// [DEBUG]
//			var annotationRows : Array;
//			var annotation : String;
//			var criteriaScoreLogger : Function = function (criteria : String, value : Number) : void {
//				var shortenCriteriaName : String = criteria.split(' ')
//						.map (function (token : String, ...etc) : String {
//							return token.charAt(0).toUpperCase();
//						}).join ('');
//				annotationRows.push (/*shortenCriteriaName + '_' + */value);
//			}
			// [/DEBUG]
			var pitchAllocations : Vector.<IPitchAllocation>;
			var numPitchAllocations : uint;
			var i4 : int = 0;
			var pitchAllocation : IPitchAllocation;
			var translatedEntry : MusicEntry = null;
			var allocatedPitch : IMusicPitch;
			var targetInstrument : IMusicalInstrument;
			var targetStreamUid : String;
			var targetStream : Array;
			for (i3 = 0; i3 < _generatedMusic.length; i3++) {
				unit = _generatedMusic.getAt(i3);
				pitchAllocations = unit.pitchAllocations;
				_evenOutVoices (pitchAllocations);
				numPitchAllocations = pitchAllocations.length;
				for (i4 = 0; i4 < numPitchAllocations; i4++) {
					pitchAllocation = pitchAllocations[i4];
					allocatedPitch = pitchAllocation.allocatedPitch;
					midiNote = allocatedPitch.midiNote;
					duration = unit.duration;
					tieNext = (midiNote && allocatedPitch.tieNext);
					// [DEBUG]
//					annotationRows = [];
//					unit.analysisScores.forEach(criteriaScoreLogger);
//					annotation = annotationRows.join('`') ;
					// [/DEBUG]
					translatedEntry = new MusicEntry (midiNote, duration as Fraction, tieNext/*, annotation*/);
					targetInstrument = pitchAllocation.instrument;
					targetStreamUid = (targetInstrument.uid + pitchAllocation.voiceIndex);
					targetStream = VOICE_STREAMS_REGISTRY[targetStreamUid];
					targetStream.push (translatedEntry);
				}
			}

			// Package and release the data
			return { "out" : ret};
		}
		
		/**
		 * Called by MAIDENS after this Generator has been loaded and initialized. Returns a list
		 * with objects that describe the public accessors of this Generator the end-user should
		 * have access to from within a graphical interface. The actual graphical interface will
		 * be built by MAIDENS.
		 * @see GeneratorBase `$uiEndpoints()`
		 */
		override public function get $uiEndpoints() : Object {
			var configuration : Object = {};
			var animatedParameters : Object = {};
			var animatedParameterUids : Array = [];
			var endPoints : Object = {};
			endPoints[GeneratorKeys.UI_GENERATOR_CONFIG] = configuration;
			endPoints[GeneratorKeys.PARAMETERS] = _parameters;
			endPoints[GeneratorKeys.ANIMATED_PARAMETERS] = animatedParameters;
			endPoints[GeneratorKeys.ANIMATED_PARAMETER_UIDS] = animatedParameterUids;
			
			// Internal callback. Translates intrinsic parameter properties, so that they can be used
			// by the UI builder library. This function is executed for each item available inside the
			// `_parameters` list.
			var mover : Function = function (parameter : IParameter,
											 index : int,
											 list : IParametersList) : void {
				var parameterId : String = parameter.uid;
				var parameterDefault : Object = parameter.payload;
				var parameterType : Object = parameter.type;
				if (parameterType == TYPE_ARRAY) {
					var paramValues : Array = (parameterDefault as Array);
					if (PointTools.pointsIncurTweening (paramValues)) {
						animatedParameters[parameterId] = parameter;
						animatedParameterUids.push (parameterId);
					}
				}
				endPoints[parameterId] = parameterDefault;
				var parameterConfiguration : Object = configuration[parameterId] || (configuration[parameterId] = {});
				parameterConfiguration.Index = index;
				var rendererConfiguration : Object = parameterConfiguration.CustomComponent || (parameterConfiguration.CustomComponent = {});
				rendererConfiguration.hideLabel = true;
				rendererConfiguration.parameterUid = parameterId;
				rendererConfiguration.label = parameter.name;
				rendererConfiguration.description = parameter.description;
				rendererConfiguration.documentationUrl = parameter.documentationUrl;
				rendererConfiguration.color = parameter.color;
				rendererConfiguration.icon = parameter.icon;
				rendererConfiguration.maxValue = parameter.maxValue;
				rendererConfiguration.minValue = parameter.minValue;
				rendererConfiguration.type = parameterType;
				rendererConfiguration.isTweenable = parameter.isTweenable;
				rendererConfiguration.dataproviderName = DATA_PROVIDER_NAME;
				rendererConfiguration.classFqn = CUSTOM_COMPONENT_FQN;
			}
			_parameters.forEach (mover);
			return endPoints;
		}
		
		/**
		 * Compiles and produces the IMusicRequest instance this Generator needs in order to 
		 * produce output.
		 */
		private function _buildRequest (targets : Array, userSettings : ISettingsList = null) : IMusicRequest {

			// Setup a Music Request (what instruments shall play the generated music,
			// what time signatures should the generated passage use and what values
			// has the user chosen for every available parameter)
			_request = new MusicRequest;

			// 1. USER SETTINGS
			// Gather and apply parameter values, either the default or user provided ones. The user
			// changes are saved (inside the "_parameters" IParametersList) the moment they are operated
			// inside the Generator Configuration window, so there is no need for any further processing
			// to retrieve them.
			var settings : ISettingsList = new SettingsList;
			var mover : Function = function (parameter : IParameter, index : int, list : IParametersList) : void {
				var payload : Object = parameter.payload;
				if (!payload) {
					return;
				}
				if (parameter.type == CoreOperationKeys.TYPE_ARRAY) {
					var time : int;
					var value : uint;
					for (time = 0; time < payload.length; time++) {
						if (payload[time] !== undefined) {
							value = (payload[time] as uint);
							settings.setValueAt (parameter, time, value);
						}
					}
				} 
				else {
					switch (parameter.type) {
						case CoreOperationKeys.TYPE_INT:
							var intVal : int = (payload as int);
							settings.setValueAt (parameter, 1, intVal);
							break;
						
						// TODO: add the rest of supported types when they become available
						// (for the time being, we only have ARRAYs and INTs).
					}
				}
			}
			_parameters.forEach (mover);
			_request.userSettings = settings;
			
			// 2. INSTRUMENTS AND TIME MAP
			var instruments : Vector.<IMusicalInstrument> = new Vector.<IMusicalInstrument>;
			var timeMap : ITimeSignatureMap = new TimeSignatureMap;
			
			// Callback. Executed when we have the list of full datasets representing the target Sections
			var _onSectionsListReady : Function = function (apiName : String, sections : Vector.<ProjectData>) : void {
				
				// 1. Collect instruments
				var firstSection : ProjectData = (sections[0] as ProjectData);
				var parts : Vector.<ProjectData> = Vector.<ProjectData> (ModelUtils.getChildrenOfType (firstSection, DataFields.PART));
				var j : int;
				var part : ProjectData;
				var partName : String;
				var ordinalIndex : int;
				var instrument : IMusicalInstrument;
				for (j = 0; j < parts.length; j++) {
					part = parts[j];
					partName = (part.getContent (DataFields.PART_NAME) as String);
					ordinalIndex = part.getContent (DataFields.PART_ORDINAL_INDEX) as int;
					instrument = InstrumentFactory.$get (partName, ordinalIndex);
					instrument.uid = (part.getContent(DataFields.PART_MIRROR_UID) as String);
					instrument.stavesNumber = (part.getContent(DataFields.PART_NUM_STAVES) as int);
					instruments.push (instrument);
				}
				
				// 2. Build the measure map
				var timeSignatureEntry : ITimeSignatureEntry;
				var k : int;
				var section : ProjectData;
				var firstPartInsection : ProjectData;
				var measuresInSection : Vector.<ProjectData>;
				var i2:int;
				var measure : ProjectData;
				var timeSignatureInfo : Object;
				var beatsNumber : uint;
				var beatDuration : uint;
				var timeSignatureDefinition : ITimeSignatureDefinition;
				for (k = 0; k < sections.length; k++) {
					section = sections[k];
					firstPartInsection = (section.getDataChildAt(0) as ProjectData);
					measuresInSection = Vector.<ProjectData> (ModelUtils.getChildrenOfType (firstPartInsection, DataFields.MEASURE));
					for (i2 = 0; i2 < measuresInSection.length; i2++) {
						measure = measuresInSection[i2];
						timeSignatureInfo = _getTimeSignatureData (measure.route);
						beatsNumber = (timeSignatureInfo[DataFields.BEATS_NUMBER] as uint);
						beatDuration = (timeSignatureInfo[DataFields.BEAT_DURATION] as uint);
						
						// Commit and close time signature entry if signature changes
						if (timeSignatureEntry && (timeSignatureEntry.signature.shownNumerator != beatsNumber ||
							timeSignatureEntry.signature.shownDenominator != beatDuration)) {
							timeMap.push (timeSignatureEntry);
							timeSignatureEntry = null;
						}
						
						// Initialize a new time signature if this is first measure or a signature
						// change just occured
						if (!timeSignatureEntry) {
							timeSignatureEntry = new TimeSignatureEntry;
							timeSignatureDefinition = TimeSignatureFactory.$get (beatsNumber, beatDuration);
							timeSignatureEntry.signature = timeSignatureDefinition;
							timeSignatureEntry.repetitions = 1;
						} 
						
						// Update existing time signature span if this is a subsequent occurence of
						// the same signature (i.e., previous measure was a 4/4, and this is still a 
						// 4/4)
						else {
							timeSignatureEntry.repetitions += 1;
						}
					}
					if (timeSignatureEntry) {
						timeMap.push (timeSignatureEntry);
						timeSignatureEntry = null;
					}
				}				
				_request.timeMap = timeMap;
			}
			
			// Resolve our shallow representation of the target Sections to a list of full datasets. The actual
			// parsing of this list is done inside the `_onSectionsListReady()` callback.
			var i : int;
			var sectionName : String;
			var request : IMusicRequest = new MusicRequest;
			var sectionNames : Vector.<String> = new Vector.<String>;
			var sections : Vector.<ProjectData> = new Vector.<ProjectData>;			
			for (i = 0; i < targets.length; i++) {
				var target : Object = targets[i] as Object;
				if (target[DataFields.DATA_TYPE] == DataFields.SECTION) {
					sectionName = (target[DataFields.UNIQUE_SECTION_NAME] as String);
					sectionNames[i] = sectionName;
				}
			}
			$callAPI (CoreApiNames.GET_SECTIONS_BY_NAMES, [sectionNames], _onSectionsListReady);
			_request.instruments = instruments;
			
			// Return the built Music Request
			return _request;
		}
		
		/**
		 * Causes the Controller to look up and return information about the explicit or inherited
		 * time signature of the Measure node with the provided `measureDataUis`, chasing this
		 * information to the closest definition point available.
		 * 
		 * Note: Since PTT communication is synchronous, we can pack this information exchange
		 * in a single function.
		 */
		private function _getTimeSignatureData (measureDataUid : String) : Object {
			var ret : Object = {};
			
			// Internal callback executed when data becomes available
			var onDataReady : Function = function (response : Object) : void {
				PTT.getPipe().unsubscribe (ViewKeys.TIME_SIGNATURE_DATA_READY, onDataReady);
				for (var key : String in response) {
					ret[key] = response[key];
				} 
			}
			PTT.getPipe().subscribe (ViewKeys.TIME_SIGNATURE_DATA_READY, onDataReady);
			PTT.getPipe().send (ViewKeys.NEED_TIME_SIGNATURE_DATA, measureDataUid);
			return ret;
		}

		/**
		 * Alters given pitch allocations in order to avoid having staves that hold no voices. This can happen when an
		 * instrument has more staves than it has autonomous voices. Does not return a value but modifies received
		 * values in place.
		 *
		 * NOTE:
		 * The algorithm is:
		 * - determine the number of elligible staves: this is the smallest of the number of autonomous voices of the
		 *   instrument or the instrument's *current* number of staves ("current", because the user can alter this);
		 * - loop through the instrument's elligible staves in reverse order, and look for a pitch allocation that
		 *   matches that staff (in order to "match" a staff, the allocation's voice index must hold one of the
		 *   values <staff index> * 2 + 1 or <staff index> * 2 + 2, where <staff index> is zero-based, and the
		 *   resulting voice index value is 1-based;
		 * - if a matching pitch allocation is found, move to the staff immediately above;
		 * - if a matching pitch allocation is NOT found, "borrow" one from the nearest staff above, and then move
		 *   to the staff immediately above ("borrowing" is done by changing the staff index of the "borrowed"
		 *   pitch allocation to be <staff index> * 2 + 1, i.e., the first voice of the current staff);
		 * - repeat until there are no staves anymore to be visited (because we reached staff with index 0).
		 */
		private function _evenOutVoices (sortedAllocations : Vector.<IPitchAllocation>) : void {
			//var sortedAllocations :  Vector.<IPitchAllocation> = pitchAllocations.concat();
			//sortedAllocations.sort (_byUidAndReverseVoiceIndex);
			var currInstrumentUid : String;
			var currInstrumentNumStaves : int;
			var voiceSearchIndex : int = int.MAX_VALUE;
			var currAllocation : IPitchAllocation;
			var tmpInstrument : IMusicalInstrument;
			var tmpVoiceIndex : int;
			var is2ndVoiceOnCurrStaff : Boolean;
			var is1stVoiceonCurrStaff : Boolean;
			var isOnAStaffAbove : Boolean;
			var i : int;
			for (i = 0; i < sortedAllocations.length; i++) {
				currAllocation = sortedAllocations[i];
				tmpInstrument = currAllocation.instrument;
				if (tmpInstrument.uid != currInstrumentUid) {
					currInstrumentUid = tmpInstrument.uid;
					currInstrumentNumStaves = tmpInstrument.stavesNumber;
					voiceSearchIndex = (currInstrumentNumStaves - 1) * 2;
				}
				if (voiceSearchIndex <= 0) {
					continue;
				}
				tmpVoiceIndex = currAllocation.voiceIndex;
				is2ndVoiceOnCurrStaff =  (tmpVoiceIndex == voiceSearchIndex + 1);
				if (is2ndVoiceOnCurrStaff) {
					continue;
				}
				is1stVoiceonCurrStaff = (tmpVoiceIndex == voiceSearchIndex);
				if (is1stVoiceonCurrStaff) {
					voiceSearchIndex -= 2;
					continue;
				}
				isOnAStaffAbove = (tmpVoiceIndex < voiceSearchIndex);
				if (isOnAStaffAbove) {
					currAllocation.voiceIndex = voiceSearchIndex;
					voiceSearchIndex -= 2;
					continue;
				}
			}
		}

		/**
		 * Used as a sort function by `_evenOutVoices()` to optimize the voice redistribution process. The sorting is
		 * not permanent.
		 *
		 * NOTE:
		 * Currently, allocations come grouped by instrument; also, for multi-voice instruments, they are laid out from
		 * bottom to top, e.g.:
		 * [instrument HARP(b7105ddd-05c2-487f-ad53-0988f510d82b), voice 1, pitch 58]
		 * [instrument HARP(b7105ddd-05c2-487f-ad53-0988f510d82b), voice 0, pitch 66]
		 *
		 * However, this might change in the future, because the program hasn't reached maturity. It's safer to ensure
		 * that allocations always come in the order we expect them.
		 */
		private function _byUidAndReverseVoiceIndex (pAllocationA : IPitchAllocation, pAllocationB : IPitchAllocation) : int {
			var instAUid : String = pAllocationA.instrument.uid;
			var instBUid : String = pAllocationB.instrument.uid;
			var score : int = (instAUid < instBUid)? -1 : (instAUid > instBUid)? 1 : 0;
			if (score == 0) {
				var vAIndex : int = pAllocationA.voiceIndex;
				var vBIndex : int = pAllocationB.voiceIndex;
				score = (vBIndex - vAIndex);
			}
			return score;
		}

		/**
		 * Executed when updates are available regarding the ongoing generation process.
		 */
		private function _onProcessUpdate (info : Object) : void {
			$callAPI (CoreApiNames.REPORT_GENERATION_PROGRESS, [info, $pipe]);
			if (info.state == AbstractGeneratorModule.STATUS_COMPLETED) {
				_generatedMusic = _generator.lastResult;
				$pipe.unsubscribe (GeneratorKeys.GEN_ABORT_REQUESTED, _onAbortRequest);
				$notifyGenerationComplete();
			} else if (info.state == AbstractGeneratorModule.STATUS_ABORTED) {
				$notifyGenerationAborted();
			}
		}
		
		/**
		 * Runs when the user requests that execution be aborted (the "Generation Process"
		 * window that is displayed during generation contains an "Abort" button).
		 */
		private function _onAbortRequest (... etc) : void {
			$pipe.unsubscribe (GeneratorKeys.GEN_ABORT_REQUESTED, _onAbortRequest);
			_generator.abort();
		}
	}
}