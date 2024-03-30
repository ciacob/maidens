package ro.ciacob.maidens.controller {

import com.adobe.crypto.MD5;

import flash.events.DataEvent;
import flash.filesystem.File;
import flash.utils.ByteArray;

import ro.ciacob.desktop.data.constants.DataKeys;
import ro.ciacob.desktop.data.importers.PlainObjectImporter;
import ro.ciacob.desktop.io.AbstractDiskWritter;
import ro.ciacob.desktop.io.RawDiskWritter;
import ro.ciacob.desktop.signals.PTT;
import ro.ciacob.maidens.controller.constants.LauncherKeys;
import ro.ciacob.maidens.controller.constants.LauncherMessages;
import ro.ciacob.maidens.legacy.ProjectData;
import ro.ciacob.maidens.legacy.constants.FileAssets;

import ro.ciacob.utils.ByteArrays;
import ro.ciacob.utils.Files;
import ro.ciacob.utils.OSFamily;
import ro.ciacob.utils.Strings;
import ro.ciacob.utils.Templates;
import ro.ciacob.utils.constants.CommonStrings;
import ro.ciacob.utils.constants.FileTypes;

public class NativeAppsWrapper {
    private static const $BANNER_MADE_MIDI:String = 'MIDI CONVERSION DONE FOR: %token%';
    private static const $BANNER_MADE_PDF:String = 'ABC TO PDF CONVERSION DONE FOR: %token%';
    private static const $BANNER_MADE_XML:String = 'ABC TO XML CONVERSION DONE FOR: %token%';
    private static const $BANNER_MADE_WAV:String = 'RECORDING TO WAV DONE FOR: %token%';
    private static const $BANNER_MIDI_PLAYBACK_DONE:String = 'PLAYBACK DONE FOR: %token%';
    private static const $BANNER_MIDI_STOPPED:String = 'MIDI PLAYBACK STOPPED FOR: %token%';

    private static const $SCRIPT_MAKE_MIDI:String = 'abc2midi';
    private static const $SCRIPT_MAKE_PDF:String = 'abc2pdf';
    private static const $SCRIPT_MAKE_XML:String = 'abc2xml';
    private static const $SCRIPT_MAKE_WAV:String = 'midi2wav';
    private static const $SCRIPT_START_MIDI_PLAYBACK:String = 'playMidi';
    private static const $SCRIPT_STOP_MIDI_PLAYBACK:String = 'stopMidi';

    private static const APP_FILE_NAME_KEY:String = 'appFileName';
    private static const ARGUMENTS_KEY:String = 'arguments';
    private static const FAILED:String = 'FAILED';

    private static const LAUNCHER_INTERNAL_ERROR_BATCH:String = 'NativeAppsWrapper: _runBatchScript - launcher returned internal error while running native application: "%s". Please double check arguments sent to `_runBatchScript()`.';
    private static const LAUNCHER_INTERNAL_ERROR_NATIVE:String = 'NativeAppsWrapper: _runNativeApp - launcher returned internal error while running native application: "%s". Please double check arguments sent to `_runNativeApp()`.';
    private static const MESSAGE_KEY:String = 'message';
    private static const NATIVE_APPS_KEY:String = 'nativeAppsHome';
    private static const NATIVE_HAS_COMPLETED:String = 'nativeHasCompleted';
    private static const NATIVE_HAS_STDERR:String = 'nativeHasStderr';
    private static const NATIVE_HAS_STDOUT:String = 'nativeHasStdout';
    private static const DEFAULT_PIPE_NAME:String = 'NativeAppsWrapper_internalPipe';
    private static const DEFAULT_PTT_PIPE:PTT = PTT.getPipe(DEFAULT_PIPE_NAME);
    private static const SUCCESS:String = 'SUCCESS';
    private static const TEMP_DIR_NAME_TEMPLATE:String = 'maidens-temp-%s';
    private static const TOKEN:String = '%token%';
    private static const UID_LENGTH:int = 5;
    private static const WIN_NATIVE_APPS_DIR:String = 'winnative';
    private static const MAC_NATIVE_APPS_DIR:String = 'macnative';

    private static var _instance:NativeAppsWrapper = new NativeAppsWrapper;

    public static function get instance():NativeAppsWrapper {
        return _instance;
    }

    private static function get NATIVE_APPS_DIR():String {
        if (OSFamily.isWindows) {
            return WIN_NATIVE_APPS_DIR;
        }
        if (OSFamily.isMac) {
            return MAC_NATIVE_APPS_DIR;
        }
        // Will crash on a different OS
        return null;
    }

    public function NativeAppsWrapper() {
        if (_instance != null) {
            throw(new Error('Class NativeAppsWrapper is a singleton, please use `NativeAppsWrapper.instance` instead.'));
        }

        // Setup scratch directory
        if (_tempDirectory == null) {
            var tempRootPath:String = Files.WIN_TMP_ROOT_PATH;
            var dirName:String = TEMP_DIR_NAME_TEMPLATE.replace('%s', Strings.generateUniqueId(_uidsPool, UID_LENGTH));
            _tempDirectory = (new File(tempRootPath)).resolvePath(dirName);
            _tempDirectory.createDirectory();
        }

        // Setup native applications directory
        if (_nativeAppsFolder == null) {
            _nativeAppsFolder = (new File(Files.WIN_INSTALL_PATH)).resolvePath(NATIVE_APPS_DIR);
        }
    }

    private var _currAbcFile:File;
    private var _currAbcMarkup:String;
    private var _currMidiFile:File;
    private var _launcherInternalErrors:Array = [LauncherMessages.BAD_INTERPRETER_PATH,
        LauncherMessages.CANNOT_EXECUTE, LauncherMessages.CANNOT_RESOLVE_PATH,
        LauncherMessages.MISSING_REQUIRED_PATH, LauncherMessages.MISSING_REQUIRED_WDIR,
        LauncherMessages.NP_API_UNAVAILABLE]
    private var _nativeAppsFolder:File;
    private var _tempDirectory:File;
    private var _uidsPool:Object = {};

    public function abcToMIDI(abcMarkup:String, settings:Object, callback:Function):void {
        var session:String = _makeSessionFile(ByteArrays.toByteArray(abcMarkup),
                FileTypes.ABC, _tempDirectory);
        var complete_callback:Function = function (data:Object):void {
            var appFileName:String = (data[APP_FILE_NAME_KEY] as String);
            var arguments:Array = (data[ARGUMENTS_KEY] as Array);
            // var message:String = (data[MESSAGE_KEY] as String);
            if (appFileName == $SCRIPT_MAKE_MIDI) {
                if (arguments.indexOf(session) >= 0) {
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_COMPLETED, complete_callback);
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_STDERR, _onScriptError);
                    callback(session);
                    // On macOs The program producing the MIDI file appends the "1" digit
                    // to the session name.
                    if (OSFamily.osFamily == OSFamily.MAC) {
                        session += '1';
                    }
                    _currMidiFile = _tempDirectory.resolvePath(session.concat(CommonStrings.DOT, FileTypes.MIDI));
                }
            }
        }
        var completionMessage:String = $BANNER_MADE_MIDI.replace(TOKEN, session);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_COMPLETED, complete_callback);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_STDERR, _onScriptError);
        _callNativeApp($SCRIPT_MAKE_MIDI, completionMessage, [session, _tempDirectory.nativePath]);
    }

    public function abcToPdf(abcMarkup:String, settings:Object, callback:Function):void {
        var session:String = _makeSessionFile(ByteArrays.toByteArray(abcMarkup),
                FileTypes.ABC, _tempDirectory);
        var complete_callback:Function = function (data:Object):void {
            var appFileName:String = (data[APP_FILE_NAME_KEY] as String);
            var arguments:Array = (data[ARGUMENTS_KEY] as Array);
            // var message:String = (data[MESSAGE_KEY] as String);
            if (appFileName == $SCRIPT_MAKE_PDF) {
                if (arguments.indexOf(session) >= 0) {
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_COMPLETED, complete_callback);
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_STDERR, _onScriptError);
                    var pdfFile:File = _tempDirectory.resolvePath(session.concat(CommonStrings.DOT, FileTypes.PDF));
                    callback(pdfFile);
                }
            }
        }
        var completionMessage:String = $BANNER_MADE_PDF.replace(TOKEN, session);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_COMPLETED, complete_callback);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_STDERR, _onScriptError);
        _callNativeApp($SCRIPT_MAKE_PDF, completionMessage, [session, _tempDirectory.nativePath]);
    }

    /**
     * Converts given ABC markup into Music XML markup.
     */
    public function abcToXml(abcMarkup:String, settings:Object, callback:Function):void {
        var session:String = _makeSessionFile(ByteArrays.toByteArray(abcMarkup), FileTypes.ABC, _tempDirectory);
        var complete_callback:Function = function (data:Object):void {
            var appFileName:String = (data[APP_FILE_NAME_KEY] as String);
            var arguments:Array = (data[ARGUMENTS_KEY] as Array);
            // var message:String = (data[MESSAGE_KEY] as String);
            if (appFileName == $SCRIPT_MAKE_XML) {
                if (arguments.indexOf(session) != -1) {
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_COMPLETED, complete_callback);
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_STDERR, _onScriptError);
                    var xmlFile:File = _tempDirectory.resolvePath(session.concat(CommonStrings.DOT, FileTypes.XML));
                    callback(xmlFile);
                }
            }
        };
        var completionMessage:String = $BANNER_MADE_XML.replace(TOKEN, session);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_COMPLETED, complete_callback);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_STDERR, _onScriptError);
        _callNativeApp($SCRIPT_MAKE_XML, completionMessage, [session, _tempDirectory.nativePath]);
    }

    public function get currABCFile():File {
        return _currAbcFile;
    }

    public function get currAbcMarkup():String {
        return _currAbcMarkup;
    }

    public function get currMIDIFile():File {
        return _currMidiFile;
    }

    public function deleteScratchDisk():void {
        if (_tempDirectory.exists) {
            _tempDirectory.deleteDirectoryAsync(true);
            _currMidiFile = null;
            _currAbcFile = null;
            _currAbcMarkup = null;
        }
    }

    public function midiToWav(midi:File, settings:Object, callback:Function):void {
        var session:String = Files.getStrippedOffFileName(midi);
        var complete_callback:Function = function (data:Object):void {
            var appFileName:String = (data[APP_FILE_NAME_KEY] as String);
            var arguments:Array = (data[ARGUMENTS_KEY] as Array);
            // var message:String = (data[MESSAGE_KEY] as String);
            if (appFileName == $SCRIPT_MAKE_WAV) {
                if (arguments.indexOf(session) >= 0) {
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_COMPLETED, complete_callback);
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_STDERR, _onScriptError);
                    var wavFile:File = _tempDirectory.resolvePath(session.concat(CommonStrings.DOT, FileTypes.WAV));
                    callback(wavFile);
                }
            }
        }
        var completionMessage:String = $BANNER_MADE_WAV.replace(TOKEN, session);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_COMPLETED, complete_callback);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_STDERR, _onScriptError);
        _callNativeApp($SCRIPT_MAKE_WAV, completionMessage, [session, _tempDirectory.nativePath]);
    }

    public function startMidiPlayback(session:String, settings:Object, callback:Function, progressCallback:Function = null):void {
        trace('\nCalled function startMidiPlayback() with arguments:');
        trace('session:', session);
        trace('settings:', JSON.stringify(settings));
        trace('callback:', callback);
        trace('progressCallback:', progressCallback);
        var stdout_callback:Function = function (data:Object):void {
            trace('Received STDOUT from native application:');
            var appFileName:String = (data[APP_FILE_NAME_KEY] as String);
            var arguments:Array = (data[ARGUMENTS_KEY] as Array);
            var message:String = (data[MESSAGE_KEY] as String);
            trace('appFileName:', appFileName);
            trace('arguments:', arguments);
            trace('message:', message);
            if (appFileName == $SCRIPT_START_MIDI_PLAYBACK) {
                if (arguments.indexOf(session) >= 0) {
                    if (progressCallback != null) {
                        progressCallback(message);
                    }
                }
            }
        }
        var complete_callback:Function = function (data:Object):void {
            trace('Received EXIT from native application:');
            var appFileName:String = (data[APP_FILE_NAME_KEY] as String);
            var arguments:Array = (data[ARGUMENTS_KEY] as Array);
            var message:String = (data[MESSAGE_KEY] as String);
            trace('appFileName:', appFileName);
            trace('arguments:', arguments);
            trace('message:', message);
            if (appFileName == $SCRIPT_START_MIDI_PLAYBACK) {
                if (arguments.indexOf(session) >= 0) {
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_COMPLETED, complete_callback);
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_STDOUT, stdout_callback);
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_STDERR, _onScriptError);
                    callback(session);
                }
            }
        }
        var completionMessage:String = $BANNER_MIDI_PLAYBACK_DONE.replace(TOKEN,
                session);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_COMPLETED, complete_callback);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_STDOUT, stdout_callback);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_STDERR, _onScriptError);
        _callNativeApp($SCRIPT_START_MIDI_PLAYBACK, completionMessage, [session,
            _tempDirectory.nativePath]);
    }


    public function stopMidiPlayback(session:String, callback:Function):void {
        var complete_callback:Function = function (data:Object):void {
            var appFileName:String = (data[APP_FILE_NAME_KEY] as String);
            var arguments:Array = (data[ARGUMENTS_KEY] as Array);
            // var message:String = (data[MESSAGE_KEY] as String);
            if (appFileName == $SCRIPT_STOP_MIDI_PLAYBACK) {
                if (arguments.indexOf(session) >= 0) {
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_COMPLETED, complete_callback);
                    DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_STDERR, _onScriptError);
                    callback(session);
                }
            }
        }
        var completionMessage:String = $BANNER_MIDI_STOPPED.replace(TOKEN, session);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_COMPLETED, complete_callback);
        DEFAULT_PTT_PIPE.subscribe(NATIVE_HAS_STDERR, _onScriptError);
        _callNativeApp($SCRIPT_STOP_MIDI_PLAYBACK, completionMessage, [session]);
    }

    private function _buildLauncherQueryTemplateData(args:Array):Object {
        var ret:Object = {};
        ret[NATIVE_APPS_KEY] = _nativeAppsFolder.nativePath;
        ret[ARGUMENTS_KEY] = args;
        return ret;
    }

    /**
     * Figures out the appropriate application to launch (based on the current operating system) and launches it.
     */
    private function _callNativeApp(appName:String, successSTDOUT:String, args:Array =
            null):void {
        trace('\nCalled function _callNativeApp() with arguments:');
        trace('appName:', appName);
        trace('successSTDOUT:', successSTDOUT);
        trace('args:', args);

        var func:Function = null;
        var os:String = OSFamily.osFamily;
        switch (os) {
            case OSFamily.WINDOWS:
                appName = appName.concat(CommonStrings.DOT, FileTypes.BAT);
                func = _runBatchScript;
                break;
            case OSFamily.MAC:
                appName = appName.concat(CommonStrings.DOT, FileTypes.SH);
                func = _runNativeApp;
                break;
        }

        if (func != null) {
            func(appName, successSTDOUT, args);
        } else {
            trace('No native applications have been defined for use on ', os.toUpperCase(),
                    '- arguments where:', args.join('\n'));
        }
    }

    private static function _haltExecution(template:String, detail:String):void {
        var msg:String = template.replace('%s', detail);
        throw(new Error(msg));
    }

    private static function _haveText(text:String, ...inStrings):Boolean {
        for (var i:int = 0; i < inStrings.length; i++) {
            var str:String = (inStrings[i] as String);
            if (str != null) {
                if (str.indexOf(text) >= 0) {
                    return true;
                }
            }
        }
        return false;
    }

    private function _isInternalErrorMessage(message:String):Boolean {
        for (var i:int = 0; i < _launcherInternalErrors.length; i++) {
            var err:String = (_launcherInternalErrors[i] as String);
            if (message.indexOf(err) >= 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * Creates a file inside a given directory, using the given content and extension. The file name will be the MD5 hash
     * of the content. The file is not overwritten if it exists.
     * @param    fileContent
     *            The content to put inside the file.
     *
     * @param    fileExtension
     *            The extension to use for the file. Use null to bypass adding an extension.
     *
     * @param    homeDirectory
     *            The directory to store the fil in.
     *
     * @return    The MD5 hash of the content, which is also the name of the file, minus dot and extension.
     */
    private static function _makeSessionFile(fileContent:ByteArray, fileExtension:String,
                                      homeDirectory:File):String {
        var sessionName:String = MD5.hashBytes(fileContent as ByteArray);
        var sessionFile:File = homeDirectory.resolvePath(sessionName + (fileExtension ?
                '.' + fileExtension : ''));
        if (!sessionFile.exists) {
            var writer:AbstractDiskWritter = new RawDiskWritter;
            writer.write(fileContent, sessionFile);
        }
        return sessionName;
    }

    private static function _onScriptError(data:Object):void {
        DEFAULT_PTT_PIPE.unsubscribe(NATIVE_HAS_STDERR, _onScriptError);
        trace('HAVE STDERR from application: ', data[APP_FILE_NAME_KEY]);
        trace('Arguments were:\n' + (data[ARGUMENTS_KEY] as Array).join('\n'));
        trace('Message is:\n' + data[MESSAGE_KEY] as String);
        trace('————————————————————');
    }

    /**
     * Calls a Windows batch file (*.bat) in the predefined `nativeAppsHome` folder, passing it given arguments.
     * Assumes that the batch will output a specific message upon successful completion. This function does not use
     * callbacks, instead it sends notifications via the local PTT pipe.
     *
     * @param    scriptName
     *            The batch file name to run.
     *
     * @param    successSTDOUT
     *            A completion message you expect the batch to produce. You will probably include here a unique
     *            argument that you pass to the batch, e.g.: 'operation for MY_SESSION_NAME completed successfully'.
     *
     * @param    args
     *            An array of arguments to be sent to the batch script. Each element in the array will be resolved to
     *            a string, and a whitespace will be used to separate the strings. Whitespaces within the strings are
     *            automatically escaped.
     *
     * @sends    NATIVE_HAS_COMPLETED
     *            Sent when the completion message has been recognized in the batch file's STDOUT or STDERR.
     *            Listening function receives `appFileName` and `arguments` (see above), plus the STDOUT or STDERR
     *            message. Files the batch has created live in the predefined `scratchDisk` folder.
     *
     * @sends    NATIVE_HAS_STDOUT
     *            Sent when the batch produces a STDOUT message. Listening function receives `appFileName` and
     *            `arguments` (see above), plus the STDOUT.
     *
     * @sends    NATIVE_HAS_STDERR
     *            Sent when the batch produces a STDERR message. Listening function receives `appFileName` and
     *            `arguments` (see above), plus the STDERR.
     *
     * @returns    The `Launcher` instance, which received the task of executing the batch script.
     *            This is useful, for instance, for manually terminating the execution process
     *            — via `myLauncher.terminateProcess()`.
     */
    private function _runBatchScript(scriptName:String, successSTDOUT:String,
                                     args:Array = null):Launcher {

        // Internal closure to trigger on STDOUT or STDERR
        var _onLauncherActivity:Function = function (event:DataEvent):void {
            var launcher:Launcher = (event.target as Launcher);
            var messageInfo:String = event.text;
            var stdout:String = launcher.outputDetail;
            var stderr:String = launcher.errorDetail;
            if (messageInfo == LauncherMessages.NATIVE_APPLICATION_EXIT) {
                launcher.removeEventListener(LauncherKeys.LAUNCHER_ACTIVITY,
                        _onLauncherActivity);
                return;
            }
            if (_isInternalErrorMessage(messageInfo)) {
                _haltExecution(LAUNCHER_INTERNAL_ERROR_BATCH, messageInfo);
                return;
            }
            var out:Object = {};
            out[APP_FILE_NAME_KEY] = Files.removeFileNameExtension(scriptName);
            out[ARGUMENTS_KEY] = args;
            if (_haveText(successSTDOUT, messageInfo, stdout, stderr)) {
                out[MESSAGE_KEY] = (stdout || stderr);
                DEFAULT_PTT_PIPE.send(NATIVE_HAS_COMPLETED, out);
                return;
            }
            switch (messageInfo) {
                case LauncherMessages.HAVE_STDOUT:
                    out[MESSAGE_KEY] = (stdout);
                    DEFAULT_PTT_PIPE.send(NATIVE_HAS_STDOUT, out);
                    return;
                case LauncherMessages.HAVE_STDERR:
                    out[MESSAGE_KEY] = (stderr);
                    DEFAULT_PTT_PIPE.send(NATIVE_HAS_STDERR, out);
                    return;
            }
        }

        // Build the query for the Launcher
        var templateFile:File = FileAssets.TEMPLATES_DIR.resolvePath(FileAssets.LAUNCHER_QUERY_TEMPLATE);
        var templateData:Object = _buildLauncherQueryTemplateData(args);
        var launcherQuery:String = Templates.fillSimpleTemplate(templateFile,
                templateData);

        // Create the launcher instance
        var launcherDataSrc:Object = {};
        launcherDataSrc[DataKeys.CONTENT] = {};
        launcherDataSrc[DataKeys.CONTENT][LauncherKeys.ACTION] = LauncherKeys.COMMAND;
        launcherDataSrc[DataKeys.CONTENT][LauncherKeys.PATH] = _nativeAppsFolder.resolvePath(scriptName).nativePath;
        launcherDataSrc[DataKeys.CONTENT][LauncherKeys.DETAILS] = launcherQuery;
        var launcherData:ProjectData = new ProjectData;
        var importer:PlainObjectImporter = new PlainObjectImporter;
        importer.importData(launcherDataSrc, launcherData);
        var launcher:Launcher = new Launcher;
        launcher.scriptingHome = Files.WIN_SYS32_PATH;
        launcher.addEventListener(LauncherKeys.LAUNCHER_ACTIVITY, _onLauncherActivity);

        // Run the launcher
        launcher.launch(launcherData);
        return launcher;
    }

    /**
     * Very similar to `_runBatchScript`, except that it does not route execution through
     * "cmd.exe" (which makes this method suitable for running native code on systems other than Windows).
     *
     * @see `_runBatchScript`
     */
    private function _runNativeApp(appName:String, successSTDOUT:String, args:Array =
            null):Launcher {

        // Internal closure to trigger on STDOUT or STDERR
        var _onLauncherActivity:Function = function (event:DataEvent):void {
            var launcher:Launcher = (event.target as Launcher);
            var messageInfo:String = event.text;
            var stdout:String = launcher.outputDetail;
            var stderr:String = launcher.errorDetail;
            if (messageInfo == LauncherMessages.NATIVE_APPLICATION_EXIT) {
                launcher.removeEventListener(LauncherKeys.LAUNCHER_ACTIVITY,
                        _onLauncherActivity);
                return;
            }
            if (_isInternalErrorMessage(messageInfo)) {
                _haltExecution(LAUNCHER_INTERNAL_ERROR_NATIVE, messageInfo);
                return;
            }
            var out:Object = {};
            out[APP_FILE_NAME_KEY] = Files.removeFileNameExtension(appName);
            out[ARGUMENTS_KEY] = args;
            if (_haveText(successSTDOUT, messageInfo, stdout, stderr)) {
                out[MESSAGE_KEY] = (stdout || stderr);
                DEFAULT_PTT_PIPE.send(NATIVE_HAS_COMPLETED, out);
                return;
            }
            switch (messageInfo) {
                case LauncherMessages.HAVE_STDOUT:
                    out[MESSAGE_KEY] = (stdout);
                    DEFAULT_PTT_PIPE.send(NATIVE_HAS_STDOUT, out);
                    return;
                case LauncherMessages.HAVE_STDERR:
                    out[MESSAGE_KEY] = (stderr);
                    DEFAULT_PTT_PIPE.send(NATIVE_HAS_STDERR, out);
                    return;
            }
        }

        // Build the query for the Launcher
        var templateFile:File = FileAssets.TEMPLATES_DIR.resolvePath(FileAssets.LAUNCHER_QUERY_TEMPLATE);
        var templateData:Object = _buildLauncherQueryTemplateData(args);
        var launcherQuery:String = Templates.fillSimpleTemplate(templateFile,
                templateData);

        // Create the launcher instance
        var launcherDataSrc:Object = {};
        launcherDataSrc[DataKeys.CONTENT] = {};
        launcherDataSrc[DataKeys.CONTENT][LauncherKeys.ACTION] = LauncherKeys.APPLICATION;
        launcherDataSrc[DataKeys.CONTENT][LauncherKeys.PATH] = _nativeAppsFolder.resolvePath(appName).nativePath;
        launcherDataSrc[DataKeys.CONTENT][LauncherKeys.DETAILS] = launcherQuery;
        var launcherData:ProjectData = new ProjectData;
        var importer:PlainObjectImporter = new PlainObjectImporter;
        importer.importData(launcherDataSrc, launcherData);
        var launcher:Launcher = new Launcher;
        launcher.addEventListener(LauncherKeys.LAUNCHER_ACTIVITY, _onLauncherActivity);

        // Run the launcher
        launcher.launch(launcherData);
        return launcher;
    }
}
}
