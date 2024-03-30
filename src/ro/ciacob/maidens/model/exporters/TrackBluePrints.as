package ro.ciacob.maidens.model.exporters {
import ro.ciacob.utils.Objects;

public class TrackBluePrints {

    private static const CANNOT_ADD_NON_UNIQUE_ID:String = 'Cannot add track blueprint. Given uid already exists.';
    private static const FIRST_TRACK_ID:String = '00';

    private var _bluePrints:Object;

    public function TrackBluePrints() {
        _bluePrints = {};
    }

    public function add(uid:String, bluePrint:TrackBluePrint):void {
        if (uid in _bluePrints) {
            throw (new Error(CANNOT_ADD_NON_UNIQUE_ID));
        }
        _bluePrints[uid] = bluePrint;
    }

    public function get(uid:String):TrackBluePrint {
        return ((_bluePrints[uid] as TrackBluePrint) || null);
    }

    public function getFirst():TrackBluePrint {
        return get(FIRST_TRACK_ID);
    }

    /**
     * Removes a previously registered TrackBluePrint by its `uid`. Returns `true` on success, or `false`
     * on failure (e.g., if given uid was never registered).
     */
    public function remove(uid:String):Boolean {
        if (uid in _bluePrints) {
            return delete (_bluePrints[uid]);
        }
        return false;
    }

    /**
     * Visits each registered blueprint in turn, calling given callback with relevant info.
     *
     * @param   callback
     *          Function to be called for each registered track blueprint. Signature must be:
     *          function myCallback (blueprintUid : String, blueprint : TrackBluePrint, index : uint) : void.
     *
     *          Registered track blueprints are iterated based on their sorted uids (alphabetically ascending).
     */
    public function forEach(callback:Function):void {
        if (callback != null) {
            var keys:Array = Objects.getKeys(_bluePrints, true);
            var i:int = 0;
            var numKeys:uint = keys.length;
            var key:String;
            var bluePrint:TrackBluePrint;
            for (i = 0; i < numKeys; i++) {
                key = (keys[i] as String);
                bluePrint = (_bluePrints[key] as TrackBluePrint);
                callback(key, bluePrint, i);
            }
        }
    }

    public function toString():String {
        var out:Array = [];
        var keys:Array = Objects.getKeys(_bluePrints, true);
        for (var i:int = 0; i < keys.length; i++) {
            out.push('[' + i + ']' + '. ' + keys[i] + ': ' + _bluePrints[keys[i]]);
        }
        return out.join('\n');
    }
}
}
