package ro.ciacob.maidens.model.exporters {
public class TrackBluePrint {

    private var _voiceObjects : Vector.<VoiceInfo>;
    private var _clusterObjects : Vector.<ClusterInfo>;
    private var _partLabel : String;
    private var _presetNumber : int;

    public function TrackBluePrint (partLabel : String, presetNumber : int) {
        _partLabel = partLabel;
        _presetNumber = presetNumber;
        _voiceObjects = new Vector.<VoiceInfo>;
        _clusterObjects = new Vector.<ClusterInfo>;
    }

    public function get voiceObjects():Vector.<ro.ciacob.maidens.model.exporters.VoiceInfo> {
        return _voiceObjects;
    }

    public function get clusterObjects():Vector.<ro.ciacob.maidens.model.exporters.ClusterInfo> {
        return _clusterObjects;
    }

    public function get partLabel():String {
        return _partLabel;
    }

    public function get presetNumber():int {
        return _presetNumber;
    }

    public function toString () : String {
        return (_partLabel + '(' + _presetNumber +
                ');\n\t Voice Info objects: ' + _voiceObjects.join(', ') +
                '\n\t Cluster Info objects: ' + _clusterObjects.join(', '));
    }
}
}
