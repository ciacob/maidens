package ro.ciacob.maidens.model.constants {
	import flash.filesystem.File;
	import ro.ciacob.utils.Strings;

	public final class FileAssets {
		public static const ABC_FILE_DESCRIPTION:String = 'ABC files (*.abc)';
		public static const PDF_FILE_DESCRIPTION:String = 'PDF files (*.pdf)';
		public static const XML_FILE_DESCRIPTION:String = 'XML files (*.xml)';
		public static const PROJECT_FILE_DESCRIPTION:String = 'project files (*.maid)';
		public static const MIDI_FILE_DESCRIPTION:String = 'MIDI files (*.mid)';
		public static const WAV_FILE_DESCRIPTION:String = 'WAV files (*.wav)';

		public static const ABC_SCREEN:String = 'abcScreen.tpl';
		public static const ABC_PRINT:String = 'abcPrint.tpl';
		public static const ABC_AUDIO:String = 'abcAudio.tpl';
		public static const APPDIR_TOKEN:String = '%appdir%';
		public static const DEFAULT_PROJECT_FILE_NAME:String = 'default';
		public static const GENERATOR_INFO_TEMPLATE:String = 'generatorInfo.tpl';
		public static const LAUNCHER_QUERY_TEMPLATE:String = 'launcherQuery.tpl';
		public static const PROJECT_FILE_EXTENSION:String = 'maid';

		public static const AUDIO_ASSETS_HOME:String = 'assets/sounds';
		public static const AUDIO_ASSET_FILE_TYPE:String = '.swf';
		public static const AUDIO_WORKER_FILE_KEY : int = 653;
		public static const AUDIO_WORKER_FILE_LABEL : String = 'Audio Synthesis Engine';

		public static function get CONTENT_DIR():File {
			return _resolveAppDirPath('%appdir%/assets/content/');
		}

		public static function get TEMPLATES_DIR():File {
			return _resolveAppDirPath('%appdir%/assets/helpers/templates');
		}

		private static function _resolveAppDirPath(path:String):File {
			path = path.replace(APPDIR_TOKEN, File.applicationDirectory.nativePath);
			path = path.replace(/\x2f/g, File.separator);
			path = path.replace(new RegExp(Strings.escapePattern(File.separator).
				concat('{2,}'), 'g'), File.separator);
			var file:File = new File(path);
			file.canonicalize();
			return file;
		}
	}
}
