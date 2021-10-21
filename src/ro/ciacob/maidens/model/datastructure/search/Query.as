package ro.ciacob.maidens.model.datastructure.search {
	import ro.ciacob.maidens.model.datastructure.IDocumentFragment;
	import ro.ciacob.maidens.model.datastructure.search.operators.Operator;

	public class Query extends SearchConstruct {

		public function Query(name:String, operator:Operator, value:Object) {
			_name=name;
			_operator=operator;
			_value=value;
		}

		private var _name:String;
		private var _operator:Operator;
		private var _value:Object;
		private var _sourceData;

		public function get name():String {
			return _name;
		}

		public function get operator():Operator {
			return _operator;
		}

		public function get value():Object {
			return _value;
		}
		
		override public function execute (targetData : IDocumentFragment = null) : Boolean {
			return _operator.func (
				targetData? 
					(_name in targetData)? 
						targetData[_name] :
						targetData.getTag(_name) :
				_name,
				
				_value);
		}
	}
}
