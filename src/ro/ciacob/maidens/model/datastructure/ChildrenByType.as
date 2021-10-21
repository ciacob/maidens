package ro.ciacob.maidens.model.datastructure {
	import ro.ciacob.maidens.model.datastructure.search.Group;
	import ro.ciacob.maidens.model.datastructure.search.Keys;
	import ro.ciacob.maidens.model.datastructure.search.Query;
	import ro.ciacob.maidens.model.datastructure.search.operators.And;
	import ro.ciacob.maidens.model.datastructure.search.operators.Equals;

	public class ChildrenByType extends Group {
		
		public function ChildrenByType (parent : IDocumentFragment, type : String) {
			super (And, 
				new Query (Keys.TYPE, Equals, type), 
				new Query (Keys.PARENT, Equals, parent)
			);
		}
	}
}
