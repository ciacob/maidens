package ro.ciacob.maidens.model.datastructure.search {
	import ro.ciacob.maidens.model.datastructure.IDocumentFragment;

	public class SearchConstruct {
		public function SearchConstruct() {
		}
		
		/**
		 * Sub-classes must override.
		 */
		public function execute (targetData : IDocumentFragment = null) : Boolean {
			return false;
		}
	}
}
