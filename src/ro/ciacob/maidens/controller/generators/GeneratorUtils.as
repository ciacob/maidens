package ro.ciacob.maidens.controller.generators {
import eu.claudius.iacob.maidens.Sizes;

import flash.utils.getDefinitionByName;
import flash.utils.getQualifiedClassName;

import mx.core.ClassFactory;

import ro.ciacob.desktop.data.constants.DataKeys;
import ro.ciacob.desktop.signals.IObserver;
import ro.ciacob.desktop.signals.PTT;
import ro.ciacob.desktop.windows.IWindowContent;
import ro.ciacob.desktop.windows.IWindowsManager;
import ro.ciacob.desktop.windows.WindowActivity;
import ro.ciacob.desktop.windows.WindowStyle;
import ro.ciacob.desktop.windows.WindowsManager;
import ro.ciacob.desktop.windows.prompts.constants.PromptDefaults;
import ro.ciacob.maidens.controller.Controller;
import ro.ciacob.maidens.controller.MusicUtils;
import ro.ciacob.maidens.controller.QueryEngine;
import ro.ciacob.maidens.controller.constants.GeneratorKeys;
import ro.ciacob.maidens.controller.constants.GeneratorPipes;
import ro.ciacob.maidens.generators.GeneratorBase;
import ro.ciacob.maidens.generators.constants.GeneratorBaseKeys;
import ro.ciacob.maidens.generators.constants.GeneratorSupportedTypes;
import ro.ciacob.maidens.generators.core.ParametersList;
import ro.ciacob.maidens.generators.core.abstracts.AbstractGeneratorModule;
import ro.ciacob.maidens.generators.core.constants.CoreOperationKeys;
import ro.ciacob.maidens.generators.core.interfaces.IParameter;
import ro.ciacob.maidens.model.GeneratorInstance;
import ro.ciacob.maidens.model.GeneratorsWiringMap;
import ro.ciacob.maidens.model.ProjectData;
import ro.ciacob.maidens.model.constants.DataFields;
import ro.ciacob.maidens.model.constants.StaticFieldValues;
import ro.ciacob.maidens.model.constants.StaticTokens;
import ro.ciacob.maidens.view.components.GeneratorProgressUI;
import ro.ciacob.maidens.view.constants.PromptColors;
import ro.ciacob.maidens.view.constants.PromptKeys;
import ro.ciacob.maidens.view.constants.ViewKeys;
import ro.ciacob.utils.ConstantUtils;
import ro.ciacob.utils.Strings;
import ro.ciacob.utils.Templates;
import ro.ciacob.utils.Time;
import ro.ciacob.utils.constants.CommonStrings;

/**
 * "Extension" of the Controller class, grouping code related to Generators manipulation.
 */
public class GeneratorUtils {

    // -----------------
    // Private constants
    // -----------------
    private static const GLOBAL_PIPE:PTT = PTT.getPipe();
    private static const GENERATORS_INIT_PIPE:PTT = PTT.getPipe(GeneratorPipes.INITIALIZATION);
    private static const GENERATORS_OP_PIPE:PTT = PTT.getPipe(GeneratorPipes.OPERATION);
    private static const HIDE_PROGRESS_DELAY:Number = 1.5;


    // -----------------
    // Private variables
    // -----------------
    private var _controller:Controller;
    private var _generatorsManager:GeneratorsManager;
    private var _apiController:ApiController;
    private var _genCfgWindowFactory:ClassFactory;
    private var _currGeneratingModuleId:GeneratorInstance;
    private var _wiringsMap:GeneratorsWiringMap = new GeneratorsWiringMap;
    private var _progressWindowUid:String;
    private var _onProgressWindowExiting:Function;
    private var _onProgressMinimize:Function;

    /**
     * "Extension" of the Controller class, grouping code related to Generators manipulation.
     * @constructor
     */
    public function GeneratorUtils(controller:Controller) {

        // Store a link to the main controller class
        _controller = controller;

        // Initialize the communication system
        _initializeCommunications();

        // Initialize generators handling.
        _generatorsManager = new GeneratorsManager(_controller);
        _apiController = new ApiController(this);
    }


    // --------------
    // Public methods
    // --------------
    /**
     * Provides external access to the received Controller instance.
     */
    public function get controller():Controller {
        return _controller;
    }

    /**
     * Provides external access to the local GeneratorsManager instance.
     */
    public function get generatorsManager():GeneratorsManager {
        return _generatorsManager;
    }

    /**
     * Provides external access to the local GeneratorInstance that represents
     * the currently running Generator.
     */
    public function get currentlyGeneratingModuleUid():GeneratorInstance {
        return _currGeneratingModuleId;
    }

    /**
     * Provides external access to the local GeneratorsWiringMap instance.
     */
    public function get wiringsMap():GeneratorsWiringMap {
        return _wiringsMap;
    }

    /**
     * Handles prompts requested by generators. Short blank prompts will be rendered in the status bar; for other types,
     * appropriate prompt windows shall be used.
     */
    public function showGeneratorPrompt(
            generatorUid:String,
            message:String,
            kind:String = PromptKeys.PROMPT_TYPE_BLANK,
            confirmationCallback:Function = null):void {

        var text:String = StaticTokens.GENERATOR_MESSAGE.replace('%s', _printGeneratorsList(new <String>[generatorUid])).replace('%s', message);
        var renderUsingStatusBar:Boolean = (kind == PromptKeys.PROMPT_TYPE_BLANK && text.length <= StaticFieldValues.MAX_STATUS_TEXT_LENGTH);
        if (renderUsingStatusBar) {
            var data:Object = [];
            data[PromptKeys.TEXT] = text;
            data[PromptKeys.BACKGROUND_COLOR] = PromptColors.INFORMATION;
            GLOBAL_PIPE.send(ViewKeys.NEED_PROMPT, data);
            return;
        }

        var title:String = PromptDefaults.INFORMATION_TITLE;
        var buttons:Vector.<String> = Vector.<String>([PromptDefaults.OK_LABEL]);
        switch (kind) {
            case PromptKeys.PROMPT_TYPE_OK_CANCEL:
                buttons.push(PromptDefaults.OK_LABEL, PromptDefaults.CANCEL_LABEL);
                title = PromptDefaults.CONFIRMATION_TITLE;
                break;
            case PromptKeys.PROMPT_TYPE_YES_NO:
                buttons.push(PromptDefaults.YES_LABEL, PromptDefaults.NO_LABEL);
                title = PromptDefaults.CONFIRMATION_TITLE;
                break;
        }
        var observer:IObserver = _controller.promptsManager.prompt(text, title, null, buttons);
        if (confirmationCallback != null) {
            var callback:Function = function (promptDetail:String):void {
                observer.stopObserving(PromptDefaults.USER_INTERRACTION, callback);
                if (promptDetail == PromptDefaults.OK_LABEL || promptDetail == PromptDefaults.YES_LABEL) {
                    confirmationCallback();
                }
            };
            observer.observe(PromptDefaults.USER_INTERRACTION, callback);
        }
    }

    /**
     * Handles progress reporting requests issued by Generators. Produces a modal dialog that features information,
     * a progress bar, and buttons to abort the process or minimize the application.
     */
    public function showGeneratorProgress(generatorUid:String, info:Object, pipe:PTT):void {

        var windowsManager:IWindowsManager = _controller.windowsManager;
        var status:String = (info.state as String);
        var sessionCompleted:Boolean = (status == AbstractGeneratorModule.STATUS_COMPLETED) ||
                (status == AbstractGeneratorModule.STATUS_ABORTED);

        // Generation done: destroy the window (if available) and exit
        if (sessionCompleted) {
            if (_progressWindowUid) {
                if (windowsManager.isWindowAvailable(_progressWindowUid)) {
                    Time.delay(HIDE_PROGRESS_DELAY, function ():void {
                        if (_onProgressWindowExiting != null) {
                            windowsManager.stopObservingWindowActivity(_progressWindowUid,
                                    WindowActivity.BEFORE_DESTROY, _onProgressWindowExiting);
                            _onProgressWindowExiting = null;
                        }
                        if (_onProgressMinimize != null) {
                            pipe.unsubscribe(GeneratorKeys.GEN_MINIMIZE_REQUESTED, _onProgressMinimize);
                            _onProgressMinimize = null;
                        }
                        windowsManager.destroyWindow(_progressWindowUid);
                        _progressWindowUid = null;
                    });
                }
            }
            windowsManager.updateWindowTitle(_progressWindowUid, Strings.sprintf(
                    GeneratorKeys.GENERATION_STATUS_TEMPLATE, status));
            pipe.send(GeneratorKeys.STATUS_CHANGED, info);
            return;
        }

        // Generation just started: create the window and set it up
        if (!_progressWindowUid) {
            var ui:GeneratorProgressUI = new GeneratorProgressUI;
            ui.pipe = pipe;
            ui.generatorName = _printGeneratorsList(Vector.<String>([generatorUid]));
            _controller.registerColorizableUi(ui);
            _progressWindowUid = windowsManager.createWindow(ui, WindowStyle.PROMPT | WindowStyle.NATIVE, true);
            _onProgressWindowExiting = function (...etc):Boolean {
                pipe.send(GeneratorKeys.GEN_ABORT_REQUESTED);
                return false;
            }
            _onProgressMinimize = function (...etc):void {
                windowsManager.hideWindow(windowsManager.mainWindow);
            }
            pipe.subscribe(GeneratorKeys.GEN_MINIMIZE_REQUESTED, _onProgressMinimize);
            windowsManager.observeWindowActivity(_progressWindowUid, WindowActivity.BEFORE_DESTROY, _onProgressWindowExiting);
            windowsManager.showWindow(_progressWindowUid);
            windowsManager.updateWindowBounds(_progressWindowUid, Sizes.GENERATION_PROGRESS_WINDOW_BOUNDS, true);
            windowsManager.alignWindows(_progressWindowUid, windowsManager.mainWindow, 0.5, 0.5);
        }

        // Generation in progress: just update the window
        windowsManager.updateWindowTitle(_progressWindowUid, Strings.sprintf(
                GeneratorKeys.GENERATION_STATUS_TEMPLATE, status));
        pipe.send(GeneratorKeys.STATUS_CHANGED, info);
    }

    /**
     * Responds to the `GeneratorKeys.PROJECT_GENERATORS_READY` notification sent through the `GeneratorPipes.STATUS` pipe.
     */
    public function onProjectGeneratorsReady(statusQuo:Object):void {
        PTT.getPipe(GeneratorPipes.STATUS).unsubscribe(GeneratorKeys.PROJECT_GENERATORS_READY, onProjectGeneratorsReady);
        _showInitReport(statusQuo);
    }

    // ---------------
    // Private methods
    // ---------------
    /**
     * Subscribes to relevant Generator notifications.
     */
    private function _initializeCommunications():void {
        GLOBAL_PIPE.subscribe(ViewKeys.NEED_AVAILABLE_GENERATORS, _onAvailableGeneratorsRequested);
        GENERATORS_INIT_PIPE.subscribe(GeneratorKeys.GENERATOR_BINDING_REQUEST, _onGeneratorBindingRequested);
        GENERATORS_OP_PIPE.subscribe(GeneratorKeys.NEED_GEN_PROMPT, _onGeneratorPromptRequested);
        GENERATORS_OP_PIPE.subscribe(GeneratorKeys.NEED_GEN_DIALOG, _onGeneratorDialogRequested);
        GENERATORS_OP_PIPE.subscribe(GeneratorKeys.NEED_GEN_OUTPUT_TARGETS, _onOutputTargetsRequested);
        GENERATORS_OP_PIPE.subscribe(GeneratorKeys.NEED_GEN_CFG, _onGenCfgRequested);
        GENERATORS_OP_PIPE.subscribe(GeneratorKeys.NEED_GEN_CFG_FORCE_CLOSED, _onGenCfgForceCloseRequested);
        GENERATORS_OP_PIPE.subscribe(GeneratorKeys.NEED_GEN_EXECUTION, _onGenerateRequested);
    }

    /**
     * Creates a Generator class instance for each generator-connection pair (and stores it for future reuse).
     *
     *
     * @param generatorInstance
     *        An object uniquely designating a specific request for a specific generator to be used.
     *        The user can request several instances of the same generator type, therefore the GeneratorID
     *        class provides both the generator UID and its connection UID.
     *
     * @param callback
     *        A callback to run when the generator code is available.
     */
    private function _wireUpGenerator(generatorInstance:GeneratorInstance, callback:Function):void {
        var generatorClass:Class = _generatorsManager.getGeneratorClassByUid(generatorInstance.fqn);
        if (generatorClass) {
            var generator:GeneratorBase = ((new generatorClass) as GeneratorBase);
            _wiringsMap.add(generatorInstance, generator);
            generator.$init(PTT.getPipe(generatorInstance.signature));
            _sendGeneratorTargetInfo(generatorInstance);
            var generatorData:ProjectData = _controller.queryEngine.getGeneratorNodeData(generatorInstance) as ProjectData;
            var cfgDataset:Object = (generatorData.getContent(GeneratorKeys.CONFIGURATION_DATA) as Object);
            _updateParameterDefaults(generator.$uiEndpoints, cfgDataset);
            callback(generatorInstance);
        }
    }

    private function _writeValueToGenerator(slotValue:Object, generator:ProjectData, slotType:String):void {
        // TODO: implement when generators will accept inputs
    }


    /**
     * Produces a list with the friendly names of the generators referred to by the
     * given `uids`.
     *
     * @param    uids
     *            A list with generator uids.
     *
     * @param    additionalData
     *            Data that is to be printed next to each generator name. Accepts
     *            an object with generator uids as keys and strings as values.
     *
     * @return    A formatted list with generator names (and, optionally, some other
     *            information).
     */
    private function _printGeneratorsList(uids:Vector.<String>, additionalData:Object = null):String {
        var i:int;
        var uid:String;
        var label:String;
        var specificData:String;
        var generatorData:ProjectData;
        var ret:Array = [];
        for (i = 0; i < uids.length; i++) {
            uid = uids[i];
            generatorData = _generatorsManager.getGeneratorByUid(uid);
            label = generatorData.getContent(GeneratorKeys.NAME);
            if (additionalData != null) {
                specificData = (additionalData[uid] as String);
                if (specificData != null) {
                    label += (CommonStrings.SPACE_DASH_SPACE + specificData);
                }
            }
            ret.push(label);
        }
        return ret.join(CommonStrings.COMMA_SPACE);
    }


    /**
     * Throws if given outcome does not meet specific criteria, or if it is null.
     *
     * @param    generatorUid
     *            The unique id of the generator, which produced the outcome being tested.
     *            To be used in the error messages.
     *
     * @param    slotValue
     *            The actual outcome to validate.
     *
     * @param    slotType
     *            The expected data type of the outcome.
     */
    private function _assertValidOutcome(generatorUid:String, slotValue:Object, slotType:String):void {
        var err:String = StaticTokens.INVALID_GENERATOR_OUTCOME.replace('%s', _printGeneratorsList(new <String>[generatorUid]));
        if (slotValue == null) {
            err = err.concat(CommonStrings.SPACE, StaticTokens.NULL_OUTCOME);
            throw (new Error(err));
        }
        var fqn:String = getQualifiedClassName(slotValue);
        var args:Array = ConstantUtils.getAllValues(GeneratorSupportedTypes);
        args.unshift(fqn);
        if (!Strings.isAny.apply(this, args)) {
            err = err.concat(CommonStrings.SPACE,
                    StaticTokens.ILLEGAL_OUTCOME_TYPE.replace('%s',
                            ConstantUtils.getAllValues(GeneratorSupportedTypes).join(', ')
                    )
            );
            throw (new Error(err));
        }
        if (fqn != slotType) {
            err = err.concat(CommonStrings.SPACE, StaticTokens.WRONG_OUTCOME_TYPE.replace('%s', fqn).replace('%s', slotType));
            throw (new Error(err));
        }
    }


    /**
     * We send the generator some basic data about the sections it was connected to, if any.
     * Some generators use such data to further refine their output (e.g., let the user choose
     * which of the available parts to generate for).
     */
    private function _sendGeneratorTargetInfo(generatorId:GeneratorInstance):void {
        var qEngine:QueryEngine = _controller.queryEngine;
        var generatorInstance:Object = _wiringsMap.$get(generatorId);
        var generatorData:ProjectData = qEngine.getGeneratorNodeData(generatorId) as ProjectData;
        var outputConnections:Array = (generatorData.getContent(GeneratorKeys.OUTPUT_CONNECTIONS) as Array);
        var outputsDescription:Array = (generatorData.getContent(GeneratorKeys.OUTPUTS_DESCRIPTION) as Array);
        var targetsInfo:Array = [];
        var info:Object = null;
        for (var i:int = 0; i < outputsDescription.length; i++) {
            var matchingConnectionUid:String = (outputConnections[i] as String);
            var connIdType:String = qEngine.getConnectionUidType(matchingConnectionUid);
            if (connIdType == DataFields.SECTION) {
                var section:ProjectData = qEngine.getSectionByConnectionUid(matchingConnectionUid);
                info = {};
                info[DataFields.DATA_TYPE] = DataFields.SECTION;
                info[DataFields.UNIQUE_SECTION_NAME] = (section.getContent(DataFields.UNIQUE_SECTION_NAME) as String);
                targetsInfo.push(info);
            }
            if (connIdType == DataFields.GENERATOR) {
                var generator:ProjectData = qEngine.getGeneratorByConnectionUid(matchingConnectionUid);
                info = {};
                info[DataFields.DATA_TYPE] = DataFields.GENERATOR;
                info[GeneratorKeys.GLOBAL_UID] = (generator.getContent(GeneratorKeys.GLOBAL_UID) as String);
                targetsInfo.push(info);
            }
        }
        generatorInstance[GeneratorKeys.TARGETS_INFO] = targetsInfo;
    }

    /**
     * Displays a prompt with information about initialized Generators
     */
    private function _showInitReport(statusQuo:Object):void {

        // Display a summary of the generators initialization process
        var all:Vector.<String> = (statusQuo[GeneratorKeys.REQUIRED_GENERATORS_LIST] as Vector.<String>);
        var initialized:Vector.<String> = (statusQuo[GeneratorKeys.INITIALIZED_GENERATORS_LIST] as Vector.<String>);
        if (all.length > 0) {
            var colorStyle:String = PromptColors.WARNING;
            var template:String;
            if (all.length == initialized.length) {
                colorStyle = PromptColors.NOTICE;
                template = StaticTokens.ALL_PROJECT_GENERATORS_INITIALIZED;
            } else {
                template = (initialized.length > 0) ? StaticTokens.SOME_PROJECT_GENERATORS_INITIALIZED : StaticTokens.NO_PROJECT_GENERATORS_INITIALIZED;
            }
            var templateData:Object = {};
            var message:String = Templates.fillSourceTemplate(template, templateData);
            _controller.showStatusOrPrompt(message, colorStyle);
        }
    }

    /**
     * Transfers the music produced by a generator into one of MAIDENS' sections.
     * Filters and transforms the data as needed in the process.
     *
     * @param    slotValue
     *            An object containing the music produced by the generator. The exact
     *            format has still to be determined.
     *
     *            Currently, the only mandatory request is that the object contain a
     *            "noteStreams" key, pointing to a multi-dimensional Array. The expected
     *            format of this multi-dimensional array is as follows:
     *
     *            // level 0 - "partStreams", top level container;
     *            [
     *                // level 1 - "voiceStreams", data for voices pertaining to each
     *                // of the available parts, respectively;
     *                [
     *                    // level 2 - "notesStream", data for the notes to be added to
     *                    // each voice; voices are filled by staff index first, and by
     *                    // voice index second (e.g., first voice of each available
     *                    // staff is first added, from top to bottom, then the second
     *                    // voice of each staff, and so on).
     *                    [
     *                    ]
     *                ]
     *            ]
     *
     * @param    section
     *            The section generated music is to be placed in.
     *
     * @param    slotType
     *            The expected data type of the `slotValue`, as defined by the
     *            generator's "generator.xml" file. Currently, the only supported
     *            value is "Object".
     *
     * @param    generator
     *            The Generator node that produced the value to be written to a section.
     *            Useful for selection management.
     */
    private function _writeValueToSection(slotValue:Object, section:ProjectData, slotType:String, generator:ProjectData):void {
        var qEngine:QueryEngine = _controller.queryEngine;
        switch (slotType) {
            case GeneratorSupportedTypes.OBJECT:
                var partStreams:Array = (slotValue[GeneratorBaseKeys.NOTE_STREAMS] as Array);
                if (partStreams != null) {
                    var partsList:Array = qEngine.getSectionPartsList(section);
                    // TODO: allow generators to control:
                    // - which voices to fill;
                    // - how many measures to output;
                    // - at which measure in the section to start overwriting the
                    // existing
                    //   content;
                    // - and what kind of time signatures to use within these
                    // measures (and
                    //   where).
                }
                for (var i:int = 0; i < partStreams.length; i++) {
                    var voiceStreams:Array = (partStreams[i] as Array);
                    if (voiceStreams != null) {
                        var targetPartName:String = (partsList[i] as String);
                        if (targetPartName) {
                            var targetPart:ProjectData = qEngine.getPartByName(section, targetPartName);
                            if (targetPart == null) {
                                targetPart = qEngine.createPartByName(targetPartName, section);
                            }

                            // The method "putIntoMeasures()" has many interesting (but
                            // optional) features — such as, being able to specify HOW
                            // MANY of the measures of a part to populate/overwrite — but
                            // we chose to ignore those for now; the entire span of a part
                            // is, for now, rewritten, so we explicitly empty ALL the
                            // measures it has, to make room for new content.
                            var numMeasures:int = qEngine.getSectionNumMeasures(section);
                            for (var j:int = 0; j < numMeasures; j++) {
                                var measure:ProjectData = (targetPart.getDataChildAt(j) as ProjectData);
                                qEngine.clearMeasureContent(measure);
                            }
                            for (var streamIndex:int = 0; streamIndex < voiceStreams.length; streamIndex++) {
                                var originalStream:Array = (voiceStreams[streamIndex] as Array);
                                var streamCopy:Array = originalStream.concat();
                                var staffIndex:int = Math.ceil((streamIndex + 1) * 0.5);
                                var voiceIndex:int = ((streamIndex + 1) % 2) ? 1 : 2;
                                qEngine.putIntoMeasures(targetPart, streamCopy, [staffIndex, voiceIndex]);
                            }
                        }
                    }
                }

                // We use held pitches in adjacent chords to replicate polyphony in generated
                // chorals. We reckon that held notes in generated melodies are, graphically
                // superfluous, therefore we will consolidate all these, whenever possible.
                MusicUtils.consolidatePrimeIntervals(section);

                // Since generated music does not precisely overlap the target section (most of the
                // time is a little longer), chances are for ties to be left over on the last
                // generated Cluster. We want to get rid of these.
                MusicUtils.clearTrailingTies(section);

                _controller.model.refreshCurrentProject(false);
                _controller.updateAllViews();
                _controller.lastSelection = null;
                _controller.setSelection(generator);

                // Add recovery point
                _controller.snapshotsManager.takeSnapshot(
                        _controller.model.currentProject,
                        Strings.sprintf(
                                StaticTokens.GENERATOR_WRITE_OPERATION,
                                section.getContent(DataFields.UNIQUE_SECTION_NAME)
                        )
                );
                _controller.updateUndoRedoUi();
                break;
        }

    }

    /**
     * Overwrites all parameters' defaults with their respective user-provided settings, as stored in the current
     * generator's configuration.
     * @param    uiBlueprint
     *            An Object describing the UI controls that need to show in the Configuration window. This Object is
     *            also augmented with a live list of all Parameters, so that the actual payload of every Parameter of
     *            the current Generator is accessible by means of this "uiBlueprint" argument.
     *            @see GeneratorBase.$uiEndpoints
     * @param    cfgDataset
     *            An Object storing the last saved state of a particular generator's instance settings. These are
     *            usually user explicit settings (such as parameter's custom values) but can also originate from
     *            presets.
     *
     *    This method does not return a value; instead it updates the actual payload of all parameters of the current
     *    generator, as well as the values to be shown in the Configuration window, in the event the user chooses to
     *    open it.
     */
    private function _updateParameterDefaults(uiBlueprint:Object, cfgDataset:Object):void {
        if (uiBlueprint && (GeneratorKeys.PARAMETERS in uiBlueprint)) {
            (uiBlueprint[GeneratorKeys.PARAMETERS] as ParametersList).forEach(function (item:IParameter, index:int, etc:Object):void {
                var updatedPayload:Object = cfgDataset.content[item.name];
                if (updatedPayload) {
                    if (item.type == CoreOperationKeys.TYPE_ARRAY) {
                        var arrPayload:Array = (item.payload as Array);
                        var arrUpdatedPayload:Array = (updatedPayload as Array);
                        var spliceArgs:Array = arrUpdatedPayload.concat();
                        spliceArgs.unshift(0, arrPayload.length);
                        arrPayload.splice.apply(arrPayload, spliceArgs);
                    } else {
                        item.payload = updatedPayload;
                    }
                    uiBlueprint[item.uid] = item.payload;
                }
            });
        }
    }

    /**
     * Responds to the GeneratorUI asking for a list with all available generators.
     */
    private function _onAvailableGeneratorsRequested(...ignore):void {
        var availableGenerators:Vector.<ProjectData> = _generatorsManager.getGeneratorsList();
        GLOBAL_PIPE.send(ViewKeys.GENERATORS_LIST, availableGenerators);
    }

    /**
     * Called when a Generator requests that a public API be executed. Triggers the API, and
     * returns the result through a system of callbacks and a pipe.
     *
     * @param    generatorPipe
     *            The pipe to return the result through.
     *
     * @param    inData
     *            The data needed for triggering the API, containing the API name and the arguments
     *            to pass.
     */
    private function _onApiExecutionRequested(generatorPipe:PTT, inData:Object):void {
        var apiName:String = (inData[GeneratorBaseKeys.API_NAME] as String);
        var arguments:Array = (inData[GeneratorBaseKeys.API_ARGUMENTS] as Array);
        var on_api_executed:Function = function (apiName:String, result:Object):void {
            var outData:Object = {};
            outData[GeneratorBaseKeys.API_NAME] = apiName;
            outData[GeneratorBaseKeys.API_OUTPUT] = result;
            generatorPipe.send(GeneratorBaseKeys.API_EXECUTION_RESULT, outData);
        }
        _apiController.touchApi(apiName, on_api_executed, true, arguments);
    }

    /**
     * Called when a Generator requests that a public API availability be confirmed. The answer
     * is sent back through a system of callbacks and a pipe.
     *
     * @param    generatorPipe
     *            The pipe to return the result through.
     *
     * @param    apiName
     *            The name of the API to check if available.
     */
    private function _onApiAvailabilityRequested(generatorPipe:PTT, apiName:String):void {
        var on_api_verified:Function = function (api_name:String, is_api_available:Boolean):void {
            var outData:Object = {};
            outData[GeneratorBaseKeys.API_NAME] = api_name;
            outData[GeneratorBaseKeys.API_EXISTS] = is_api_available;
            generatorPipe.send(GeneratorBaseKeys.API_AVAILABILITY_RESULT, outData);
        }
        _apiController.touchApi(apiName, on_api_verified);
    }

    /**
     * Responds to a `GeneratorKeys.NEED_GEN_OUTPUT_TARGETS` notification received throughout the
     * `GeneratorPipes.OPERATION` pipe.
     *
     * Execution is triggered by the UIBase's `commitProperties()` method. Compiles and sends back
     * a list with all the Section UIDs currently available in the Score.
     *
     * @param    generator
     *            A dataset representing the Generator which initiated the request.
     *
     * @return    An Array with a single element, an Object containing the requested information.
     *            This format is expected by the initiating party.
     */
    private function _onOutputTargetsRequested(generator:ProjectData):void {
        var payload:Object = {};
        var sectionConnectionUids:Array = _controller.queryEngine.getSectionConnectionUids();
        if (sectionConnectionUids.length > 0) {
            payload[ViewKeys.PAGE_HEADER] = GeneratorKeys.SECTION_TARGETS;
            payload[ViewKeys.PAGE_BODY] = sectionConnectionUids;
        }
        GENERATORS_OP_PIPE.send(GeneratorKeys.OUTPUT_TARGETS, [payload]);
    }

    /**
     * Responds to a request of forcingly closing the Generator Configuration window.
     */
    private function _onGenCfgForceCloseRequested(...ignore):void {
        _onGenCfgWindowClosed();
        GLOBAL_PIPE.send(ViewKeys.GEN_CFG_WINDOW_CLOSE);
    }

    /**
     * Responds to a notification of the Generator Configuration window being closed.
     */
    private function _onGenCfgWindowClosed(...ignore):void {
        _controller.windowsManager.stopObservingWindowActivity(_controller.genCfgWindowUid, WindowActivity.BEFORE_DESTROY, _onGenCfgWindowClosing);
        GENERATORS_OP_PIPE.unsubscribe(ViewKeys.GEN_CFG_WINDOW_CLOSE, _onGenCfgWindowClosed);
        _controller.windowsManager.destroyWindow(_controller.genCfgWindowUid);
    }

    /**
     * Responds to a request of showing the Generator Configuration window.
     */
    private function _onGenCfgRequested(generatorInstance:GeneratorInstance):void {

        // Internal callback to handle displaying of the configuration UI for the
        // current generator
        var show_configuration_for:Function = function (generator_instance:GeneratorInstance):void {
            var $winManager:WindowsManager = _controller.windowsManager;

            // Build the configuration window content
            var generatorInstance:Object = _wiringsMap.$get(generator_instance);
            var generatorData:ProjectData = _controller.queryEngine.getGeneratorNodeData(generator_instance) as ProjectData;
            var uiBlueprint:Object = generatorInstance.$uiEndpoints;

            // Show the configuration window. If the generator defines a custom UI class, we redefine the
            // "generator configuration window factory" with that class (by default, the `GeneratorBasicConfiguration`
            // class is used.
            var uiClass:Class;
            var uiClassFqn:String = generatorData.getContent(GeneratorKeys.CONFIGURATION_UI_CLASS);
            if (uiClassFqn != DataFields.VALUE_NOT_SET) {
                uiClass = (getDefinitionByName(uiClassFqn) as Class);
            }
            if (uiClass) {
                _genCfgWindowFactory = new ClassFactory(uiClass);
            }
            var windowData:Object = {};

            // If applicable, overwrite default values in the blueprint with the values stored in the generator instance
            var cfgDataset:Object = (generatorData.getContent(GeneratorKeys.CONFIGURATION_DATA) as Object);
            if (cfgDataset && cfgDataset != DataFields.VALUE_NOT_SET) {
                windowData[GeneratorKeys.GEN_CFG_DATASET] = cfgDataset;
            }

            windowData[GeneratorKeys.GEN_CFG_UI_BLUEPRINT] = uiBlueprint;
            var properties:Object = {};
            properties[ViewKeys.GEN_CFG_WINDOW_DATA] = windowData;
            properties[ViewKeys.PTT_PIPE_NAME] = GeneratorPipes.OPERATION;
            _genCfgWindowFactory.properties = properties;
            var windowContent:IWindowContent = (_genCfgWindowFactory.newInstance() as IWindowContent);
            _controller.registerColorizableUi(windowContent);
            _controller.genCfgWindowUid = $winManager.createWindow(windowContent,
                    WindowStyle.TOOL | WindowStyle.TOP | WindowStyle.NATIVE,
                    true,
                    _controller.mainWindowUid);
            var windowTitle:String = Strings.sprintf(StaticTokens.CONFIGURE_GENERATOR,
                    _printGeneratorsList(new <String>[generator_instance.fqn]), generator_instance.link);
            $winManager.updateWindowTitle(_controller.genCfgWindowUid, windowTitle);
            $winManager.updateWindowBounds(_controller.genCfgWindowUid, Sizes.MIN_GEN_CFG_WINDOW_BOUNDS, false);
            $winManager.updateWindowMinSize(_controller.genCfgWindowUid, Sizes.MIN_GEN_CFG_WINDOW_BOUNDS.width,
                    Sizes.MIN_GEN_CFG_WINDOW_BOUNDS.height, true);
            $winManager.observeWindowActivity(_controller.genCfgWindowUid, WindowActivity.BEFORE_DESTROY,
                    _onGenCfgWindowClosing, this);
            $winManager.showWindow(_controller.genCfgWindowUid);
            $winManager.alignWindows(_controller.genCfgWindowUid, _controller.windowsManager.mainWindow, 0.5, 0.5);
            GENERATORS_OP_PIPE.send(ViewKeys.GEN_CFG_WINDOW_OPEN);
            GENERATORS_OP_PIPE.subscribe(ViewKeys.GEN_CFG_WINDOW_CLOSE, _onGenCfgWindowClosed);
        }

        if (!_wiringsMap.has(generatorInstance)) {
            _wireUpGenerator(generatorInstance, show_configuration_for);
        } else {
            show_configuration_for(generatorInstance);
        }
    }

    /**
     * Responds to a `GeneratorKeys.NEED_GEN_PROMPT` request received throughout the
     * `GeneratorPipes.OPERATION` pipe.
     */
    private function _onGeneratorPromptRequested(text:String):void {
        _controller.showStatusOrPrompt(text, PromptColors.INFORMATION);
    }

    /**
     * Responds to a `GeneratorKeys.NEED_GEN_DIALOG` request delivered throughout the `GeneratorPipes.OPERATION`
     * pipe. Causes the Controller to display a dialog window on behalf of a generator.
     */
    private function _onGeneratorDialogRequested(text:String):void {
        _controller.showPrompt(text);
    }

    /**
     * Responds to a `GeneratorKeys.NEED_GEN_DEFAULT_DATA` request coming throughout the `GENERATORS_INIT_PIPE`.
     * This is executed when user selects a generator entry in the "Binding" combo box control inside the
     * Generator Editor panel. Causes the selected Generator to be initialized and readied.
     */
    private function _onGeneratorBindingRequested(uid:String):void {

        // Internal callback to handle initialization success
        var respondBack:Function = function (generator_uid:String):void {
            GENERATORS_INIT_PIPE.unsubscribe(GeneratorKeys.INITIALIZED_GENERATOR, respondBack);
            GENERATORS_INIT_PIPE.send(ViewKeys.GENERATOR_BINDING_DONE, uid);
            _controller.showStatusOrPrompt(
                    Strings.sprintf(
                            StaticTokens.GENERATOR_INITIALIZED,
                            _printGeneratorsList(
                                    Vector.<String>([uid])
                            )
                    )
            );
        }

        // Initialize generator if needed, otherwise just provide its stored data
        if (!_generatorsManager.isGeneratorInitialized(uid)) {
            GENERATORS_INIT_PIPE.subscribe(GeneratorKeys.INITIALIZED_GENERATOR, respondBack);
            _generatorsManager.initializeGenerator(uid);
        } else {
            respondBack(uid);
        }
    }


    /**
     * Called when user clicks on the "generate" button inside the GeneratorUI view.
     * Receives the generator's global UID as a parameter.
     */
    private function _onGenerateRequested(generatorId:GeneratorInstance):void {

        // Internal callback to handle the execution of the module's code
        var launch_execution_for:Function = function (...args):void {
            _currGeneratingModuleId = generatorId;
            var generatorData:ProjectData = _controller.queryEngine.getGeneratorNodeData(generatorId) as ProjectData;
            var generatorPipe:PTT = PTT.getPipe(generatorId.signature);
            generatorPipe.subscribe(GeneratorBaseKeys.MODULE_GENERATION_COMPLETE, on_generator_output_ready);
            generatorPipe.subscribe(GeneratorBaseKeys.MODULE_GENERATION_ABORTED, on_generator_output_aborted);
            generatorPipe.subscribe(GeneratorBaseKeys.NEED_API_EXECUTION, function (...args):void {
                args.unshift(generatorPipe);
                _onApiExecutionRequested.apply(this, args);
            });
            generatorPipe.subscribe(GeneratorBaseKeys.NEED_API_AVAILABILITY, function (...args):void {
                args.unshift(generatorPipe);
                _onApiAvailabilityRequested.apply(this, args);
            });
            var generatorInstance:GeneratorBase = _wiringsMap.$get(generatorId);
            var confData:Object = generatorData.getContent(GeneratorKeys.CONFIGURATION_DATA);
            if (confData != DataFields.VALUE_NOT_SET) {
                var values:Object = confData [DataKeys.CONTENT];
                for (var key:String in values) {

                    // NOTE: legacy generator (Atonal Line, Atonal Harmony) use lists of parameters,
                    // which are known ahead of time, and thus are implemented as public members of
                    // their base classes.
                    //
                    // By contrast, second generation generators (HarmonyGenerator) are modelled using
                    // a scalable model, where parameters can be added to an existing generator as
                    // needed, to enrich its abilities. These generators use an alternative mechanism
                    // for collecting user input (the pervasive, "_parameters" IParameterList), which
                    // makes defining public members for each supported parameter futile. The code
                    // below is legacy code, and is only used by legacy generators.
                    if (key in generatorInstance) {
                        var value:Object = (values[key] as Object);
                        generatorInstance[key] = value;
                    }
                }
            }
            generatorInstance.$generate();
        }

        // Internal callback to handle the retrieval of the Generator's output and its dispatch to interested parties
        var on_generator_output_ready:Function = function (...args):void {
            var outcome:Object;
            var generatorData:ProjectData = _controller.queryEngine.getGeneratorNodeData(generatorId) as ProjectData;
            var outputConnections:Array = (generatorData.getContent(GeneratorKeys.OUTPUT_CONNECTIONS) as Array);
            var outputsDescription:Array = (generatorData.getContent(GeneratorKeys.OUTPUTS_DESCRIPTION) as Array);
            var generatorPipe:PTT = PTT.getPipe(generatorId.signature);
            generatorPipe.unsubscribe(GeneratorBaseKeys.MODULE_GENERATION_COMPLETE, on_generator_output_ready);
            generatorPipe.unsubscribe(GeneratorBaseKeys.MODULE_GENERATION_ABORTED, on_generator_output_aborted);
            generatorPipe.unsubscribe(GeneratorBaseKeys.NEED_API_EXECUTION);
            generatorPipe.unsubscribe(GeneratorBaseKeys.NEED_API_AVAILABILITY);
            var generatorInstance:GeneratorBase = _wiringsMap.$get(generatorId);
            outcome = generatorInstance.$getOutput();
            if (outcome != null) {
                for (var i:int = 0; i < outputsDescription.length; i++) {
                    var desc:Object = outputsDescription[i];
                    var slotName:String = (desc[GeneratorKeys.SLOT_NAME] as String);
                    var slotType:String = (desc[GeneratorKeys.SLOT_DATA_TYPE] as String);
                    var slotValue:Object = outcome[slotName];
                    _assertValidOutcome(generatorId.fqn, slotValue, slotType);
                    for (var j:int = 0; j < outputConnections.length; j++) {
                        var connectionId:String = (outputConnections[j] as String);
                        var connIdType:String = _controller.queryEngine.getConnectionUidType(connectionId);
                        var generator:ProjectData = _controller.queryEngine.getGeneratorByConnectionUid(generatorId.link);
                        if (connIdType == DataFields.SECTION) {
                            var section:ProjectData = _controller.queryEngine.getSectionByConnectionUid(connectionId);
                            _writeValueToSection(slotValue, section, slotType, generator);
                        } else if (connIdType == DataFields.GENERATOR) {
                            _writeValueToGenerator(slotValue, generator, slotType);
                        }
                    }
                }
            }
            _currGeneratingModuleId = null;
            GENERATORS_OP_PIPE.send(GeneratorKeys.ALL_GENERATION_DONE);
            _controller.showStatusOrPrompt(
                    StaticTokens.GENERATION_SUCCESS.replace(
                            '%s', _printGeneratorsList(
                                    Vector.<String>(
                                            [generatorId.fqn]
                                    )
                            )
                    )
            );
        }

        // Internal callback to handle the scenario where the user cancels the generation process midway
        var on_generator_output_aborted:Function = function (...args):void {
            var generatorPipe:PTT = PTT.getPipe(generatorId.signature);
            generatorPipe.unsubscribe(GeneratorBaseKeys.MODULE_GENERATION_COMPLETE, on_generator_output_ready);
            generatorPipe.unsubscribe(GeneratorBaseKeys.MODULE_GENERATION_ABORTED, on_generator_output_aborted);
            generatorPipe.unsubscribe(GeneratorBaseKeys.NEED_API_EXECUTION);
            generatorPipe.unsubscribe(GeneratorBaseKeys.NEED_API_AVAILABILITY);
            _currGeneratingModuleId = null;
            GENERATORS_OP_PIPE.send(GeneratorKeys.ALL_GENERATION_DONE);
        }

        if (!_wiringsMap.has(generatorId)) {
            _wireUpGenerator(generatorId, launch_execution_for);
        } else {
            launch_execution_for(generatorId);
        }
    }


    /**
     * Executes when the generator Configuration window initiates its closing sequence as
     * a result of the user clicking its "X" button.
     *
     * Prevents the window from closing and reports the matter to interested parties.
     * The window will be closed programmatically instead, when appropriate.
     */
    private static function _onGenCfgWindowClosing(...ignore):Boolean {
        GENERATORS_OP_PIPE.send(ViewKeys.GEN_CFG_WINDOW_CLOSING);
        return false;
    }

    //---
}
}