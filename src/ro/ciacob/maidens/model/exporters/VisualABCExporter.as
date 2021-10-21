package ro.ciacob.maidens.model.exporters {
import ro.ciacob.desktop.data.DataElement;
import ro.ciacob.desktop.data.constants.DataKeys;
import ro.ciacob.maidens.generators.constants.BracketTypes;
import ro.ciacob.maidens.generators.constants.parts.AutoGrouping;
import ro.ciacob.maidens.generators.constants.parts.PartFamilies;
import ro.ciacob.maidens.model.ModelUtils;
import ro.ciacob.maidens.model.constants.DataFields;
import ro.ciacob.maidens.view.constants.ViewKeys;
import ro.ciacob.utils.Strings;
import ro.ciacob.utils.constants.CommonStrings;

/**
	 * Root class containing traits for both screen and printed renditions (diverges from,
	 * e.g., audio renditions). Specifics of screen and print need to be implemented in their
	 * own subclasses.
	 */
	public class VisualABCExporter extends BaseABCExporter {

		private static const ABREVNAME_TEMPLATE:String='sname="%s"';
		private static const NAME_TEMPLATE:String='name="%s"';
		private static const NAME_TOKEN : String = 'nameToken';
		private static const SNAME_TOKEN : String = 'snameToken';
		private static const NAME : String = 'name';
		private static const ABREV_NAME : String = 'abrevName';
		private static const STAVES_GROUPING : String = 'stavesGrouping';
		private static const IS_FIRST_OF_GROUP : String = 'isFirstOfGroup';
		private static const IS_LAST_OF_GROUP : String = 'isLastOfGroup';
		private static const BEGINS_BRACE : String = 'beginsBrace';
		private static const ENDS_BRACE : String = 'endsBrace';
		private static const BEGINS_BRACKET : String = 'beginsBracket';
		private static const ENDS_BRACKET : String = 'endsBracket';
		private static const IS_FIRST_OF_AUTO_GROUP : String = 'isFirstOfAutoGroup';
		private static const IS_LAST_OF_AUTO_GROUP : String = 'isLastOfAutoGroup';
		private static const BEGINS_AUTO_BRACKET : String = 'beginsAutoBracket';
		private static const ENDS_AUTO_BRACKET : String = 'endsAutoBracket';
		private static const IS_FIRST_OF_AUTO_SUBGROUP : String = 'isFirstOfAutoSubGroup';
		private static const IS_LAST_OF_AUTO_SUBGROUP : String = 'isLastOfAutoSubGroup';
		private static const BEGINS_AUTO_SUBBRACKET : String = 'beginsAutoSubBracket';
		private static const ENDS_AUTO_SUBBRACKET : String = 'endsAutoSubBracket';

		/**
		 * Temporary local storage for the `project` argument received by overriden method `export()`.
		 */
		private static var _project : DataElement;

		/**
		 * Temporary local storage for the `partData` argument received by overriden method `buildStaffHeaderData()`.
		 */
		private static var _prevPartData : Object;

		/**
		 * Temporary local storage for the last processed part name.
		 * NOTE: at this level, part names come prefixed with their UID; this variable holds the "cleaned up" name
		 * of the part, with its UID removed.
		 */
		private static var _prevPartCleanName : String;

		/**
		 * Flag we raise as soon as we have at least two parts added to an auto group. Used by method
		 * `buildStaffHeaderData()`.
		 */
		private static var _haveOpenAutoGroup : Boolean;

		/**
		 * Flag we raise as soon as we have at least two part instances (e.g., Violin 1 and Violin 2) added to an
		 * auto sub-group. Used by method `buildStaffHeaderData()`.
		 */
		private static var _haveOpenAutoSubGroup : Boolean;

		/**
		 * Temporary local storage for the `target` argument received by overriden method `buildStaffHeaderData()`.
		 */
		private var _staffHeaderDataTarget:Object;


		public function VisualABCExporter() {
			super();
		}

		/**
		 * Overriden, to reset local state before each export
		 */
		override public function export(project:DataElement, shallow:Boolean=false, isRecursiveCall : Boolean = false):* {
			_prevPartData = null;
			_prevPartCleanName = null;
			_haveOpenAutoGroup = false;
			_haveOpenAutoSubGroup = false;
			_staffHeaderDataTarget={};
			_project = project;
			return super.export(project, shallow);
		}

		/**
		 * Overriden to add support for brackets, braces, and grouping (reflected in the
		 * way barlines brake or continue across the staves).
		 *
		 * @see BaseAbcExporter.buildStaffHeaderData
		 *
		 */
		override protected function buildStaffHeaderData(partData:Object, target:Object, staffIndex:int):void {
			_staffHeaderDataTarget=target;
			super.buildStaffHeaderData(partData, target, staffIndex);
			var staves:Array=(target['staves'] as Array);
			var lastAddedStaff:Object=staves[staves.length - 1];

			// Some staves must have "hidden" names, which is problematic at its best; We'll use our own fiels
			// `nameToken` and `snameToken` to help cope with that
			lastAddedStaff[NAME_TOKEN]=NAME_TEMPLATE.replace('%s', lastAddedStaff[NAME] +
					CommonStrings.NON_BREAKING_SPACE);
			lastAddedStaff[SNAME_TOKEN]=ABREVNAME_TEMPLATE.replace('%s', lastAddedStaff[ABREV_NAME] +
					CommonStrings.NON_BREAKING_SPACE);

			var partName:String=(partData['partName'] as String);
			var partCleanName : String = Strings.trim (partName.split(CommonStrings.BROKEN_VERTICAL_BAR)[1]);
			var partNumStaves:int=(partData['partNumStaves'] as int);
			var isFirstStaffOfPart : Boolean = (staffIndex == 0);
			var isLastStaffOfPart : Boolean = (staffIndex == partNumStaves - 1);
			var part : DataElement = _project.getElementByRoute(partData[DataKeys.ROUTE]);
			var isLastPartInScore : Boolean = (part.index == part.dataParent.numDataChildren - 1);
			var partBracketType:String=(partData[DataFields.PART_OWN_BRACKET_TYPE] as String);

			// 1. Handle auto-grouping: contiguous parts of the same family shall be automatically grouped together
			// under a bracket. Contiguous instances of the same part (e.g., Violin 1 and Violin 2) shall be further
			// grouped under a supplementary bracket (the music renderer will know to draw that bracket differently).
			if (_prevPartData) {
				var notSamePart : Boolean = (_prevPartData[ViewKeys.PART_CHILD_INDEX] != partData[ViewKeys.PART_CHILD_INDEX]);
				var sameFamily : Boolean = PartFamilies.haveSameFamily ([_prevPartCleanName, partCleanName]);
				var isPartInstance : Boolean = (_prevPartCleanName == partCleanName);
				var isFamilyEligible : Boolean = AutoGrouping.isPartFamilyElligible (_prevPartCleanName);
				var firstStaffOfPrevPart : Object = staves[staves.length - _prevPartData.partNumStaves - 1];
				var lastStaffOfPrevPart : Object = staves[staves.length - 2];

				// Group contiguous parts
				if (notSamePart && sameFamily && !_haveOpenAutoGroup && isFamilyEligible) {
					firstStaffOfPrevPart[IS_FIRST_OF_AUTO_GROUP]=true;
					firstStaffOfPrevPart[BEGINS_AUTO_BRACKET]=true;
					_haveOpenAutoGroup = true;
				}
				if (notSamePart && !sameFamily && _haveOpenAutoGroup && isFamilyEligible) {
					lastStaffOfPrevPart[IS_LAST_OF_AUTO_GROUP]=true;
					lastStaffOfPrevPart[ENDS_AUTO_BRACKET]=true;
					_haveOpenAutoGroup = false;
				}
				if (isLastPartInScore && isLastStaffOfPart && _haveOpenAutoGroup && isFamilyEligible) {
					lastAddedStaff[IS_LAST_OF_AUTO_GROUP]=true;
					lastAddedStaff[ENDS_AUTO_BRACKET]=true;
					_haveOpenAutoGroup = false;
				}

				// Group contiguous part instances
				if (notSamePart && isPartInstance && !_haveOpenAutoSubGroup && isFamilyEligible) {
					firstStaffOfPrevPart[IS_FIRST_OF_AUTO_SUBGROUP] = true;
					firstStaffOfPrevPart[BEGINS_AUTO_SUBBRACKET] = true;
					_haveOpenAutoSubGroup = true;
				}
				if (notSamePart && !isPartInstance && _haveOpenAutoSubGroup && isFamilyEligible) {
					lastStaffOfPrevPart[IS_LAST_OF_AUTO_SUBGROUP] = true;
					lastStaffOfPrevPart[ENDS_AUTO_SUBBRACKET] = true;
					_haveOpenAutoSubGroup = false;
				}
				if (isLastPartInScore && isLastStaffOfPart && _haveOpenAutoSubGroup && isFamilyEligible) {
					lastAddedStaff[IS_LAST_OF_AUTO_SUBGROUP] = true;
					lastAddedStaff[ENDS_AUTO_SUBBRACKET] = true;
					_haveOpenAutoSubGroup = false;
				}
			}
			_prevPartData = partData;
			_prevPartCleanName = partCleanName;

			// 2. Handle inner grouping: some parts feature several staves that need a bracket and/or special barlines.
			if (partNumStaves > 1) {

				// Staff starts an inner group
				if (isFirstStaffOfPart) {
					lastAddedStaff[IS_FIRST_OF_GROUP]=true;
					if (partBracketType == BracketTypes.BRACE_FIRST_TWO) {
						lastAddedStaff[BEGINS_BRACE]=true;
					} else if (partBracketType == BracketTypes.BRACKET_ALL) {
						lastAddedStaff[BEGINS_BRACKET]=true;
					}
				}

				// Staff closes a group of two
				if (staffIndex == 1) {
					if (partBracketType == BracketTypes.BRACE_FIRST_TWO) {
						lastAddedStaff[ENDS_BRACE]=true;
					}
				}

				// Staff closes a group of `n`
				if (isLastStaffOfPart) {
					lastAddedStaff[IS_LAST_OF_GROUP]=true;
					if (partBracketType == BracketTypes.BRACKET_ALL) {
						lastAddedStaff[ENDS_BRACKET]=true;
					}
				}

				// Only the first staff in a braced group of two must display a name
				if (partBracketType == BracketTypes.BRACE_FIRST_TWO && staffIndex == 1) {
					lastAddedStaff[NAME_TOKEN]='';
					lastAddedStaff[SNAME_TOKEN]='';
				}

				// Each staff under a bracket should have its own, meaningful name, either stock or derived
				var notBraced:Boolean=(!lastAddedStaff[BEGINS_BRACE] && !lastAddedStaff[ENDS_BRACE]);
				if (notBraced) {

					// Full name
					var voiceLabel:String=ModelUtils.compileVoiceLabel(partName, partNumStaves, staffIndex) +
						CommonStrings.NON_BREAKING_SPACE;
					if (voiceLabel == null) {
						var labelBuffer:Array=[];
						labelBuffer.push(lastAddedStaff[NAME], CommonStrings.DASH, staffIndex + 1);
						voiceLabel=labelBuffer.join(CommonStrings.SPACE);
					}
					lastAddedStaff[NAME_TOKEN]=NAME_TEMPLATE.replace('%s', voiceLabel);
					// Abbreviated name
					var voiceAbbrevLabel:String=ModelUtils.compileVoiceAbbreviatedLabel(partName, partNumStaves, staffIndex) +
						CommonStrings.NON_BREAKING_SPACE;

					if (voiceAbbrevLabel == null) {
						var abbrevLabelBuffer:Array=[];
						abbrevLabelBuffer.push(lastAddedStaff[ABREV_NAME], CommonStrings.DASH, staffIndex + 1);
						voiceAbbrevLabel=abbrevLabelBuffer.join(CommonStrings.SPACE);
					}
					lastAddedStaff[SNAME_TOKEN]=ABREVNAME_TEMPLATE.replace('%s', voiceAbbrevLabel);
				}
			}
		}

		/**
		 * Overriden to add support for brackets, braces, and grouping (reflected in the
		 * way barlines brake or continue across the staves).
		 *
		 * @see BaseAbcExporter.sortStaves
		 */
		override protected function sortStaves(staves:Array):void {
			var i:int;
			var L:int=staves.length;
			if (L > 0) {
				super.sortStaves(staves);
				var groupingMarkupBuffer:Array=[];
				for (i=0; i < staves.length; i++) {
					var staff:Object=staves[i];

					// Break barlines before current group
					if (staff[IS_FIRST_OF_AUTO_GROUP]) {
						groupingMarkupBuffer.push(_drawPipeChar(i, L, groupingMarkupBuffer));
					}
					if (staff[IS_FIRST_OF_AUTO_SUBGROUP]) {
						groupingMarkupBuffer.push(_drawPipeChar(i, L, groupingMarkupBuffer));
					}
					if (staff[IS_FIRST_OF_GROUP]) {
						groupingMarkupBuffer.push(_drawPipeChar(i, L, groupingMarkupBuffer));
					}

					// Mark beginning of groups, from outer to innermost
					if (staff[BEGINS_AUTO_BRACKET]) {
						groupingMarkupBuffer.push('[');
					}
					if (staff[BEGINS_AUTO_SUBBRACKET]) {
						groupingMarkupBuffer.push('[');
					}
					if (staff[BEGINS_BRACKET]) {
						groupingMarkupBuffer.push('[');
					}
					if (staff[BEGINS_BRACE]) {
						groupingMarkupBuffer.push('{');
					}

					// Place the UID of the current staff
					groupingMarkupBuffer.push(staff['uid']);

					// Mark ending of groups, from inner to outermost
					if (staff[ENDS_BRACE]) {
						groupingMarkupBuffer.push('}');
					}
					if (staff[ENDS_BRACKET]) {
						groupingMarkupBuffer.push(']');
					}
					if (staff[ENDS_AUTO_SUBBRACKET]) {
						groupingMarkupBuffer.push(']');
					}
					if (staff[ENDS_AUTO_BRACKET]) {
						groupingMarkupBuffer.push(']');
					}

					// Break barlines after current group
					if (staff[IS_LAST_OF_GROUP]) {
						groupingMarkupBuffer.push(_drawPipeChar(i, L, groupingMarkupBuffer));
					}
					if (staff[IS_LAST_OF_AUTO_SUBGROUP]) {
						groupingMarkupBuffer.push(_drawPipeChar(i, L, groupingMarkupBuffer));
					}
					if (staff[IS_LAST_OF_AUTO_GROUP]) {
						groupingMarkupBuffer.push(_drawPipeChar(i, L, groupingMarkupBuffer));
					}
				}

				// Actually build and apply the grouping mark-up
				var groupingMarkup:String=groupingMarkupBuffer.join(CommonStrings.SPACE);
				_staffHeaderDataTarget[STAVES_GROUPING]=groupingMarkup;
			}
		}

		/**
		 * @see "sortStaves()"
		 * The pipe char is used in ABC to define barline continuation of staff systems in a score.
		 */
		private static function _drawPipeChar(i:int, len:int, buffer : Array):String {
			return ((i > 0 && i < len - 1 && buffer[buffer.length - 1] != CommonStrings.PIPE)?
					CommonStrings.PIPE : CommonStrings.EMPTY);
		}
	}
}
