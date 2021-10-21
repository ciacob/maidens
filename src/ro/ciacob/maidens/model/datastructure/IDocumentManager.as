package ro.ciacob.maidens.model.datastructure {

	import ro.ciacob.maidens.model.datastructure.search.SearchConstruct;

	/**
	 * Interface that represent the DocumentManager implementation, usefull
	 * for testing the DocumentFragment sub-classes, as they all use dependency
	 * injection (they inject this interface in the constructor).
	 */
	public interface IDocumentManager {
		
		function registerFragment (fragment : IDocumentFragment) : String;
		
		function find (... queries : Vector.<SearchConstruct>) : Vector.<IDocumentFragment>;
	}
}
