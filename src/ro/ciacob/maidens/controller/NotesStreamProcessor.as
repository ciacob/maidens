package ro.ciacob.maidens.controller {
	import ro.ciacob.maidens.generators.MusicEntry;
	import ro.ciacob.maidens.generators.constants.parts.PartRanges;
	import ro.ciacob.maidens.generators.constants.pitch.MiddleCMapping;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.utils.Assertions;
	import ro.ciacob.utils.ConstantUtils;

	/**
	 * Performs operations on a stream of `MusicEntry` instances, such as, for example,  fitting all the
	 * notes into a given ambitus.
	 */
	public class NotesStreamProcessor {

		private static const BASS_TRANSPOSITION_PIVOT_BIAS:Number = 0.4;
		private static const DESCANT_TRANSPOSITION_PIVOT_BIAS:Number = 0.6;
		private static const GAMUT:String = 'gamut';
		private static const GAMUT_OVERFLOW_POINTS:String = 'gamutOverflowPoints';
		private static const HIGHEST_PITCH:String = 'highestPitch';
		private static const LOWEST_PITCH:String = 'lowestPitch';
		private static const OCTAVE_SPAN:int = 12;
		private static const PIVOT_PITCH:String = 'pivotPitch';

		/**
		 * @constructor
		 * @param	notesStream
		 * 			An Array of MusicEntry instances to operate on.
		 */
		public function NotesStreamProcessor(stream:Array) {
			_source = [];
			for (var i:int = 0; i < stream.length; i++) {
				var entry:MusicEntry = _retrieveEntryAt(i, stream);
				_source.push(entry);
			}
		}

		private var _highestPermittedPitch:int;
		private var _lowestPermittedPitch:int;
		private var _source:Array;
		private var _transpositionPivotBias:Number;

		/**
		 * Returns a deep copy of source stream were all the notes fit a given ambitus.
		 *
		 * @return	An Array with MusicEntry instances.
		 */
		public function fit():Array {
			Assertions.assertNotNull(_source, '_sourceStream');
			Assertions.assertNotZero(_highestPermittedPitch, '_highestInTarget');
			Assertions.assertNotZero(_lowestPermittedPitch, '_lowestInTarget');
			Assertions.assertNotNaN(_transpositionPivotBias, '_targetPivotBias');
			Assertions.assertGreaterThan(_highestPermittedPitch, _lowestPermittedPitch,
				'_highestInTarget > _lowestInTarget');

			var maxPermittedGamut:int = (_highestPermittedPitch - _lowestPermittedPitch);
			var srcAnalysisResults:Object = _analyseStream(_source, maxPermittedGamut);
			var currentHighestPitch:int = (srcAnalysisResults[HIGHEST_PITCH] as int);
			var currentLowestPitch:int = (srcAnalysisResults[LOWEST_PITCH] as int);
			var currentGamut:int = (srcAnalysisResults[GAMUT] as int);
			var currentPivotPitch:int = (srcAnalysisResults[PIVOT_PITCH] as int);
			var overflowPoints:Array = (srcAnalysisResults[GAMUT_OVERFLOW_POINTS] as
				Array);

			// Case 1: the stream fits in the target as it is.
			if (currentGamut <= maxPermittedGamut && currentLowestPitch >= _lowestPermittedPitch &&
				currentHighestPitch <= _highestPermittedPitch) {
				return _source;
			}

			// Case 2: the stream fits in the target if block-pitched up or down.
			if (currentGamut <= maxPermittedGamut) {
				_fitStream(_source, currentGamut, currentPivotPitch, maxPermittedGamut,
					_transpositionPivotBias, _lowestPermittedPitch, _highestPermittedPitch);
				return _source;
			}

			// Case 3: the stream does not fit in the target.
			var newStream:Array = [];
			var lastSlicePoint:int = 0;
			for (var i:int = 0; i < overflowPoints.length; i++) {
				var currSlicePoint:int = (overflowPoints[i] as int);
				var numElementsToCut:int = (currSlicePoint - lastSlicePoint);
				var streamSlice:Array = _source.splice(lastSlicePoint, numElementsToCut);
				lastSlicePoint = currSlicePoint;
				streamSlice = _autoFitStream(streamSlice);
				newStream = newStream.concat(streamSlice);
			}
			if (_source.length > 0) {
				_source = _autoFitStream(_source);
				newStream = newStream.concat(_source);
			}
			return newStream;
		}

		/**
		 * Specifies the boundaries notes are to be fitted in. This method is
		 * mutually exclusive with `setTargetInstrument` — whichever is called last,
		 * overrides the former.
		 *
		 * @param	lowPitch
		 * 			The low (bass) pitch boundary, in MIDI pitch notation.
		 *
		 * @param	highPitch
		 * 			The high (descant) pitch boundary, in MIDI pitch notation.
		 */
		public function setTargetRange(lowPitch:int, highPitch:int):void {
			_lowestPermittedPitch = lowPitch;
			_highestPermittedPitch = highPitch;
		}

		/**
		 * Specifies a part as a transposition/fit target. Automatically populates/overrides range and pivot.
		 * Range is set to instrument's range, pivot to 0.6 for descant instruments and 0.4 for bass
		 * instruments.
		 *
		 * @param	partDefinition
		 * 			A ProjectData instance pointing to a part element.
		 */
		public function set targetInstrument(partDefinition:ProjectData):void {
			var instrumentRange:Array = (ConstantUtils.getValueByMatchingName(PartRanges,
				partDefinition.getContent(DataFields.PART_NAME)) as Array);
			_lowestPermittedPitch = (instrumentRange[0] as int);
			_highestPermittedPitch = (instrumentRange[1] as int);
			var isInstrumentBass:Boolean = (_lowestPermittedPitch <= (MiddleCMapping.
				MIDDLE_C_MIDI_VALUE - OCTAVE_SPAN));
			_transpositionPivotBias = (isInstrumentBass ? BASS_TRANSPOSITION_PIVOT_BIAS :
				DESCANT_TRANSPOSITION_PIVOT_BIAS);
		}

		/**
		 * Specifies the ideal placement of all transposed notes when fitting a stream. E.g., `0.5` tries to center
		 * the stream in the alowable gamut, while `0.6` tries to push them 10% higher.
		 *
		 * This method is mutually exclusive with `setTargetInstrument` — whichever is called last, overrides the former.
		 *
		 * @param	bias
		 * 			A percent, expressed as a 0 to 1 number.
		 */
		public function set transpositionPivotBias(bias:Number):void {
			_transpositionPivotBias = bias;
		}

		/**
		 * @private
		 */
		private function _analyseStream(sourceStream:Array, targetGamut:int):Object {
			var sourceGamut:int = 0;
			var lowestInSource:int = MiddleCMapping.MAXIMUM_PITCH;
			var highestInSource:int = MiddleCMapping.MINIMUM_PITCH;
			var sourceOverflowPoints:Array = [];
			var overflowThreshold:int = targetGamut;
			for (var i:int = 1; i < sourceStream.length; i++) {
				var entry:MusicEntry = (sourceStream[i] as MusicEntry);
				var currPitch:int = entry.pitch;
				if (currPitch == 0) {
					continue;
				}
				if (currPitch > highestInSource) {
					highestInSource = currPitch;
				}
				if (currPitch < lowestInSource) {
					lowestInSource = currPitch;
				}
				sourceGamut = Math.abs(highestInSource - lowestInSource);
				if (sourceGamut > overflowThreshold) {
					sourceOverflowPoints.push(i);
					overflowThreshold += OCTAVE_SPAN;
				}
			}
			var sourcePivot:int = (Math.round(sourceGamut * 0.5) + lowestInSource);
			var ret:Object = {};
			ret[GAMUT] = sourceGamut;
			ret[LOWEST_PITCH] = lowestInSource;
			ret[HIGHEST_PITCH] = highestInSource;
			ret[GAMUT_OVERFLOW_POINTS] = sourceOverflowPoints;
			ret[PIVOT_PITCH] = sourcePivot;
			return ret;
		}

		private function _autoFitStream(stream:Array):Array {
			var targetGamut:int = (_highestPermittedPitch - _lowestPermittedPitch);
			var srcAnalysisResults:Object = _analyseStream(stream, targetGamut);
			var highestInSource:int = (srcAnalysisResults[HIGHEST_PITCH] as int);
			var lowestInSource:int = (srcAnalysisResults[LOWEST_PITCH] as int);
			var sourceGamut:int = (srcAnalysisResults[GAMUT] as int);
			var sourcePivot:int = (srcAnalysisResults[PIVOT_PITCH] as int);
			var sourceOverflowPoints:Array = (srcAnalysisResults[GAMUT_OVERFLOW_POINTS] as
				Array);
			return _fitStream(stream, sourceGamut, sourcePivot, targetGamut, _transpositionPivotBias,
				_lowestPermittedPitch, _highestPermittedPitch);
		}

		/**
		 * @private
		 */
		private function _fitStream(
			stream:Array, 
			streamGamut:int, 
			streamPivot:int,
			targetGamut:int, 
			targetPivotBias:Number, 
			targetLowBoundary:int, 
			targetHighBoundary:int) : Array {
			
			// TODO
			// FIX this function is is very buggy. Also, fix the generators instead,
			// so they do not produce out of range notes, in the first place.
			// This function should only be available for on-demand call (by the user, e.g.,
			// from a menu).
			// DISABLING FOR NOW
			return stream;
			
			var _targetPivot:int = (Math.round(targetPivotBias * targetGamut) + targetLowBoundary);
			var descantNegativeError:int = (targetHighBoundary - (_targetPivot +
				Math.round(streamGamut * 0.5)));
			if (descantNegativeError < 0) {
				_targetPivot += descantNegativeError;
			}
			var bassPositiveError:int = (targetLowBoundary - (_targetPivot - Math.
				round(streamGamut * 0.5)));
			if (bassPositiveError > 0) {
				_targetPivot += bassPositiveError;
			}
			var fixedAdjustment:int = (_targetPivot - streamPivot);
			var entry:MusicEntry = null;
			for (var j:int = 0; j < stream.length; j++) {
				entry = (stream[j] as MusicEntry);
				if (entry.pitch == 0) {
					continue;
				}
				entry.pitch += fixedAdjustment;
				if (entry.pitch > targetHighBoundary || entry.pitch < targetLowBoundary) {
					throw(new Error('Something is wrong. Target range is ' + targetLowBoundary +
						' to ' + targetHighBoundary + ', but this note pitch is ' +
						entry.pitch));
				}
				stream[j] = entry;
			}
			return stream;
		}

		/**
		 * @private
		 */
		private function _retrieveEntryAt(index:int, stream:Array):MusicEntry {
			return (stream[index] as MusicEntry);
		}
	}
}
