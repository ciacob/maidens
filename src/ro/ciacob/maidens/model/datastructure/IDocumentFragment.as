package ro.ciacob.maidens.model.datastructure {

	/**
	 * Interface that represents the DocumentFragment implementation, and all its
	 * subclasses. Usefull for dependency-injection based testing.
	 */
	public interface IDocumentFragment {

		function get manager():IDocumentManager;
		function get sysId():String;
		function get type():String;
		
		function getTag(tagName:String):Object;
		function hasTag(tagName:String, tagValue:Object=null):Boolean;
		function setTag(tagName:String, tagValue:Object=null):void;
		function unsetTag(tagName):void;
	}
}
