package ro.ciacob.maidens.model.datastructure {
	import ro.ciacob.utils.Strings;

	/**
	 * Manages all DocumentFragments in the current data set.
	 */
	public class DocumentManager implements IDocumentManager {

		private static var _instance:DocumentManager;
		private var _allFragments : Vector.<IDocumentFragment>;

		public static function get instance():DocumentManager {
			return (_instance || (_instance=new DocumentManager));
		}

		public function DocumentManager() {
			if (_instance != null) {
				throw new Error('Class DocumentManager is a Singleton. Please use `DocumentManager.instance` instead.')
			}
		}
		
		public function registerFragment (fragment : IDocumentFragment) : String {
			if (fragment && fragment.manager === this) {
				var uuid : String = Strings.UUID;
				_allFragments[uuid] = fragment;
				return uuid;
			}
			return null;
		}
	}
}
