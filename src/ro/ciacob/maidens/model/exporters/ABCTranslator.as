package ro.ciacob.maidens.model.exporters {
	import ro.ciacob.maidens.generators.constants.BarTypes;
	import ro.ciacob.maidens.generators.constants.ClefTypes;
	import ro.ciacob.maidens.generators.constants.pitch.PitchAlterationTypes;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.utils.constants.CommonStrings;

	public final class ABCTranslator {

		public static const CHORD_BEGIN_MARK:String = "[";
		public static const CHORD_END_MARK:String = "]";

		public static const DOUBLE_FLAT:String = "__";
		public static const DOUBLE_SHARP:String = "^^";
		public static const FLAT:String = "_";
		public static const FULL_MEASURE_INVISIBLE_REST:String = 'X';
		public static const FULL_MEASURE_REST:String = 'Z';
		public static const INVISIBLE_REST_PREFIX:String = 'x';
		public static const NATURAL:String = "=";
		public static const REST_PREFIX:String = 'z';
		public static const REST_TEMPLATE:String = 'z%d/%d';
		public static const INVISIBLE_REST_TEMPLATE:String = 'x%d/%d';
		public static const SHARP:String = "^";
		public static const TEMPORARY_VOICE_OPERATOR:String = '&';
		public static const DUMMY_ELEMENT:String = '{z1/128}';
		public static const REGULAR_BAR:String = '|';
		public static const THIN_THICK_BAR:String = '|]';
		public static const THIN_THIN_BAR:String = '||';
		public static const INVISIBLE_BAR:String = '[|]';

		public static const ABC_OCTAVE_MARKS:Array = ["%upper%,,,,", "%upper%,,,", "%upper%,,",
			"%upper%,", "%upper%", "%lower%", "%lower%'", "%lower%''", "%lower%'''", "%lower%''''"];

		public static const CROSS_MARKS:Array = [CommonStrings.CIRCUMFLEX, CommonStrings.
			UNDERSCORE, CommonStrings.GREATER_THAN, CommonStrings.LESS_THAN];
		
		public static const TOP_BOTTOM_MARKS:Array = [CommonStrings.CIRCUMFLEX, CommonStrings.UNDERSCORE];
		public static const LEFT_RIGHT_MARKS : Array = [CommonStrings.LESS_THAN, CommonStrings.GREATER_THAN];
		public static const LEFT_MARK : Array = [CommonStrings.LESS_THAN];
		public static const TOP_MARK : Array = [CommonStrings.CIRCUMFLEX];
		public static const LOWER_TOKEN:String = '%lower%';
		public static const METER_FIELD_TEMPLATE:String = '[M:%d/%d]';
		public static const NOTE_TEMPLATE:String = '%s%s%d/%d%s';
		public static const UPPER_TOKEN:String = '%upper%';

		public static function buildAnnotation(uid:String, marks : Array = null):String {
			if (!marks) {
				marks = CROSS_MARKS;
			}
			var ret:Array = [];
			for (var i:int = 0; i < marks.length; i++) {
				ret.push(CommonStrings.QUOTES);
				ret.push(marks[i] as String);
				ret.push(uid);
				ret.push(CommonStrings.QUOTES);
			}
			return ret.join('');
		}

		public static function translateBarType(barType:String):String {
			switch (barType) {
				case BarTypes.NORMAL_BAR:
					return REGULAR_BAR;
				case BarTypes.DOUBLE_BAR:
					return THIN_THIN_BAR;
				case BarTypes.FINAL_BAR:
					return THIN_THICK_BAR;
			}
			return null;
		}

		/**
		 * Translates a MAIDENS clef symbol into an ABC clef definition
		 * @param	clef
		 * 			The clef to translate, typically a one-char string.
		 *
		 * @return	The corresponding ABC string.
		 */
		public static function translateClef(clef:String):String {
			var abc:String = 'none';
			switch (clef) {
				case ClefTypes.BASS:
					abc = 'bass';
					break;
				case ClefTypes.TREBLE:
					abc = 'treble';
					break;
				case ClefTypes.TENOR:
					abc = 'tenor';
					break;
				case ClefTypes.TENOR_MODERN:
					abc = 'treble-8';
					break;
				case ClefTypes.CONTRABASS:
					abc = 'bass-8';
					break;
				case ClefTypes.ALTO:
					abc = 'alto';
					break;
			}
			return abc;
		}

		public static function translateNote(duration:Fraction, pitchName:String, alteration:int,
			octaveIndex:int, mustTie:Boolean):String {
			// Octave indices lower than 0 are not supported
			if (octaveIndex < 0) {
				octaveIndex = 0;
			}
			var abcAlteration:String = '';
			switch (alteration) {
				case PitchAlterationTypes.DOUBLE_FLAT:
					abcAlteration = DOUBLE_FLAT;
					break;
				case PitchAlterationTypes.FLAT:
					abcAlteration = FLAT;
					break;
				case PitchAlterationTypes.SHARP:
					abcAlteration = SHARP;
					break;
				case PitchAlterationTypes.DOUBLE_SHARP:
					abcAlteration = DOUBLE_SHARP;
					break;
				case PitchAlterationTypes.NATURAL:
					abcAlteration = NATURAL;
					break;
			}
			octaveIndex = Math.max(0, Math.min(ABC_OCTAVE_MARKS.length - 1, octaveIndex));
			var abcOctaveTemplate:String = ABC_OCTAVE_MARKS[octaveIndex];
			var abcPitch:String = (abcOctaveTemplate.indexOf(LOWER_TOKEN) >= 0) ? abcOctaveTemplate.
				replace(LOWER_TOKEN, pitchName.toLowerCase()) : (abcOctaveTemplate.indexOf(UPPER_TOKEN) >=
				0) ? abcOctaveTemplate.replace(UPPER_TOKEN, pitchName.toUpperCase()) : '';
			return NOTE_TEMPLATE.replace('%s', abcAlteration).replace('%s', abcPitch).replace('%d',
				duration.numerator).replace('%d', duration.denominator).replace('%s', mustTie ?
				'-' : '');
		}

		public static function translateRest(duration:Fraction, visibleRest:Boolean=true):String {
			var template : String = visibleRest? REST_TEMPLATE : INVISIBLE_REST_TEMPLATE;
			return template.replace('%d', duration.numerator).replace('%d', duration.
				denominator);
		}

		public static function translateTimeSignature(timeSignature:Array):String {
			var num:String = timeSignature[0];
			var den:String = timeSignature[1];
			return METER_FIELD_TEMPLATE.replace('%d', num).replace('%d', den);
		}
	}
}
