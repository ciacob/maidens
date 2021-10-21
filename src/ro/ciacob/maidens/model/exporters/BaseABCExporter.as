package ro.ciacob.maidens.model.exporters {
	import flash.filesystem.File;

	import ro.ciacob.ciacob;
	import ro.ciacob.desktop.data.DataElement;
	import ro.ciacob.desktop.data.exporters.IExporter;
	import ro.ciacob.desktop.signals.PTT;
	import ro.ciacob.maidens.generators.constants.BarTypes;
	import ro.ciacob.maidens.generators.constants.pitch.PitchAlterationTypes;
	import ro.ciacob.maidens.model.ModelUtils;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.maidens.model.constants.StaticFieldValues;
	import ro.ciacob.maidens.model.constants.Voices;

	import eu.claudius.iacob.maidens.Colors;

	import ro.ciacob.maidens.view.constants.ViewKeys;
	import ro.ciacob.maidens.view.constants.ViewPipes;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.utils.Descriptor;
	import ro.ciacob.utils.Templates;
	import ro.ciacob.utils.constants.CommonStrings;

	use namespace ciacob;

	/**
	 *
	 * @author ciacob
	 */
	public class BaseABCExporter implements IExporter {
		protected static const BAR:String = 'bar';
		protected static const CHARSET:String = 'utf-8';
		protected static const CREATOR_SOFTWARE:String = 'creatorSoftware';
		protected static const SCORE_BACKGROUND:String = 'scoreBackground';
		protected static const SCORE_FOREGROUND:String = 'scoreForeground';
		protected static const EVENTS:String = 'events';
		protected static const MEASURES:String = 'measures';
		protected static const SECTIONS:String = 'sections';
		protected static const SECTION_NAME:String = 'name';
		protected static const TIME_SIGNATURE:String = 'timeSignature';

		protected var persistentAlterations:Object;
		protected var pitchesMap:Object;
		protected var stavesUidDictionary:Object;

		private var _timeSignature:Array = null;
		private var _lastTupletMarker:TupletMarker;
		private var _paddingDurations:Array;

		public function BaseABCExporter() {
			super();
		}

		/**
		 * @see ro.ciacob.desktop.data.exporters.IExporter#export
		 */
		public function export(project:DataElement, shallow:Boolean = false, isRecursiveCall:Boolean = false):* {
			persistentAlterations = {};
			pitchesMap = {};
			stavesUidDictionary = {};
			_lastTupletMarker = null;
			_timeSignature = null;

			MeasurePaddingMarker.reset();
			var templateData:Object = buildTemplateData(ProjectData(project));
			return Templates.fillSimpleTemplate(abcTemplateFile, templateData);
		}

		/**
		 * Returns a file containing the ABC template to be populated by this
		 * ABCExporter instance.
		 *
		 * Subclasses must override and provide an implementation.
		 *
		 * @return An existing file.
		 */
		protected function get abcTemplateFile():File {
			return null;
		}

		/**
		 * Copies, and translates as needed, the data between a given source project and
		 * an implied `staff` target object. Resulting data is meant to populate the ABC
		 * tune body (by providing measures, notes and so on).
		 *
		 * @param	project
		 * 			The project to extract information from.
		 */
		protected function buildBodyData(project:ProjectData):void {
			var partUid:String;
			var partNode:ProjectData;
			var partEquivalentSignature:String;
			var transcribedEqSigns:Array;
			var transcribedUids:Array;
			for (var i:int = 0; i < ModelUtils.sectionsOrderedList.length; i++) {
				var sectionName:String = ModelUtils.sectionsOrderedList[i];
				var partsInCurrentSection:Object = ModelUtils.partsPerSection[sectionName];
				// We first transcribe the parts that play in the current section.
				transcribedEqSigns = [];
				transcribedUids = [];
				for (var partName:String in partsInCurrentSection) {
					var partInstances:Array = (partsInCurrentSection[partName] as Array);
					for (var partIdx:int = 0; partIdx < partInstances.length; partIdx++) {
						partUid = (partInstances[partIdx] as String);
						partNode = (ModelUtils.partsUidsToNodesMap[partUid] as ProjectData);
						buildPartData(partNode, sectionName);
						partEquivalentSignature = ModelUtils.getPartEquivalentSignature(partNode);
						transcribedEqSigns.push(partEquivalentSignature);
						transcribedUids.push(partUid);
					}
				}
				// Then, we add blank measures for the ones that don't.
				for (var j:int = 0; j < ModelUtils.unifiedPartsList.length; j++) {
					var partData:Object = (ModelUtils.unifiedPartsList[j] as Object);
					partUid = (partData[DataFields.PART_UID] as String);
					partNode = (ModelUtils.partsUidsToNodesMap[partUid] as ProjectData);
					partEquivalentSignature = ModelUtils.getPartEquivalentSignature(partNode);
					var wasntTranscribed:Boolean = (transcribedEqSigns.indexOf(partEquivalentSignature) ==
							-1);
					if (wasntTranscribed) {
						var modelForBlanks:ProjectData = (ModelUtils.partsUidsToNodesMap[transcribedUids[0] as
						String]);
						buildPartData(partNode, sectionName, modelForBlanks);
					}
				}
			}
		}

		/**
		 * Copies, and translates as needed, the data between a given source project and
		 * a target object. Resulting data is meant to populate the ABC header fields.
		 *
		 * @param	project
		 * 			The project to extract, and translate data form.
		 *
		 * @param	target
		 * 			The object to write translated data into.
		 */
		protected function buildHeaderData(project:ProjectData, target:Object):void {
			// Generic project data
			target[DataFields.PROJECT_NAME] = escapeABCString(project.getContent(DataFields.PROJECT_NAME));
			target[DataFields.COMPOSER_NAME] = escapeABCString(project.getContent(DataFields.COMPOSER_NAME));
			target[DataFields.CREATION_TIMESTAMP] = project.getContent(DataFields.CREATION_TIMESTAMP);
			target[DataFields.MODIFICATION_TIMESTAMP] = project.getContent(DataFields.MODIFICATION_TIMESTAMP);
			target[DataFields.CUSTOM_NOTES] = escapeABCString(project.getContent(DataFields.CUSTOM_NOTES));
			target[DataFields.COPYRIGHT_NOTE] = escapeABCString(project.getContent(DataFields.COPYRIGHT_NOTE));
			target[CREATOR_SOFTWARE] = Descriptor.getAppSignature(true);
			target[SCORE_BACKGROUND] = '#' + Colors.SCORE_BACKGROUND.toString(16);
			target[SCORE_FOREGROUND] = '#' + Colors.SCORE_FOREGROUND.toString(16);

			// List of all parts to be drawn in the score
			if (ModelUtils.unifiedPartsList != null && ModelUtils.unifiedPartsList.length >
					0) {
				if (target['staves'] == null) {
					target['staves'] = [];
				}
				for (var i:int = 0; i < ModelUtils.unifiedPartsList.length; i++) {
					var partData:Object = ModelUtils.unifiedPartsList[i];
					var partName:String = (partData[DataFields.PART_NAME] as String);
					if (partName != DataFields.VALUE_NOT_SET) {
						var partNumStaves:int = (partData[DataFields.PART_NUM_STAVES] as int);
						for (var staffIndex:int = 0; staffIndex < partNumStaves; staffIndex++) {
							buildStaffHeaderData(partData, target, staffIndex);
						}
					}
				}
				sortStaves(target['staves'] as Array);
			}
		}

		/**
		 * Copies, and translates as needed, the data between a given measure node and
		 * a target object. Resulting data is meant to provide measure content, like
		 * time signature, notes, bar type, etc.
		 *
		 * @param	measure
		 * 			The measure note to extract data from.
		 *
		 * @param	storage
		 * 			An object to store extracted data into.
		 *
		 * @param	staffIndex
		 * 			The index of the staff currently being extracted, zero based.
		 *
		 * @param	forceBlanks
		 * 			Optional. If given, all music within the measure will be replaced with
		 * 			whole note rests. Defaults to false.
		 */
		protected function buildMeasureData(measure:ProjectData, storage:Object, staffIndex:int,
											forceBlanks:Boolean = false):void {
			// Time signature
			PTT.getPipe().subscribe(ViewKeys.MEASURE_TIME_SIGNATURE_READY, _onTimeSignatureReady);
			PTT.getPipe().send(ViewKeys.NEED_MEASURE_OWN_TIME_SIGNATURE, measure);
			var abcTimeSign:String = (_timeSignature != null) ? ABCTranslator.translateTimeSignature(_timeSignature) :
					'';
			abcTimeSign = abcTimeSign.concat(CommonStrings.SPACE);

			// Bar type. If "auto", then it translates to a "thin-thick" bar for the last measure of the last
			// section, a "thin-thin" bar for the last measure of any other section, and to a "thin" (aka, regular)
			// bar for any other measure.
			var barType:String = (measure.getContent(DataFields.BAR_TYPE) as String);
			if (barType == BarTypes.AUTO_BAR) {
				if (ModelUtils.isLastMeasure(measure)) {
					barType = BarTypes.FINAL_BAR;
				} else if (ModelUtils.isLastMeasureInSection(measure)) {
					barType = BarTypes.DOUBLE_BAR;
				} else {
					barType = BarTypes.NORMAL_BAR;
				}
			}

			var abcBar:String = ABCTranslator.translateBarType(barType);
			var events:Array = [];
			if (!forceBlanks) {
				// Notes (within voices); we pay attention to inheriting alterations as a
				// result of a tie across the barline
				pitchesMap = {};
				if (persistentAlterations != null) {
					for (var persistedPitchMark:String in persistentAlterations) {
						var persistedAlteration:int = persistentAlterations[persistedPitchMark];
						pitchesMap[persistedPitchMark] = persistedAlteration;
					}
					persistentAlterations = null;
				}
				var voicesOnThisStaff:uint = 0;
				var voiceNodes:Array = ModelUtils.getChildrenOfType(measure, DataFields.VOICE);
				voiceNodes.sort(ModelUtils.compareVoiceNodes);
				for (var i:int = 0; i < voiceNodes.length; i++) {
					if (voicesOnThisStaff >= Voices.NUM_VOICES_PER_STAFF) {
						break;
					}
					var voiceNode:ProjectData = (voiceNodes[i] as ProjectData);
					var voiceStaffIndex:int = (voiceNode.getContent(DataFields.STAFF_INDEX) as int) - 1;
					if (voiceStaffIndex == staffIndex) {
						var voiceIndex:int = (voiceNode.getContent(DataFields.VOICE_INDEX) as uint);
						voicesOnThisStaff++;
						buildVoiceData(voiceNode, events);

						// We will only render the second voice if it was given explicit content
						if (voiceIndex == 2 && voiceNode.numDataChildren == 0) {
							continue;
						}

					}
				}
				if (voicesOnThisStaff == 0) {
					events.push(ABCTranslator.translateRest(Fraction.WHOLE));
				}
			}

			storage[TIME_SIGNATURE] = abcTimeSign;
			storage[EVENTS] = events;
			storage[BAR] = abcBar;
			onAfterMeasureTranslation(measure, storage);
		}

		/**
		 * @param	partNode
		 * 			The ProjectData representing the source part, which needs to be
		 * 			translated into ABC notation.
		 *
		 * @param	parentSectionName
		 * 			The name of the section containing the part which is to be translated.
		 *
		 * @param	modelForBlanks
		 * 			Optional. A part node whose measures are to be mimicked,
		 * 			but filled with whole note reasts instead of the actual music.
		 * 			The part information will still be taken from `partNode`.
		 */
		protected function buildPartData(partNode:ProjectData, parentSectionName:String, modelForBlanks:ProjectData =
				null):void {
			var partNumStaves:int = (partNode.getContent(DataFields.PART_NUM_STAVES) as int);
			for (var staffIdx:int = 0; staffIdx < partNumStaves; staffIdx++) {
				var abbrevPartName:String = partNode.getContent(DataFields.ABBREVIATED_PART_NAME);
				var partOrdNum:int = (partNode.getContent(DataFields.PART_ORDINAL_INDEX) as int);
				var rawStaffUid:String = buildStaffUid(abbrevPartName, partOrdNum, staffIdx);
				var staff:Object = stavesUidDictionary[rawStaffUid];
				if (staff) {
					var sectionsStorage:Array = (staff[SECTIONS] as Array);
					if (sectionsStorage == null) {
						sectionsStorage = [];
						staff[SECTIONS] = sectionsStorage;
					}
					var section:Object = {};
					section[SECTION_NAME] = parentSectionName;
					var measuresStorage : Array = provideMeasuresStorage (staff);
					section[MEASURES] = measuresStorage;
					var mustFillWithBlanks:Boolean = (modelForBlanks != null);
					var partMeasures:Array = ModelUtils.getChildrenOfType(mustFillWithBlanks ?
							modelForBlanks : partNode, DataFields.MEASURE);
					for (var measIdx:int = 0; measIdx < partMeasures.length; measIdx++) {
						var measureStorage:Object = {}
						var measureNode:ProjectData = (partMeasures[measIdx] as ProjectData);
						buildMeasureData(measureNode, measureStorage, staffIdx, mustFillWithBlanks);
						measuresStorage.push(measureStorage);
					}
					sectionsStorage.push(section);
				}
			}
		}

		/**
		 * Copies, and translates as needed, the data for one staff definition. This will
		 * create one `V:` ABC field in the tune header.
		 *
		 * @param	partData
		 * 			An object containing definitions for the current part.
		 *
		 * @param	target
		 * 			The object to write translated data into.
		 *
		 * @param	staffIndex
		 * 			The zero-based index of this staff, which will be includded in the
		 * 			ABC `voice` signature which links measure of music to their respective
		 * 			`voices`.
		 */
		protected function buildStaffHeaderData(partData:Object, target:Object, staffIndex:int):void {
			var ordIdx:int = partData[DataFields.PART_ORDINAL_INDEX];
			var mustShowOrdNum:Boolean = (partData[ModelUtils.MUST_SHOW_ORDINAL_NUMBER] as
					Boolean);
			var abbrev:String = partData[DataFields.ABBREVIATED_PART_NAME];
			var staffUid:String = buildStaffUid(abbrev, ordIdx, staffIndex);
			var name:String = (partData[DataFields.PART_NAME] as String).concat(mustShowOrdNum ?
					(CommonStrings.SPACE + (ordIdx + 1)) : '');
			var abbrevName:String = abbrev.concat(mustShowOrdNum ? (CommonStrings.SPACE + (ordIdx +
					1)) : '');
			var clefsList:Array = (partData[DataFields.PART_CLEFS_LIST] as Array);
			var clef:String = ABCTranslator.translateClef(clefsList[staffIndex]);
			var transposisiton:String = (partData[DataFields.PART_TRANSPOSITION] as int).toString();
			var staff:Object = {};
			staff['uid'] = staffUid;
			staff[ModelUtils.ABC_NAME_KEY] = name;
			staff['abrevName'] = abbrevName;
			staff['clef'] = clef;
			staff['transposition'] = transposisiton;
			stavesUidDictionary[staffUid] = staff;
			(target['staves'] as Array).push(staff);
		}


		/**
		 * Compiles and returns a string such as: `Pno.1-1`, to be used as the content of the
		 * ABC `V:` field.
		 *
		 * @param	abbrevPartName
		 * 			The abbreviated name of this part
		 *
		 * @param	partOrdNum
		 * 			The ordinal number of this part (i.e., if two violins play in the same
		 * 			section, the first will have a ordinal number of `1`, and the second, `2`.
		 *
		 * @param	staffIndex
		 * 			The number of staff, zero based. For instance, a piano part, which
		 * 			typically uses two staves, will invoe this function twice, first with
		 * 			`staffIndex` set to 0, and then to 1.
		 *
		 * @return	The resulting string, such as Pno.1-1
		 */
		protected function buildStaffUid(abbrevPartName:String, partOrdNum:int, staffIndex:int):String {
			var canonicName:String = abbrevPartName.replace(/[^a-zA-Z0-9]/g, '');
			return canonicName.concat(partOrdNum + 1, staffIndex + 1);
		}

		/**
		 * Creates a template friendly data source from a given roject.
		 * @param	project
		 * 			A project to extract data from.
		 *
		 * @return	An object to run against the template engine.
		 */
		protected function buildTemplateData(project:ProjectData):Object {
			var templateData:Object = {};
			buildHeaderData(project, templateData);
			buildBodyData(project);
			return templateData;
		}

		/**
		 * Copies, and translates as needed, the data for one voice node. This will
		 * create one or more melodic lines in a measure.
		 *
		 * @param	voice
		 * 			The voice node to extract data from.
		 *
		 * @param	storage
		 * 			An array to fill with strings representing musical notes in ABC
		 * 			notation.
		 */
		protected function buildVoiceData(voice:ProjectData, storage:Array):void {
			var duration:Fraction = null;
			_lastTupletMarker = null;
			var mightHaveAnotherVoice:Boolean = (storage.length > 0);
			if (mightHaveAnotherVoice) {
				storage.push(ABCTranslator.TEMPORARY_VOICE_OPERATOR);
			}
			for (var clusterIdx:int = 0; clusterIdx < voice.numDataChildren; clusterIdx++) {
				var clusterNode:ProjectData = ProjectData(voice.getDataChildAt(clusterIdx));
				onBeforeClusterTranslation(clusterNode, storage);
				// Duration
				var durationSrc:String = (clusterNode.getContent(DataFields.CLUSTER_DURATION_FRACTION) as
						String);
				if (durationSrc != DataFields.VALUE_NOT_SET) {
					duration = Fraction.fromString(durationSrc);
					// Dot
					var dotSrc:String = (clusterNode.getContent(DataFields.DOT_TYPE) as String);
					if (dotSrc != DataFields.VALUE_NOT_SET) {
						var dot:Fraction = Fraction.fromString(dotSrc);
						var toAdd:Fraction = duration.multiply(dot) as Fraction;
						duration = duration.add(toAdd) as Fraction;
					}
					// Tuplet division
					// TODO: SUPPORT NESTED TUPLETS
					var clusterStartsTuplet:Boolean = (clusterNode.getContent(DataFields.STARTS_TUPLET) as Boolean);
					if (clusterStartsTuplet) {
						var srcNumBeats:int = clusterNode.getContent(DataFields.TUPLET_SRC_NUM_BEATS) as int;
						if (srcNumBeats <= 0) {
							srcNumBeats = StaticFieldValues.DEFAULT_TUPLET_SRC_BEATS;
						}
						var targetNumBeats:int = clusterNode.getContent(DataFields.TUPLET_TARGET_NUM_BEATS) as int;
						if (targetNumBeats <= 0) {
							targetNumBeats = StaticFieldValues.DEFAULT_TUPLET_TARGET_BEATS;
						}
						var haveTuplet:Boolean = (srcNumBeats != targetNumBeats);
						if (haveTuplet) {
							if (_lastTupletMarker != null) {
								sealTuplet(_lastTupletMarker, true, storage);
							}
							var rawTupletBeatDuration:String = (clusterNode.getContent(DataFields.TUPLET_BEAT_DURATION) as String);
							if (rawTupletBeatDuration == DataFields.VALUE_NOT_SET) {
								rawTupletBeatDuration = (clusterNode.getContent(DataFields.CLUSTER_DURATION_FRACTION) as String);
							}
							var tupletBeatDuration:Fraction = Fraction.fromString(rawTupletBeatDuration);
							var intrinsicTupletSpan:Fraction = tupletBeatDuration.multiply(new Fraction(srcNumBeats)) as Fraction;

							// If the cluster that starts the tuplet has a duration greater than the intrinsic tuplet span, we force it to the
							// tuplet beat duration instead; user will take it from there.
							if (duration.greaterThan(intrinsicTupletSpan)) {
								clusterNode.setContent(DataFields.CLUSTER_DURATION_FRACTION, (duration = tupletBeatDuration).toString());
							}
							_lastTupletMarker = new TupletMarker(clusterNode.route, intrinsicTupletSpan, srcNumBeats, targetNumBeats);
							storage.push(_lastTupletMarker);
						}
					}
					if (_lastTupletMarker) {
						var response:int = _lastTupletMarker.accountFor(duration);

						// If the duration of the current cluster does not fit in the tuplet, we produce a ghost
						// rest to fill the tuplet up and move on.
						if (response == TupletMarker.OVERFULL) {
							sealTuplet(_lastTupletMarker, true, storage);
						} else {

							// If the duration of the current cluster perfectly fits in the tuplet (i.e., concludes, or completes
							// the tuplet), we just seal/unlink the tuplet as it is, and move on.
							if (response == TupletMarker.FULL) {
								sealTuplet(_lastTupletMarker);
							}
						}
					}

					// Notes & chords
					var numNotes:int = clusterNode.numDataChildren;
					if (numNotes > 0) {
						var needsGrouping:Boolean = (numNotes > 1);
						if (needsGrouping) {
							storage.push(ABCTranslator.CHORD_BEGIN_MARK);
						}
						for (var noteIdx:int = 0; noteIdx < clusterNode.numDataChildren; noteIdx++) {
							var note:ProjectData = (clusterNode.getDataChildAt(noteIdx) as
									ProjectData);
							// Pitch
							var pitchName:String = (note.getContent(DataFields.PITCH_NAME) as String);
							if (pitchName != DataFields.VALUE_NOT_SET) {
								// Octave
								var octaveIndex:int = (note.getContent(DataFields.OCTAVE_INDEX) as int);

								// Alterations (not all have to be shown)
								var pitchMark:String = pitchName.concat(octaveIndex);
								if (pitchesMap[pitchMark] == null) {
									pitchesMap[pitchMark] = PitchAlterationTypes.NATURAL;
								}
								var currentAlteration:int = (note.getContent(DataFields.PITCH_ALTERATION) as int);
								var mustShowAlteration:Boolean = false;
								if (currentAlteration != pitchesMap[pitchMark]) {
									pitchesMap[pitchMark] = currentAlteration;
									mustShowAlteration = true;
								}
								// Tie
								var mustTie:Boolean = false;
								var tieSrc:Object = (note.getContent(DataFields.TIES_TO_NEXT_NOTE));
								if (tieSrc === true) {
									mustTie = true;

									// Tying across the barline must persist the
									// alteration of he tied note into the new measure
									var isLastCluster:Boolean = (clusterIdx == voice.numDataChildren - 1);
									if (isLastCluster) {
										if (persistentAlterations == null) {
											persistentAlterations = {};
										}
										persistentAlterations[pitchMark] = currentAlteration;
									}
								}
								var abcNote:String = ABCTranslator.translateNote(duration, pitchName,
										(mustShowAlteration ? currentAlteration : PitchAlterationTypes.HIDE),
										octaveIndex, mustTie);
								storage.push(abcNote);
							}
						}
						if (needsGrouping) {
							storage.push(ABCTranslator.CHORD_END_MARK);
						}
					} else {
						var abcRest:String = ABCTranslator.translateRest(duration);
						storage.push(abcRest);
					}
				}
			}

			// If there is any leftover tuplet, close it properly
			if (_lastTupletMarker) {
				sealTuplet(_lastTupletMarker, true, storage);
			}

			// We padd every voice with invisible rests to the same nominal
			// value (determined by comparing the current measure's time signature with 
			// the effective duration of all its voices — and considering the greater
			// value). This way, all measures will always align correctly in multi-voice 
			// and/or multi-part music.
			var paddingMarker:MeasurePaddingMarker = new MeasurePaddingMarker;
			storage.push(paddingMarker);
			paddingMarker.accountFor(voice);
		}

		/**
		 * Escapes chars that have special meanings in ABC, but are to be
		 * treated literraly in the context of a string.
		 *
		 * @see http://abcnotation.com/wiki/abc:standard:v2.1#text_string_definition
		 */
		protected function escapeABCString(text:String):String {
			if (!text) {
				return '';
			}
			text = text.replace(/\x5c/g, '\\\\') // backslash
					.replace(/\x25/g, '\\%') // percent symbol
					.replace(/\x26/g, '\\&') // ampersand
					.replace(/\x22/g, '\\u0022') // double quotes
					.replace(/©/g, '\\u00a9') // copyright symbol
					.replace(/♭/g, '\\u266d') // flat symbol
					.replace(/♮/g, '\\u266e') // natural symbol
					.replace(/♯/g, '\\u266f') // sharp symbol
					.replace(/\r\n|\n|\r/g, '$&+:'); // new line continuation

			return text;
		}

		/**
		 * This function is called just before starting to process a "cluster" element.
		 * You can overwrite it to modify the cluster, to prefix its translation with some
		 * value, etc.
		 */
		protected function onBeforeClusterTranslation(clusterNode:ProjectData, storage:Array):void {
			// Subclasses can override
		}

		/**
		 * This function is called after each "measure" element was processed.
		 * You can overwrite it to ammend the translation, e.g., by inserting an anotation
		 * before the closing bar of the measure.
		 */
		protected function onAfterMeasureTranslation(measure:ProjectData, storage:Object):void {
			// Subclasses can override
		}

		/**
		 * Sorts staves according to their part order (which, in turn, is determined
		 * based on the most likely ensemble these staves would fit it).
		 *
		 * @param 	staves
		 * 			The staves to sort, as an Array. The Array is sorted in place.
		 */
		protected function sortStaves(staves:Array):void {
			ModelUtils.sortStavesByPartOrder(staves);
		}

		/**
		 * Overridable method that produces the Array to store each section's measures in. This Array will be populated
		 * with Objects that each hold information about a measure's time signature, events (notes and rests) and
		 * barline type. A class overriding this method can manipulate the stream of measures globally, e.g., it could
		 * introduce an "off-the-records" lead-in measure.
		 */
		protected function provideMeasuresStorage (staff : Object) : Array {
			return [];
		}

		private function _onTimeSignatureReady(timeSignature:Array):void {
			PTT.getPipe().unsubscribe(ViewKeys.MEASURE_TIME_SIGNATURE_READY, _onTimeSignatureReady);
			_timeSignature = timeSignature;
		}

		/**
		 * Unlinks the current tuplet marker so that it cannot account for any more clusters. Optionally,
		 * right pads it with ghost rests up to its nominal duration.
		 */
		private function sealTuplet(tupletMarker:TupletMarker, rightPad:Boolean = false, storage:Array = null):void {
			if (rightPad && storage) {

				// Cache to conserve CPU
				var $remainder:Fraction = tupletMarker.remainder;

				// Compute the duration needed to properly fill-up the tuplet. Split it into simple
				// durations (i.e., we don't want dots here) and add the results as ghost rests
				// inside the tuplet.
				var tupletGhostRests:Array = [];
				_splitRawDuration($remainder);
				var fillUpDuration:Fraction;
				for (var j:int = 0; j < _paddingDurations.length; j++) {
					fillUpDuration = _paddingDurations[j] as Fraction;
					tupletMarker.accountFor(fillUpDuration);
					tupletGhostRests.push(ABCTranslator.translateRest(fillUpDuration));
				}

				// Make sure we don't "steal" the annotation from the next "legit" cluster node:
				// try to insert the ghost rest(s) that fill up the tuplet BEFORE any trailing
				// ABC annotation code. 
				var i:int = storage.length - 1;
				while (i >= 0) {
					var lastStorageEntry:String = storage[i] as String;
					if (!lastStorageEntry) { // Might be a Marker, therefore, not a String
						i--;
						continue;
					}
					var haveTrailingAnnotation:Boolean = lastStorageEntry.indexOf(CommonStrings.BROKEN_VERTICAL_BAR) != -1;
					if (haveTrailingAnnotation) {
						var args:Array = [i, 0].concat(tupletGhostRests);
						storage.splice.apply(null, args);
					} else {
						storage.push.apply(null, tupletGhostRests);
					}
					break;
				}
			}
			_lastTupletMarker = null;
		}

		private function _splitRawDuration(duration:Fraction):void {
			PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).subscribe(ViewKeys.DURATION_SPLIT_READY,
					_onDurationSplitReady);
			PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).send(ViewKeys.SPLIT_DURATION_NEEDED,
					duration);
		}

		private function _onDurationSplitReady(data:Object):void {
			PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).unsubscribe(ViewKeys.DURATION_SPLIT_READY,
					_onDurationSplitReady);
			_paddingDurations = (data as Array);
			_paddingDurations.reverse();
		}
	}
}
