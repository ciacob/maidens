package ro.ciacob.maidens.controller.constants {
	import ro.ciacob.desktop.signals.PTT;

	public final class CoreApiArguments {

		// Format is: 
		// [{Required arguments number}, {Type of argument 1}, {Type of argument n}]
		public static const SHOW_MESSAGE:Array = [1, String, String, Function];
		public static const GET_GREATEST_DURATION_OF : Array = [1, Array];
		public static const GET_SECTIONS_BY_NAMES : Array = [1, Vector.<String>];
		public static const REPORT_GENERATION_PROGRESS : Array = [2, Object, PTT];
	}
}
