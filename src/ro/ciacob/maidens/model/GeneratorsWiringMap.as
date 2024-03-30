package ro.ciacob.maidens.model {
import ro.ciacob.maidens.generators.GeneratorBase;

public class GeneratorsWiringMap {

    public function GeneratorsWiringMap() {
    }

    private static const INTRO:String = 'Class `GeneratorsWiringMap` ';
    private static const ADD:String = 'cannot `add()`: ';
    private static const GET:String = 'cannot `get()`: ';
    private static const HAS:String = 'cannot `has()`: ';
    private static const DEL:String = 'cannot `remove()`: ';
    private static const IMPLICIT_OVERWRITE:String = 'ID already exists. Use the `replace` argument, or verify with `has()`.';
    private static const MISSING_ID:String = 'ID does not exist. Use `has()` to verify.';
    private static const NULL_ID:String = 'argument `generatorID` cannot be null.';
    private static const NULL_GENERATOR:String = 'argument `generator` cannot be null.';

    private var _ids:Object = {};
    private var _generators:Object = {};

    private function _idExists(generatorID:GeneratorInstance):Boolean {
        return (generatorID && (generatorID.signature in _ids));
    }

    private static function _byConnectionNumber(generatorIdA:GeneratorInstance, generatorIdB:GeneratorInstance):int {
        var numA:int = (parseInt(generatorIdA.link.substr(1)) as int);
        var numB:int = (parseInt(generatorIdB.link.substr(1)) as int);
        return (numA - numB);
    }

    /**
     * NOTE: Throws if either `generatorID` or `generator` are null.
     */
    public function add(generatorInstance:GeneratorInstance, generator:GeneratorBase, replace:Boolean = false):void {
        // Sanity checks
        if (generatorInstance == null) {
            throw (new Error(INTRO.concat(ADD, NULL_ID)));
        }
        if (generator == null) {
            throw (new ArgumentError(INTRO.concat(ADD, NULL_GENERATOR)));
        }
        if (!replace && _idExists(generatorInstance)) {
            throw (new Error(INTRO.concat(ADD, IMPLICIT_OVERWRITE)));
        }
        // Storage
        var signature:String = generatorInstance.signature;
        _ids[signature] = generatorInstance;
        _generators[signature] = generator;
    }

    /**
     * NOTE: Throws if given a null or non-existent ID.
     */
    public function remove(generatorID:GeneratorInstance):void {
        // Sanity checks
        if (generatorID == null) {
            throw (new Error(INTRO.concat(DEL, NULL_ID)));
        }
        if (!_idExists(generatorID)) {
            throw (new Error(INTRO.concat(DEL, MISSING_ID)));
        }
        // Erasing
        var signature:String = generatorID.signature;
        delete _ids[signature];
        delete _generators[signature];
    }

    /**
     * NOTES: Throws if given a null ID. Returns `null` if no generator was mapped under given ID.
     */
    public function $get(generatorID:GeneratorInstance):GeneratorBase {
        // Sanity checks
        if (generatorID == null) {
            throw (new Error(INTRO.concat(GET, NULL_ID)));
        }
        // Retrieval
        if (!_idExists(generatorID)) {
            return null;
        }
        var signature:String = generatorID.signature;
        return (_generators[signature] as GeneratorBase);
    }

    /**
     * NOTES: Throws if given a null ID.
     */
    public function has(generatorID:GeneratorInstance):Boolean {
        // Sanity checks
        if (generatorID == null) {
            throw (new Error(INTRO.concat(HAS, NULL_ID)));
        }
        // Retrieval
        return _idExists(generatorID);
    }

    /**
     * NOTE: Always sorts resulting vector by the connection's numeric value. Can return an empty Vector, but not `null`.
     */
    public function get generatorIDs():Vector.<GeneratorInstance> {
        var v:Vector.<GeneratorInstance> = new Vector.<GeneratorInstance>;
        var id:GeneratorInstance;
        for each (id in _ids) {
            v.push(id);
        }
        v.sort(_byConnectionNumber);
        return v;
    }

    public function clear():void {
        _ids = {};
        _generators = {};
    }
}
}