package ro.ciacob.maidens.controller {

	/**
	 * TODO: move all members that in no way rely on the MAIDENS internal data model in class
	 * ro.ciacob.maidens.generators.core.helpers.CommonMusicUtils.
	 */

	import ro.ciacob.maidens.generators.constants.MIDI;
	import ro.ciacob.maidens.generators.constants.duration.DotTypes;
	import ro.ciacob.maidens.generators.constants.duration.DurationFractions;
	import ro.ciacob.maidens.generators.constants.pitch.IntervalNames;
	import ro.ciacob.maidens.generators.constants.pitch.IntervalsSize;
	import ro.ciacob.maidens.generators.constants.pitch.MiddleCMapping;
	import ro.ciacob.maidens.generators.constants.pitch.OctaveIndexes;
	import ro.ciacob.maidens.generators.constants.pitch.PitchAlterationSymbols;
	import ro.ciacob.maidens.generators.constants.pitch.PitchAlterationTypes;
	import ro.ciacob.maidens.generators.constants.pitch.PitchNames;
	import ro.ciacob.maidens.model.ModelUtils;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.maidens.model.constants.StaticTokens;
	import ro.ciacob.maidens.view.constants.ViewKeys;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.utils.ConstantUtils;
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.constants.CommonStrings;

	public final class MusicUtils {
		
		private static const NOTE_PATTERN : RegExp = /([abcdefg])\s?([Ÿ¢ùõú]?)\s?([\0123456789]?)/i;

		private static var _chromaticScale:Array;
		private static var _intervalsMap:Array;
		private static var _octavesMap:Array;		
		private static var _reversedAlterationSymbolsMap : Object;
		private static var _pitchRudimentsList : Array;
		private static var _simpleDurations:Array;
		
		public static function get CHROMATIC_SCALE () : Array {
			if (_chromaticScale == null) {
				_chromaticScale = _buildChromaticScale();
			}
			return _chromaticScale;
		}
		
		
		/**
		 * Returns a strings array, containing only `pitch` and `alteration`
		 * information for each note in the chromatic scale.
		 */
		public static function getPitchRudimentsList () : Array {
			if (_pitchRudimentsList == null) {
				_pitchRudimentsList = [];
				var chromaticScale : Array = CHROMATIC_SCALE;
				for (var i:int = 0; i < chromaticScale.length; i++) {
					var note : ProjectData = (chromaticScale[i] as ProjectData);
					var pitch : String = (note.getContent(DataFields.PITCH_NAME) as String);
					var alteration : int = (note.getContent(DataFields.PITCH_ALTERATION) as int);
					// The chromatic scale is known to only use sharps, so we take a shortcut
					var alterationSymbol : String = ((alteration == 1)? CommonStrings.SPACE.concat(PitchAlterationSymbols.SHARP) : '');
					var str : String = pitch.concat(alterationSymbol);
					_pitchRudimentsList.push(str);
				}
			}
			return _pitchRudimentsList;
		}
		
		public static function get INTERVALS_MAP () : Array {
			if (_intervalsMap == null) {
				_intervalsMap = _buildIntervalsMap();
			}
			return _intervalsMap;
		}

		public static function get OCTAVES_MAP () : Array {
			if (_octavesMap == null) {
				_octavesMap = _buildOctavesMap();
			}
			return _octavesMap;
		}
		
		public static function get REVERSED_ALTERATION_SYMBOLS_MAP () : Object {
			if (_reversedAlterationSymbolsMap == null) {
				_reversedAlterationSymbolsMap = _buildReversedAlterationSymbolsMap();
			}
			return _reversedAlterationSymbolsMap;
		}
		
		/**
		 * Converts the given note to one of the eleven "standard" notes defined by the
		 * `CHROMATIC_SCALE`. For instance, it will conver a `C double flat` to an `A sharp`.
		 * 
		 * @param	note
		 * 			The note to convert.
		 * 
		 * @param	forceToFirstOctave
		 * 			Sets (moves) given note to first octave. To be used when dealing with
		 * 			incomplete note definitions.
		 * 
		 * @return	The converted note, or null if the note definition is incomplete, or
		 * 			erroneous.
		 */
		public static function canonicalizeNote (note : ProjectData, forceToFirstOctave : Boolean = false) : ProjectData {
			if (note != null) {
				// Running a note through this function only makes sense if `pitchAlteration`
				// was set, and is not `0`.
				var pitchAlteration : Object = note.getContent(DataFields.PITCH_ALTERATION);
				if (pitchAlteration == DataFields.VALUE_NOT_SET) {
					return note;
				}
				if (pitchAlteration === 0) {
					return note;
				}
				// The octave index is somewhat dispendable, as we are primarily looking to get rid of
				// double alterations (e.g. `double flat`, etc).
				var octaveIndex : Object = note.getContent(DataFields.OCTAVE_INDEX);
				if(octaveIndex == DataFields.VALUE_NOT_SET || forceToFirstOctave) {
					note.setContent(DataFields.OCTAVE_INDEX, MiddleCMapping.MIDDLE_C_OCTAVE_INDEX);
				}
				var midiNumber : int =  noteToMidiNumber(note);
				if (midiNumber >= 0) {
					return midiNumberToNote(midiNumber);
				}
			}
			return null;
		}
		
		public static function midiNumberToNote(midiNumber:int):ProjectData {
			var pitchIndex:int = (midiNumber % 12);
			var octaveIndex:int = ((midiNumber - pitchIndex) / 12 - 1);
			var matchingNote : ProjectData = (CHROMATIC_SCALE[pitchIndex] as ProjectData);
			if (matchingNote != null) {
				var note:ProjectData = (matchingNote.clone() as ProjectData);
				note.setContent(DataFields.OCTAVE_INDEX, octaveIndex);
				return note;
			}
			return null;
		}
		
		/**
		 * Returns an Array with the settings needed to be applied to a Note 
		 * node in order for it to reflect the given MIDI pitch. This is less expensive 
		 * than `midiNumberToNote()`, since no Note node is created in the process, not even 
		 * by clonning.
		 * 
		 * @param	midiNumber
		 * 			The MIDI pitch to convert.
		 * 
		 * @return	An array with 3 values, representing respectivelly:
		 * 			[0] Pitch name, e.g. "A";
		 * 			[1] Pitch alteration, e.g. `0` for a natural;
		 * 			[2] Octave Index`, e.g. `4` for middle C (261Hz, or MIDI note 60)
		 */
		private static function _midiNumberToNoteInfo(midiNumber:int):Array {
			var pitchIndex:int = (midiNumber % 12);
			var matchingNote : ProjectData = (CHROMATIC_SCALE[pitchIndex] as ProjectData);
			if (matchingNote != null) {
				var octaveIndex:int = ((midiNumber - pitchIndex) / 12 - 1);
				return [
					matchingNote.getContent(DataFields.PITCH_NAME),
					matchingNote.getContent(DataFields.PITCH_ALTERATION),
					octaveIndex
				]
			}
			return null;
		}
		
		/**
		 * @param	note
		 * 			The note to be converted into its MIDI number.
		 * 
		 * @return	The MIDI number representing given note, or `-1` if the note definition
		 * 			is incomplete or erroneous.
		 */
		public static function noteToMidiNumber (note : ProjectData, forceDiatonic : Boolean = false) : int {
			var ret : int = -1;
			var tmpVal : Object;
			var pitchName : String;
			var pitchAlteration : int;
			var octaveIndex : int;
			
			// Pitch Name
			tmpVal = note.getContent(DataFields.PITCH_NAME);
			if (tmpVal != null && tmpVal != DataFields.VALUE_NOT_SET) {
				pitchName = (tmpVal as String);
				
				// Pitch alteration
				tmpVal = forceDiatonic? 0 : note.getContent(DataFields.PITCH_ALTERATION);
				if (tmpVal != null && tmpVal != DataFields.VALUE_NOT_SET) {
					(pitchAlteration = tmpVal as int);
					
					// OctaveIndex
					tmpVal = note.getContent(DataFields.OCTAVE_INDEX);
					if (tmpVal != null && tmpVal != DataFields.VALUE_NOT_SET) {
						octaveIndex = (tmpVal as int);
						
						// Compute MIDI
						var noteIndex : int = _getNoteIndex (pitchName, pitchAlteration);
						ret = ((octaveIndex + 1) * 12 + noteIndex);
					}
				}
			}
			return ret;
		}

		public static function noteToString(note:ProjectData):String {
			var ret : String = '';
			var accidentalSymbol:String = null;
			var pitchAlteration:int = note.getContent(DataFields.PITCH_ALTERATION);
			switch (pitchAlteration) {
				case PitchAlterationTypes.SHARP:
					accidentalSymbol = PitchAlterationSymbols.SHARP;
					break;
				case PitchAlterationTypes.DOUBLE_SHARP:
					accidentalSymbol = PitchAlterationSymbols.DOUBLE_SHARP;
					break;
				case PitchAlterationTypes.FLAT:
					accidentalSymbol = PitchAlterationSymbols.FLAT;
					break;
				case PitchAlterationTypes.DOUBLE_FLAT:
					accidentalSymbol = PitchAlterationSymbols.DOUBLE_FLAT;
					break;
			}
			var octaveIndex:Number = parseInt (note.getContent(DataFields.OCTAVE_INDEX));
			ret = ret.concat(note.getContent(DataFields.PITCH_NAME));
			if (accidentalSymbol != null) {
				ret = ret.concat(accidentalSymbol);
			}
			if (!isNaN(octaveIndex)) {
				ret = ret.concat(octaveIndex);
			}
			return ret;
		}

		public static function semitonesToIntervalName(semitones:int, includeDirection : Boolean = true):String {
			if (semitones == 0) {
				return IntervalNames.PERFECT_UNISON;
			}
			if (_intervalsMap == null) {
				_intervalsMap = _buildIntervalsMap();
			}
			var unsignedSemitones : int = Math.abs(semitones);
			var simpleUnsignedInterval:int = unsignedSemitones;
			var numOctavesToAdd:int = 0;
			if (unsignedSemitones > 12) {
				simpleUnsignedInterval = (unsignedSemitones % 12);
				numOctavesToAdd = ((unsignedSemitones - simpleUnsignedInterval) / 12);
			}
			var name:String = _intervalsMap[simpleUnsignedInterval];
			var direction:String = includeDirection? 
				((semitones > 0) ? StaticTokens.UP : StaticTokens.DOWN).concat (CommonStrings.SPACE) : '';
			if (numOctavesToAdd > 0) {
				return StaticTokens.COMPOUND_INTERVAL_DESCRIPTION.replace('%s', direction).replace('%s', name).replace('%d', numOctavesToAdd);
			}
			return StaticTokens.SIMPLE_INTERVAL_DESCRIPTION.replace('%s', direction).replace('%s', name);
		}
		
		public static function stringToNote(str:String):ProjectData {
			var match : Array = str.match(NOTE_PATTERN);
			if (match != null) {
				var note:ProjectData = new ProjectData;
				var details:Object = {};
				details[DataFields.DATA_TYPE] = DataFields.NOTE;
				note.populateWithDefaultData(details);
				var pitchName : String = (match[1] as String);
				if (pitchName != null) {
					pitchName = pitchName.toUpperCase();
					note.setContent(DataFields.PITCH_NAME, pitchName);
				}
				note.setContent(DataFields.PITCH_ALTERATION, PitchAlterationTypes.NATURAL);
				if (match[2] !== undefined) {
					var pitchSymbol : String = (match[2] as String);
					var pitchAlteration : int = _pitchSymbolToAlteration(pitchSymbol);
					note.setContent(DataFields.PITCH_ALTERATION, pitchAlteration);
				}
				if (match[3] !== undefined) {
					var octaveIndex : Number = parseInt (match[3]);
					if (!isNaN(octaveIndex)) {
						note.setContent(DataFields.OCTAVE_INDEX, (octaveIndex as int));
					}
				}
				return note;
			}
			return null;
		}

		/**
		 * Alters each of the given `clusters` that contain Note children, so that they display
		 * higher or lower pitches than original, based on the given `transposition interval`.
		 * 
		 * @param	clusters
		 * 			Array with Cluster nodes.
		 * 
		 * @param	transpositionInterval
		 * 			Integer with number of semitones to transpose to. Positive numbers transpose up.
		 * 
		 * @param	maintainExistingNotes
		 * 			If true, dupplicates existing Note nodes in each Clusters and transposes the dupes,
		 * 			effectivelly creating parallel intervals. Existing pitches are not supplicated in 
		 * 			the process.
		 */
		public static function transposeBy (clusters : Array, transpositionInterval : int, maintainExistingNotes : Boolean = false) : void {
			if (clusters && clusters.length && transpositionInterval) {
				for (var i:int = 0; i < clusters.length; i++) {
					var cluster : ProjectData = clusters[i] as ProjectData;
					if (!cluster.numDataChildren) {
						continue;
					}
					
					// If we are requested to `maintain existing pitches`, we need to watch out for accidentally
					// creating "prime" intervals (e.g., when a "G" exists both in the original material and in 
					// the resulting, transposed material). This is a situation we want to avoid.
					var clonedNotes : Object = null;
					var originalPitches : Array = null;
					if (maintainExistingNotes) {
						originalPitches = [];
						clonedNotes = {};
					}
					
					for (var j:int = 0; j < cluster.numDataChildren; j++) {
						var note : ProjectData = cluster.getDataChildAt(j) as ProjectData;
						var noteMidiPitch : int = noteToMidiNumber(note);
						
						// When `maintaining existing pitches`, we make a clone of each existing Note node,
						// and work on that instead. We also make a note of the Note's pitch before 
						// transposition.
						if (maintainExistingNotes) {
							note = note.clone() as ProjectData;							
							originalPitches.push (noteMidiPitch);
						}
						
						noteMidiPitch += transpositionInterval;
						
						// Set aside the cloned Note; we will decide later whether to commit or not.
						if (maintainExistingNotes) {
							clonedNotes[noteMidiPitch] = note;
						}
						
						var newPitchInfo : Array = _midiNumberToNoteInfo (noteMidiPitch);
						note.setContent(DataFields.PITCH_NAME, newPitchInfo[0] as String);
						note.setContent(DataFields.PITCH_ALTERATION, newPitchInfo[1] as int);
						note.setContent(DataFields.OCTAVE_INDEX, newPitchInfo[2] as int);
					}
					
					// Eventually, we add all clonned notes that were set aside for the current Cluster.
					if (clonedNotes && originalPitches) {
						for (var key:String in clonedNotes)  {
							var newPitch : int = parseInt(key);
							if (originalPitches.indexOf (newPitch) == -1) {
								var clonedNote : ProjectData = clonedNotes[key] as ProjectData;
								cluster.addDataChild(clonedNote);
							}
						}
					}
				}
			}
		}
		
		/**
		 * Returns the bass in a given cluster. 
		 * If `returnNoteIndex` is `true`, the local index of the Note node having the lowest pitch is returned. If it is `false` (default) its
		 * MIDI is returned instead. Returns `-1` on failure (e.g., empty cluster).
		 */
		public static function getBassOfCluster (cluster : ProjectData, returnNoteIndex : Boolean = false) : int {
			if (cluster && ModelUtils.isCluster(cluster) && cluster.numDataChildren > 0) {
				var basePitch : int = MIDI.MAX;
				var noteIndex : int = -1;
				for (var j:int = 0; j < cluster.numDataChildren; j++) {
					var note : ProjectData = ProjectData(cluster.getDataChildAt(j));
					var notePitch : int = MusicUtils.noteToMidiNumber(ProjectData(note));
					if (notePitch < basePitch) {
						basePitch = notePitch;
						noteIndex = j;
					}
				}
				return returnNoteIndex? noteIndex : basePitch;
			}
			return -1;
		}

		/**
		 * Convenience method to retrieve the bass Note node in the given cluster. Returns `null` on failure (e.g., empty cluster). 
		 */
		public static function getBassNote (cluster : ProjectData) : ProjectData {
			var bassNoteIndex : int = getBassOfCluster (cluster, true);
			if (bassNoteIndex >= 0) {
				return ProjectData(cluster.getDataChildAt (bassNoteIndex));
			}
			return null;
		}
		
		/**
		 * Convenience method to transpose an entire chord when the (absolute) target pitch of its base is known.
		 * Also works on Clusters with a single Note.
		 */
		public static function transposeBaseTo (cluster : ProjectData, absolutePitch : int) : void {
			if (cluster && ModelUtils.isCluster(cluster) && cluster.numDataChildren > 0 && absolutePitch) {
				var currentBass : int = getBassOfCluster (cluster);
				if (currentBass != -1) {
					var delta : int = absolutePitch - currentBass;
					if (delta) {
						transposeBy ([cluster], delta, false);
					}
				}
			}
		}

		/**
		 * By best effort, replaces (numerous) repeating Clusters having the same pitche(s) with 
		 * (fewer) Clusters, ideally only one, having their cummulated duration. We will not cummulate
		 * if this would violate:
		 * - tupplet boundaries;
		 * - common durations (single and double dot is acceptable);
		 * - Measure (in fact Voice) boundaries.
		 *
		 * @param	sourceMaterial
		 *			Any container of Clusters
		 *	@param	onlyIfTied
		 *			Optional, defaults to "false". If true, will only consolidate if the neighbour
		 *			Clusters also have ties between them (apart from having the same pitches, in the
		 *			same order).
		 */
		public static function consolidatePrimeIntervals (sourceMaterial : ProjectData, 
			onlyIfTied : Boolean = false) : void {

			// Group toghether eligible Clusters in batches, and attempt to resolve their gross duration to one 
			// of the "common durations". On failure to do so, we narrow down the batch by one cluster and try 
			// again, until we hit a "common duration". We use it to replace all the durations left in the
			// batch, then repeat the process on the remaining eligible Clusters, until all of them are 
			// consumed. 
			// Ideally, when we reach the end of our Clusters list, we will be left with the most concise 
			// rhythmical representation that is achievable.
			var rawClusters : Array = ModelUtils.getDescendantsOfType (sourceMaterial, DataFields.CLUSTER);
			var clustersToErase : Array = [];
			var currentClustersBatch : Array = [];
			var referenceCluster : ProjectData = null;

			var processCurrentBatch : Function = function () : void {
				var rewriteInfo : Object = null;
				var firstClusterInBatch : ProjectData = currentClustersBatch[0];
				var lastClusterInBatch : ProjectData = (currentClustersBatch[currentClustersBatch.length - 1] as ProjectData);
				while (currentClustersBatch.length >= 2 &&
					!(rewriteInfo = _toKnownDurations (_addClusters.apply (null, currentClustersBatch)))) {
					rawClusters.unshift (currentClustersBatch.pop());
				}
				lastClusterInBatch = (currentClustersBatch[currentClustersBatch.length - 1] as ProjectData);
				if (rewriteInfo) {
					_alterClusterDuration (firstClusterInBatch, rewriteInfo);
					if (_hasTie (lastClusterInBatch)) {
						_tieNext (firstClusterInBatch);
					} else {
						_untieNext (firstClusterInBatch);
					}
					clustersToErase = clustersToErase.concat (currentClustersBatch.slice (1));
				}
				currentClustersBatch.length = 0;
			}
			while (rawClusters.length > 0) {
				var cluster : ProjectData = rawClusters[0];
				if (referenceCluster) {

					// Encountering a rest after another rest represents an elligible situation.
					// By best effort, they will be consolidated just like Clusters having the 
					// same pitche(s).
					if ((cluster.numDataChildren == 0) && (referenceCluster.numDataChildren == 0)) {
						if (!_isFirstInVoice (cluster) && _areInSameTuplets(referenceCluster, cluster)) {
							if (currentClustersBatch.length == 0) {
								currentClustersBatch.push (referenceCluster);
							}
							currentClustersBatch.push (cluster);
						}

						// Clusters being the first Cluster of their voice, or being in a different tuplet
						// than the reference Cluster are not elligible. Encountering such a Cluster seals
						// the current batch in its current state and forces it to be processed immediately.
						else {
							referenceCluster = null;
							processCurrentBatch ();
							continue;
						}
					}

					// Encountering a rest after a note or chord seals the current batch in its current
					// state and forces it to be processed immediately.
					else if ((cluster.numDataChildren == 0) && (referenceCluster.numDataChildren != 0)) {
						referenceCluster = null;
						processCurrentBatch ();
						continue;
					}

					// Encountering a Cluster with the same pitch as the reference Cluster (subject
					// to a number of restrictions, see below) makes for an elligible situation. By best
					// effort, they will be consolidated.
					else if (_haveSamePitch (referenceCluster, cluster) &&
						(!onlyIfTied || _hasTie(referenceCluster))) {
						if (!_isFirstInVoice (cluster) && _areInSameTuplets(referenceCluster, cluster)) {
							if (currentClustersBatch.length == 0) {
								currentClustersBatch.push (referenceCluster);
							}
							currentClustersBatch.push (cluster);
						} 

						// Clusters being the first Cluster of their voice, or being in a different tuplet
						// than the reference Cluster are not elligible. Encountering such a Cluster seals
						// the current batch in its current state and forces it to be processed immediately.
						else {
							referenceCluster = null;
							processCurrentBatch ();
							continue;
						}
					} 

					// Clusters not having the same pitch(es) as the reference Cluster, (or not being
					// tied to the reference Cluster, if the "onlyIfTied" parameter is given),
					// are not elligible. Encountering such a Cluster seals the current batch in its
					// current state and forces it to be processed immediately.
					else {
						referenceCluster = null;
						processCurrentBatch ();
						continue;
					}
				}

				// We move the "playhead" one Cluster to the right. On the subsequent "while" iteration, the next
				// pair of Clusters in the "rawClusters" Array will be examined. Note that the 
				// "processCurrentBatch()" function can "expell" Clusters from the current batch if they fail to 
				// sum up to a known duration. These Clusters are added to the start of the "rawClusters" Array, 
				// in which case, the leftmost of the rejected Clusters will become the next "referenceCluster". 
				// The "processCurrentBatch()" function will always keep the Cluster that started the batch, 
				// regardless of how useless it is, or otherwise we would have an infinite loop.
				referenceCluster = (rawClusters.shift() as ProjectData);
			}

			// Explicitely process the last batch of Clusters, if any. If we are at the end of the "sourceMaterial",
			// then there are no more triggers to cause automatic batch processing, so this needs to be handled 
			// manually.
			if (currentClustersBatch && currentClustersBatch.length > 0) {
				referenceCluster = null;
				processCurrentBatch ();
			}

			// Delete Clusters that are not needed anymore (because their value has been consolidated).
			while (clustersToErase.length > 0) {
				var deletable : ProjectData = clustersToErase.shift();
				var parentVoice : ProjectData = ProjectData (deletable.dataParent);
				parentVoice.removeDataChild (deletable);
			}
		}

		/**
		* Removes the ties on the last Cluster in each Voice in the last Measure of the "sourceMaterial",
		* if applicable. Executes changes in place.
		*/
		public static function clearTrailingTies (sourceMaterial : ProjectData) : void {
			var measures : Array = ModelUtils.getDescendantsOfType (sourceMaterial, DataFields.MEASURE);
			if (measures.length > 0) {
				var lastMeasure : ProjectData = measures.pop();
				var voices : Array = ModelUtils.getDescendantsOfType (lastMeasure, DataFields.VOICE);
				voices.forEach (function (voice : ProjectData, ...etc) : void {
					var numClusters : uint = voice.numDataChildren;
					if (numClusters > 0) {
						var lastCluster : ProjectData = (voice.getDataChildAt (numClusters - 1) as ProjectData);
						_untieNext (lastCluster);
					}
				});
			}
		}
		
		/**
		 * Produces the list of all regular, legit durations to be used in musical scores.
		 * 
		 * The list includes the Fractions of all musical durations from the WHOLE down to 
		 * the 128TH and may or may not include "composites" (obtained by adding a single or
		 * double augmentation dot to regular values) -- based on the `includeComposites` arguments.
		 * 
		 * The Array will either contain the Fractions per se, or wrapped in individual Value Objects
		 * with information about the dot used to produce the final value -- based on the `useRawFormat`
		 * argument. 
		 */
		public static function getCommonFractionsList (useRawFormat:Boolean=true, includeComposites:Boolean=false):Array {
			var list :Array = _getSimpleDurations().concat();
			if (!useRawFormat) {
				list = list.map (function (item : Fraction, ...etc) : Object {
					var obj : Object = {};
					obj[DataFields.CLUSTER_DURATION_FRACTION] = item;
					return obj;
				});
			}
			if (includeComposites) {
				// Not using double dots anymore because abcm2ps-8.14.12 (2021-07-14) wrongly flags
				// double dotted values as "Bad length" and only outputs a duration corresponding to the main
				// unit, e.g., for a double dotted half (7/8 in ABC) it only outputs one eight (1/8 in ABC).
				var dotTypes:Array=[DotTypes.SINGLE];
				for (var i:int=0; i < _simpleDurations.length; i++) {
					var simpleDuration:Fraction=(_simpleDurations[i] as Fraction);
					for (var j:int=0; j < dotTypes.length; j++) {
						var dotTypeSrc:String=(dotTypes[j] as String);
						if (dotTypeSrc == DotTypes.NONE) {
							continue;
						}
						if (simpleDuration.toString() == DurationFractions.HUNDREDTWENTYEIGHTH.toString()) {
							continue;
						}
						if (simpleDuration.toString() == DurationFractions.SIXTYFOURTH.toString() && dotTypeSrc == DotTypes.DOUBLE) {
							continue;
						}
						var dotType:Fraction=Fraction.fromString(dotTypeSrc);
						var compositeDuration:Fraction=simpleDuration.add(dotType.multiply(simpleDuration)) as Fraction;
						if (useRawFormat) {
							list.push(compositeDuration);
						} else {
							var obj : Object = {};
							obj[DataFields.CLUSTER_DURATION_FRACTION] = simpleDuration;
							obj[DataFields.DOT_TYPE] = dotTypeSrc;
							obj[ViewKeys.COMPOSITE_DURATION] = compositeDuration;
							list.push (obj);
						}
					}
				}
			}
			if (useRawFormat) {
				list.sort (Fraction.compare);
			} else {
				list.sort (function (objA : Object, objB : Object) : int {
					var fA : Fraction = objA [DataFields.CLUSTER_DURATION_FRACTION] as Fraction;
					var fB : Fraction = objB [DataFields.CLUSTER_DURATION_FRACTION] as Fraction;
					return Fraction.compare(fA, fB);
				});
			}
			return list;
		}
		
		private static function _alterClusterDuration (cluster : ProjectData, rewriteInfo : Object) : void {
			var durationSrc : String = (rewriteInfo[DataFields.CLUSTER_DURATION_FRACTION] as Fraction).toString();
			var dotTypeSrc : String = (rewriteInfo[DataFields.DOT_TYPE] as String) || DotTypes.NONE;
			cluster.setContent (DataFields.CLUSTER_DURATION_FRACTION, durationSrc);
			cluster.setContent (DataFields.DOT_TYPE, dotTypeSrc);
		}
		
		private static function _addClusters (... clusters) : Fraction {
			var duration : Fraction = Fraction.ZERO;
			for (var i:int = 0; i < clusters.length; i++) {
				var cluster : ProjectData = clusters[i] as ProjectData;
				var clusterDuration : Fraction = Fraction.fromString (cluster.getContent(DataFields.CLUSTER_DURATION_FRACTION));
				if (cluster.getContent(DataFields.DOT_TYPE) != DotTypes.NONE) {
					var dot : Fraction = Fraction.fromString (cluster.getContent(DataFields.DOT_TYPE) as String);
					var dotAugmentation : Fraction = clusterDuration.multiply (dot) as Fraction;
					clusterDuration = clusterDuration.add(dotAugmentation) as Fraction;
				}
				if (clusterDuration) {
					duration = duration.add (clusterDuration) as Fraction;
				}
			}
			return duration;
		}
		
		private static function _getSimpleDurations () : Array {
			if (_simpleDurations == null) {
				_simpleDurations=ConstantUtils.getAllValues(DurationFractions);
				_simpleDurations.sort(Fraction.compare);
			}
			return _simpleDurations;
		}
		
		private static function _isFirstInVoice (cluster : ProjectData) : Boolean {
			return (cluster.index == 0);
		}
		
		private static function _areInSameTuplets (clusterA : ProjectData, clusterB : ProjectData) : Boolean {
			var aId : String = clusterA.route;
			var bId : String = clusterB.route;
			var aStartsTuplet : Boolean = (clusterA.getContent (DataFields.STARTS_TUPLET) !== false);
			var bStartsTuplet : Boolean = (clusterB.getContent (DataFields.STARTS_TUPLET) !== false);
			var aTupletRoot : String = clusterA.getContent(DataFields.TUPLET_ROOT_ID);
			var bTupletRoot : String = clusterB.getContent(DataFields.TUPLET_ROOT_ID);
			var aIsInTuplet : Boolean = (aTupletRoot != DataFields.VALUE_NOT_SET);
			var bIsInTuplet : Boolean = (bTupletRoot != DataFields.VALUE_NOT_SET);

			// Two Clusters are in the "same" tuplet if none of them actually is in any tuplet.
			if (!aStartsTuplet && !aIsInTuplet && !bStartsTuplet && !bIsInTuplet) {
				return true;
			}

			// Two Clusters are in the same tuplet if one of them starts the tuplet, and
			// the other follows.
			if (aStartsTuplet && (bTupletRoot == aId)) {
				return true;
			}
			if (bStartsTuplet && (aTupletRoot == bId)) {
				return true;
			}

			// Two Clusters are in the same tuplet if both follow (none of them actually starts the
			// tuplet, some other Cluster does).
			if (!aStartsTuplet && !bStartsTuplet && (aTupletRoot == bTupletRoot)) {
				return true;
			}

			// Otherwise, the two Clusters are NOT in the same tuplet.
			return false;
		}
		
		private static function _haveSamePitch (clusterA : ProjectData, clusterB : ProjectData) : Boolean {
			if (clusterA.numDataChildren != clusterB.numDataChildren) {
				return false;
			}
			var clusterAPitches : Array = [];
			var clusterBPitches : Array = [];
			for (var i:int = 0; i < clusterA.numDataChildren; i++) {
				clusterAPitches.push (noteToMidiNumber (ProjectData (clusterA.getDataChildAt(i))));
				clusterBPitches.push(noteToMidiNumber( ProjectData(clusterB.getDataChildAt(i))));
			}
			clusterAPitches.sort();
			clusterBPitches.sort();
			for (var j:int = 0; j < clusterAPitches.length; j++) {
				if (clusterAPitches[j] != clusterBPitches[j]) {
					return false;
				}
			}
			return true;
		}
		
		private static function _toKnownDurations (rawFraction : Fraction) : Object {
			var knownDurations : Array = getCommonFractionsList (false, true);
			for (var i:int = 0; i < knownDurations.length; i++) {
				var durationInfo : Object = knownDurations[i] as Object;
				var knownFraction : Fraction = ((ViewKeys.COMPOSITE_DURATION in durationInfo)? 
					durationInfo[ViewKeys.COMPOSITE_DURATION] : durationInfo[DataFields.CLUSTER_DURATION_FRACTION]) as Fraction;
				if (rawFraction.equals (knownFraction)) {
					return durationInfo;
				}
			}
			return null;
		}
		
		private static function _tieNext (cluster : ProjectData) : void {
			for (var i:int = 0; i < cluster.numDataChildren; i++) {
				var note : ProjectData = ProjectData(cluster.getDataChildAt (i));
				note.setContent(DataFields.TIES_TO_NEXT_NOTE, true);
			}
		}
		
		private static function _untieNext (cluster : ProjectData) : void {
			for (var i:int = 0; i < cluster.numDataChildren; i++) {
				var note : ProjectData = ProjectData(cluster.getDataChildAt (i));
				note.setContent(DataFields.TIES_TO_NEXT_NOTE, false);
			}
		}

		private static function _hasTie (cluster : ProjectData) : Boolean {
			for (var i:int = 0; i < cluster.numDataChildren; i++) {
				var note : ProjectData = ProjectData(cluster.getDataChildAt (i));
				if (note.getContent(DataFields.TIES_TO_NEXT_NOTE) === true) {
					return true;
				}
			}
			return false;
		}
		
		private static function _buildChromaticScale():Array {
			var scale:Array = [];
			var template:Array = [[PitchNames.C, PitchAlterationTypes.NATURAL], [PitchNames.C, PitchAlterationTypes.SHARP], [PitchNames.D, PitchAlterationTypes.NATURAL], [PitchNames.D, PitchAlterationTypes.
				SHARP], [PitchNames.E, PitchAlterationTypes.NATURAL], [PitchNames.F, PitchAlterationTypes.NATURAL], [PitchNames.F, PitchAlterationTypes.SHARP], [PitchNames.G, PitchAlterationTypes.NATURAL],
				[PitchNames.G, PitchAlterationTypes.SHARP], [PitchNames.A, PitchAlterationTypes.NATURAL], [PitchNames.A, PitchAlterationTypes.SHARP], [PitchNames.B, PitchAlterationTypes.NATURAL]];
			for (var i:int = 0; i < template.length; i++) {
				var templateEl:Array = template[i];
				var note:ProjectData = new ProjectData;
				var details:Object = {};
				details[DataFields.DATA_TYPE] = DataFields.NOTE;
				note.populateWithDefaultData(details);
				note.setContent(DataFields.PITCH_NAME, templateEl[0]);
				note.setContent(DataFields.PITCH_ALTERATION, templateEl[1]);
				scale.push(note);
			}
			return scale;
		}

		private static function _buildIntervalsMap():Array {
			var map:Array = [];
			var allIntervalNames:Array = ConstantUtils.getAllNames(IntervalNames);
			for (var i:int = 0; i < allIntervalNames.length; i++) {
				var intervalName:String = allIntervalNames[i];
				var intervalSize:int = -1;
				if (ConstantUtils.hasName(IntervalsSize, intervalName)) {
					intervalSize = (IntervalsSize[intervalName] as int);
					if (intervalSize >= 0) {
						map[intervalSize] = Strings.fromAS3ConstantCase(intervalName);
					}
				}
			}
			return map;
		}
		
		private static function _buildOctavesMap():Array {
			var map:Array = [];
			var allOctaveNames:Array = ConstantUtils.getAllNames(OctaveIndexes);
			for (var i:int = 0; i < allOctaveNames.length; i++) {
				var octaveName : String = allOctaveNames [i];
				var octaveIndex : int = OctaveIndexes[octaveName];
				if (octaveIndex >= 0) {
					map[octaveIndex] = octaveName;
				}
			}
			return map;
		}
		
		private static function _buildReversedAlterationSymbolsMap () : Object {
			var ret : Object = {};
			var keys : Array = ConstantUtils.getAllNames(PitchAlterationSymbols);
			for (var i:int = 0; i < keys.length; i++) {
				var key : String = keys[i];
				var value : String = PitchAlterationSymbols[key];
				ret[value] = key;
			}
			return ret;
		}
		
		/**
		 * Computes and returns the `CHROMATIC_SCALE` index that corresponds to given
		 * pitch name and pitch alteration. This allows to gracefully equivalate
		 * `C double flat` to `A sharp`, and the like.
		 * 
		 * @param	pitchName
		 * 			A pitch name, such as `C`.
		 * 
		 * @param	pitchAlteration
		 * 			A pitch alteration, such as `-2` for `double flat`.
		 * 
		 * @return	The resulting index in the `CHROMATIC_SCALE`, such as `10` for the
		 * 			example values.
		 */
		private static function _getNoteIndex (pitchName : String, pitchAlteration : int) : int {
			var baseIndex : int = -1;
			switch (pitchName) {
				case PitchNames.C:
					baseIndex = 0;
					break;
				case PitchNames.D:
					baseIndex = 2;
					break;
				case PitchNames.E:
					baseIndex = 4;
					break;
				case PitchNames.F:
					baseIndex = 5;
					break;
				case PitchNames.G:
					baseIndex = 7;
					break;
				case PitchNames.A:
					baseIndex = 9;
					break;
				case PitchNames.B:
					baseIndex = 11;
					break;
			}
			var adjustedIndex : int = (baseIndex + pitchAlteration);
			if (adjustedIndex < 0) {
				adjustedIndex = (12 + pitchAlteration);
			}
			if (adjustedIndex >= 12) {
				adjustedIndex -= 12;
			}
			return adjustedIndex;	
		}
		
		private static function _pitchSymbolToAlteration(symbol : String) : int {
			return ( PitchAlterationTypes[REVERSED_ALTERATION_SYMBOLS_MAP[symbol]] as int);
		}
	}
}
