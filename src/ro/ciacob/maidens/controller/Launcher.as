package ro.ciacob.maidens.controller {
import com.adobe.crypto.MD5;

import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.DataEvent;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IEventDispatcher;
import flash.events.NativeProcessExitEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.utils.IDataInput;

import ro.ciacob.desktop.io.DiskWritterEvent;
import ro.ciacob.desktop.io.TextDiskWritter;
import ro.ciacob.maidens.controller.constants.KnownScripts;
import ro.ciacob.maidens.controller.constants.LauncherKeys;
import ro.ciacob.maidens.controller.constants.LauncherMessages;
import ro.ciacob.maidens.legacy.ProjectData;

import ro.ciacob.utils.Files;
import ro.ciacob.utils.Patterns;
import ro.ciacob.utils.Strings;
import ro.ciacob.utils.constants.FileTypes;

public class Launcher implements ILauncher {
    private static const SCRIPTS_HOME:String = 'scriptsHome';
    private static const STARTUP_ARGUMENT_WRAPPER:RegExp = /--arg=([\x22\x27\x60])(.+?)\1/;
    private static const STARTUP_ARGUMENT_WRAPPER_GLOBAL:RegExp = /--arg=([\x22\x27\x60])(.+?)\1/g;
    private static const WDIR_ARGUMENT_WRAPPER:RegExp = /--startIn=([\x22\x27\x60])(.+?)\1/;
    private static const WDIR_ARGUMENT_WRAPPER_GLOBAL:RegExp = /--startIn=([\x22\x27\x60])(.+?)\1/g;
    private static const WINDOWS_EOL:String = '\r\n';

    public function Launcher() {
        // Initialize the IEventDispatcher delegation
        _dispatcher = new EventDispatcher(this);
    }

    private var _actionType:String;
    private var _details:String;
    private var _dispatcher:IEventDispatcher;
    private var _errorDetail:String;
    private var _file:File;
    private var _outputDetail:String;
    private var _path:String;

    private var _process:NativeProcess;
    private var _scriptingHomePath:String;
    private var _srcData:ProjectData;
    private var _startupArguments:Vector.<String>;
    private var _successfullyLaunched:Boolean = false;
    private var _workingDirectory:File;

    public function addEventListener(type:String, listener:Function, useCapture:Boolean =
            false, priority:int = 0, useWeakReference:Boolean = false):void {
        _dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
    }

    public function dispatchEvent(event:Event):Boolean {
        return _dispatcher.dispatchEvent(event);
    }

    public function get errorDetail():String {
        return _errorDetail;
    }

    public function hasEventListener(type:String):Boolean {
        return _dispatcher.hasEventListener(type);
    }

    public function launch(srcData:ProjectData):void {

        _srcData = srcData;
        _errorDetail = null;
        _outputDetail = null;

        var _flatItemsList:Array = _flattenData(_srcData);
        _flatItemsList.shift();

        // Prepare for launching
        if (_srcData != null) {
            _path = _srcData.getContent(LauncherKeys.PATH);
            _details = _srcData.getContent(LauncherKeys.DETAILS);
            var haveDetails:Boolean = (_details != null && !Strings.isEmpty(Strings.trim(_details)));
            if (haveDetails) {
                _startupArguments = _getStartupArguments(_details);
                _workingDirectory = _getWorkingDir(_details);
            }

            _actionType = _srcData.getContent(LauncherKeys.ACTION);
            if (_actionType == LauncherKeys.AUTO) {
                _actionType = _findActionType(_path, _details);
            }

            // Handle NON SCRIPT launches (those that do not require invoking a script
            // interpreter on the user machine)
            if (_actionType == LauncherKeys.WEB || _actionType == LauncherKeys.FILE || _actionType == LauncherKeys.FOLDER || _actionType ==
                    LauncherKeys.APPLICATION) {

                var havePath:Boolean = (_path != null && !Strings.isEmpty(Strings.trim(_path)));
                if (!havePath) {
                    dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY,
                            false, false, LauncherMessages.MISSING_REQUIRED_PATH));
                    return;
                }

                // Handle LOCAL launches
                if (_actionType != LauncherKeys.WEB) {
                    if (!Files.isValidPath(_path)) {
                        dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY,
                                false, false, LauncherMessages.CANNOT_RESOLVE_PATH));
                        return;
                    }
                    _file = new File(_path);
                    if (_actionType == LauncherKeys.FILE || _actionType == LauncherKeys.FOLDER) {
                        _file.openWithDefaultApplication();
                        _successfullyLaunched = true;
                    } else if (_actionType == LauncherKeys.APPLICATION) {
                        var errorCode:String = _runApplication(_file, _startupArguments,
                                _workingDirectory);
                        if (errorCode != null) {
                            dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false,
                                    false, errorCode));
                            return;
                        }
                        _successfullyLaunched = true;
                    }
                }

                // Handle WEB launches
                else {
                    var url:URLRequest = new URLRequest(_path);
                    navigateToURL(url);
                    _successfullyLaunched = true;
                }
            } else if (_actionType == LauncherKeys.COMMAND) {
                return _runCommand();
            }
        }

        // Handle failures
        if (!_successfullyLaunched) {
            dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY, false,
                    false, LauncherMessages.NO_LAUNCH_SCENARIO));
            return;
        }

        dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY, false, false,
                LauncherMessages.TERMINATED_NORMALLY));
    }


    public function get outputDetail():String {
        return _outputDetail;
    }

    public function removeEventListener(type:String, listener:Function, useCapture:Boolean =
            false):void {
        _dispatcher.removeEventListener(type, listener, useCapture);
    }

    public function set scriptingHome(value:String):void {
        if (value != null && Files.isValidPath(value)) {
            _scriptingHomePath = value;
        }
    }

    public function get srcData():ProjectData {
        return _srcData;
    }

    public function willTrigger(type:String):Boolean {
        return _dispatcher.willTrigger(type);
    }

    /**
     * If we have an interpreter, working directory, script file, and a (possibly empty) list
     * of startup arguments, we could actually run a script:
     *
     * 1. Concatenate hardcoded with user-provided startup arguments, keeping the path to the
     *    script in-between PRE_ARGS and POST_ARGS. Arguments the user received in
     *    the `details` field, by using the --args="" token come last, e.g.:
     *
     *    cmd.exe PRE_ARG_1...PRE_ARG_N myScript.bat POST_ARG_1...POST_ARG_N --args="..." etc.
     *
     *      The PRE_ARGS and POST_ARGS arguments are defined for each known script language,
     *      within the KnownScripts class.
     *
     * 2. Perform a regular launch of an application that has both startup arguments and a
     *    working directory setup. The application is the interpreter file.
     */
    private function _executeScript(interpreter:File, workingDirectory:File,
                                    scriptFile:File, startupArguments:Vector.<String>):void {
        var interpreterFileName:String = interpreter.name;
        var scriptInfo:Object;
        for (var header:String in KnownScripts.TABLE) {
            var interpreterName:String = KnownScripts.TABLE[header][KnownScripts.INTERPRETER];
            if (interpreterName == interpreterFileName) {
                scriptInfo = KnownScripts.TABLE[header];
                break;
            }
        }

        // Place `POST_ARGS` before existing arguments
        var postArgs:Vector.<String> = (scriptInfo[KnownScripts.POST_ARGS] as
                Vector.<String>);
        for (var i:int = postArgs.length - 1; i >= 0; i--) {
            var postArg:String = postArgs[i];
            if (!Strings.isEmpty(Strings.trim(postArg))) {
                startupArguments.unshift(postArg);
            }
        }

        // Place the path of the script file before `POST_ARGS` (which were just prepended)
        startupArguments.unshift(scriptFile.nativePath);

        // Place `PRE_ARGS` before the script file path (which was just prepended)
        var preArgs:Vector.<String> = (scriptInfo[KnownScripts.PRE_ARGS] as Vector.<String>);
        for (var j:int = preArgs.length - 1; j >= 0; j--) {
            var preArg:String = preArgs[j];
            if (!Strings.isEmpty(Strings.trim(preArg))) {
                startupArguments.unshift(preArg);
            }
        }

        // Run the script via its interpreter
        _runApplication(interpreter, startupArguments, workingDirectory);
    }

    private static function _findActionType(path:String, details:String):String {

        if (Files.isValidURL(path)) {
            return LauncherKeys.WEB;
        }
        if (Files.isValidPath(path)) {
            var tmp:File = new File(path);
            if (tmp.isDirectory) {
                tmp = null;
                return LauncherKeys.FOLDER;
            }
            // AIR refuses to run several scriptable extensions under Windows.
            // We have to hardcode resolutions for these extensions, in order to
            // make them executable.
            if (Files.isPathOfType(path, [FileTypes.BAT])) {
                return LauncherKeys.COMMAND;
            }
            if (Files.isPathOfType(path, [FileTypes.JS])) {
                return LauncherKeys.COMMAND;
            }
            if (Files.isApplication(path)) {
                return LauncherKeys.APPLICATION;
            }
            return LauncherKeys.FILE;
        }
        var isCommand:Boolean = false;
        for (var header:String in KnownScripts.TABLE) {
            if (details.indexOf(header) == 0) {
                isCommand = true;
                break;
            }
        }
        if (isCommand) {
            return LauncherKeys.COMMAND;
        }

        return null;
    }

    private function _flattenData(data:ProjectData):Array {
        var list:Array = [];
        data.walk(function (item:ProjectData):void {
            list.push(item);
        });
        return list;
    }

    private static function _getStartupArguments(rawText:String):Vector.<String> {
        var ret:Vector.<String> = new Vector.<String>;
        // Collect startup arguments
        var argumentWrappers:Array = rawText.match(STARTUP_ARGUMENT_WRAPPER_GLOBAL);
        if (argumentWrappers != null) {
            for (var i:int = 0; i < argumentWrappers.length; i++) {
                var wrapper:String = argumentWrappers[i];
                var wrapperContent:Array = wrapper.match(STARTUP_ARGUMENT_WRAPPER);
                if (wrapperContent != null) {
                    var argumentBody:String = Strings.trim(wrapperContent[2]);
                    ret.push(argumentBody);
                }
            }
        }
        return ret;
    }

    private static function _getWorkingDir(rawText:String):File {
        var wdirWrappers:Array = rawText.match(WDIR_ARGUMENT_WRAPPER_GLOBAL);
        if (wdirWrappers != null && wdirWrappers.length > 0) {
            var wrapper:String = wdirWrappers[0];
            var wrapperContent:Array = wrapper.match(WDIR_ARGUMENT_WRAPPER);
            if (wrapperContent != null) {
                var wdirBody:String = Strings.trim(wrapperContent[2]);
                wdirBody = Strings.deQuote(wdirBody, Strings.DEQUOTE_BACKTICK |
                        Strings.DEQUOTE_DOUBLE);
                if (Files.isValidPath(wdirBody)) {
                    var wDir:File = new File(wdirBody);
                    if (wDir.isDirectory) {
                        return wDir;
                    }
                }
            }
        }
        return null;
    }

    private function _onNPErrorData(event:ProgressEvent):void {
        var process:NativeProcess = (event.target as NativeProcess);
        var processError:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
        _errorDetail = processError;
        dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY, false, false,
                LauncherMessages.HAVE_STDERR));
    }

    private function _onNPExit(event:NativeProcessExitEvent):void {
        var process:NativeProcess = (event.target as NativeProcess);
        process.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, _onNPOutputData);
        process.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, _onNPErrorData);
        dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY, false, false,
                LauncherMessages.NATIVE_APPLICATION_EXIT));
    }

    private function _onNPOutputData(event:ProgressEvent):void {
        var process:NativeProcess = (event.target as NativeProcess);
        var stdOut:IDataInput = process.standardOutput;
        _outputDetail = stdOut.readUTFBytes(process.standardOutput.bytesAvailable);
        dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY, false, false,
                LauncherMessages.HAVE_STDOUT));
    }

    private function _runApplication(file:File, startupArguments:Vector.<String>,
                                     workingDirectory:File):String {
        if (NativeProcess.isSupported) {
            var processInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
            processInfo.executable = file;
            var haveStartupArguments:Boolean = (startupArguments != null && startupArguments.length > 0);
            if (haveStartupArguments) {
                processInfo.arguments = startupArguments;
                if (workingDirectory != null) {
                    processInfo.workingDirectory = workingDirectory;
                }
            }
            _process = new NativeProcess;
            _process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, _onNPOutputData);
            _process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, _onNPErrorData);
            _process.addEventListener(NativeProcessExitEvent.EXIT, _onNPExit);
            try {
                _process.start(processInfo);
            } catch (error:Error) {
                _errorDetail = error.message;
                trace('CANNOT LAUNCH. Path: ' + processInfo.executable.nativePath + '; ERROR: ' + _errorDetail);
                return LauncherMessages.CANNOT_EXECUTE;
            }
        } else {
            return LauncherMessages.NP_API_UNAVAILABLE;
        }
        return null;
    }

    /**
     * Additionally to running executable files, we can also directly send
     * raw scripts code to the appropriate script interpreter for running.
     * For example, lines written in Windows Batch language can be sent to
     * `cmd.exe`, which will be running it with current user's privileges.
     */
    private function _runCommand():void {

        // FIND THE INTERPRETER (typically an *.exe) that will run the script
        var interpreter:File;
        var interpreterFileName:String;
        var resolvedInterpreterFileName:String;
        var header:String;
        var havePath:Boolean;
        var haveDetails:Boolean;
        var scriptFile:File;
        var scriptFileFolder:File;
        var workingDirectory:File;
        var startupArguments:Vector.<String> = new Vector.<String>;

        // Do we have `details`? If so, they might contain a header as the
        // first token, which will resolve to an interpreter.
        haveDetails = (_details != null && !Strings.isEmpty(Strings.trim(_details)));
        if (haveDetails) {
            for (header in KnownScripts.TABLE) {
                if (_details.indexOf(header) == 0) {
                    interpreterFileName = KnownScripts.TABLE[header][KnownScripts.INTERPRETER];
                    break;
                }
            }
        }

        // If we couldn't find the name of our interpreter, do we have a `path`?
        // If so, it should point to a script file to run, whose type will give
        // a hint for the interpreter to use.
        if (interpreterFileName == null) {
            havePath = (_path != null && !Strings.isEmpty(Strings.trim(_path)));
            if (havePath) {
                for (header in KnownScripts.TABLE) {
                    var fileType:String = KnownScripts.TABLE[header][KnownScripts.FILE_TYPE];
                    if (Files.isPathOfType(_path, [fileType])) {
                        interpreterFileName = KnownScripts.TABLE[header][KnownScripts.INTERPRETER];
                        break;
                    }
                }
            }
        }
        if (interpreterFileName != null) {

            // Is the interpreter file name an absolute path?
            if (Files.isApplication(interpreterFileName)) {
                interpreter = new File(interpreterFileName);
            }

            // Or maybe it is a path relative to the system folder
            else {

                if (_scriptingHomePath != null) {
                    var scriptingHome:File = new File(_scriptingHomePath);
                    if (scriptingHome.exists && scriptingHome.isDirectory) {
                        resolvedInterpreterFileName = scriptingHome.resolvePath(interpreterFileName).nativePath;
                        if (Files.isApplication(resolvedInterpreterFileName)) {
                            interpreter = new File(resolvedInterpreterFileName);
                        }
                    }
                }
            }
        }
        if (interpreter == null) {
            _errorDetail = Strings.trim(_scriptingHomePath).concat('\\', interpreterFileName);
            dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY, false,
                    false, LauncherMessages.BAD_INTERPRETER_PATH));
            return;
        }

        // 2. FIND THE WORKING DIRECTORY for the script
        // Do we have the `workingDirectory` set?
        if (_workingDirectory != null) {
            workingDirectory = _workingDirectory;
        }

                // Otherwise, do we have a `path`? If so, it should point to a script
        // file to run, whose parent directory will be our working directory.
        else {
            havePath = (_path != null && !Strings.isEmpty(Strings.trim(_path)));
            if (havePath) {
                scriptFile = new File(_path);
                scriptFileFolder = scriptFile.parent;
                if (scriptFileFolder.exists) {
                    workingDirectory = scriptFileFolder;
                }
            }
        }
        if (workingDirectory == null) {
            dispatchEvent(new DataEvent(LauncherKeys.LAUNCHER_ACTIVITY, false,
                    false, LauncherMessages.MISSING_REQUIRED_WDIR));
            return;
        }

        // 3. FIND THE ARGUMENTS to be sent to the interpreter.
        // Do we have the `startupArguments` set?
        havePath = (_path != null && !Strings.isEmpty(Strings.trim(_path)));
        if (havePath) {
            if (_startupArguments != null && _startupArguments.length > 0) {
                startupArguments = _startupArguments;
            }
        }

        // 4. GET THE SCRIPT FILE to be run:
        // Do we have a `path`? If so, this is our script file to run.
        if (havePath) {
            scriptFile = new File(_path);
        }

                // Otherwise, do we have `details`? Hash them, and create a file using
                // the hash as the name, under the application storage directory. Write
                // the `details` there.
        // This is our script file to run. The file will be reused if it exists.
        else {
            haveDetails = (_details != null && !Strings.isEmpty(Strings.trim(_details)));
            if (haveDetails) {
                var scriptContent:String = ('').concat(_details);
                scriptContent = scriptContent.replace(WDIR_ARGUMENT_WRAPPER_GLOBAL,
                        '');
                scriptContent = scriptContent.replace(STARTUP_ARGUMENT_WRAPPER_GLOBAL,
                        '');
                scriptContent = scriptContent.replace(Patterns.UNIX_EOL, WINDOWS_EOL);
                scriptContent = scriptContent.replace(Patterns.MAC_EOL, WINDOWS_EOL);
                var scriptFileName:String = MD5.hash(scriptContent);
                var scriptFileType:String;
                for (header in KnownScripts.TABLE) {
                    var interpreterName:String = KnownScripts.TABLE[header][KnownScripts.INTERPRETER];
                    if (interpreterName == interpreterFileName) {
                        scriptFileType = KnownScripts.TABLE[header][KnownScripts.FILE_TYPE];
                        break;
                    }
                }
                scriptFile = File.applicationStorageDirectory.resolvePath(SCRIPTS_HOME).resolvePath(scriptFileName.concat('.', scriptFileType));
                if (!scriptFile.exists) {
                    var writer:TextDiskWritter = new TextDiskWritter;
                    var callback:Function = function (event:DiskWritterEvent):void {
                        writer.removeEventListener(DiskWritterEvent.WRITE_COMPLETED,
                                callback);
                        _executeScript(interpreter, workingDirectory, scriptFile,
                                startupArguments);
                    }
                    writer.addEventListener(DiskWritterEvent.WRITE_COMPLETED,
                            callback);
                    writer.write(scriptContent, scriptFile);

                    return;
                }
            }
        }
        // Any meaningful status, from now on, is to be returned by the
        // `executeScript` method.
        _executeScript(interpreter, workingDirectory, scriptFile, startupArguments);
    }
}
}
