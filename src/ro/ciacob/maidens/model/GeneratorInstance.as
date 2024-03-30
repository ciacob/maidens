package ro.ciacob.maidens.model {

import ro.ciacob.utils.Strings;
import ro.ciacob.utils.constants.CommonStrings;

public class GeneratorInstance {

    private var _fullyQualifiedName:String;
    private var _linkNumber:String;
    private var _signature:String;

    public function GeneratorInstance(generatorUID:String, connectionUid:String) {
        const INTRO:String = 'Cannot create GeneratorID: ';
        const UID_IS_EMPTY:String = 'given `generator UID` is empty.';
        const CONNECTION_IS_EMPTY:String = 'given `connection name` is empty.';

        // Sanity checks
        if (Strings.isEmpty(generatorUID)) {
            throw (new Error(INTRO.concat(UID_IS_EMPTY)));
        }
        if (Strings.isEmpty(connectionUid)) {
            throw (new Error(INTRO.concat(CONNECTION_IS_EMPTY)));
        }

        // Storage
        _fullyQualifiedName = generatorUID;
        _linkNumber = connectionUid;
        _signature = _fullyQualifiedName.concat(CommonStrings.DOUBLE_COLON, _linkNumber);
    }

    public function get signature():String {
        return _signature;
    }

    public function equals(otherID:GeneratorInstance):Boolean {
        return (_signature == otherID.signature);
    }

    /**
     * Also known as `generatorUID`. Example: `ro.ciacob.maidens.generators.builtin.atonalline`.
     */
    public function get fqn():String {
        return _fullyQualifiedName;
    }

    /**
     * Also known as `connectionUid`. In the UI is displayed as a number preceded by a link graphic. In MAIDENS'
     * dedicated font, this graphic is represented by a repurposed char, "Á". Example: `Á2`
     */
    public function get link():String {
        return _linkNumber;
    }
}
}