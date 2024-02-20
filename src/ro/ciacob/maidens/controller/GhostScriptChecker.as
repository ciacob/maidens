package ro.ciacob.maidens.controller {
import flash.events.EventDispatcher;
import flash.events.Event;
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.NativeProcessExitEvent;
import flash.events.ProgressEvent;
import flash.events.IOErrorEvent;
import flash.filesystem.File;

import ro.ciacob.utils.Strings;

/**
 * The GhostscriptChecker class checks if Ghostscript is installed on the current macOs system.
 * It dispatches a GHOSTSCRIPT_CHECK_EVENT event upon completion of the check.
 * To retrieve the Ghostscript path, listen for the GHOSTSCRIPT_CHECK_EVENT event and access the ghostscriptPath property.
 * If Ghostscript is not installed, ghostscriptPath will be null.
 */
public class GhostScriptChecker extends EventDispatcher {
    /**
     * Dispatched when the Ghostscript check is complete.
     * Access the ghostscriptPath property to retrieve the Ghostscript installation path.
     * If Ghostscript is not installed, ghostscriptPath will be null.
     */
    public static const GHOSTSCRIPT_CHECK_EVENT:String = "ghostScriptCheckEvent";
    private var _ghostscriptPath:String;

    /**
     * Retrieves the Ghostscript installation path.
     * If Ghostscript is not installed, ghostscriptPath will be null.
     */
    public function get ghostscriptPath():String {
        return _ghostscriptPath;
    }

    /**
     * Checks if Ghostscript is installed on the current system.
     * Dispatches a GHOSTSCRIPT_CHECK_EVENT event upon completion of the check.
     * To retrieve the Ghostscript path, listen for the GHOSTSCRIPT_CHECK_EVENT event and access the ghostscriptPath property.
     * If Ghostscript is not installed, ghostscriptPath will be null.
     */
    public function checkGhostscriptInstallation():void {
        var shellPath:String = determineShellPath();
        if (!shellPath) {
            dispatchEvent(new Event(GHOSTSCRIPT_CHECK_EVENT));
            return;
        }

        var processArgs:Vector.<String> = new Vector.<String>();
        processArgs.push("-l"); // Login shell
        processArgs.push("-c"); // Command to execute
        processArgs.push("which gs");

        var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
        nativeProcessStartupInfo.executable = new File(shellPath);
        nativeProcessStartupInfo.arguments = processArgs;

        var process:NativeProcess = new NativeProcess();
        process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
        process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
        process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onError);
        process.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);
        process.start(nativeProcessStartupInfo);
    }

    private static function determineShellPath():String {
        var terminalShells:Array = ["/bin/bash", "/bin/zsh", "/bin/sh", "/bin/csh", "/bin/ksh"];
        for each (var shell:String in terminalShells) {
            var shellFile:File = new File(shell);
            if (shellFile.exists) {
                return shell;
            }
        }
        return null;
    }

    private function onOutputData(event:ProgressEvent):void {
        var process:NativeProcess = event.target as NativeProcess;
        var output:String = Strings.trim(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable));

        try {
            var ghostscriptFile:File = new File(output);
            if (ghostscriptFile.exists) {
                _ghostscriptPath = ghostscriptFile.nativePath;
            } else {
                _ghostscriptPath = null; // Set to null if gs is not found
            }
        } catch (error:Error) {
            _ghostscriptPath = null; // Set to null if an error occurs
        }
    }

    private function onErrorData(event:ProgressEvent):void {
        _ghostscriptPath = null;
    }

    private function onError(event:IOErrorEvent):void {
        _ghostscriptPath = null;
    }

    private function onProcessExit(event:Event):void {
        dispatchEvent(new Event(GHOSTSCRIPT_CHECK_EVENT));
    }
}

}
