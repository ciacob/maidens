package ro.ciacob.maidens.model.datastructure {
	import ro.ciacob.maidens.model.constants.DataFields;

	public class Generator extends DocumentFragment {

		override public function get type():String {
			return DataFields.GENERATOR;
		}
	}
}
