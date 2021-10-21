package ro.ciacob.maidens.model.exporters {
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.math.Fraction;
	
	
	/**
	 * Collects tuplet data and outputs it in ABC syntax when serialized via
	 * `toString()`. 
	 * 
	 * The ABC tuplet syntax is "(p:q:r" - which means: "put p notes into the
	 * time of q for the next r notes". For instance, "(3:2:3" would create
	 * an eighths triplet.
	 */
	public class TupletMarker implements IABCMarker {
		
		public static const UNDERFULL : int = -1;
		public static const FULL : int = 0;
		public static const OVERFULL : int = 1;
		
		private static const ABC_TUPLET_TEMPLATE : String = ' (%p:%q:%r ';
		
		/**
		 * Also known as `r` in the ABC tuplet syntax `(p:q:r` (see class documentation).
		 */
		private var _tupletNumNotes : int;
		
		/**
		 * Keeps track of the durations added to the tuplet.
		 */
		private var _tupletSpanSoFar : Fraction;
		
		/**
		 * The unique ID of the cluster node that starts this tuple (aka "root node").
		 */
		private var _rootId : String;
		
		/**
		 * The total musical span this tuplet is expected to cover, expressed as a
		 * Fraction. For instance, an eighths triplet will have a total duration of 3/8.
		 */
		private var _expectedTupletSpan : Fraction;
		
		/**
		 * The "source" number of beats for this tuplet. In an eighths triplet this would be "3".
		 * This would be `p` in the ABC tuplet syntax `(p:q:r` (see class documentation).
		 */
		private var _srcNumBeats : uint;

		/**
		 * The "target" number of beats for this tuplet. In an eighths triplet this would be "2".
		 * This would be `q` in the ABC tuplet syntax `(p:q:r` (see class documentation).
		 */
		private var _targetNumBeats : uint;
		
		/**
		 * @constructor
		 * See class documentation for details
		 * 
		 * @param	rootId
		 * 			See documentation for `_rootId`
		 * 
		 * @param	expectedTupletSpan
		 * 			See documentation for `_expectedTupletSpan`
		 * 
		 * @param	srcNumBeats
		 * 			See documentation for `_srcNumBeats`
		 * 
		 * @param	targetNumBeats
		 * 			See documentation for `_targetNumBeats`
		 */
		public function TupletMarker(rootId : String, expectedTupletSpan : Fraction, srcNumBeats : uint, targetNumBeats : uint) {
			_rootId = rootId;
			_expectedTupletSpan = expectedTupletSpan;
			_srcNumBeats = srcNumBeats;
			_targetNumBeats = targetNumBeats;
			_tupletNumNotes = 0;
			_tupletSpanSoFar = Fraction.ZERO;
		}
		
		/**
		 * Returns the current root id. See documentation for `_rootId`.
		 */
		public function get rootId () : String {
			return _rootId;
		}
		
		/**
		 * See the documentation for the `accountFor()` method for more details.
		 */
		public function get remainder () : Fraction {
			return _expectedTupletSpan.subtract(_tupletSpanSoFar) as Fraction;
		}
		
		/**
		 * Takes note of a newly proposed cluster duration and decides whether it fits the
		 * tuplet duration that was advertised before hand. Returns of of three possible
		 * static constants, which are defined on this class:
		 * 
		 * UNDERFULL (-1);
		 * 		means that, after taking into account given cluster node's duration, there
		 * 		is still "room" to fill the tuplet. E.g., this would be the case after 
		 * 		receiving an `eighth` in an eighths triplet that's currently accounted for
		 * 		another eighth.
		 * 
		 * 	FULL (0);
		 * 		means that, after taking into account given cluster node's duration, the
		 * 		tuplet is "complete". E.g., this would be the case after receiving an 
		 * 		`eighth` in an eighths triplet that's already accounted for two more 
		 * 		eighths.
		 * 
		 * 	OVERFULL (1);
		 * 		means that  given cluster node's duration cannot be accounted for because,
		 * 		if it was, would "overflow" the tuplet. E.g., this would be the case when
		 * 		receiving a `quarter` (crotchet) in an eighths triplet that's already accounted
		 * 		for two eighths. The offending duration will be rejected. As far as this class
		 * 		is concerned, it is expected that the calling code provides an acceptable 
		 * 		duration.
		 * 
		 * 		The `remainder` class member contains the largest acceptable duration. The 
		 * 		calling code can query and use this information to mitigate the issue.
		 * 
		 * @param	element : Object (Fraction)
		 * 			The duration of a cluster node, expressed as a fraction, e.g., 1/8
		 * 			for one eighth.
		 * 
		 */
		public function accountFor (element : Object) : int {
			
			// TODO: SUPPORT NESTED TRIPLETS
			
			var response : int = TupletMarker.OVERFULL;
			var clusterDuration : Fraction = (element as Fraction);
			
			// Cache to conserve CPU
			var $remainder : Fraction = remainder;
			
			// Decide whether the new duration fits
			// (a) Does not fit
			
			if ($remainder.lessThan(clusterDuration)) {
				return response;
			}
			
			// (b) Fits exactly
			else if ($remainder.equals(clusterDuration)) {
				response = TupletMarker.FULL;
				_tupletSpanSoFar = _expectedTupletSpan;
				_tupletNumNotes++;
			}
			
			// (c) Fits loosely
			else if ($remainder.greaterThan(clusterDuration)) {
				response = TupletMarker.UNDERFULL;
				_tupletSpanSoFar = _tupletSpanSoFar.add(clusterDuration) as Fraction;
				_tupletNumNotes++;
			}
			
			return response;
		}
		
		public function toString () : String {
			return ABC_TUPLET_TEMPLATE
				.replace ('%p', _srcNumBeats)
				.replace ('%q', _targetNumBeats)
				.replace ('%r', _tupletNumNotes);
		}
	}
}