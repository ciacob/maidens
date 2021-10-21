package ro.ciacob.maidens.view.components {
	import flash.events.Event;
	
	import mx.controls.HorizontalList;

	public class CustomHorizontalList extends HorizontalList {
		
		public function CustomHorizontalList () {
			super();
		}

		[Bindable]
		public var itemStyleName : String;
		private static const HORIZONTAL_BAR_STATUS_CHANGE:String = 'horizontalBarStatusChange';

		private var _isHorizontalScrollBarVisible:Boolean;

		[Bindable("horizontalBarStatusChange")]
		[Inspectable(category = "General", defaultValue = "false")]
		public function get isHorizontalScrollBarVisible():Boolean {
			return _isHorizontalScrollBarVisible;
		}

		override protected function updateDisplayList(w:Number, h:Number):void {
			super.updateDisplayList(w, h);
			_updateHorizontalBarStatus();
		}

		private function _updateHorizontalBarStatus():void {
			var isNowVisible:Boolean = (super.horizontalScrollBar != null && super.horizontalScrollBar.visible == true);
			if (isNowVisible != _isHorizontalScrollBarVisible) {
				_isHorizontalScrollBarVisible = isNowVisible;
				dispatchEvent(new Event(HORIZONTAL_BAR_STATUS_CHANGE));
			}
		}
	}
}
