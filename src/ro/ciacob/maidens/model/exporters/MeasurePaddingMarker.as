package ro.ciacob.maidens.model.exporters {
	import ro.ciacob.desktop.signals.PTT;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.maidens.model.constants.Voices;
	import ro.ciacob.maidens.view.constants.ViewKeys;
	import ro.ciacob.maidens.view.constants.ViewPipes;
	import ro.ciacob.math.Fraction;

	/**
	 * Placeholder for zero or more "invisible rests" (constructs in the ABC music
	 * language represented by the "x" letter; they affect spacing of notes as normal
	 * rests do, but do not show in the score); they are padded to the right of the
	 * measure content at rendering time, to make sure measures align properly in
	 * multi-voice and/or multi-part music.
	 */
	public class MeasurePaddingMarker implements IABCMarker {

		private static var _measuresSpanMap:Object = {};

		/**
		 * Globally erases all the previously stored information about measures span.
		 */
		public static function reset():void {
			_measuresSpanMap = {};
		}

		/**
		 * Globally stores the "span" (i.e., expected duration) for a specific measure,
		 * but only if greater than the previously stored value (or if no value was
		 * previously stored at all).
		 *
		 * @param	measureNumber
		 * 			The global number of a measure to store a span for.
		 *
		 * @param	span
		 * 			The span value to be stored, as a fraction.
		 */
		private static function _registerMeasureSpan(measureNumber:int, span:Fraction):void {
			if (measureNumber in _measuresSpanMap) {
				var existingSpan:Fraction = (_measuresSpanMap[measureNumber] as Fraction);
				if (existingSpan.greaterThan(span) || existingSpan.equals(span)) {
					return;
				}
			}
			_measuresSpanMap[measureNumber] = span;
		}

		public function MeasurePaddingMarker() {
		}

		private var _voice:ProjectData;
		private var _voiceDuration:Fraction;
		private var _measureSpan:Fraction;
		private var _measureNumber:uint;
		private var _paddingDurations:Array;

		/**
		 * Called against each measure being rendered. Stores the total duration of the
		 * clusters contained by that measure.
		 *
		 * @param	element
		 * 			A measure whose cluster children durations are to be summed up.
		 */
		public function accountFor (element : Object ) : int {
			if (_voice == null) {
				if (element is ProjectData) {
					var test:ProjectData = (element as ProjectData);
					if (test.getContent(DataFields.DATA_TYPE) == DataFields.VOICE) {
						_voice = test;
						_queryVoiceData();
						_registerMeasureSpan(_measureNumber, _measureSpan);
						return 1;
					}
				}
				throw(new ArgumentError('Method `accountFor()` in class MeasurePaddingMarker expects an ProjectData implementor of type `measure`, `' +
					element + '` given.'));
			}
			return 0;
		}

		/**
		 * Computes the delta between the current measure span and its duration, produces
		 * ABC markup with invisible rests to that ammount, and returns it. Returns an
		 * empty string if no padding is needed.
		 *
		 * @overrides `Object.toString()`
		 */
		public function toString():String {
			return _buildOutput();
		}

		private function _buildOutput():String {
			
			// We pad completely empty second voices with invisible rests, in order to
			// relax (set to automatic) stem rules for notes in voice 1.
			var voiceIndex : int = _voice.getContent (DataFields.VOICE_INDEX);
			var isSecondVoice : Boolean = (voiceIndex == Voices.SECOND_VOICE);
			var isVoiceEmpty : Boolean = (_voice.numDataChildren == 0);
			var mustUseHiddenRests : Boolean = (isSecondVoice && isVoiceEmpty);
			var restPrefix : String = mustUseHiddenRests? ABCTranslator.INVISIBLE_REST_PREFIX : ABCTranslator.REST_PREFIX;
			
			var out : String = '';
			var measureSpan:Fraction = (_measuresSpanMap[_measureNumber] as Fraction);
			if (measureSpan != null) {
				var delta:Fraction = measureSpan.subtract(_voiceDuration) as Fraction;
				if (delta.greaterThan(Fraction.ZERO)) {
					_splitRawDuration (delta);
					if (_paddingDurations != null && _paddingDurations.length > 0) {
						out = restPrefix.concat (_paddingDurations.join (restPrefix));
					}
				}
			}			
			return out;
		}

		private function _splitRawDuration (duration : Fraction) : void {
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

		private function _onVoiceDataReady(data:Object):void {
			PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).unsubscribe(ViewKeys.VOICE_DATA_READY,
				_onVoiceDataReady);
			_measureNumber = (data[ViewKeys.MEASURE_NUMBER] as uint);
			_voiceDuration = (data[ViewKeys.VOICE_DURATION] as Fraction);
			_measureSpan = (data[ViewKeys.MEASURE_SPAN] as Fraction);
		}

		private function _queryVoiceData():void {
			PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).subscribe(ViewKeys.VOICE_DATA_READY,
				_onVoiceDataReady);
			PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).send(ViewKeys.NEED_VOICE_DATA, _voice);
		}
	}
}
