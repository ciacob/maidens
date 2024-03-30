package ro.ciacob.maidens.model.exporters {

import ro.ciacob.maidens.legacy.ProjectData;
import ro.ciacob.math.Fraction;

public class VoiceInfo {

    private var _indicesMap:Array;
    private var _rawVoiceData:ProjectData;
    private var _startTime:Fraction;

    public function VoiceInfo(indicesMap:Array, rawVoiceData:ProjectData) {
        _indicesMap = indicesMap;
        _rawVoiceData = rawVoiceData;
    }


    public function get indicesMap():Array {
        return _indicesMap;
    }

    public function get rawVoiceData():ProjectData {
        return _rawVoiceData;
    }

    public function get startTime():Fraction {
        return _startTime;
    }

    public function set startTime(value:Fraction):void {
        _startTime = value;
    }

    public function toString():String {
        return (_startTime + ' | ' + _rawVoiceData.route);
    }

}
}
