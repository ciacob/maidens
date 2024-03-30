package ro.ciacob.maidens.controller {
import flash.events.IEventDispatcher;

import ro.ciacob.maidens.legacy.ProjectData;


public interface ILauncher extends IEventDispatcher {
    function get errorDetail():String;

    function launch(object:ProjectData):void;

    function get outputDetail():String;

    function get srcData():ProjectData;

    function set scriptingHome(value:String):void;
}
}
