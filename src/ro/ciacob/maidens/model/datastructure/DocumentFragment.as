package ro.ciacob.maidens.model.datastructure {

	public class DocumentFragment implements IDocumentFragment {

		public function DocumentFragment(manager:IDocumentManager) {
			_manager=manager;
			_sysId=_manager.registerFragment(this);
		}

		private var _manager:IDocumentManager;

		private var _sysId:String;
		private var _tags:Object={};

		public function getTag(tagName : String):Object {
			return (_tags[tagName] || null);
		}

		public function hasTag(tagName:String, tagValue:Object=null):Boolean {
			if (tagValue) {
				return (_tags[tagName] === tagValue);
			}
			return (tagName in _tags);
		}

		public function get manager():IDocumentManager {
			return _manager;
		}

		public function setTag(tagName:String, tagValue:Object=null):void {
			_tags[tagName]=tagValue;
		}

		public function get sysId():String {
			return _sysId;
		}

		/**
		 * Sub-classes must override.
		 */
		public function get type():String {
			return null;
		}

		public function unsetTag(tagName):void {
			delete(_tags[tagName]);
		}
	}
}
