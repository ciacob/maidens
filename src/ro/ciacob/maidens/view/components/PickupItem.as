package ro.ciacob.maidens.view.components {
	import flash.net.registerClassAlias;
	
	import mx.utils.ObjectUtil;
	
	import avmplus.getQualifiedClassName;
	
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.constants.CommonStrings;

	public class PickupItem extends Object {
		private static const UID_CHARS_NUM:int = 5;

		private static const _uidsPool:Object = {};

		public function PickupItem (arg : Object):void {
			if (arg == null) {
				throw(new ArgumentError('PickupItem: constructor(): The argument at index 0 cannot be null.'));
			}
			if (arg is PickupItem) {
				_buildFromOtherInstance(arg as PickupItem);
			} else {
				_buildFromScratch (arg);
			}
		}

		private var _label:String;
		private var _uid:String;
		private var _src:Object;

		public function clone():PickupItem {
			registerClassAlias(getQualifiedClassName(this), Object(this).constructor);
			return PickupItem(ObjectUtil.clone(this));
		}

		public function isEquivalentTo(otherItem:PickupItem):Boolean {
			return (_label == otherItem.label);
		}

		public function isIdenticTo(otherItem:PickupItem):Boolean {
			return (_uid == otherItem.uid);
		}

		public function get label():String {
			return _label;
		}

		public function get src() : Object {
			return _src;
		}
		
		public function makeCopy():PickupItem {
			return new PickupItem(this);
		}
		
		public function toString () : String {
			return _label;
		}

		public function get uid():String {
			return _uid;
		}

		private function _buildFromOtherInstance(other:PickupItem):void {
			_label = other.label;
			_src = ObjectUtil.clone (other.src);
			_uid = _makeUID();
		}

		private function _buildFromScratch (src : Object):void {
			_label = ('label' in src)? src['label'] : CommonStrings.EMPTY.concat (src);
			_src = src;
			_uid = _makeUID();
		}

		private function _makeUID():String {
			return Strings.generateUniqueId(_uidsPool, UID_CHARS_NUM);
		}
	}
}
