package ro.ciacob.maidens.model.constants {
	import ro.ciacob.maidens.generators.constants.BracketTypes;
	import ro.ciacob.maidens.generators.constants.duration.DivisionsEquivalency;
	import ro.ciacob.maidens.generators.constants.duration.DotTypes;
	import ro.ciacob.maidens.generators.constants.duration.DurationFractions;
	import ro.ciacob.maidens.generators.constants.duration.TimeSignature;
	import ro.ciacob.maidens.generators.constants.parts.PartAbbreviatedNames;
	import ro.ciacob.maidens.generators.constants.parts.PartDefaultClefs;
	import ro.ciacob.maidens.generators.constants.parts.PartDefaultStavesNumber;
	import ro.ciacob.maidens.generators.constants.parts.PartNames;
	import ro.ciacob.maidens.generators.constants.parts.PartRanges;
	import ro.ciacob.maidens.generators.constants.parts.PartTranspositions;
	import ro.ciacob.maidens.generators.constants.pitch.MiddleCMapping;
	import ro.ciacob.maidens.generators.constants.pitch.PitchNames;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.utils.constants.CommonStrings;

	public final class StaticFieldValues {
		public static const DEFAULT_ABBREVIATED_PART_NAME:String = PartAbbreviatedNames.
			FLUTE;
		public static const DEFAULT_CLUSTER_DIVISION:String = DivisionsEquivalency.
			REGULAR;
		public static const DEFAULT_CLUSTER_DOT_TYPE:String = DotTypes.NONE;
		public static const DEFAULT_CLUSTER_DURATION:String = DurationFractions.
			QUARTER.toString();
		public static const DEFAULT_COMPOSER_NAME:String = 'Unknown composer';
		public static const DEFAULT_CONNECTION_ID:String = StaticTokens.DEFAULT_CONNECTION_PREFIX.
			concat('1');
		public static const DEFAULT_COPYRIGHT_NOTE:String = CommonStrings.COPYRIGHT_SIGN;
		public static const DEFAULT_CUSTOM_NOTES:String = '';
		public static const DEFAULT_DYNAMIC_MARK:String = 'mf';
		public static const DEFAULT_NUM_MEASURES:int = 8;
		public static const DEFAULT_OCTAVE_INDEX:int = MiddleCMapping.MIDDLE_C_OCTAVE_INDEX;
		public static const DEFAULT_PART_BRACKET_TYPE:String = BracketTypes.NONE;
		public static const DEFAULT_PART_CLEFS_LIST:Array = PartDefaultClefs.FLUTE;
		public static const DEFAULT_PART_NAME:String = PartNames.FLUTE;
		public static const DEFAULT_PART_NUM_STAVES:int = PartDefaultStavesNumber.
			FLUTE;
		public static const DEFAULT_PART_ORDINAL_INDEX:int = 0;
		public static const DEFAULT_PART_TRANSPOSITION:int = PartTranspositions.
			FLUTE;
		public static const DEFAULT_PART_UID:String = 'z9W';
		public static const DEFAULT_PITCH:String = PitchNames.C;
		public static const DEFAULT_PROJECT_NAME:String = 'Untitled Project';
		public static const DEFAULT_SECTION_NAME:String = 'Section 1';
		public static const DEFAULT_TEMPO_INSTRUCTION:String = 'Moderato';
		public static const DEFAULT_TIME_FRACTION:Fraction = TimeSignature.COMMON_TIME;
		public static const DEFAULT_TIME_LABEL:String = 'C';
		public static const DFAULT_CONCERT_PITCH_RANGE:Array = PartRanges.FLUTE;
		public static const DFAULT_PITCH_ALTERATION:int = 0;
		public static const DEFAULT_VOICE_INDEX : int = 1;
		public static const DEFAULT_NUM_UNDO_STEPS : uint = 10;
		public static const DEFAULT_TUPLET_SRC_BEATS : uint = 3;
		public static const DEFAULT_TUPLET_TARGET_BEATS : uint = 2;
		
		public static const CONSTANT : String = 'constant';
		public static const PROGRESSIVELLY : String = 'progressivelly';
		public static const THRESHOLD : String = 'threshold';
		public static const ANCHOR_ON_INITIAL_NOTE : String = 'anchorOnInitialNote';
		public static const CENTER_ON_PIVOT_PITCH : String = 'centerOnPivotPitch';
		public static const ALIGN_TO_CEILING : String = 'alignToCeiling';
		public static const ALIGN_TO_FLOOR : String = 'alignToFloor';
		public static const CONSOLIDATE_PRIMES : String = 'consolidatePrimes';
		public static const PRESERVE_PRIMES : String = 'preservePrimes';
		
		public static const CTA_SPIN_DELAY : int = 60;
		public static const CTA_HIDE_TIME : Number = 0.3;
		public static const CTA_SHOW_TIME : Number = 0.4;
		
		public static const MAX_STATUS_TEXT_LENGTH : Number = 128;
	}
}
