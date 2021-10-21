package ro.ciacob.maidens.view.components {
	import mx.controls.TileList;

	public class CustomTileList extends TileList {
		
		public function CustomTileList () {
			super();
		}
		
		[Bindable]
		public var itemStyleName:String;
	}
}
