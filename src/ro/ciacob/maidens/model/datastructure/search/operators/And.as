package ro.ciacob.maidens.model.datastructure.search.operators {

	public class And extends Operator {
		
		private static const AND : String = 'and';
		
		public function And(name:String, func:Function) {
			super (AND, _bothAreTrue);
		}
		
		private function _bothAreTrue (a : Object, b : Object) : Boolean {
			return (a && b);
		}
	}
}
