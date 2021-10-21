package ro.ciacob.maidens.view {
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IViewCursor;
	
	import ro.ciacob.desktop.signals.PTT;
	import ro.ciacob.maidens.controller.MusicUtils;
	import ro.ciacob.maidens.controller.constants.MeasureSelectionKeys;
	import ro.ciacob.maidens.generators.constants.StemDirection;
	import ro.ciacob.maidens.generators.constants.duration.DurationFractions;
	import ro.ciacob.maidens.generators.constants.pitch.IntervalsSize;
	import ro.ciacob.maidens.model.HotspotBindingModel;
	import ro.ciacob.maidens.model.ModelUtils;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.maidens.view.constants.AnnotationMetrics;
	import eu.claudius.iacob.maidens.Colors;
	import eu.claudius.iacob.maidens.Sizes;
	import ro.ciacob.maidens.view.constants.SvgEntities;
	import ro.ciacob.maidens.view.constants.ViewKeys;
	import ro.ciacob.math.Fraction;
	import ro.ciacob.utils.ColorUtils;
	import ro.ciacob.utils.ConstantUtils;
	import ro.ciacob.utils.Geometry;
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.constants.CommonStrings;
	import ro.ciacob.utils.constants.GenericFieldNames;

	public class SvgPreProcessor {

		/**
		 * Graphic of button to be overlaid on measure hotspots, the "down" state of the button. The button
		 * will add "voice 2" in measures where it is missing.
		 */
		private static const ADD_VOICE_DOWN:XML=<g> <path fill="white" d="M28.6,127.5c-10,0-17.5-6.6-17.8-15.7v-0.3v-0.3c0-4.2,1.5-8.1,4.3-11.2l0.1-0.1C9.6,92.1,5.9,83.4,4.3,74 C-1.7,40.8,21.6,7.6,55.1,1.6c3.5-0.6,7.2-0.9,10.8-0.9c0.9,0,1.9,0,2.8,0.1h0.1c23.9,1.4,44.7,15.7,54.3,37.6l0.1,0.2 c9.1,22.1,5.1,47.2-10.5,65.3l-0.1,0.1c-12,13.4-29.2,21.1-47.2,21.1l0,0c-5.3,0-10.7-0.7-15.9-2.1 C42.6,126.1,35.7,127.5,28.6,127.5L28.6,127.5L28.6,127.5z"/> <path d="M112.3,43.2c-7.9-17.8-25-29.6-44.4-30.8c-3.7-0.1-7.3,0.1-11,0.7C29.7,18,10.7,44.9,15.5,72c1.9,10.4,6.9,20,14.5,27.4 l-6.3,7.9c-0.9,1-1.5,2.4-1.5,3.8c0.1,2.8,2.7,4.6,6.3,4.6l0,0c5.8,0,11.5-1.3,16.8-3.5l0.5-0.2c0.8-0.3,1.6-0.7,2.4-0.8 c1.2,0,2.2,0.2,3.4,0.6L52,112c18.8,4.9,38.8-1,51.6-15.5C116.3,81.8,119.7,61.1,112.3,43.2z"/> <path fill="white" d="M60.8,55.8V40.6H71v15.3h15.2V66H71v15.2H60.8V66H45.6V55.8H60.8z"/> </g>;

		/**
		 * Graphic of button to be overlaid on measure hotspots, the "up" state of the button. The button
		 * will add "voice 2" in measures where it is missing.
		 */
		private static const ADD_VOICE_UP:XML=<g> <path fill="white" d="M28.6,127.5c-10,0-17.5-6.6-17.8-15.7v-0.3v-0.3c0-4.2,1.5-8.1,4.3-11.2l0.1-0.1C9.6,92.1,5.9,83.4,4.3,74 C-1.7,40.8,21.6,7.6,55.1,1.6c3.5-0.6,7.2-0.9,10.8-0.9c0.9,0,1.9,0,2.8,0.1h0.1c23.9,1.4,44.7,15.7,54.3,37.6l0.1,0.2 c9.1,22.1,5.1,47.2-10.5,65.3l-0.1,0.1c-12,13.4-29.2,21.1-47.2,21.1l0,0c-5.3,0-10.7-0.7-15.9-2.1 C42.6,126.1,35.7,127.5,28.6,127.5L28.6,127.5L28.6,127.5z"/> <path d="M103.8,54.7C97,39.3,82.2,29.1,65.5,28.1c-3.2-0.1-6.3,0.1-9.5,0.6c-23.5,4.2-39.9,27.5-35.8,50.9c1.6,9,6,17.3,12.5,23.7 l-5.4,6.8c-0.8,0.9-1.3,2.1-1.3,3.3c0.1,2.4,2.3,4,5.4,4l0,0c5,0,9.9-1.1,14.5-3l0.4-0.2c0.7-0.3,1.4-0.6,2.1-0.7 c1,0,1.9,0.2,2.9,0.5l0.4,0.1c16.2,4.2,33.5-0.9,44.6-13.4C107.3,88,110.2,70.2,103.8,54.7z"/> <path fill="white" d="M59.4,65.6V52.4h8.8v13.2h13.1v8.8H68.1v13.1h-8.8V74.4H46.2v-8.8H59.4z"/> </g>;

		private static const CLEF_SYMBOLS:Array=['#tclef' /* G */, '#bclef' /* F */, '#cclef' /* C */];
		private static const CLEF_SYMBOL_SIZES:Object={'#tclef': {w: 18, h: 60}, '#bclef': {w: 20, h: 42}, '#cclef': {w: 18, h: 26}};
		private static const DATA : String = 'data';
		private static const ELEMENT:String='element';
		private static const GHOST_STYLE:String='fill-opacity:0.35;stroke-width:1;stroke-opacity:0.35;';
		private static const HOTSPOT_STYLE:String='stroke-width:1;fill-opacity:0.55;stroke-opacity:0.95;';
		private static const MARKUP : String = 'markup';
		private static const MEASURE_MIN_BOUNDARY_POINTS:uint=3;
		private static const CLUSTER_MIN_BOUNDARY_POINTS:uint = 2;
		private static const NOTEHEAD_SYMBOLS:Array=['#HD' /* whole */, '#Hd' /* half */, '#hd' /* quarter and below */];
		private static const NOTEHEAD_SYMBOL_SIZES:Object={'#HD': {w: 12, h: 8}, '#Hd': {w: 10, h: 8}, '#hd': {w: 10, h: 8}};
		private static const PATH:String='path';
		private static const DEFAULT_CLUSTER_HOTSPOT_WIDTH : uint = 20;
		private static const DEFAULT_CLUSTER_HOTSPOT_ALIGN_X : Number = 0.5;
		private static const DEFAULT_REST_HOTSPOT_ALIGN_X : Number = 0.5;
		private static const CLUSTER_HOTSPOT_GUTTER : uint = 2;
		private static const DOUBLE_COLUMN_CHORD_FACTOR : Number = 1.7;
		private static const DOUBLE_COLUMN_X_ALIGN_FACTOR : Number = 0.2;
		private static const DOWN_STEM_DOUBLE_COL_CLUSTER_OFFSET : int = -8;

		/**
		 * The root node in the data model is the Project, which always has a UID of "-1".
		 */
		private static const PROJECT_UID : String = '-1';
		
		private static var _allDurations : Array = null;
		private static function get ALL_DURATIONS () : Array {
			if (!_allDurations) {
				_allDurations = ConstantUtils.getAllValues (DurationFractions);
				_allDurations.sort (Fraction.compare);
				_allDurations.reverse();
				_allDurations = _allDurations.map (function (fraction : Fraction, ...etc) : String { return fraction.toString() });
			}
			return _allDurations;
		}
		
		private static const REST_SYMBOLS:Array=['#r1' /* whole */, '#r2' /* half */, '#r4' /* quarter and below */, '#r8', '#r16', '#r32', '#r64', '#r128'];
		private static const REST_SYMBOL_SIZES:Object = {
			'#r1': {w: 7, h: 3},
			'#r2': {w: 7, h: 3},
			'#r4': {w: 5, h: 16},
			'#r8': {w: 6, h: 10},
			'#r16': {w: 8, h: 16},
			'#r32': {w: 9, h: 21},
			'#r64': {w: 11, h: 27}
		};
		private static const STAFF_D_PATTERN:RegExp=/^(m\d{1,4}\.\d{2}\s+\d{1,4}\.\d{2}\s+h\d{1,4}\.\d{2}\s{0,2}){5}$/i;
		private static const SVG_HORIZ_LINE_PATTERN:RegExp=/h(\d{1,4}\.\d{2})/;
		private static const SVG_MOVE_PATTERN:RegExp=/m(\d{1,4}\.\d{2})\s{1,}(\d{1,4}\.\d{2})/ig;
		private static const SVG_SCALE_TEMPLATE:String='scale(%s)';
		private static const SVG_TRANSLATE_TEMPLATE:String='translate(%s,%s)';

		/**
		 * Graphic of button to be overlaid on measure hotspots, the "down" state of the button. The button
		 * will set a measure's hotspot target to the "measure" node (rather than a voice child).
		 */
		private static const TARGET_MEASURE_DOWN:XML=<g> <path fill="white" d="M89.5,127.4c-4.1,0-8.2-1.6-11-4.4l-22-21.9H27.4c-13,0-23.6-10.5-23.6-23.6V24.6c0-13,10.5-23.6,23.6-23.6 H104c13,0,23.6,10.5,23.6,23.6v52.8c0,13-10.5,23.5-23.5,23.6l0.9,9.1c0.7,6.6-2.9,12.9-8.8,15.7C94.1,126.8,91.9,127.4,89.5,127.4 z"/> <path d="M103.9,12.7c6.6,0,11.9,5.4,11.9,11.9v52.8c0,6.6-5.4,11.9-11.9,11.9H91l2.2,22c0.1,1.6-0.8,3.3-2.2,4 c-1.4,0.7-3.4,0.4-4.4-0.7L61.3,89.3H27.4c-6.6,0-11.9-5.4-11.9-11.9V24.6c0-6.6,5.4-11.9,11.9-11.9h76.5V12.7z"/> <path fill="white" d="M45.2,25.3h9.4l11.7,35.2L78,25.3h9.4l8.4,50.4h-9.2l-5.4-31.8L70.4,75.7H62L51.4,43.9l-5.5,31.8h-9.4 L45.2,25.3z"/> </g>;

		/**
		 * Graphic of button to be overlaid on measure hotspots, the "up" state of the button. The button
		 * will set a measure's hotspot target to the "measure" node (rather than a voice child).
		 */
		private static const TARGET_MEASURE_UP:XML=<g> <path fill="white" d="M89.5,127.4c-4.1,0-8.2-1.6-11-4.4l-22-21.9H27.4c-13,0-23.6-10.5-23.6-23.6V24.6c0-13,10.5-23.6,23.6-23.6 H104c13,0,23.6,10.5,23.6,23.6v52.8c0,13-10.5,23.5-23.5,23.6l0.9,9.1c0.7,6.6-2.9,12.9-8.8,15.7C94.1,126.8,91.9,127.4,89.5,127.4 z"/> <path d="M95.8,29.4c5.6,0,10.2,4.6,10.2,10.2v45.1c0,5.6-4.6,10.2-10.2,10.2h-11l1.9,18.8c0.1,1.4-0.7,2.8-1.9,3.4 c-1.2,0.6-2.9,0.3-3.8-0.6L59.4,94.8h-29c-5.6,0-10.2-4.6-10.2-10.2V39.5c0-5.6,4.6-10.2,10.2-10.2h65.4V29.4z"/> <path fill="white" d="M45.6,40.1h8l10,30.1l10.1-30.1h8l7.2,43.1H81L76.4,56l-9.2,27.2H60L50.9,56l-4.7,27.2h-8L45.6,40.1z"/> </g>;

		/**
		 * Graphic of button to be overlaid on measure hotspots, the "down" state of the button. The button
		 * will set a measure's hotspot target to the "voice one" of the respective staff.
		 */
		private static const TARGET_VOICE_ONE_DOWN:XML=<g> <path fill="white" d="M28.4,127.5c-10,0-17.5-6.6-17.9-15.8l0-0.3l0-0.3c0-4.1,1.5-8.1,4.2-11.2l0.1-0.2C9.3,92.1,5.6,83.4,3.9,73.9 C-2,40.6,21.3,7.3,54.9,1.3c3.5-0.6,7.2-1,10.8-1c0.9,0,1.9,0,2.8,0.1l0.1,0c23.9,1.4,44.8,15.8,54.5,37.7l0.1,0.3 c9.1,22.2,5.1,47.3-10.6,65.6l-0.2,0.2c-12,13.5-29.3,21.2-47.4,21.2c0,0,0,0,0,0c-5.4,0-10.7-0.7-15.9-2 C42.5,126.1,35.6,127.5,28.4,127.5L28.4,127.5L28.4,127.5z"/> <path d="M112.4,42.9c-7.9-17.8-25.1-29.7-44.5-30.8c-3.7-0.2-7.4,0.1-11,0.7c-27.3,4.9-46.4,32-41.6,59.1 c1.9,10.5,6.9,20.1,14.5,27.5l-6.2,7.9c-1,1-1.5,2.4-1.5,3.9c0.1,2.8,2.7,4.7,6.3,4.7l0,0c5.8,0,11.5-1.2,16.8-3.5l0.4-0.2 c0.8-0.4,1.6-0.7,2.4-0.8c1.1,0,2.3,0.2,3.3,0.6l0.5,0.1c18.8,4.9,38.9-1.1,51.9-15.6C116.5,81.6,119.9,60.9,112.4,42.9z"/> <path fill="white" d="M56.6,35h16.8v58.9H62.2V45.5H50.1L56.6,35z"/> </g>;

		/**
		 * Graphic of button to be overlaid on measure hotspots, the "up" state of the button. The button
		 * will set a measure's hotspot target to the "voice one" of the respective staff.
		 */
		private static const TARGET_VOICE_ONE_UP:XML=<g> <path fill="white" d="M28.4,127.5c-10,0-17.5-6.6-17.9-15.8l0-0.3l0-0.3c0-4.1,1.5-8.1,4.2-11.2l0.1-0.2C9.3,92.1,5.6,83.4,3.9,73.9 C-2,40.6,21.3,7.3,54.9,1.3c3.5-0.6,7.2-1,10.8-1c0.9,0,1.9,0,2.8,0.1l0.1,0c23.9,1.4,44.8,15.8,54.5,37.7l0.1,0.3 c9.1,22.2,5.1,47.3-10.6,65.6l-0.2,0.2c-12,13.5-29.3,21.2-47.4,21.2c0,0,0,0,0,0c-5.4,0-10.7-0.7-15.9-2 C42.5,126.1,35.6,127.5,28.4,127.5L28.4,127.5L28.4,127.5z"/> <path d="M103.8,54.7C97,39.3,82.2,29.1,65.5,28.1c-3.2-0.1-6.3,0.1-9.5,0.6c-23.5,4.2-39.9,27.5-35.8,50.9c1.6,9,6,17.3,12.5,23.7 l-5.4,6.8c-0.8,0.9-1.3,2.1-1.3,3.3c0.1,2.4,2.3,4,5.4,4l0,0c5,0,9.9-1.1,14.5-3l0.4-0.2c0.7-0.3,1.4-0.6,2.1-0.7 c1,0,1.9,0.2,2.9,0.5l0.4,0.1c16.2,4.2,33.5-0.9,44.6-13.4C107.3,88,110.2,70.2,103.8,54.7z"/> <path fill="white" class="st0" d="M55.7,47.8h14.4v50.7h-9.6V56.9H50.1L55.7,47.8z"/> </g>;

		/**
		 * Graphic of button to be overlaid on measure hotspots, the "down" state of the button. The button
		 * will set a measure's hotspot target to the "voice two" of the respective staff (provided there is a
		 * voice two, otherwise, the button will not be visible).
		 */
		private static const TARGET_VOICE_TWO_DOWN:XML=<g> <path fill="white" d="M28,127.5c-10,0-17.6-6.6-17.9-15.8v-0.3V111c0-4.2,1.5-8.2,4.3-11.3l0.1-0.1C8.9,91.9,5.1,83.1,3.5,73.7 C-2.4,40.3,21,7,54.6,0.9C58.1,0.3,61.8,0,65.4,0c0.9,0,1.9,0,2.8,0.1h0.1C92.3,1.5,113.3,16,123,38l0.1,0.2 c9.2,22.2,5.1,47.5-10.6,65.7l-0.1,0.1c-12.1,13.5-29.3,21.2-47.5,21.2l0,0c-5.4,0-10.7-0.7-16-2.1C42,126.1,35.2,127.5,28,127.5 L28,127.5L28,127.5z"/> <path d="M112.1,42.7c-7.9-17.9-25.2-29.8-44.6-31c-3.7-0.1-7.3,0.1-11.1,0.7c-27.4,4.9-46.5,32-41.7,59.3 c1.9,10.5,7,20.1,14.6,27.6l-6.3,7.9c-0.9,1-1.5,2.4-1.5,3.8c0.1,2.8,2.7,4.7,6.3,4.7l0,0c5.8,0,11.5-1.3,16.9-3.5l0.5-0.2 c0.8-0.3,1.6-0.7,2.4-0.8c1.2,0,2.2,0.2,3.4,0.6l0.5,0.1c18.9,4.9,39-1,51.9-15.6C116.2,81.5,119.6,60.8,112.1,42.7z"/> <path fill="white" d="M57.4,49.7H46.2c0.3-6.5,2.3-11.6,6.1-15.3c3.8-3.7,8.6-5.6,14.6-5.6c3.7,0,6.9,0.8,9.7,2.3 c2.8,1.5,5,3.8,6.7,6.7c1.7,2.9,2.5,5.9,2.5,8.9c0,3.6-1,7.4-3.1,11.5c-2,4.1-5.8,9-11.2,14.6l-6.8,7.1h21.5v10.6H44.6V85l18.6-19 c4.5-4.6,7.5-8.2,9-11c1.5-2.8,2.2-5.3,2.2-7.5c0-2.3-0.8-4.2-2.3-5.8c-1.5-1.5-3.5-2.3-6-2.3c-2.5,0-4.5,0.9-6.1,2.7 C58.4,44.1,57.5,46.6,57.4,49.7z"/> </g>;

		/**
		 * Graphic of button to be overlaid on measure hotspots, the "up" state of the button. The button
		 * will set a measure's hotspot target to the "voice two" of the respective staff (provided there is a
		 * voice two, otherwise, the button will not be visible).
		 */
		private static const TARGET_VOICE_TWO_UP:XML=<g> <path fill="white" d="M28,127.5c-10,0-17.6-6.6-17.9-15.8v-0.3V111c0-4.2,1.5-8.2,4.3-11.3l0.1-0.1C8.9,91.9,5.1,83.1,3.5,73.7 C-2.4,40.3,21,7,54.6,0.9C58.1,0.3,61.8,0,65.4,0c0.9,0,1.9,0,2.8,0.1h0.1C92.3,1.5,113.3,16,123,38l0.1,0.2 c9.2,22.2,5.1,47.5-10.6,65.7l-0.1,0.1c-12.1,13.5-29.3,21.2-47.5,21.2l0,0c-5.4,0-10.7-0.7-16-2.1C42,126.1,35.2,127.5,28,127.5 L28,127.5L28,127.5z"/> <path d="M103.8,54.7C97,39.3,82.2,29.1,65.5,28.1c-3.2-0.1-6.3,0.1-9.5,0.6c-23.5,4.2-39.9,27.5-35.8,50.9c1.6,9,6,17.3,12.5,23.7 l-5.4,6.8c-0.8,0.9-1.3,2.1-1.3,3.3c0.1,2.4,2.3,4,5.4,4l0,0c5,0,9.9-1.1,14.5-3l0.4-0.2c0.7-0.3,1.4-0.6,2.1-0.7 c1,0,1.9,0.2,2.9,0.5l0.4,0.1c16.2,4.2,33.5-0.9,44.6-13.4C107.3,88,110.2,70.2,103.8,54.7z"/> <path fill="white" d="M56.8,60.7h-9.6c0.3-5.6,2-10,5.3-13.2c3.2-3.2,7.4-4.8,12.5-4.8c3.1,0,5.9,0.7,8.3,2 c2.4,1.3,4.3,3.2,5.8,5.7s2.2,5,2.2,7.6c0,3.1-0.9,6.4-2.6,9.9c-1.7,3.5-4.9,7.7-9.6,12.6l-5.8,6.1h18.4v9.1H45.8V91l16-16.3 c3.9-3.9,6.4-7.1,7.7-9.4c1.3-2.4,1.9-4.5,1.9-6.5c0-2-0.7-3.6-2-4.9s-3-2-5.1-2c-2.1,0-3.9,0.8-5.3,2.4 C57.6,55.9,56.9,58,56.8,60.7z"/> </g>;
		private static const TOOLBAR_BACKGROUND_STYLE:String='fill-opacity:0.0001';
		private static const TWO_LEVELS_DEEPER_SUFFIX : String = '_0_0';
		private static var _dummyPart : ProjectData;
		
		/**
		 * Returns a Part element surogate, used by the annotations processor in order to cope with
		 * the very special case of Part annotations.
		 * 
		 * Due to the complex nature of part representations in the score and in the data model, we
		 * cannot know to which Part in the data model a part label from the score should bind to, 
		 * not until the score has been rendered. Therefore, at this very early, pre-processing stage,
		 * we will give "something" to the code that expects each annotation to have a data model
		 * object it points to. The Parts are an exception, and this is how we deal with it.
		 */
		private static function get DUMMY_PART_ELEMENT () : ProjectData {
			if (!_dummyPart) {
				_dummyPart=new ProjectData;
				var dummyDetails:Object={};
				dummyDetails[DataFields.DATA_TYPE]=DataFields.PART;
				_dummyPart.populateWithDefaultData(dummyDetails);
			}
			return _dummyPart;
		}

		/**
		 * SvgPreProcessor: Walks the SVG tree generated by abcm2ps.exe and carries
		 * out actions that result in modifying the SVG elements before sending them
		 * to the renderer, or indexing them, in order to facilitate their mapping
		 * to the score's data model.
		 */
		public function SvgPreProcessor() {
			PTT.getPipe().subscribe(ViewKeys.SHORT_UID_INFO_READY, _onShortUidInfoReady);
		}

		private var _annotationsParent:XML;
		private var _bindingOrderedUids:Array=[];
		private var _bindings:Object={};
		private var _clefSvgElements:Array=[];
		private var _clefsLeftEdge:Number;
		private var _clefsRightEdge:Number;
		private var _hotspotsMap:Object={};
		private var _measureButtonsContainer:XML;
		private var _sectionLeads:Object={};
		private var _noteheadSvgElements:Array=[];
		private var _resolvedShortUidInfo:Object;
		private var _restSvgEntities:Array=[];
		private var _sectionAnnotationsQueue:Array;
		
		private var _splitAnnotationCounters : Object = {};
		private var _staffRectangles:Array;
		private var _staffSVGElements:Array=[];
		private var _svg:XML;
		private var _xlink:Namespace;

		/**
		 * Processes the provided SVG document, by carying out a number of operations on
		 * it. The modified SVG can be obtained via the "svg" accessor.
		 *
		 * @see "__executeLocalOperations()"
		 */
		public function process():void {
			// "Local operations" are functions that operate against each SVG element
			// in the document
			var localOperations:Array=[
				_forceMonochrome,
				_collectStaves,
				_collectClefs,
				_processAnnotations,
				_collectNoteHeads,
				_collectRests
			];

			// "Global operations" are functions that operate against the SVG document,
			// as a whole
			var globalOperations:Array=[
				_purgeSVG, 
				_patchScheduledSectionAnnotations, 
				_bindNoteheads, 
				_addHotSpots, 
				_addMeasureButtons, 
				_makeGhostRestsTransparent
			];

			_svg=_executeLocalOperations.apply(this, ([_svg]).concat(localOperations));
			_svg=_executeGlobalOperations.apply(this, ([_svg]).concat(globalOperations));
		}

		/**
		 * Invoked externally to obtain the SVG document in its current form. Most usefull
		 * if called after "process()".
		 * @return
		 */
		public function get svg():XML {
			return _svg;
		}

		/**
		 * Invoked externally to pass-in the SVG document to process
		 * @param value
		 */
		public function set svg(value:XML):void {
			_svg=value;
			_reset();
			_xlink=_svg.namespace('xlink');
		}

		/**
		 * Custom compare function, intended to sort the list of Note children of a Cluster
		 * by their musical pitch (or reversed MIDI pitch, since lower pitched notes have lower
		 * MIDI pitch values).
		 *
		 * See also the notes for the `_bindNoteheads()` method.
		 */
		private function __note_elements_by_reverse_midi_pitch(noteA:ProjectData, noteB:ProjectData):int {
			var aMidi:uint=MusicUtils.noteToMidiNumber(noteA);
			var bMidi:uint=MusicUtils.noteToMidiNumber(noteB);
			return (bMidi - aMidi);
		}

		/**
		 * Custom compare function, intended to sort the list of collected noteheads so that they
		 * are ordered by the top most, and then by the left most. This is thought to minimize the
		 * iterations needed for correctly matching the noteheads to their "home" Cluster boundaries.
		 *
		 * See also the notes for the `_bindNoteheads()` method.
		 */
		private function __notehead_elements_by_y_then_x (noteDataA:Object, noteDataB:Object):int {
			
			var noteheadA : XML = noteDataA.notehead as XML;
			var noteheadB : XML = noteDataB.notehead as XML;
			
			var aX:Number=parseFloat(noteheadA.@x);
			var aY:Number=parseFloat(noteheadA.@y);

			var bX:Number=parseFloat(noteheadB.@x);
			var bY:Number=parseFloat(noteheadB.@y);

			var xDelta:int=Math.round(aX - bX) as int;
			var yDelta:int=Math.round(aY - bY) as int;

			return (yDelta || xDelta);
		}
		
		/**
		 * Keeps track of how many separate SVG elements there are for split annotations
		 * (e.g., a single Part object is denoted by several annotated elements in the 
		 * score).
		 * 
		 * See the NOTES for the '_provideBinding()' method for a detailed explanation. 
		 */
		private function _acknowledgeSplitAnnotationFor (splitUid : String) : void {
			if (!(splitUid in _splitAnnotationCounters)) {
				_splitAnnotationCounters[splitUid] = -1;
			}
			_splitAnnotationCounters[splitUid]++;
		}

		/**
		 * Builds the clickable areas as SVG rectangles. Their boundaries are defined by the annotations'
		 * coordinates. Their ID attribute is the UID of an element they represent in the data model.
		 */
		private function _addHotSpots(... args):void {

			if (_annotationsParent != null) {
				_annotationsParent['@class']=SvgEntities.ANNOTATIONS_PARENT;

				// The structure of the SVG files the underlying, "abcm2ps.exe"
				// renderer generates is chaotical for any practical purpose, so
				// we cannot rely on any existing SVG node for placing our 
				// hotspots there. If we do, they will most likely be covered by
				// notes and rests, rendering them unusable.
				// Therefore, we take a valid container, clone it, strip it off 
				// from any children it may have, add hotspot nodes there, then
				// add the clone as the last child of the container's parent. 

				var hotspotsContainer:XML=_annotationsParent.copy();
				delete hotspotsContainer.*;
				hotspotsContainer['@class']=SvgEntities.HOTSPOTS_CONTANER;
				var hotspotsContainerParent:XML=_annotationsParent.parent();

				var uid:String=null;
				var binding:HotspotBindingModel=null;
				var rectangles:Array=null;
				var rectangle:Rectangle=null;
				var rectEl:XML=null;
				var fillColor:String=CommonStrings.HASH.concat(ColorUtils.toHexNotation(Colors.HOTSPOT_SELECTION_PRIMARY));
				var strokeColor:String=CommonStrings.HASH.concat(ColorUtils.toHexNotation(Colors.HOTSPOT_SELECTION_SECONDARY));
				var i:int=0;
				var numBindings:uint=_bindingOrderedUids.length;
				var j:int=0;
				var numRectangles:uint;
				var classNames:Array;
				var indexProxy:Object;
				var element:ProjectData;
				for (i; i < numBindings; i++) {
					uid=(_bindingOrderedUids[i] as String);
					binding=(_bindings[uid] as HotspotBindingModel);
					classNames=[SvgEntities.HOTSPOT_CLASS];
					element=binding.element;
					
					// Special case: measure hotspots
					if (ModelUtils.isMeasure(element)) {
						classNames.push(SvgEntities.MEASURE);
						indexProxy=new StaffIndexProxy;
						classNames.push(indexProxy);
					}
					
					// Special case: part hotspots
					if (ModelUtils.isPart(element)) {
						classNames.push(SvgEntities.PART);
					}
					
					// Special case: cluster hotspots
					if (ModelUtils.isCluster(element)) {
						if (binding.haveStemInfo && binding.isDoubleColumnCluster) {
							if (binding.stemDirection == StemDirection.DOWN) {
								binding.boundingBox.x += DOWN_STEM_DOUBLE_COL_CLUSTER_OFFSET;
							}
						}
					}
					
					rectangles=binding.adjustedBoundingBoxes || [binding.boundingBox];
					numRectangles=rectangles.length;
					for (j=0; j < numRectangles; j++) {
						rectangle=rectangles[j] as Rectangle;
						rectEl=new XML('<rect/>');
						rectEl.@x=rectangle.x.toFixed(2);
						rectEl.@y=rectangle.y.toFixed(2);
						rectEl.@width=rectangle.width.toFixed(2);
						rectEl.@height=rectangle.height.toFixed(2);
						if (indexProxy) {
							indexProxy.value=j + 1;
						}
						rectEl['@class']=classNames.join(CommonStrings.SPACE);
						rectEl.@id=binding.elementUID;
						rectEl.@fill=fillColor;
						rectEl.@stroke=strokeColor;
						rectEl.@rx=2;
						rectEl.@ry=2;
						rectEl.@style=HOTSPOT_STYLE;
						hotspotsContainer.appendChild(rectEl);
						if (!_hotspotsMap[uid]) {
							_hotspotsMap[uid]=[];
						}
						(_hotspotsMap[uid] as Array).push(rectEl);
					}
				}

				hotspotsContainerParent.appendChild(hotspotsContainer);
			}
		}

		/**
		 * Builds the buttons used for re-targeting a measure's hotspot (so that clicking on
		 * that hotspot will, in fact, connect to one of the measure's "voice" children, when
		 * needed). Caches the resulting SVG in-memory for the life-span of the class.
		 */
		private function _addMeasureButtons(svg:XML):void {
			if (_annotationsParent != null) {
				if (!_measureButtonsContainer) {

					_measureButtonsContainer=_annotationsParent.copy();
					delete _measureButtonsContainer.*;
					_measureButtonsContainer.@id=SvgEntities.MEASURE_BUTTONS_CONTAINER;
					_measureButtonsContainer.@display='none';

					// This is needed to globally catch mouse events such as "mouse over" and "mouse out"
					var background:XML=new XML('<rect/>');
					var bgGap:Number=Sizes.SVG_BUTTON_GAP_PERCENT * Sizes.IN_SCORE_BUTTONS_SIZE;
					var bgNegativeGap:Number=(bgGap * -1);
					background.@x=bgNegativeGap;
					background.@y=bgNegativeGap;
					background.@width=3 * Sizes.IN_SCORE_BUTTONS_SIZE + 3 * bgGap;
					background.@height=Sizes.IN_SCORE_BUTTONS_SIZE + bgGap;
					background.@style=TOOLBAR_BACKGROUND_STYLE;
					_measureButtonsContainer.appendChild(background);

					var svgButtonRatio:Number=Sizes.IN_SCORE_BUTTONS_SIZE / Sizes.SVG_BUTTON_DEFAULT_SIZE;

					// Button 1: Sets selection target to the measure node (always shown)
					var targetMeasureBtn:XML=<g/>;
					targetMeasureBtn.@id=SvgEntities.TARGET_MEASURE_BUTTON;
					targetMeasureBtn.@transform=Strings.sprintf(SVG_SCALE_TEMPLATE, svgButtonRatio);
					TARGET_MEASURE_UP.@display='block';
					TARGET_MEASURE_UP['@class']=MeasureSelectionKeys.UP;
					targetMeasureBtn.appendChild(TARGET_MEASURE_UP);
					TARGET_MEASURE_DOWN.@display='none';
					TARGET_MEASURE_DOWN['@class']=MeasureSelectionKeys.DOWN;
					targetMeasureBtn.appendChild(TARGET_MEASURE_DOWN);
					_measureButtonsContainer.appendChild(targetMeasureBtn);

					// Button 2: Sets selection target to the "voice one" node (always shown)
					var targetVoiceOneBtn:XML=<g/>;
					targetVoiceOneBtn.@id=SvgEntities.TARGET_VOICE_ONE_BUTTON;
					var xTranslate:Number=Sizes.SVG_BUTTON_DEFAULT_SIZE + Sizes.SVG_BUTTON_DEFAULT_SIZE * Sizes.SVG_BUTTON_GAP_PERCENT;
					targetVoiceOneBtn.@transform=[Strings.sprintf(SVG_SCALE_TEMPLATE, svgButtonRatio), Strings.sprintf(SVG_TRANSLATE_TEMPLATE, xTranslate, 0)].join(CommonStrings.SPACE);
					TARGET_VOICE_ONE_UP.@display='block';
					TARGET_VOICE_ONE_UP['@class']=MeasureSelectionKeys.UP;
					targetVoiceOneBtn.appendChild(TARGET_VOICE_ONE_UP);
					TARGET_VOICE_ONE_DOWN.@display='none';
					TARGET_VOICE_ONE_DOWN['@class']=MeasureSelectionKeys.DOWN;
					targetVoiceOneBtn.appendChild(TARGET_VOICE_ONE_DOWN);
					_measureButtonsContainer.appendChild(targetVoiceOneBtn);

					// Button 3: Sets selection target to the "voice two" node (only shown when current measure has a voice 2)
					var targetVoiceTwoBtn:XML=<g display="none"/>;
					targetVoiceTwoBtn.@id=SvgEntities.TARGET_VOICE_TWO_BUTTON;
					xTranslate=(Sizes.SVG_BUTTON_DEFAULT_SIZE + Sizes.SVG_BUTTON_DEFAULT_SIZE * Sizes.SVG_BUTTON_GAP_PERCENT) * 2;
					targetVoiceTwoBtn.@transform=[Strings.sprintf(SVG_SCALE_TEMPLATE, svgButtonRatio), Strings.sprintf(SVG_TRANSLATE_TEMPLATE, xTranslate, 0)].join(CommonStrings.SPACE);
					TARGET_VOICE_TWO_UP.@display='block';
					TARGET_VOICE_TWO_UP['@class']=MeasureSelectionKeys.UP;
					targetVoiceTwoBtn.appendChild(TARGET_VOICE_TWO_UP);
					TARGET_VOICE_TWO_DOWN.@display='none';
					TARGET_VOICE_TWO_DOWN['@class']=MeasureSelectionKeys.DOWN;
					targetVoiceTwoBtn.appendChild(TARGET_VOICE_TWO_DOWN);
					_measureButtonsContainer.appendChild(targetVoiceTwoBtn);

					// Button 4: Adds voice two (only shown when current measure is missing a second voice, and the 
					// parent part supports two voices)
					var addVoiceTwoBtn:XML=<g display="none"/>;
					addVoiceTwoBtn.@id=SvgEntities.ADD_VOICE_TWO_BUTTON;
					addVoiceTwoBtn.@transform=[Strings.sprintf(SVG_SCALE_TEMPLATE, svgButtonRatio), Strings.sprintf(SVG_TRANSLATE_TEMPLATE, xTranslate, 0)].join(CommonStrings.SPACE);
					ADD_VOICE_UP.@display='block';
					ADD_VOICE_UP['@class']=MeasureSelectionKeys.UP;
					addVoiceTwoBtn.appendChild(ADD_VOICE_UP);
					ADD_VOICE_DOWN.@display='none';
					ADD_VOICE_DOWN['@class']=MeasureSelectionKeys.DOWN;
					addVoiceTwoBtn.appendChild(ADD_VOICE_DOWN);
					_measureButtonsContainer.appendChild(addVoiceTwoBtn);

					// Enforce score colors on the toolbar buttons
					_executeLocalOperations(_measureButtonsContainer, _forceMonochrome);
				}

				var containerParent:XML=_annotationsParent.parent();
				containerParent.appendChild(_measureButtonsContainer);
			}
		}

		/**
		 * Produces bindings between each of the noteheads drawn in the musical score
		 * and their respective equivalent Note objects in the data model.
		 *
		 * Due to the peculiar nature of the underlying `abcm2ps.exe` rendering engine,
		 * our only solution is to compare each SVG element bounding box and y position
		 * against already detected Cluster element's bounding boxes.
		 *
		 * Also, we cannot do this in one go, while walking the SVG tree (it would have
		 * saved some CPU cycles, but no luck).
		 */
		private function _bindNoteheads(svg:XML):void {

			if (_noteheadSvgElements.length == 0) {
				return;
			}

			// Sort the noteheads by their Y and X; presumably, this will cause fewer iterations
			// when trying to match them to the known Clusters bounding boxes
			_noteheadSvgElements.sort(__notehead_elements_by_y_then_x);

			// Notehead related variables
			var noteheadsCollection:ArrayCollection=new ArrayCollection(_noteheadSvgElements);
			var noteheadsIterator:IViewCursor=null;
			var numMatchedNoteheads:uint=0;
			var currNoteheadData:Object = null;
			var currNotehead:XML=null;
			var currNoteheadCenterX:Number=NaN;
			var currNoteheadCenterY:Number=NaN;
			var currNoteheadType:String=null;
			var currNoteheadTypeRadiusX:Number=NaN;
			var currNoteheadTypeRadiusY:Number=NaN;
			var currNoteheadTypeLeft:Number=NaN;
			var currNoteheadTypeRight:Number=NaN;
			var currNoteheadTypeTop:Number=NaN;
			var currNoteheadTypeBottom:Number=NaN;
			var currNoteheadBinding:HotspotBindingModel=null;
			var currNoteheadBindingUid:String=null;
			var currNoteheadBindingElement:ProjectData=null;

			// Existing bindings related variables
			var binding:HotspotBindingModel=null;
			var bindingElement:ProjectData=null;
			var bindingRect:Rectangle=null;

			// Cluster elements related variables
			var clusterNotes:Array=null;
			var numClusterNotes:uint=0;

			// Iteration related variables
			var uid:String=null;
			var i:int=0;
			var numBindings:uint=_bindingOrderedUids.length;

			for (i; i < numBindings; i++) {

				// We iterate through all existing bindings, and only retain those that 
				// relate to Cluster elements
				uid=(_bindingOrderedUids[i] as String);
				binding=(_bindings[uid] as HotspotBindingModel);
				bindingElement=binding.element;
				if (ModelUtils.isCluster(bindingElement)) {

					// Get a hold of the clusters bounding box (this was previously determined, 
					// via abc annotations. Too bad annotations only work for notes, not 
					// individual noteheads. We sort the Note children of the Cluster by 
					// their reverse MIDI pitch in order to match them to our notehead graphics
					// which were already sorted by their vertical placement on the page).
					bindingRect=binding.boundingBox;
					clusterNotes=ModelUtils.getChildrenOfType(bindingElement, DataFields.NOTE);
					numClusterNotes=clusterNotes.length;
					clusterNotes.sort(__note_elements_by_reverse_midi_pitch);
					numMatchedNoteheads=0;

					// We iterate through all the notehead graphics
					noteheadsIterator=noteheadsCollection.createCursor();
					while (!noteheadsIterator.afterLast) {
						currNoteheadData=(noteheadsIterator.current as Object);
						currNotehead=currNoteheadData.notehead as XML;
						currNoteheadCenterX=parseFloat(currNotehead.@x);
						currNoteheadCenterY=parseFloat(currNotehead.@y);
						if (bindingRect.contains(currNoteheadCenterX, currNoteheadCenterY)) {
							
							// Side effect: commit information about stem atitude and size, if available
							binding.haveStemInfo = currNoteheadData.haveStemInfo;
							binding.stemDirection = currNoteheadData.stemDirection;

							// Count the match
							numMatchedNoteheads++;

							// Provide data for a hotspot to be created, that overlays this notehead and
							// links to the correct Note element in the data model
							currNoteheadType=currNotehead.@_xlink::href.toString();
							currNoteheadTypeRadiusX=(NOTEHEAD_SYMBOL_SIZES[currNoteheadType].w as Number) * 0.5;
							currNoteheadTypeRadiusY=(NOTEHEAD_SYMBOL_SIZES[currNoteheadType].h as Number) * 0.5;
							currNoteheadTypeLeft=(currNoteheadCenterX - currNoteheadTypeRadiusX);
							currNoteheadTypeRight=(currNoteheadCenterX + currNoteheadTypeRadiusX);
							currNoteheadTypeTop=(currNoteheadCenterY - currNoteheadTypeRadiusY);
							currNoteheadTypeBottom=(currNoteheadCenterY + currNoteheadTypeRadiusY);
							currNoteheadBindingElement=(clusterNotes[numMatchedNoteheads - 1] as ProjectData);

							// We'd rather have an inaccessible notehead than a program crash..
							if (currNoteheadBindingElement) {
								currNoteheadBindingUid=currNoteheadBindingElement.route;
								currNoteheadBinding=_provideBinding(currNoteheadBindingUid);
								currNoteheadBinding.element=currNoteheadBindingElement;
								currNoteheadBinding.addBoundariesPoint(new Point(currNoteheadTypeLeft, currNoteheadTypeTop));
								currNoteheadBinding.addBoundariesPoint(new Point(currNoteheadTypeRight, currNoteheadTypeBottom));
							}

							// Remove the match, so that we don't have to iterate over it again
							noteheadsIterator.remove();
						} else {

							// We only skip to the next notehead if there was no match; otherwise, the mere fact
							// that we removed the matching notehead moves the cursor to the next available notehead.
							noteheadsIterator.moveNext();
						}

						// Exit the loop if we matched as many hoteheads as there are Note elements in the Cluster
						if (numMatchedNoteheads == numClusterNotes) {
							break;
						}
					}
				}
			}
		}

		private function _collectClefs(element:XML):void {
			if (element.localName() == SvgEntities.USE) {
				var useSrc:String=element.@_xlink::href.toString();
				if (CLEF_SYMBOLS.indexOf(useSrc) >= 0) {
					_clefSvgElements.push(element);
					// Clefs are horizontally anchored to their center
					var x:Number=parseInt(element.@x);
					var radius:Number=_getWidestClef() * 0.5;
					if (!_clefsRightEdge) {
						_clefsRightEdge=x + radius;
					}
					if (!_clefsLeftEdge) {
						_clefsLeftEdge=x - radius;
					}
				}
			}
		}

		/**
		 * Collects all SVG nodes of type `<use />` that point to a symbol with an id of "hd"
		 * (or variations). These are notehead representations, and will be bound to Note data
		 * model objects in a later stage.
		 * 
		 * Wherever possible, we collect information about the stem next to the (first) notehead
		 * in a note (or chord); especially of interest is whether the stem goes up or down,
		 * and what length it is. We use this information to fine tune the resulting hotspot
		 * for the containing Cluster element.
		 */
		private function _collectNoteHeads(element:XML):void {
			if (element.localName() == SvgEntities.USE) {
				var useSrc:String=element.@_xlink::href.toString();
				if (NOTEHEAD_SYMBOLS.indexOf(useSrc) >= 0) {
					var noteheadData : Object = {notehead: element};
					var testSibling : XML = element.parent().children()[ element.childIndex() + 1 ] as XML;
					
					// There can be intervening accidentals between the primary notehead and its stem
//					if (testSibling && testSibling.localName() == SvgEntities.DEFS) {
//						var testSibling2 : XML = element.parent().children()[ element.childIndex() + 2 ] as XML;
//						if (testSibling2 && testSibling2.localName() == SvgEntities.USE) {
//							var testUSeSrc:String=element.@_xlink::href.toString();
//							if (testUSeSrc = SvgEntities.SHARP_ID) {
//								testSibling = element.parent().children()[ element.childIndex() + 3 ] as XML;
//							}
//						}
//					}
					
					if (testSibling && 
						testSibling.localName() == SvgEntities.PATH &&
						!testSibling.hasOwnProperty(SvgEntities.STROKE_WIDTH) &&
						testSibling.hasOwnProperty('@class') && 
						testSibling['@class'] == SvgEntities.STROKE) {
						var pathDescriptor : String = testSibling.@d;
						var commands : Array = pathDescriptor.split(SvgEntities.VERTICAL_LINE_RELATIVE);
						var stemLength : Number = parseFloat (commands.pop());
						if (!isNaN (stemLength)) {
							noteheadData.haveStemInfo = true;
							noteheadData.stemDirection = (stemLength > 0)? StemDirection.DOWN : StemDirection.UP;
						}
					}
					_noteheadSvgElements.push(noteheadData);
				}
			}
		}

		/**
		 * TO DO: document
		 */
		private function _collectRelatedDots(restAnchor:XML):Array {
			// TODO: implement
			return [];
		}

		/**
		 * Collects all SVG nodes of type `<use />` that point to a symbol with an id of
		 * "r1" through "r128". These are rest representations, part of which are "ghost" rests,
		 * i.e., rests that were automatically added by the renderer to fill underfull measures.
		 * We want to draw ghost rests in a lighter shade/alpha, and in order to do that we first
		 * need to collect all of them (we will decide at a later stage which ones are ghosts, and
		 * which aren't).
		 *
		 * This produces and Array of Objects having each three properties:
		 * - fraction: the musical duration the intrinsic SVG graphics represent;
		 * - elements: the SVG elements that comprise a "rest entity", applicable for dotted rests;
		 * - bounds: an aproximation of the area the "entity" occupies on the screen.
		 */
		private function _collectRests(element:XML):void {
			if (element.localName() == SvgEntities.USE) {
				var useSrc:String=element.@_xlink::href.toString();
				var restIndex:int=REST_SYMBOLS.indexOf(useSrc);
				if (restIndex >= 0) {
					var relatedDots:Array=_collectRelatedDots(element);
					var fraction:Fraction= Fraction.fromString (ALL_DURATIONS[restIndex]);
					if (relatedDots.length > 0) {
						var durationToAdd:Fraction=fraction;
						for (var i:int=relatedDots.length; i > 0; i--) {
							durationToAdd=durationToAdd.divide(DurationFractions.HALF) as Fraction;
							fraction=fraction.add(durationToAdd) as Fraction;
						}
					}
					var elements:Array=[element].concat(_collectRelatedDots(element));
					var elBounds:Rectangle=new Rectangle;
					var j:int=0;
					var numEl:uint=elements.length;
					var el:XML=null;
					var x:int=0;
					var y:int=0;
					var rx:int=0;
					var ry:int=0;
					var restSize : Object;
					var w : Number;
					var h : Number;
					for (j; j < numEl; j++) {
						
						// Rest SVG elements are anchored in their middle, and have each fixed sizes, which are
						// known beforehand
						restSize = REST_SYMBOL_SIZES[useSrc] as Object;
						if (restSize) {
							w = restSize.w;
							elBounds.width = w;
							h = restSize.h;
						}
						elBounds.height = h;
						el=(elements[j] as XML);
						x=parseInt(el.@x);
						y=parseInt(el.@y);
						elBounds.x = (x - w * 0.5);
						elBounds.y = (y - h * 0.5);
						
						// Dots are defined as circles, therefore have `rx` anf `ry` attributes
						if (el.hasOwnProperty('@rx') && el.hasOwnProperty('@rx')) {
							rx=parseInt(el.@rx);
							ry=parseInt(el.@ry);
							Geometry.inflateRectToPoint(elBounds, new Point(x - rx, y - ry));
							Geometry.inflateRectToPoint(elBounds, new Point(x + rx, y + ry));
						}
					}
					_restSvgEntities.push({fraction: fraction, elements: elements, bounds: elBounds});
				}
			}
		}

		/**
		 * Collects all SVG Paths that are used to draw staves. These will be used to refine
		 * the hotspots for measures.
		 */
		private function _collectStaves(element:XML):void {
			if (element.localName() == PATH) {
				if (element.hasOwnProperty("@d")) {
					var dAttribute:String=Strings.removeNewLines(Strings.trim(element.@d.toString()));
					if (STAFF_D_PATTERN.test(dAttribute)) {
						_staffSVGElements.push(element);
						_staffRectangles.push(_getStaffRectangle(dAttribute));
					}
				}
			}
		}

		/**
		 * Executes given operations in given order on the SVG document, as a whole.
		 *
		 * @param 	svg
		 * 			An XML structure.
		 *
		 * @param	operations
		 * 			An array of functions; each receives the SVG document as their lone
		 * 			argument. You CAN execute deletions from one of these functions.
		 *
		 * @return	The given XML structure with any modifications that might have
		 * 			occured.
		 */
		private function _executeGlobalOperations(svg:XML, ... operations):XML {
			var i:int=0;
			var operation:Function;
			var numOperations:uint=operations.length;
			for (i=0; i < numOperations; i++) {
				operation=(operations[i] as Function);
				operation(svg);
			}
			return svg;
		}

		/**
		 * Executes given operations in given order on each descendant of the given XML.
		 *
		 * @param 	svg
		 * 			An XML structure.
		 *
		 * @param	operations
		 * 			An array of functions; each receives the current XML element as the
		 * 			first argument. DO NOT execute any deletions from any of those
		 * 			functions. Instead, mark elements (changing either their id or class),
		 * 			and remove them AFTER "__executeLocalOperations" has returned.
		 *
		 * @return	The given XML structure with any modifications that might have occured.
		 */
		private function _executeLocalOperations(svg:XML, ... operations):XML {
			var i:int=0;
			var operation:Function;
			var numOperations:uint=operations.length;
			var j:int=0;
			var descendantNode:XML;
			var rootNodes:XMLList=(svg.*::* as XMLList);
			var descendantNodes:XMLList=rootNodes.descendants();
			var numDescendantNodes:int=descendantNodes.length();
			for (i=0; i < numOperations; i++) {
				operation=(operations[i] as Function);
				for (j=0; j < numDescendantNodes; j++) {
					descendantNode=(descendantNodes[j] as XML);
					operation(descendantNode);
				}
			}
			return svg;
		}

		/**
		 * Forces the color and fill of all elements to be in a certain color
		 * @param	element
		 * 			This function receives, in turn, each XML element in the document
		 * 			tree.
		 */
		private function _forceMonochrome(element:XML):void {
			var foregroundColor:String=CommonStrings.HASH.concat(ColorUtils.toHexNotation(Colors.SCORE_FOREGROUND));
			var backgroundColor:String=CommonStrings.HASH.concat(ColorUtils.toHexNotation(Colors.SCORE_BACKGROUND));

			// Turn all strokes to foreground color
			if (element.hasOwnProperty('@stroke')) {
				element.@stroke=foregroundColor;
			}

			// Turn all texts to foreground color
			if (element.localName() == SvgEntities.TEXT) {
				element.@fill=foregroundColor;
			}

			// Turn all fills to "foreground color", unless they were initially set to
			// (1) "white", in which case, we switch them to background color or
			// (2) "none", in which case we leave them alone
			if (element.hasOwnProperty('@fill')) {
				if (element.@fill != "none") {
					element.@fill=(element.@fill == "white") ? backgroundColor : foregroundColor;
				}
			}
		}

		/**
		 * Collects the actual rectangles the drawn staves occupy on the graphical score
		 */
		private function _getStaffRectangle(svgDrawingInstructions:String):Rectangle {

			// Collect "move" points, as they give the staff's height, x and y
			var rect:Rectangle=null;
			var moveInstruction:Array=null;
			var movePoints:Array=[];
			var x:Number=NaN;
			var y:Number=NaN;
			SVG_MOVE_PATTERN.lastIndex=0;
			while ((moveInstruction=SVG_MOVE_PATTERN.exec(svgDrawingInstructions))) {
				x=parseInt(moveInstruction[1]);
				y=parseInt(moveInstruction[2]);
				if (!isNaN(x) && !isNaN(y)) {
					movePoints.push(new Point(x, y));
				}
			}

			// For some reason, staves are laid down top to bottom
			movePoints.reverse();
			rect=new Rectangle((movePoints[0] as Point).x, (movePoints[0] as Point).y);
			rect.bottom=(movePoints[movePoints.length - 1] as Point).y;

			// All "horizontal line" instructions are identical in a staff drawing, so we only need one
			var hInstruction:Array=svgDrawingInstructions.match(SVG_HORIZ_LINE_PATTERN);
			x+=parseInt(hInstruction[1]);
			if (!isNaN(x)) {
				rect.right=x;
			}
			return rect;
		}

		private function _getWidestClef():uint {
			var maxW:uint=0;
			var key:String;
			var dimensions:Object;
			var w:uint;
			for (key in CLEF_SYMBOL_SIZES) {
				dimensions=CLEF_SYMBOL_SIZES[key] as Object;
				w=dimensions.w;
				if (w > maxW) {
					maxW=w;
				}
			}
			return maxW;
		}
		
		/**
		 * Convenience way of grouping all validation rules that determine whether an
		 * annotation UID should be considered a "split annotation UID". Parts are a good example:
		 * a single Part object can be represented by several clickable SVG text labels
		 * in the score, all of which will be bound to the same UID.
		 * 
		 * When an annotation is split, it is added a suplemental ID (the ordinal index of 
		 * each instance, so that we are able to tell them apart, after all).
		 */
		private function _isSplitUid (annotationUID : String) : Boolean {
			return (annotationUID == PROJECT_UID || ModelUtils.isMirrorUid(annotationUID));
		}

		/**
		 * Lowers the alpha of those "rest" SVG elements that do not have an overlayed, corresponding hotspot
		 * element (where "corresponding" means: a hotspot having a Cluster as the bound element, that has
		 * no children, and has a matching duration);
		 */
		private function _makeGhostRestsTransparent(svg:XML):void {

			// Prepare loop variables
			var i1:int;
			var numBindings:uint=_bindingOrderedUids.length;
			var uid:String=null;
			var binding:HotspotBindingModel=null;
			var element:ProjectData=null;
			var isRestBinding:Boolean=false;
			var bindingDuration:Fraction=null;

			var i0:int;
			var numRestSvgEntities:uint=_restSvgEntities.length;
			var restSvgEntity:Object=null;
			var entityDuration:Fraction=null;
			var entityBounds:Rectangle=null;
			var hotspotRectangles:Array=null;

			var i2a:int;
			var numRectangles:uint=0;
			var rectXML : XML=null;
			var rect:Rectangle=null;

			var i2b:int;
			var svgElements:Array=null;
			var numSvgElements:uint=0;
			var svgElement:XML=null;

			// Loop through all available SVG "rest" entities; we need to tell which ones are "ghosts".
			svgEntitiesLoop: for (i0=0; i0 < numRestSvgEntities; i0++) {
				restSvgEntity=_restSvgEntities[i0] as Object;
				entityDuration=(restSvgEntity.fraction as Fraction);
				entityBounds=(restSvgEntity.bounds as Rectangle);
				
				// Loop through all available bindings. Check for overlapping hotspots that represent rests of 
				// suitable durations. If any match is found, then this is not a "ghost" rest.
				bindingsLoop: for (i1 = 0; i1 < numBindings; i1++) {
					uid=(_bindingOrderedUids[i1] as String);
					binding=(_bindings[uid] as HotspotBindingModel);
					element=binding.element;
					isRestBinding=(ModelUtils.isCluster(element) && element.numDataChildren == 0);
					if (isRestBinding) {
						bindingDuration=Fraction.fromString(element.getContent(DataFields.CLUSTER_DURATION_FRACTION));
						if (bindingDuration.equals(entityDuration)) {
							
							// Bindings can be visually represented by one or more rectangles on the interractive score
							// (this is why we need to loop through a binding's rectangles). For Clusters though, it is
							// expected to always have a single rectangle.
							hotspotRectangles=(_hotspotsMap[uid] as Array);
							numRectangles=hotspotRectangles.length
							rectanglesLoop: for (i2a=0; i2a < numRectangles; i2a++) {
								rectXML=(hotspotRectangles[i2a] as XML);
								rect = new Rectangle (
									parseInt (rectXML.@x),
									parseInt (rectXML.@y),
									parseInt (rectXML.@width),
									parseInt (rectXML.@height)
								);
								if (entityBounds.intersects(rect)) {
									
									// This SVG rest-related entity has a hotspot rectangle, therefore it is not a "ghost"
									// rest; continue search with the next entity available. 
									continue svgEntitiesLoop;
								}
							}
						}
					}
				}

				// No binding/hotspot has been found for the current "rest" SVG entity, so chances are good that it
				// represents a "ghost" entry. Lower alpha to all elements that comprise it (e.g., those could be an
				// "S" path followed by a circle, for a "quarter and a half" rest).
				svgElements=(restSvgEntity.elements as Array);
				numSvgElements=svgElements.length;
				svgElementsLoop: for (i2b=0; i2b < numSvgElements; i2b++) {
					svgElement=(svgElements[i2b] as XML);
					svgElement.@style=GHOST_STYLE;
					svgElement['@class']=SvgEntities.GHOST_REST;
				}
			}
		}

		/**
		 * Responds to a "resolvedFullUidReady" message sent through the pipe.
		 */
		private function _onShortUidInfoReady(data:Object):void {
			_resolvedShortUidInfo=data;
		}
		
		/**
		 * Carries on section annotations that are held in queue for processing. More specifically,
		 * it translates each section annotation to the beginning of its leading measure and above
		 * the top most staff.
		 */
		private function _patchScheduledSectionAnnotations(...etc) : void {
			for (var i:int = 0; i < _sectionAnnotationsQueue.length; i++) {
				var entry : Object = _sectionAnnotationsQueue[i] as Object;
				var xml : XML = entry[MARKUP] as XML;
				var section : ProjectData = entry[DATA] as ProjectData;
				var leadingSectionUid : String = section.route;
				if (leadingSectionUid in _sectionLeads) {
					var leadingMeasureBoundaries : Rectangle = (_sectionLeads[leadingSectionUid] as Rectangle);
					xml.@x = leadingMeasureBoundaries.left;
					xml.@y = leadingMeasureBoundaries.top - AnnotationMetrics.SECTION_ANNOTATION_OFFSET;
				}
			}
		}
		
		/**
		 * Picks up, processes and marks for deletion every <text/> node, which was
		 * produced by an ABC "annotation" markup.
		 *
		 * Annotations is what we use to locate were in the score is a particular
		 * datamodel entry drawn. Once we collect information from an annotation
		 * (particularly x/y coordinates, and the corresponding datamodel entry unique
		 * ID), we can safely discard it.
		 *
		 * @param	element
		 * 			This function receives, in turn, each XML element in the document
		 * 			tree.
		 */
		private function _processAnnotations(element:XML):void {
			var resolvedUid:String;
			var resolvedElement:ProjectData;
			var binding:HotspotBindingModel;
			var anchorX:Number;
			var anchorY:Number;
			var left:Number;
			var top:Number;
			var right:Number;
			var radiusX:Number;
			var radiusY:Number;
			var topLeft:Point;
			var bottomRight:Point;
			var adjustedBindingBox:Rectangle;

			if (element.localName() == SvgEntities.TEXT) {
				var textContent:String=element.toString();
				var annotationCharIndex:int=textContent.indexOf(CommonStrings.BROKEN_VERTICAL_BAR);

				// If the text node `is`, or `contains` an annotation
				if (annotationCharIndex >= 0) {

					// This variable receives the full UID the annotation points to, via a synchronous PTT 
					// pipe. It will be null if there is no matching ID
					_resolvedShortUidInfo=null;

					// A "dedicated annotation" is a text node that only contains the annotation code.
					// This code always ends with a special char ("broken vertical bar"), After processing,
					// these text nodes need to be removed.
					var isDedicatedAnnotation:Boolean=(annotationCharIndex == textContent.length - 1);
					if (isDedicatedAnnotation) {

						// If a matching UID exists, set it as `_resolvedFullUid`:
						PTT.getPipe().send(ViewKeys.NEED_SHORT_UID_INFO, textContent);

						// If we have a matching UID, process it
						if (_resolvedShortUidInfo != null) {
							resolvedUid=(_resolvedShortUidInfo[GenericFieldNames.GUID] as String);
							resolvedElement=(_resolvedShortUidInfo[GenericFieldNames.ITEM] as ProjectData);
							if (resolvedUid && resolvedElement) {
								_annotationsParent=(_annotationsParent || element.parent());
								element['@class']=SvgEntities.DELETION_MARK;
								top=parseFloat(element.@x.toString());
								left=parseFloat(element.@y.toString());
								binding=_provideBinding(resolvedUid);
								binding.element=resolvedElement;
								topLeft=new Point(top, left);
								binding.addBoundariesPoint(topLeft);
								
								// For clusters we need some extra-processing, since the width of the hotspot is given
								// by the cluster's duration. Also, it is of relevance whether the cluster contains children 
								// or not (as empty clusters are rendered as rests, and they use a different widths table),
								// and if notes in a chord are layed down in one column or two columns (as it the case for
								// chords that contain seconds, e.g., C-E-G-A),
								if (ModelUtils.isCluster(resolvedElement)) {
									if (binding.numPoints >= CLUSTER_MIN_BOUNDARY_POINTS) {
										binding.clearAdjustedBindingBoxes();
										var clusterDuration : String = resolvedElement.getContent(DataFields.CLUSTER_DURATION_FRACTION) as String;
										var durationIndex : int = ALL_DURATIONS.indexOf(clusterDuration);
										var w : Number = DEFAULT_CLUSTER_HOTSPOT_WIDTH;
										var horizontalAlign : Number = DEFAULT_CLUSTER_HOTSPOT_ALIGN_X; 
										var isRest : Boolean = resolvedElement.numDataChildren == 0;
										
										// Cluster is a rest; use rests widths table.
										if (isRest) {
											var restDurationSymbol : String = REST_SYMBOLS[durationIndex] as String;
											var restSymbolWidth : Number = REST_SYMBOL_SIZES[restDurationSymbol].w as Number;
											if (!isNaN(restSymbolWidth)) {
												w = restSymbolWidth;
												horizontalAlign = (REST_SYMBOL_SIZES[restDurationSymbol].xAlign as Number) || DEFAULT_REST_HOTSPOT_ALIGN_X;
											}
										} else {
											
											// Cluster is a single note or a chord; use noteheads widths table.
											if (durationIndex >= NOTEHEAD_SYMBOLS.length) {
												durationIndex = NOTEHEAD_SYMBOLS.length - 1;
											}
											var noteheadDurationSymbol : String = NOTEHEAD_SYMBOLS[durationIndex] as String;
											var noteheadSymbolWidth : Number = NOTEHEAD_SYMBOL_SIZES[noteheadDurationSymbol].w as Number;
											if (!isNaN(noteheadSymbolWidth)) {
												w = noteheadSymbolWidth;
												horizontalAlign =  NOTEHEAD_SYMBOL_SIZES[noteheadDurationSymbol].xAlign as Number || DEFAULT_CLUSTER_HOTSPOT_ALIGN_X;
											}
											
											// Do we deal with a chord that contains at least one "prime" or "second" interval?
											// If so, we need to augment the width to account for two column of noteheads.
											if (resolvedElement.numDataChildren > 1) {
												var midiPitches : Array = [];
												var prevMidiPitch : int = 0;
												var midiPitch : int;
												var j:int;
												for (j = 0; j < resolvedElement.numDataChildren; j++) {
													var note : ProjectData = resolvedElement.getDataChildAt(j) as ProjectData;
													midiPitch = MusicUtils.noteToMidiNumber (note, true);
													midiPitches.push (midiPitch);
												}
												midiPitches.sort (Array.NUMERIC);
												for (j = 0; j < midiPitches.length; j++) {
													midiPitch = midiPitches[j];
													if (prevMidiPitch) {
														var delta : int = Math.abs (midiPitch - prevMidiPitch);
														if (delta <= IntervalsSize.MAJOR_SECOND) {
															binding.isDoubleColumnCluster = true;
															w *= DOUBLE_COLUMN_CHORD_FACTOR;
															horizontalAlign = DOUBLE_COLUMN_X_ALIGN_FACTOR;
															break;
														}
													}
													prevMidiPitch = midiPitch;
												}
											}
										}
										
										// Setup hotspot width based on previous calculus
										binding.boundingBox.x -= (CLUSTER_HOTSPOT_GUTTER + w * horizontalAlign);
										binding.boundingBox.width += (w + CLUSTER_HOTSPOT_GUTTER * 2);
									}
								}

								// For measures we also need some extra-processing, as to display one measure hotspot over each 
								// staff of the instrument
								if (ModelUtils.isMeasure(resolvedElement)) {
									if (binding.numPoints >= MEASURE_MIN_BOUNDARY_POINTS) {
										binding.clearAdjustedBindingBoxes();
										var part:ProjectData=ModelUtils.getParentPart(resolvedElement) as ProjectData;
										var numExpectedStaves:uint=part.getContent(DataFields.PART_NUM_STAVES) as uint;
										var numAdjustments:uint=0;
										var i:int=0;
										var numStaffRectangles:uint=_staffRectangles.length;
										var staffRectangle:Rectangle;
										var measureRoute : String = resolvedElement.route;
										var sectionRoute : String = measureRoute.split(CommonStrings.UNDERSCORE).slice (0, -2).join(CommonStrings.UNDERSCORE);
										for (i=0; i < numStaffRectangles; i++) {
											staffRectangle=_staffRectangles[i] as Rectangle;
											if (staffRectangle.intersects(binding.boundingBox)) {
												adjustedBindingBox=staffRectangle.intersection(binding.boundingBox);
												adjustedBindingBox.top-=Sizes.MEASURE_HOTSPOT_TOP_GUTTER;
												adjustedBindingBox.bottom+=Sizes.MEASURE_HOTSPOT_BOTTOM_GUTTER;
												adjustedBindingBox.left-=Sizes.MEASURE_HOTSPOT_LEFT_GUTTER;
												binding.addAdjustedBindingBox(adjustedBindingBox);
												numAdjustments++;
												
												// If this is the first measure in its section, we take note of its
												// boundaries. This will help us adjust sections' annotations
												// boundaries
												if (resolvedElement.index == 0) {
													if (!(sectionRoute in _sectionLeads)) {
														_sectionLeads[sectionRoute] = adjustedBindingBox;
													}
													var currY : Number = (_sectionLeads[sectionRoute] as Rectangle).top;
													var newY : Number = adjustedBindingBox.top;
													if (newY < currY) {
														_sectionLeads[sectionRoute] = adjustedBindingBox;
													}
												}
											}
											if (numAdjustments >= numExpectedStaves) {
												break;
											}
										}
									}
								}
							}
						}
					}

					// "Inline" annotations, are valid text nodes to be displayed in the score, that have been
					// pre-pended an annotation code. After processing, these nodes need to be left in place, only the
					// annotation code stripped off. Only part labels, section and generator names, and project labels
					// make use of inline annotations.
					else {
						var splitAnnotationOrdinal : int = 0;
						var cssClasses : Array = [];
						var tmp:Array=textContent.split(CommonStrings.BROKEN_VERTICAL_BAR);
						var uid:String=(tmp.shift() as String).concat(CommonStrings.BROKEN_VERTICAL_BAR);
						var txt:String=tmp.pop() as String;
						element.*=txt;

						// If a matching UID exists, set it as `_resolvedFullUid`:
						PTT.getPipe().send(ViewKeys.NEED_SHORT_UID_INFO, uid);

						// If we have a matching UID, process it
						if (_resolvedShortUidInfo != null) {
							resolvedUid=(_resolvedShortUidInfo[GenericFieldNames.GUID] as String);
							resolvedElement=(_resolvedShortUidInfo[GenericFieldNames.ITEM] as ProjectData);
							if (resolvedUid) {
								cssClasses.push (SvgEntities.INLINE_ANNOTATION, resolvedUid);
								_annotationsParent=(_annotationsParent || element.parent());
								
								// Part annotations need extra-case, since they actually reuse UIDs
								// (there can be several annotated labels in the score for a given
								// Part; see detailed explanation in the NOTES for the 
								//'_provideBinding()' method.  
								if (_isSplitUid(resolvedUid)) {
									_acknowledgeSplitAnnotationFor(resolvedUid);
									splitAnnotationOrdinal = _splitAnnotationCounters[resolvedUid];
									binding=_provideBinding(resolvedUid, splitAnnotationOrdinal);
									cssClasses.push (splitAnnotationOrdinal);
								} else {
									binding=_provideBinding(resolvedUid);
								}
								
								// By default, section annotations are off to the right, by the width of the measure they
								// were anchored on. In order to successfully translate them to the left, we need to wait
								// until all measure annotations are fully processed.
								if (resolvedElement && ModelUtils.isSection(resolvedElement)) {
									element['@text-anchor']='start';
									element['@font-size']=SvgEntities.SECTION_FONT_SIZE;
									cssClasses.push (SvgEntities.SECTION);
									_scheduleSectionAnnotationPatching (element, resolvedElement);
								}

								element['@class'] = cssClasses.join (CommonStrings.SPACE);
								
								// All SVG texts are anchored to bottom center; this is all the positioning information
								// that we can get at this pre-processing stage; we'll actually align the resulting hotspots
								// once the text has been rendered on the page.
								anchorX=parseFloat(element.@x.toString());
								anchorY=parseFloat(element.@y.toString());
								binding.addBoundariesPoint(new Point (anchorX - AnnotationMetrics.TMP_OFFSET_SIZE, anchorY - AnnotationMetrics.TMP_OFFSET_SIZE));
								binding.addBoundariesPoint(new Point (anchorX + AnnotationMetrics.TMP_OFFSET_SIZE, anchorY + AnnotationMetrics.TMP_OFFSET_SIZE));

								// For Part inline annotation we will provide a surrogate, as the actual model object to
								// bind to needs to be determined at runtime
								if (ModelUtils.isMirrorUid(resolvedUid)) {
									binding.element=DUMMY_PART_ELEMENT;
								}

								// For any other type of inline annotation (e.g., project title, composer name, section name)
								// we know the actual model object to bind to beforehand, and we can provide it here
								else {
									binding.element=resolvedElement;
								}
							}
						}
					}
				}
			}
		}
		
		/**
		 * Creates or reuses an AnnotationBindingModel having the given unique ID.
		 * 
		 * NOTE:
		 * The peculiar case of Part annotations/bindings must be dealt with separately.
		 * 
		 * If, say, on a score page we have four staff systems, each comprising a Violin 
		 * and a Piano, then there will be four annotated labels for the Violin Part and
		 * four annotated labels for the Piano part. If there is a single section spread
		 * over the entire page, then all the Violin labels, when clicked, should select
		 * the same violin Part, and all Piano labels, the same piano Part. This is why
		 * PART LABELS ARE ANNOTATED WITH THE PART MIRROR UID, which is global. Unless
		 * there is a single staff system of any given instrument, THERE WILL ALWAYS BE
		 * SEVERAL ANNOTATED PART LABELS SHARING THE SAME UID, so we cannot rely on the
		 * their uid alone to provide unique bindings for them.
		 * 
		 * In order to cope with this situation, we store each part annotation under a
		 * composit key, build from the annotation's uid and its ordinal index.
		 * 
		 * @see AnnotationBindingModel
		 */
		private function _provideBinding(uid:String, partAnnotationOrdinal : int = -1) : HotspotBindingModel {
			if (partAnnotationOrdinal >= 0) {
				uid += CommonStrings.SPACE.concat (partAnnotationOrdinal);
			}
			if (!(uid in _bindings)) {
				_bindings[uid]=new HotspotBindingModel(uid);
				_bindingOrderedUids.push(uid);
			}
			return (_bindings[uid] as HotspotBindingModel);
		}

		/**
		 * Removes all annotations.
		 */
		private function _purgeSVG(svg:XML):void {
			var toDelete:XMLList=svg.descendants().(hasOwnProperty('@class') && attribute('class') == SvgEntities.DELETION_MARK);
			while (toDelete.length() > 0) {
				delete toDelete[0];
			}
		}

		/**
		 * This class is meant to be long-lived. Therefore, we need to reset essential
		 * information when the SVG content changes.
		 */
		private function _reset():void {
			_splitAnnotationCounters = {};
			_staffRectangles=[];
			_clefSvgElements=[];
			_staffSVGElements=[];
			_clefsRightEdge=0;
			_clefsLeftEdge=0;
			_bindings={};
			_bindingOrderedUids=[];
			_noteheadSvgElements=[];
			_restSvgEntities=[];
			_resolvedShortUidInfo=null;
			_annotationsParent=null;
			_hotspotsMap={};
			 _sectionLeads={};
			_sectionAnnotationsQueue = [];
		}
		
		/**
		 * Stores section annotations data for later processing.
		 */
		private function _scheduleSectionAnnotationPatching (element : XML, resolvedElement : ProjectData) : void {
			var entry : Object = {};
			entry [MARKUP] = element;
			entry [DATA] = resolvedElement;
			_sectionAnnotationsQueue.push (entry);
		}
	}
}

import ro.ciacob.maidens.controller.constants.MeasureSelectionKeys;
import ro.ciacob.utils.Strings;
/**
 * Internal class used to stamp the staff index the multiple hotspots representing a
 * Measure each point to. The index will eventually be added as a class on the SVG element,
 * e.g., "staff-1" for the first staff, and so on.
 */
class StaffIndexProxy extends Object {
	
	public function StaffIndexProxy() {
		super();
	}
	
	private static const TEMPLATE:String=MeasureSelectionKeys.STAFF_PREFIX.concat('%s');

	public var value:int;

	public function toString():String {
		return Strings.sprintf(TEMPLATE, value);
	}
}
