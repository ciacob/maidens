package ro.ciacob.maidens.model.datastructure.search.operators {
	public class Operator {

		private var _name : String;
		private var _func : String;
		
		public function Operator (name : String, func : Function) {
			_name = name;
			_func = func;
		}
		
		public function get name () : String {
			return _name;
		}
		
		/**
		 * The returned function must accept exactly two arguments (the two operands)
		 */
		public function get func () : Function {
			return _func;
		}
	}
}