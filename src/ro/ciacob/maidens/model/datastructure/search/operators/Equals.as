package ro.ciacob.maidens.model.datastructure.search.operators {
	
	public class Equals extends Operator {
		private static const EQUALS:String='equals';

		public function Equals(name:String, shortName:String) {
			super(EQUALS, _isEqual);
		}

		private function _isEqual(a:Object, b:Object):Boolean {
			return (a === b);
		}
	}
}
