package ro.ciacob.maidens.controller.constants {
import ro.ciacob.maidens.legacy.constants.DataFields;


/**
	 * Note we *need* lowercase constant members in this class to speed up access.
	 */
	public final class CopiableProperties {
		public function CopiableProperties() {}
		
		public static const cluster:Array = [
			DataFields.CLUSTER_DURATION_FRACTION,
			DataFields.DOT_TYPE
		];
		public static const voice:Array = [
			// None, we actually only copy children and keep everything else as is.
		];
		public static const measure:Array = [
			DataFields.BAR_TYPE
		];
	}
}