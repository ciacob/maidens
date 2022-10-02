package ro.ciacob.maidens.model.exporters {
public class NoteInfo {

    private var _midiPitch : int;
    private var _tiesLeft : Boolean;
    private var _tiesRight : Boolean;
    private var _tieGroupId : String;

    public function NoteInfo(midiPitch : int,
                             tiesLeft : Boolean = false, tiesRight : Boolean = false,
                             tieGroupId : String = null) {
        _midiPitch = midiPitch;
        _tiesLeft = tiesLeft;
        _tiesRight = tiesRight;
        _tieGroupId = tieGroupId;
    }

    public function get midiPitch():int {
        return _midiPitch;
    }

    public function get tiesLeft():Boolean {
        return _tiesLeft;
    }

    public function set tiesLeft(value:Boolean):void {
        _tiesLeft = value;
    }

    public function get tiesRight():Boolean {
        return _tiesRight;
    }

    public function set tiesRight(value:Boolean):void {
        _tiesRight = value;
    }

    public function get tieGroupId():String {
        return _tieGroupId;
    }

    public function set tieGroupId(value:String):void {
        _tieGroupId = value;
    }

    public function toString () : String {
        return (_tiesLeft? '←' : '') + _midiPitch + (tiesRight? '→' : '');
    }
}
}
