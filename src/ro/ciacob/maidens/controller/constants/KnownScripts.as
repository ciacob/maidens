package ro.ciacob.maidens.controller.constants {
	import ro.ciacob.utils.constants.FileTypes;

	public final class KnownScripts {

		// General use keys
		public static const INTERPRETER:String = 'interpreter';
		public static const FILE_TYPE:String = 'fileType';
		public static const PRE_ARGS:String = 'preArgs';
		public static const POST_ARGS:String = 'postArgs';

		// Windows batch (*.bat) scripts
		public static const BATCH_HEADER:String = 'REM BATCH';
		private static const BATCH_INTERPRETER:String = 'cmd.exe';

		// Windows Host - Javascript (*.js) scripts
		public static const WJS_HEADER:String = '//WJS';
		public static const WJS_INTERPRETER:String = 'wscript.exe';

		/**
		 * @private
		 * The table of known scripts, along with handling information.
		 */
		private static var _knownScripts:Object;

		public static function get TABLE():Object {
			if (_knownScripts == null) {

				// Initialize the scripts table
				_knownScripts = {};

				// Windows Batch
				TABLE[BATCH_HEADER] = {};
				TABLE[BATCH_HEADER][INTERPRETER] = BATCH_INTERPRETER;
				TABLE[BATCH_HEADER][FILE_TYPE] = FileTypes.BAT;
				TABLE[BATCH_HEADER][PRE_ARGS] = Vector.<String>(['/c']);
				TABLE[BATCH_HEADER][POST_ARGS] = Vector.<String>([]);

				// Windows Script Host - Javascript
				TABLE[WJS_HEADER] = {}
				TABLE[WJS_HEADER][INTERPRETER] = WJS_INTERPRETER;
				TABLE[WJS_HEADER][FILE_TYPE] = FileTypes.JS;
				TABLE[WJS_HEADER][PRE_ARGS] = Vector.<String>([]);
				TABLE[WJS_HEADER][POST_ARGS] = Vector.<String>([]);
			}
			return _knownScripts;
		}

	}
}
