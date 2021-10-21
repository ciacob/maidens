package ro.ciacob.maidens.model.datastructure {
	import ro.ciacob.maidens.model.constants.DataFields;

	/**
	 * Represents the concept of a project, e.g., a musical opus.
	 */
	public class Project extends DocumentFragment {

		override public function get type():String {
			return DataFields.PROJECT;
		}

		private var _composerName:String;
		private var _copyright:String;
		private var _creationTime:Date;
		private var _modificationTime:Date;
		private var _name:String;
		private var _notes:String;
		
		public function get generators () : Vector.<Generator> {
			return DocumentManager.instance.find (new ChildrenByType (this, DataFields.GENERATOR));
		}

		public function get composerName():String {
			return _composerName;
		}

		public function set composerName(value:String):void {
			_composerName=value;
		}

		public function get copyright():String {
			return _copyright;
		}

		public function set copyright(value:String):void {
			_copyright=value;
		}

		public function get creationTime():Date {
			return _creationTime;
		}

		public function set creationTime(value:Date):void {
			_creationTime=value;
		}

		public function get modificationTime():Date {
			return _modificationTime;
		}

		public function set modificationTime(value:Date):void {
			_modificationTime=value;
		}

		public function get name():String {
			return _name;
		}

		public function set name(value:String):void {
			_name=value;
		}

		public function get notes():String {
			return _notes;
		}

		public function set notes(value:String):void {
			_notes=value;
		}
	}
}
