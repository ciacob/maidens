package ro.ciacob.maidens.model {
	import flash.geom.Point;
	import flash.geom.Rectangle;

import ro.ciacob.maidens.legacy.ProjectData;

import ro.ciacob.utils.Geometry;

	/**
	 * Holds information that represents a connection (binding) between one entry in the
	 * data model and the corresponding element, as it was drawn in the on-screen score.
	 * The data model entry is represented by its unique id, and the in-score drawing is
	 * represented by its bounding box.
	 */
	public final class HotspotBindingModel {

		private static const BINDING_MODELS_MAP:Object={};
		private static const BOUND_UIDS_LIST:Object=[];
		
		/**
		 * Used for refining Cluster hotspots based on stem information availability.
		 */
		public var haveStemInfo : Boolean;
		
		/**
		 * Used for refining Cluster hotspots based on stem attitude (i.e., whether it is "up" or "down").
		 */
		public var stemDirection : String;
		
		/**
		 * Used to help slightly translate toward left all Cluster hotspots that lay out notes in two roes
		 * (e.g., because they contain a "prime" or "second" musical interval) while also having a "down"
		 * stem.
		 */
		public var isDoubleColumnCluster : Boolean;

		/**
		 * Holds information that represents a connection (binding) between one entry in the
		 * data model and the corresponding element, as it was drawn in the on-screen score.
		 * The data model entry is represented by its unique id, and the in-score drawing is
		 * represented by its bounding box.
		 *
		 * @param	elementUID
		 * 			The unique ID of an entry in the data model (i.e., an ProjectData
		 * 			implementor) to create a binding to.
		 */
		public function HotspotBindingModel(elementUID:String) {
			_elementUID=elementUID;
			_boundingBox=new Rectangle;
			if (!(_elementUID in BINDING_MODELS_MAP)) {
				BOUND_UIDS_LIST.push(elementUID);
			}
			BINDING_MODELS_MAP[_elementUID]=this;
		}

		private var _adjustedBoundingBoxes:Array;
		private var _boundaryPoints:Array=[];
		private var _boundingBox:Rectangle;
		private var _element:ProjectData;
		private var _elementUID:String;

		/**
		 * Allows client code to "manually" store a custom rectangle into this binding model.
		 */
		public function addAdjustedBindingBox(box:Rectangle):void {
			if (!_adjustedBoundingBoxes) {
				_adjustedBoundingBoxes = [];
			}
			_adjustedBoundingBoxes.push(box);
		}
		
		/**
		 * Removes all custom rectangles previously stored.
		 */
		public function clearAdjustedBindingBoxes () : void {
			if (_adjustedBoundingBoxes) {
				_adjustedBoundingBoxes.length = 0;
				_adjustedBoundingBoxes = null;
			}
		}

		/**
		 * Adds a new point, and recalculates the "boundingBox" rectangle accordingly.
		 */
		public function addBoundariesPoint(point:Point):void {
			_boundaryPoints.push(point);
			if (isFirstPoint()) {
				_boundingBox.x=point.x;
				_boundingBox.y=point.y;
			} else {
				Geometry.inflateRectToPoint(_boundingBox, point);
			}
		}

		/**
		 * Returns all the custom rectangles stored so far (if any).
		 */
		public function get adjustedBoundingBoxes():Array {
			return _adjustedBoundingBoxes;
		}

		/**
		 * Returns the calculated rectangle defined by all the most northwestern and
		 * southeastern of all the added points.
		 */
		public function get boundingBox():Rectangle {
			return _boundingBox;
		}

		/**
		 * Accessor for the data model object this binding points to.
		 */
		public function get element():ProjectData {
			return _element;
		}

		public function set element(value:ProjectData):void {
			_element=value;
		}

		/**
		 * The unique ID of the element in the data model we bound to.
		 */
		public function get elementUID():String {
			return _elementUID;
		}

		public function isFirstPoint():Boolean {
			return (_boundaryPoints.length == 1);
		}

		public function get numPoints():uint {
			return _boundaryPoints.length;
		}
	}
}
