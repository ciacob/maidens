package ro.ciacob.maidens.view.components {
	import mx.controls.Tree;

	public class CustomTree extends Tree {
		public function CustomTree() {
			super();
		}
		
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight : Number) : void {
			
			// The Tree component crashes big time. This is in place of a real solution until
			// we switch to Starling/Feathers UI or a custom Flex component
			try {
				super.updateDisplayList (unscaledWidth, unscaledHeight);
			} catch (e : Error) {
				trace ('Tree component crashed: ' + e.message);
			}
		} 
	}
}