package ro.ciacob.maidens.model.datastructure.search {
	import ro.ciacob.maidens.model.datastructure.IDocumentFragment;
	import ro.ciacob.maidens.model.datastructure.search.operators.Operator;

	public class Group extends SearchConstruct {
		
		private var _logicalOperator : Operator;
		private var _constructs : Vector.<SearchConstruct>;
		
		public function Group (logicalOperator : Operator, ...constructs : Vector.<SearchConstruct>) {
			_logicalOperator = logicalOperator;
			_constructs = constructs;
		}
		
		public function get logicalOperator () : Operator {
			return _logicalOperator;
		}
		
		public function get queries () : Vector.<Query> {
			return _constructs;
		}
		
		override public function execute (targetData : IDocumentFragment = null):Boolean {
			var logicalFun : Function = _logicalOperator.func;
			var result : Boolean = false;
			while (_constructs.length >= 2) {
				var operandA : SearchConstruct = _constructs.shift();
				var operandB : SearchConstruct = _constructs.shift();
				result = logicalFun (operandA.execute(targetData), operandB.execute(targetData));
			}
			return result;
		}
	}
}
