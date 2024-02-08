package ro.ciacob.maidens.controller {
import com.greensock.plugins.AutoAlphaPlugin;
import com.greensock.plugins.TweenPlugin;

import eu.claudius.iacob.maidens.Sizes;
import eu.claudius.iacob.maidens.skins.RasterImages;
import eu.claudius.iacob.synth.constants.OperationTypes;
import eu.claudius.iacob.synth.events.PlaybackAnnotationEvent;
import eu.claudius.iacob.synth.events.SystemStatusEvent;
import eu.claudius.iacob.synth.sound.generation.SynthProxy;
import eu.claudius.iacob.synth.sound.map.AnnotationAction;
import eu.claudius.iacob.synth.sound.map.AnnotationTask;
import eu.claudius.iacob.synth.utils.AudioUtils;
import eu.claudius.iacob.synth.utils.FileUtils;
import eu.claudius.iacob.synth.utils.PresetDescriptor;
import eu.claudius.iacob.synth.utils.ProgressReport;
import eu.claudius.iacob.synth.utils.SoundLoader;
import eu.claudius.iacob.synth.utils.StreamingUtils;

import flash.desktop.InvokeEventReason;
import flash.desktop.NativeApplication;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Stage;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.InvokeEvent;
import flash.filesystem.File;
import flash.filters.ColorMatrixFilter;
import flash.geom.Rectangle;
import flash.net.URLRequest;
import flash.net.navigateToURL;
import flash.utils.ByteArray;
import flash.utils.getQualifiedClassName;

import mx.controls.Menu;
import mx.controls.ToolTip;
import mx.core.ClassFactory;
import mx.core.FlexGlobals;
import mx.events.MenuEvent;
import mx.utils.UIDUtil;

import ro.ciacob.ciacob;
import ro.ciacob.data.Snapshot;
import ro.ciacob.data.SnapshotsManager;
import ro.ciacob.desktop.data.DataElement;
import ro.ciacob.desktop.data.constants.DataKeys;
import ro.ciacob.desktop.filebrowser.FileFilterEntry;
import ro.ciacob.desktop.filebrowser.FileSelectionEvent;
import ro.ciacob.desktop.filebrowser.components.FileBrowser;
import ro.ciacob.desktop.filebrowser.windowable.WindowableFileBrowser;
import ro.ciacob.desktop.io.AbstractDiskReader;
import ro.ciacob.desktop.io.AbstractDiskWritter;
import ro.ciacob.desktop.io.RawDiskReader;
import ro.ciacob.desktop.io.RawDiskWritter;
import ro.ciacob.desktop.io.TextDiskWritter;
import ro.ciacob.desktop.signals.IObserver;
import ro.ciacob.desktop.signals.PTT;
import ro.ciacob.desktop.statefull.Persistence;
import ro.ciacob.desktop.windows.IWindowContent;
import ro.ciacob.desktop.windows.IWindowsManager;
import ro.ciacob.desktop.windows.WindowActivity;
import ro.ciacob.desktop.windows.WindowStyle;
import ro.ciacob.desktop.windows.WindowsManager;
import ro.ciacob.desktop.windows.prompts.PromptsManager;
import ro.ciacob.desktop.windows.prompts.constants.PromptDefaults;
import ro.ciacob.maidens.controller.constants.AudioKeys;
import ro.ciacob.maidens.controller.constants.CopiableProperties;
import ro.ciacob.maidens.controller.constants.GeneratorKeys;
import ro.ciacob.maidens.controller.constants.GeneratorPipes;
import ro.ciacob.maidens.controller.constants.MeasureSelectionKeys;
import ro.ciacob.maidens.controller.delegates.ContextualMenusManager;
import ro.ciacob.maidens.controller.generators.GeneratorUtils;
import ro.ciacob.maidens.controller.generators.GeneratorsManager;
import ro.ciacob.maidens.generators.constants.BarTypes;
import ro.ciacob.maidens.generators.constants.BracketTypes;
import ro.ciacob.maidens.generators.constants.ClefTypes;
import ro.ciacob.maidens.generators.constants.MIDI;
import ro.ciacob.maidens.generators.constants.duration.CompoundTimeSignatures;
import ro.ciacob.maidens.generators.constants.duration.DivisionTypes;
import ro.ciacob.maidens.generators.constants.duration.DivisionsEquivalency;
import ro.ciacob.maidens.generators.constants.duration.DivisionsUsedInCompoundSignatures;
import ro.ciacob.maidens.generators.constants.duration.DivisionsUsedInSimpleSignatures;
import ro.ciacob.maidens.generators.constants.duration.DurationFractions;
import ro.ciacob.maidens.generators.constants.duration.DurationSymbols;
import ro.ciacob.maidens.generators.constants.parts.PartAbbreviatedNames;
import ro.ciacob.maidens.generators.constants.parts.PartDefaultBrackets;
import ro.ciacob.maidens.generators.constants.parts.PartDefaultClefs;
import ro.ciacob.maidens.generators.constants.parts.PartDefaultStavesNumber;
import ro.ciacob.maidens.generators.constants.parts.PartNames;
import ro.ciacob.maidens.generators.constants.parts.PartRanges;
import ro.ciacob.maidens.generators.constants.parts.PartTranspositions;
import ro.ciacob.maidens.generators.constants.pitch.Direction;
import ro.ciacob.maidens.model.Model;
import ro.ciacob.maidens.model.ModelUtils;
import ro.ciacob.maidens.model.ProjectData;
import ro.ciacob.maidens.model.constants.Common;
import ro.ciacob.maidens.model.constants.DataFields;
import ro.ciacob.maidens.model.constants.DataFormats;
import ro.ciacob.maidens.model.constants.FileAssets;
import ro.ciacob.maidens.model.constants.ModelKeys;
import ro.ciacob.maidens.model.constants.PersistenceKeys;
import ro.ciacob.maidens.model.constants.StaticFieldValues;
import ro.ciacob.maidens.model.constants.StaticTokens;
import ro.ciacob.maidens.model.constants.URLs;
import ro.ciacob.maidens.model.constants.Voices;
import ro.ciacob.maidens.model.exporters.SynthTracksProducer;
import ro.ciacob.maidens.view.components.PickupComponentWindow;
import ro.ciacob.maidens.view.components.RenderProgressUI;
import ro.ciacob.maidens.view.components.ScaleIntervalsUI;
import ro.ciacob.maidens.view.components.TranspositionUi;
import ro.ciacob.maidens.view.constants.AudioPipes;
import ro.ciacob.maidens.view.constants.MenuCommandNames;
import ro.ciacob.maidens.view.constants.PromptColors;
import ro.ciacob.maidens.view.constants.PromptKeys;
import ro.ciacob.maidens.view.constants.UiColorizationThemes;
import ro.ciacob.maidens.view.constants.ViewKeys;
import ro.ciacob.maidens.view.constants.ViewPipes;
import ro.ciacob.math.Fraction;
import ro.ciacob.utils.ConstantUtils;
import ro.ciacob.utils.Descriptor;
import ro.ciacob.utils.Files;
import ro.ciacob.utils.Strings;
import ro.ciacob.utils.Time;
import ro.ciacob.utils.constants.CommonStrings;
import ro.ciacob.utils.constants.FileTypes;
import ro.ciacob.utils.constants.GenericFieldNames;

import spark.components.WindowedApplication;

use namespace ciacob;

public class Controller {

    /**
     * @constructor
     *
     * @param    mainView
     *            The outermost container, holding all the other "views" or view "parts" in the application.
     *
     * @param    windowsManager
     *            The WindowsManager instance that will handle creating secondary windows.
     *
     * @param    mainWindowUid
     *            The unique ID of the window that is to be considered "main".
     */
    public function Controller(mainView:DisplayObjectContainer, windowsManager:IWindowsManager, mainWindowUid:String) {

        // Initialize audio support
        _audioStorage = AudioUtils.makeSamplesStorage();
        _synthProxy = new SynthProxy(_audioStorage);
        _synthProxy.addEventListener(PlaybackAnnotationEvent.PLAYBACK_ANNOTATION_EVENT, _onPlaybackAnnotation);
        _soundLoader = new SoundLoader;
        _soundLoader.addEventListener(SystemStatusEvent.REPORT_EVENT, _onSoundsLoaderReport);

        // Initialize delegates (essentially Controller's extensions, so that we need not put all the code in one class).
        _contextualMenusManager = new ContextualMenusManager(this);
        _generatorUtils = new GeneratorUtils(this);

        // Initialize Undo/Redo support
        _snapshotsManager = new SnapshotsManager(StaticFieldValues.DEFAULT_NUM_UNDO_STEPS);

        // Initialize the application
        var _mainApplication:WindowedApplication = WindowedApplication(FlexGlobals.topLevelApplication);
        _mainView = mainView;
        registerColorizableUi(_mainView);

        // Initialize the communication system
        _initializeCommunications();

        // Initialize model and main view
        _model = new Model;
        _initializeMainView();

        // Initialize additional windows
        _windowsManager = windowsManager;
        _mainWindowUid = mainWindowUid;
        _windowsManager.observeWindowActivity(_mainWindowUid, WindowActivity.FOCUS, _updateProjectInfo);
        _pickupComponentWindowFactory = new ClassFactory(PickupComponentWindow);
        _fileBrowserWindowFactory = new ClassFactory(WindowableFileBrowser);

        // Initialize standard "prompts" (Alert, Confirmation, Question, etc.)
        _promptsManager = new PromptsManager;
        _promptsManager.init(_windowsManager,
                RasterImages.PROMPT_INFO,
                RasterImages.PROMPT_QUESTION,
                RasterImages.PROMPT_ERROR,
                RasterImages.PROMPT_INFO,
                null,
                null,
                null,
                null,
                registerColorizableUi,
                true);

        // Initialize the persistence system
        _persistenceEngine = new Persistence(Descriptor.getAppSignature());
        _readFromPersistence();

        // Initialize termination tasks
        _mainApplication.addEventListener(Event.CLOSING, _onMainWindowClosing);

        // Initialize `invocations` handling (enables the application to open
        // registered files when double clicked, as well as receiving command-line
        // (startup arguments).
        _mainApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, _onNativeInvocation);

        // Initialize animation library
        _initTweening();
    }


    // ----------------
    // Public variables
    // ----------------
    /**
     * The unique id of the Generator Configuration window.
     */
    public var genCfgWindowUid:String;

    /**
     * Storage for the last known selected element.
     */
    public var lastSelection:ProjectData;


    // -----------------
    // Private constants
    // -----------------
    private static const PASTE_MULTIPLE:String = 'pasteMultiple';
    private static const PASTE_SINGLE:String = 'pasteSingle';
    private static const GLOBAL_PIPE:PTT = PTT.getPipe();
    private static const RENDER_PIPE:PTT = PTT.getPipe(AudioPipes.RENDER_PIPE);
    private static const STREAMING_DELAY:int = 1;
    private static const RENDER_WINDOW_CLOSE_DELAY:int = 1;


    // -----------------
    // Private variables
    // -----------------

    /**
     * Stores a reference to the ByteArray where rendered audio is being stored.
     */
    private var _audioStorage:ByteArray;

    /**
     * Stores a reference to the class that produces organized sound based on the current score.
     */
    private var _synthProxy:SynthProxy;

    /**
     * Holds an instance of the eu.claudius.iacob.synth.utils.SoundLoader class; used to load external sounds for the
     * synthesizer to use.
     */
    private static var _soundLoader:SoundLoader;

    /**
     * Cache to hold ByteArrays for every sound data needed in order to synthesize audio for the musical instruments
     * currently involved with the score. The ByteArrays are indexed by their respective instrument MIDI preset number
     * (e.g., `0` will hold the sounds for the Piano, `40` will hold the sounds for the Violin, etc.).
     */
    private static var _loadedSounds:Object;

    /**
     * Holds an instance of the eu.claudius.iacob.synth.utils.StreamingUtils class; used to begin playback of a score
     * while its audio is being rendered in the background.
     */
    private var _audioStreamer:StreamingUtils;

    /**
     * Holds an instance of the eu.claudius.iacob.synth.utils.FileUtils class; mainly used to export audio to disk, as
     * *.wav files.
     */
    private var _audioFileUtils:FileUtils;

    /**
     * Bidimensional Array containing Arrays of low-level synth instructions that, when carried out, will result in
     * an audio rendering ready to be played back;
     */
    private var _tracksInfo:Array;

    /**
     * Set to either `_doOnlineStreaming()` or `_doOfflineStreaming()`, to carry on an audible or silent streaming,
     * respectively.
     */
    private var _streamingRoutine:Function;

    /**
     * Stores a reference to the file the user selects as a target for exporting the project in WAVE format.
     */
    private var _targetWaveFile:File;

    /**
     * Storage for the UID allocated to the "Record in Progress" window that shows when doing a "dry" export to
     * WAVE format (choosing "File - Export - To WAV format" without listening to the score first, so that it has a
     * chance to render MIDI to audio).
     */
    private var _renderWindowUid:String;

    /**
     * Stores a pointer to the listener that responds to the user closing the "Record in Progress" window by its "x"
     * button.
     */
    private var _onRenderWindowExiting:Function;

    /**
     * Stores a pointer to the listener that responds to the user pressing the "Minimize" button inside the
     * "Record in Progress" window.
     */
    private var _onRenderMinimize:Function;

    /**
     * Stores a pointer to the listener that responds to the user pressing the "Abort" button inside the "Record in
     * Progress" window.
     */
    private var _onRenderAbort:Function;

    /**
     * Stores a reference to the class that manages contextual menus.
     */
    private var _contextualMenusManager:ContextualMenusManager;

    /**
     * Stores a reference to the class that handles Generators.
     */
    private var _generatorUtils:GeneratorUtils;

    /**
     * Used by the current Undo/Redo implementation.
     */
    private var _snapshotsManager:SnapshotsManager;

    /**
     * Used by the in-score copy/cut/paste implementation
     */
    private var _pasteSource:ProjectData;

    /**
     * Used by the in-score copy/cut/paste implementation: a `copy` operation will
     * allow for multiple `paste` operations, while a `cut` operation will allow for
     * exactly one paste.
     */
    private var _pasteType:String = PASTE_MULTIPLE;

    /**
     * Used by the transposition "macro". Stores the last settings that the user has entered in the
     * "Transpose" UI. The next time the user opens that interface, it will have these settings preloaded.
     * The idea is to make it easier for the user to apply similar transposition settings several times.
     */
    private var _transpositionUserConfig:Object;

    /**
     * Used by the scale intervals "macro". Stores the last settings that the user has entered in the
     * "Scale Intervals" UI. The next time the user opens that interface, it will have the settings
     * preloaded.
     */
    private var _scaleIntervalsUserConfig:Object;

    /**
     * @volatile
     * Only used while updating or deleting part nodes. Do not employ anywhere else.
     */
    private var __beingSearchedForPartUuid:String;

    /**
     * TODO: Document.
     */
    private var _bufferedABC:String;

    /**
     * TODO: Document.
     */
    private var _bufferedTreeData:Object;

    /*
	 * Maintains a reference to the `Part` instance relevant to current selection. Since the editor works on
	 * orphaned clones, this is the only way to let children of a part (measures, voices, clusters**, notes)
	 * know about the part they relate to.
	 */
    private var _currentPart:ProjectData;

    /*
	 * Used as a heuristic approach to deliver the likely most relevant Part node when the user clicks on a part
	 * hotspot in the score.
	 */
    private var _currentSection:ProjectData;

    /*
	 * TODO: document
	 */
    private var _fileBrowserWindowFactory:ClassFactory;

    /**
     * TODO: Document.
     */
    private var _fileBrowserWindowUid:String;

    /**
     * TODO: Document.
     */
    private var _fileBrowser:FileBrowser;

    /*
	 * A function to be called when a file or folder is selected within the file browser. Must accept an argument
	 * of type File.
	 */
    private var _fileSelectedCallback:Function;

    /*
	 * A flag to be raised when the file browser window must be kept alive after selecting a file (e.g., to support
	 * a secondary window, such as: "Are you sure you want to override file X?"
	 */
    private var _deferFileBrowserClose:Boolean;

    /*
	 * Context to run the Function object pointed-to by `_fileSelectedCallback` in. Optional -- `null` is a valid
	 * context too.
	 */
    private var _fileSelectedCallbackContext:Object;

    /**
     * Holds the unique ID of the window that delivers the "Transpose" functionality.
     */
    private var _transpositionWindowUid:String;

    /**
     * Holds the unique ID of the window that delivers the "Scale Intervals" functionality.
     */
    private var _scaleIntervalsWindowUid:String;

    /**
     * Flag we raise while MIDI transport is in progress.
     */
    private var _isMidiPlaying:Boolean;

    /**
     * TODO: Document.
     */
    private var _mainView:DisplayObjectContainer;

    /**
     * TODO: Document.
     */
    private var _mainWindowUid:String;

    /**
     * Holds an instance of the "persistence engine" (see the Persistence Library), a simple mechanism to deposit values
     * cross sessions.
     */
    private var _persistenceEngine:Persistence;

    /**
     * TODO: Document.
     */
    private var _measureSelectionStaffIndex:int = 0;

    /**
     * TODO: Document.
     */
    private var _measureSelectionType:String = MeasureSelectionKeys.DEFAULT_SELECTION_MODE;

    /**
     * TODO: Document.
     */
    private var _midiSessionUid:String;

    /**
     * TODO: Document.
     */
    private var _model:Model;

    /**
     * TODO: Document.
     */
    private var _pickupComponentWindowFactory:ClassFactory;

    /**
     * TODO: Document.
     */
    private var _pickupWindowUid:String;

    /**
     * TODO: Document.
     */
    private var _scoreRendererReady:Boolean;

    /**
     * TODO: Document.
     */
    private var _structureTreeReady:Boolean;

    /**
     * TODO: Document.
     */
    private var _windowsManager:IWindowsManager;

    /**
     * TODO: Document.
     */
    private var _promptsManager:PromptsManager;

    /**
     * Holds a reference to the pop-up menu that is currently visible over the main view.
     */
    private var _popUpMenu:Menu;

    /**
     * Storage for all Display Objects needing to be colorized if/when a user chooses to use a
     * theme other than the default.
     */
    private var _colorizableUi:Object;

    /**
     * Saves the current operating mode of the "nudge" buttons. When `true` (default), "nudging" must respect current
     * container's boundaries, e.g., clusters cannot be nudged outside their voice/measure; when `false`, "nudging" can
     * cross boundaries, subject to specific rules (e.g., clusters can be nudged to the same voice of adjacent
     * measures).
     */
    private var _nudgeLock:Boolean = true;

    /**
     * Color matrix to be applied to all the items collected in `_colorizationClients`.
     */
    public var currColorMatrix:ColorMatrixFilter = null;


    // ----------------
    // Public accessors
    // ----------------
    /**
     * Provides external access to the local SnapshotsManager instance.
     */
    public function get snapshotsManager():SnapshotsManager {
        return _snapshotsManager;
    }

    /**
     * Provides external access to the local Model instance.
     */
    public function get model():Model {
        return _model;
    }

    /**
     * Provides external access to the received WindowsManager instance.
     */
    public function get windowsManager():WindowsManager {
        return (_windowsManager as WindowsManager);
    }

    /**
     * Provides external access to the unique id of the main window.
     */
    public function get mainWindowUid():String {
        return _mainWindowUid;
    }

    /**
     *  Provides external access to the local PromptsManager instance.
     */
    public function get promptsManager():PromptsManager {
        return _promptsManager;
    }

    /**
     * Proxy to deliver the correct QueryEngine.
     */
    public function get queryEngine():QueryEngine {
        return _model.queryEngine;
    }


    // --------------
    // Public methods
    // --------------
    /**
     * Updates the Undo/Redo menu entries and/or toolbar buttons based on the internal
     * state of the application.
     */
    public function updateUndoRedoUi():void {
        var data:Object = {};
        if (_snapshotsManager.canUndo) {
            data[ViewKeys.UNDO_DESCRIPTION] = _snapshotsManager.undoLabel;
        }
        if (_snapshotsManager.canRedo) {
            data[ViewKeys.REDO_DESCRIPTION] = _snapshotsManager.redoLabel;
        }
        data[ViewKeys.CAN_UNDO] = _snapshotsManager.canUndo;
        data[ViewKeys.CAN_REDO] = _snapshotsManager.canRedo;
        GLOBAL_PIPE.send(ViewKeys.UNDO_REDO_STATUSQUO, data);
    }

    /**
     * Propagates given selection to a number of views, depending on the arguments.
     *
     * @param element
     *        The element to consider the current selection
     *
     * @param omitScore
     *        Optional, defaults to `false`. Whether to skip updating the score (useful when the
     * current selection operation originated from the score editor).
     *
     * @param omitTree
     *        Optional, defaults to false. Whether to skip updating the "project structure" tree
     *        (useful when the current selection operation originated from the tree component).
     */
    public function setSelection(element:ProjectData, omitScore:Boolean = false, omitTree:Boolean = false):void {
        if (lastSelection != element) {

            // Mark generated MIDI as dirty (because playback must respect the selection, if there is one).
            _midiSessionUid = null;

            lastSelection = element;
            var uid:String = null;
            if (element != null) {
                uid = element.route;
            }

            // Update the tree selection
            if (!omitTree) {
                PTT.getPipe(ViewPipes.PROJECT_TREE_PIPE).send(ViewKeys.EXTERNALLY_SELECTED_TREE_ITEM, uid);
            }

            // Update the availability status of the ADD, REMOVE, UP, DOWN,
            // COPY, CUT, DELETE operations
            _updateStructureOperationsStatus();

            // Load the selected element in the editor
            var data:Object = {};
            data[ViewKeys.EDITED_ELEMENT_ROUTE] = uid;
            if (element != null) {
                data[ViewKeys.EDITED_ELEMENT] = (element as ProjectData);
            } else {
                data[ViewKeys.EDITED_ELEMENT] = null;
            }
            PTT.getPipe(ViewPipes.EDITOR_PIPE).send(ViewKeys.EDITOR_CONTENT, data);

            // Update the score selection
            if (!omitScore) {
                if (element && ModelUtils.isPart(element)) {
                    uid = element.getContent(DataFields.PART_MIRROR_UID) as String;
                }
                GLOBAL_PIPE.send(ViewKeys.EXTERNALLY_SELECTED_SCORE_ITEM, uid);
            }
        }
    }

    /**
     * Causes a general-purpose notice to be displayed, to let the user know that something happened within the application.
     * Short prompts will be rendered in the status bar; longer prompts will be rendered using an "Information" window.
     */
    public function showStatusOrPrompt(text:String, color:String = PromptColors.NOTICE):void {
        var renderUsingStatusBar:Boolean = (text.length <= StaticFieldValues.MAX_STATUS_TEXT_LENGTH);
        if (renderUsingStatusBar) {
            showStatus(text, color);
            return;
        }
        showPrompt(text);
    }

    /**
     * Causes a status bar notification to be displayed. Text only (no buttons will be shown).
     * For colors, see constants defined in class "PromptColors".
     */
    public function showStatus(text:String, color:String = PromptColors.NOTICE, autoClose:Boolean = true):void {
        var data:Object = {};
        data[PromptKeys.TEXT] = text;
        data[PromptKeys.BACKGROUND_COLOR] = color;
        data[PromptKeys.AUTOCLOSE] = autoClose;
        GLOBAL_PIPE.send(ViewKeys.NEED_PROMPT, data);
    }

    /**
     * Causes any currently displayed status bar notification to be hidden.
     */
    public function hideStatus():void {
        GLOBAL_PIPE.send(ViewKeys.NEED_PROMPT_DISCARDED);
    }

    /**
     * Causes a general-purpose "Info" dialog to be displayed, regardless of the length of the text involved.
     */
    public function showPrompt(text:String):void {
        _promptsManager.information(text);
    }

    /**
     * Tells all "views" to update their content.
     */
    public function updateAllViews(updateScore:Boolean = true):void {

        // The QueryEngine instance maintains a cache to speed up delivering an
        // answer for repeated, identical queries. This is a good moment to
        // start fresh.
        queryEngine.resetCache();

        // Actually update
        _updateProjectStructure();
        if (updateScore) {
            _updateProjectScore();
        }

        // Mark generated MIDI as dirty.
        _midiSessionUid = null;
        _updateProjectInfo();
    }

    // ---------------
    // Private methods
    // ---------------
    /**
     * @filter
     * Only used as a filter function to retrieve Part nodes having a specific uid. Do not employ in other
     * scenarios.
     */
    private function __partsByUuid(part:ProjectData, ...ignore):Boolean {
        return (part.getContent(DataFields.PART_MIRROR_UID) === __beingSearchedForPartUuid);
    }

    /**
     * Sets user provided data to a Part node identified by its route. Intended to be used inside loops, therefore
     * does not update the views or the global list of available parts.
     */
    private function _applyPartDataToTargetRoute(partData:Object, targetRoute:String):void {

        // We reset the `partUid` field of the part that we are updating, to force the ABC exporter into
        // generating leading measures every time it renders the score. These play the crucial role
        // of correctly aligning the parts vertically.
        partData[DataFields.PART_UID] = DataFields.VALUE_NOT_SET;

        if (queryEngine.updateContentOf(targetRoute, partData)) {

            // When a Part that has music in it changes, we need to revisit every Measure, to make sure that
            // there are two Voices for every staff of that Part.
            // This may involve adding new Voices (because, for instance, switching from a "Flute" to an "Organ"
            // adds two staves), relocating existing Voices or hiding existing voices (for instance, when switching
            // an "Organ" part to a "Flute").
            var targetNode:ProjectData = (_model.currentProject.getElementByRoute(targetRoute) as ProjectData);
            ModelUtils.ensureMaxVoicesPerStaff(targetNode);
        }
    }

    /**
     * Closes the window displaying the FileBrowser component
     */
    private function _closeFileBrowserWindow():void {
        if (_windowsManager.isWindowAvailable(_fileBrowserWindowUid)) {
            _windowsManager.stopObservingWindowActivity(_fileBrowserWindowUid, WindowActivity.BEFORE_DESTROY, _onFileBrowserXClose);
            _windowsManager.destroyWindow(_fileBrowserWindowUid);
        }
    }

    private function _commitData(committedData:ProjectData, targetRoute:String):void {
        var committedContent:Object = committedData.getContentMap();
        if (queryEngine.updateContentOf(targetRoute, committedContent)) {
            updateAllViews();
        }
    }

    /**
     * Commits given data to all the measures that are part of the same measure stack as
     * the current measure. In other words, measures residing in different parts, but having
     * the same measure number, are to be sent the same content.
     *
     * This is because the hierarchical model we use to represent music fails to cope to
     * the classical paradox: do we have parts containing measures, or measures containing
     * parts?
     *
     * @param    measureData
     *           Expectedly, a "measure" clone, as the one returned by the Score Editor.
     *
     * @param    targetRoute
     *           The route of a "real" measure in the stack to update.
     */
    private function _commitMeasureData(measureData:ProjectData, targetRoute:String, updateViews:Boolean = true):void {

        // Measures residing in different parts, but having the same index are to be
        // sent the same content upon committing.
        var currentMeasure:ProjectData = ProjectData(_model.currentProject.getElementByRoute(targetRoute));
        if (currentMeasure != null) {
            var committedContent:Object = measureData.getContentMap();
            var measureIndex:int = currentMeasure.index;
            var currentPart:ProjectData = ProjectData(currentMeasure.dataParent);
            var currentSection:ProjectData = ProjectData(currentPart.dataParent);
            var allPartsInSection:Array = ModelUtils.getChildrenOfType(currentSection, DataFields.PART);
            for (var i:int = 0; i < allPartsInSection.length; i++) {
                var somePart:ProjectData = ProjectData(allPartsInSection[i]);
                var someMeasure:ProjectData = ProjectData(somePart.getDataChildAt(measureIndex));
                var someRoute:String = someMeasure.route;
                if (queryEngine.updateContentOf(someRoute, committedContent)) {
                    if (updateViews) {
                        updateAllViews();
                    }
                }
            }
        }
    }

    /**
     * NOTE: Instead of only committing the new data to the intended Part node, we need to do so for all
     * parts that have the same unique id.
     */
    private function _commitPartData(committedData:ProjectData, targetRoute:String):void {
        var partData:Object = committedData.getContentMap();
        var targetPartNode:ProjectData = (_model.currentProject.getElementByRoute(targetRoute) as ProjectData);
        __beingSearchedForPartUuid = (targetPartNode.getContent(DataFields.PART_MIRROR_UID) as String);
        var currentInstrument:String = targetPartNode.getContent(DataFields.PART_NAME) as String;
        var newInstrument:String = partData[DataFields.PART_NAME] as String;
        var haveInstrumentChange:Boolean = (newInstrument != currentInstrument);
        var allSections:Array = queryEngine.getAllSectionNodes();
        for (var i:int = 0; i < allSections.length; i++) {
            var someSection:ProjectData = (allSections[i] as ProjectData);
            var allPartsInSection:Array = ModelUtils.getChildrenOfType(someSection, DataFields.PART);
            var matchingParts:Array = allPartsInSection.filter(__partsByUuid);
            if (matchingParts.length > 0) {
                var mirroredPart:ProjectData = (matchingParts[0] as ProjectData);
                _applyPartDataToTargetRoute(partData, mirroredPart.route);
            }
        }
        __beingSearchedForPartUuid = null;
        ModelUtils.updateUnifiedPartsList(_model.currentProject);
        updateAllViews();

        // If user has changed the current part's instrument, then we need to issue a selection
        // message, so that the corresponding score label gets highlighted.
        if (haveInstrumentChange) {
            GLOBAL_PIPE.send(ViewKeys.EXTERNALLY_SELECTED_SCORE_ITEM, targetRoute);
        }
    }

    /**
     * Deletes a part, across all sections in the project. Requires user confirmation if
     * musical content is to be lost this way.
     *
     * @param part
     *        A Part node to initialize deletion from.
     */
    private function _deletePartNode(part:ProjectData):void {
        var parentSection:ProjectData = (ModelUtils.getClosestAscendantByType(part, DataFields.SECTION) as ProjectData);
        __beingSearchedForPartUuid = (part.getContent(DataFields.PART_MIRROR_UID) as String);
        var deletionList:Array = [];
        var doIt:Function = function ():void {
            while (deletionList.length > 0) {
                queryEngine.deleteElement(deletionList.pop() as ProjectData);
            }
            ModelUtils.updateUnifiedPartsList(_model.currentProject);
            updateAllViews();
            setSelection(parentSection);
        }
        var isMusicLost:Boolean = false;
        var allSections:Array = queryEngine.getAllSectionNodes();
        for (var i:int = 0; i < allSections.length; i++) {
            var someSection:ProjectData = (allSections[i] as ProjectData);
            var allPartsInSection:Array = ModelUtils.getChildrenOfType(someSection, DataFields.PART);
            var matchingParts:Array = allPartsInSection.filter(__partsByUuid);
            if (matchingParts.length > 0) {
                var mirroredPart:ProjectData = (matchingParts[0] as ProjectData);
                deletionList.push(mirroredPart);
                if (!isMusicLost) {
                    var measuresInPart:Array = ModelUtils.getChildrenOfType(mirroredPart, DataFields.MEASURE);
                    for (var j:int = 0; j < measuresInPart.length; j++) {
                        var someMeasure:ProjectData = (measuresInPart[j] as ProjectData);
                        var measureDuration:Fraction = queryEngine.computeMeasureDuration(someMeasure);
                        if (measureDuration.greaterThan(Fraction.ZERO)) {
                            isMusicLost = true;
                            break;
                        }
                    }
                }
            }
        }
        if (!isMusicLost) {
            doIt();
        } else {
            var partRawName:String = part.getContent(DataFields.PART_NAME) as String;
            var partOrdinalIndex:int = part.getContent(DataFields.PART_ORDINAL_INDEX) as int;
            var mustShowOrdNum:Boolean = (partOrdinalIndex > 0);
            var partName:String = partRawName.concat(mustShowOrdNum ? (CommonStrings.SPACE + (partOrdinalIndex + 1)) : '');
            _showConfirmationPrompt(Strings.sprintf(StaticTokens.DELETING_PART_LOOSES_MUSIC, partName), doIt);
        }
        __beingSearchedForPartUuid = null;
    }

    /**
     * Deletes a voice node. The following logic applies:
     * (1) If the voice is not assigned to a staff, it is just deleted;
     * (2) If the voice index is `2+`, it is just deleted;
     * (3) If the voice is "voice 1", then the next subsequent voice (e.g., "voice 2") is
     * promoted as "the new voice 1", then "the old voice 1" is deleted. Note: current
     * settings prohibit deleting the last voice of a staff, so this should be a safe
     * approach.
     *
     * TO BE CONSIDERED: display a confirmation message when musical material is to be lost
     * by deleting a voice.
     */
    private function _deleteVoiceNode(voice:ProjectData):ProjectData {
        var voiceStaffIndex:int = (voice.getContent(DataFields.STAFF_INDEX) as int);
        if (voiceStaffIndex > 0) {
            var parentMeasure:ProjectData = (voice.dataParent as ProjectData);
            var allVoicesInMeasure:Array = ModelUtils.getChildrenOfType(parentMeasure, DataFields.VOICE);
            var __matchesStaffIndex:Function = function (testVoice:*, ...etc):Boolean {
                return (testVoice !== voice && (testVoice.getContent(DataFields.STAFF_INDEX) as int) == voiceStaffIndex);
            }
            var otherVoicesOnStaff:Array = allVoicesInMeasure.filter(__matchesStaffIndex);
            otherVoicesOnStaff.sort(ModelUtils.sortVoicesByStaffAndIndex);
            var replacementVoice:ProjectData = (otherVoicesOnStaff[0] as ProjectData);
            var replacementVoiceIndex:int = (replacementVoice.getContent(DataFields.VOICE_INDEX) as int);
            if (replacementVoiceIndex > 1) {
                replacementVoice.setContent(DataFields.VOICE_INDEX, Voices.FIRST_VOICE);
            }
            queryEngine.deleteElement(voice);
            return replacementVoice;
        }
        return queryEngine.deleteElement(voice);
    }

    private function _exitApplication():void {
        _stopMidi();
        if (_model.haveUnsavedData() || (_snapshotsManager.canRedo || _snapshotsManager.canUndo)) {
            _showDiscardChangesPrompt(_terminateApplication);
        } else {
            _terminateApplication();
        }
    }

    private function _undo():void {
        var undoSnapshot:Snapshot = _snapshotsManager.getNextUndoSnapshot();
        if (undoSnapshot) {
            updateUndoRedoUi();
            var undoneProject:ProjectData = undoSnapshot.source as ProjectData;
            _loadProject(undoneProject, true, true);
        }
    }

    private function _redo():void {
        var redoSnapshot:Snapshot = _snapshotsManager.getNextRedoSnapshot();
        if (redoSnapshot) {
            updateUndoRedoUi();
            var redoneProject:ProjectData = redoSnapshot.source as ProjectData;
            _loadProject(redoneProject, true, true);
        }
    }

    private function _resetSnapshotsHistory():void {
        _snapshotsManager.reset();
        _snapshotsManager.takeSnapshot(
                _model.currentProject,
                Strings.sprintf(StaticTokens.ITEM_ADD_OPERATION, DataFields.PROJECT)
        );
        updateUndoRedoUi();
    }

    /**
     * Triggered when user selects 'Export > To ABC file...' from the
     * application menu.
     */
    private function _exportCurrentProjectToABC():void {
        var title:String = StaticTokens.CHOOSE_EXPORT_ABC_FILE;
        var folder:File = _model.currentProjectFile ? _model.currentProjectFile.parent : File.documentsDirectory;
        var fileTypes:Array = [new FileFilterEntry(FileAssets.ABC_FILE_DESCRIPTION, FileTypes.ABC)];
        _fileSelectedCallback = _onAbcFileSelectedForSave;
        _openFileBrowser(title, folder, fileTypes);
    }

    /**
     * Triggered when user selects 'Export > To MIDI file...' from the
     * application menu.
     */
    private function _exportCurrentProjectToMIDI():void {
        var proceed:Function = function (noDelay:Boolean = false):void {
            var title:String = StaticTokens.CHOOSE_EXPORT_MIDI_FILE;
            var folder:File = _model.currentProjectFile ? _model.currentProjectFile.parent : File.documentsDirectory;
            var fileTypes:Array = [new FileFilterEntry(FileAssets.MIDI_FILE_DESCRIPTION, FileTypes.MIDI)];
            _fileSelectedCallback = _onMidiFileSelectedForSave;
            if (noDelay) {
                _openFileBrowser(title, folder, fileTypes);
            } else {
                Time.advancedDelay(_openFileBrowser, this, Time.VERY_SHORT_DURATION, title, folder, fileTypes);
            }
        };
        _prepareMidi(proceed);
    }

    /**
     * Triggered when user selects 'Export > To PDF file...' from the
     * application menu.
     */
    private function _exportCurrentProjectToPDF():void {
        var title:String = StaticTokens.CHOOSE_EXPORT_PDF_FILE;
        var folder:File = _model.currentProjectFile ? _model.currentProjectFile.parent : File.documentsDirectory;
        var fileTypes:Array = [new FileFilterEntry(FileAssets.PDF_FILE_DESCRIPTION, FileTypes.PDF)];
        _fileSelectedCallback = _onPdfFileSelectedForSave;
        _openFileBrowser(title, folder, fileTypes);
    }

    /**
     * Triggered when user selects 'Export > To XML file (MusicXML format)...' from the
     * application menu.
     */
    private function _exportCurrentProjectToXML():void {
        var title:String = StaticTokens.CHOOSE_EXPORT_XML_FILE;
        var folder:File = _model.currentProjectFile ? _model.currentProjectFile.parent : File.documentsDirectory;
        var fileTypes:Array = [new FileFilterEntry(FileAssets.XML_FILE_DESCRIPTION, FileTypes.XML)];
        _fileSelectedCallback = _onXmlFileSelectedForSave;
        _openFileBrowser(title, folder, fileTypes);
    }

    /**
     * Triggered when user selects 'Export > To WAV file...' from the
     * application menu.
     */
    private function _exportCurrentProjectToWAV():void {
        var title:String = StaticTokens.CHOOSE_EXPORT_WAV_FILE;
        var folder:File = _model.currentProjectFile ?
                _model.currentProjectFile.parent : File.documentsDirectory;
        var fileTypes:Array = [new FileFilterEntry(FileAssets.WAV_FILE_DESCRIPTION, FileTypes.WAV)];
        _fileSelectedCallback = _onWavFileSelectedForSave;
        _openFileBrowser(title, folder, fileTypes);
    }

    /**
     * Gathers, packs and returns information about the given measure, that is related to
     * its second voice presence and availability. This is valuable data for the "measure toolbar"
     * floating UI that the score editor shows for measures.
     */
    private function _getMeasureSelectionInfo(measure:ProjectData):Object {
        var ret:Object = {};

        // Has this measure a "second voice"?
        var voiceTwoMap:Array = [];
        var part:ProjectData = ModelUtils.getParentPart(measure);
        var partNumStaves:uint = ModelUtils.getPartNumStaves(part);
        var i:int;
        for (i = 1; i <= partNumStaves; i++) {
            voiceTwoMap[i] = (ModelUtils.getVoiceByPlacement(measure, i, 2));
        }
        ret[MeasureSelectionKeys.SECOND_VOICE_AVAILABILITY] = voiceTwoMap;

        // Does this part support voice two?
        // TODO: implement part's ability to limit its own number of voices
        // Until this is implemented, `true` will always be returned.
        ret[MeasureSelectionKeys.SECOND_VOICE_PERMITTED] = true;

        // What is the current measure selection mode?
        ret[MeasureSelectionKeys.SELECTION_MODE] = _measureSelectionType;

        // What is the current measure selection staff index?
        ret[MeasureSelectionKeys.STAFF_INDEX_FILTER] = _measureSelectionStaffIndex;
        return ret;
    }

    private function _getSelection():ProjectData {
        return lastSelection;
    }

    /**
     * Triggered when application is invoked with a file (i.e., user double clicks on
     * a file type which has been registered with the application).
     */
    private function _handleFileInvocation(file:File):void {
        if (file.exists && file.extension == FileAssets.PROJECT_FILE_EXTENSION) {
            _onProjectFileSelectedForOpen(file);
        }
    }

    private static function _initTweening():void {
        TweenPlugin.activate([AutoAlphaPlugin]);
    }

    private function _initializeCommunications():void {
        var $subscribe:Function = GLOBAL_PIPE.subscribe;
        $subscribe(ViewKeys.APP_EXIT_BUTTON_CLICK, _onAppExitRequested);
        $subscribe(ViewKeys.APP_MENU_TRIGGERED, _onAppMenuTriggered);
        $subscribe(ViewKeys.NEED_PART_NAMES_LIST, _onPartNamesRequested);
        $subscribe(ViewKeys.NEED_BRACKET_TYPES_LIST, _onBracketTypesRequested);
        $subscribe(ViewKeys.NEED_BAR_TYPES_LIST, _onBarTypesRequested);
        $subscribe(ViewKeys.NEED_CLEF_TYPES_LIST, _onClefTypesRequested);
        $subscribe(ViewKeys.NEED_PICKUP_COMPONENT_WINDOW, _onPickupWindowRequested);
        $subscribe(ViewKeys.NEED_PICKUP_COMPONENT_WINDOW_FORCE_CLOSED, _onPickupWindowForceCloseRequested);
        $subscribe(ViewKeys.COMMITTING_USER_CHANGES, _onUserCommit);
        $subscribe(ViewKeys.NEED_PART_DEFAULT_DATA, _onPartDefaultDataRequested);
        $subscribe(ViewKeys.NEED_INHERITED_TIME_SIGNATURE, _onInheritedTimeSignatureRequested);
        $subscribe(ViewKeys.CONVERT_MEASURE_NUMBER_TO_UID, _onMeasureNumberToUidRequested);
        $subscribe(ViewKeys.CONVERT_UID_TO_MEASURE_NUMBER, _onMeasureUidToNumberRequested);
        $subscribe(ViewKeys.GET_LABEL_FOR_TREE_ELEMENT, _onLabelForTreeElementRequested);
        $subscribe(ViewKeys.NEED_MAX_VOICES_PER_STAFF_NUMBER, _onMaxVoicesPerStaffRequested);
        $subscribe(ViewKeys.NEED_CURRENT_PART_STAFFS_NUMBER, _onPartStaffsNumberRequested);
        $subscribe(ViewKeys.NEED_DURATIONS_LIST, _onDurationsListRequested);
        $subscribe(ViewKeys.NEED_SUITABLE_DIVISIONS_LIST, _onDivisionsListRequested);
        $subscribe(ModelKeys.STOP_REQUESTED, _onStopRequested);
        $subscribe(ModelKeys.PLAYBACK_REQUESTED, _onPlaybackRequested);
        $subscribe(ViewKeys.SCORE_RENDERER_AVAILABLE, _onScoreRendererAvailable);
        $subscribe(ViewKeys.CLICKED_SCORE_ITEM, _onScoreItemClicked);
        $subscribe(ViewKeys.RIGHT_CLICKED_SCORE, _onScoreRightClicked);
        $subscribe(ViewKeys.MIDDLE_CLICKED_SCORE, _onScoreMiddleClicked)
        $subscribe(ViewKeys.NEED_UID_FOR_ANNOTATION, _onUidForAnnotationRequested);
        $subscribe(ViewKeys.NEED_SHORT_UID_INFO, _onShortUidInfoRequested);
        $subscribe(ViewKeys.NEED_SHORTENED_UID_FOR, _onShortenedUidRequested);
        $subscribe(ViewKeys.STRUCTURE_ITEM_ADD, _onStructureItemAdd);
        $subscribe(ViewKeys.STRUCTURE_ITEM_REMOVE, _onStructureItemRemove);
        $subscribe(ViewKeys.STRUCTURE_ITEM_NUDGE_UP, _onStructureItemNudgeUp);
        $subscribe(ViewKeys.STRUCTURE_ITEM_NUDGE_DOWN, _onStructureItemNudgeDown);
        $subscribe(ViewKeys.SECTION_NAME_VALIDATION, _onSectionNameValidationRequested);
        $subscribe(ViewKeys.NEED_MEASURE_OWN_TIME_SIGNATURE, _onMeasureTimeSignatureRequested);
        $subscribe(ViewKeys.NEED_TIME_SIGNATURE_DATA, _onMeasureTimeSignatureDataRequired);
        $subscribe(ViewKeys.NEED_CURRENT_PART_NAME, _onCurrentPartNameRequested);
        $subscribe(ViewKeys.CHECK_IF_LAST_VOICE_OF_STAFF, _onLastVoiceOfStaffCheckRequested);
        $subscribe(ViewKeys.NEED_UID_FOR_PART_ANNOTATION, _onPartAnnotationUidRequested);
        $subscribe(ViewKeys.TRANSPOSITION_OPERATION_COMMIT, _onTranspositionRequested);
        $subscribe(ViewKeys.SCALE_INTERVALS_OPERATION_COMMIT, _onScaleIntervalsRequested);
        $subscribe(ViewKeys.SCORE_WAS_SCROLLED, _onScoreScrolled);
        $subscribe(ViewKeys.CHANGING_VOICE_POSITION, _onVoiceChanging);
        $subscribe(ViewKeys.DECOMMISSION_TUPLET, _onTupletDecommissioningRequested);
        $subscribe(ViewKeys.RESET_TUPLET, _onTupletResetRequested);
        $subscribe(ViewKeys.POPUP_SHOWN, registerColorizableUi);
        $subscribe(ViewKeys.POPUP_HIDDEN, registerColorizableUi);
        $subscribe(ViewKeys.SECTION_TOGGLE_STATE, onSectionToggleStateChange);
        var $subscribeTree:Function = PTT.getPipe(ViewPipes.PROJECT_TREE_PIPE).subscribe;
        $subscribeTree(ViewKeys.STRUCTURE_TREE_READY, _onStructureTreeReady);
        $subscribeTree(ViewKeys.TREE_ITEM_CLICK, _onTreeItemClick);
        var $subscribeMeasurePadding:Function = PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).subscribe;
        $subscribeMeasurePadding(ViewKeys.SPLIT_DURATION_NEEDED, _onSplitDurationRequested);
        $subscribeMeasurePadding(ViewKeys.NEED_VOICE_DATA, _onVoiceDataRequested);
    }

    /**
     * Updates window title;
     * Loads an empty project;
     * Restricts the width of tooltips.
     */
    private function _initializeMainView():void {
        ToolTip.maxWidth = Sizes.TOOLTIP_MAX_WIDTH;
        _updateMainAppTitle(Descriptor.getAppSignature());
        _loadDefaultProject();
    }

    private function _readFromPersistence():void {
        // Apply last used theme
        var lastThemeName : String = _persistenceEngine.persistence(PersistenceKeys.THEME);
        currColorMatrix = UiColorizationThemes[lastThemeName];
        GLOBAL_PIPE.send(ViewKeys.COLORIZATION_UPDATED, lastThemeName);
        applyCurrentColorization();

        // Apply last section toggle states
        GLOBAL_PIPE.send(PersistenceKeys.PROJECT_TOGGLE_STATE, _persistenceEngine.persistence(PersistenceKeys.PROJECT_TOGGLE_STATE));
        GLOBAL_PIPE.send(PersistenceKeys.EDITOR_TOGGLE_STATE, _persistenceEngine.persistence(PersistenceKeys.EDITOR_TOGGLE_STATE));
    }

    /**
     * According to 2017/07 revamp and JIRA issue "MAID-21" (https://ciacob.atlassian.net/browse/MAID-21),
     * "Voices, as data model objects, will only be deletable if there already are two voices" per part staff.
     * @return    `True` if given voice can be safely deleted by the user, `false` otherwise.
     *
     * Logic follows:
     * (1) if the current measure currently only has one voice, there's nothing to delete; return `false`;
     * (2) if the voice is shown on staff `0`, then it is orphaned, therefore deletable (staves are indexed
     * starting from `1`): return `true`;
     * (3) otherwise, build a voices-to-staff map; if there is more than one voice in the same staff as
     * the voice we are investigating, we're good to go: return `true`;
     * (4) otherwise, return `false`.
     */
    private static function _isLastVoiceOnItsStaff(voice:ProjectData, parentMeasure:ProjectData):Boolean {
        // If the entire measure contains one single voice, then it is clearly the "last one on its staff"
        if (parentMeasure.numDataChildren == 1) {
            return true;
        }

        // If our voice has not been assigned to a staff, then the logic below does not apply.
        var voiceStaffIndex:int = (voice.getContent(DataFields.STAFF_INDEX) as int);
        if (voiceStaffIndex == 0) {
            return false;
        }
        var voicesToStavesMap:Array = [];
        var allVoicesInMeasure:Array = ModelUtils.getChildrenOfType(parentMeasure, DataFields.VOICE);
        var i:int = 0;
        var numVoices:uint = allVoicesInMeasure.length;
        var testVoice:ProjectData;
        var testVoiceStaffIndex:int;
        var staffSlot:Array;
        for (i; i < numVoices; i++) {
            testVoice = (allVoicesInMeasure[i] as ProjectData);
            testVoiceStaffIndex = (testVoice.getContent(DataFields.STAFF_INDEX) as int);
            staffSlot = (voicesToStavesMap[testVoiceStaffIndex] || (voicesToStavesMap[testVoiceStaffIndex] = []));
            staffSlot.push(testVoice);
        }
        return ((voicesToStavesMap[voiceStaffIndex] as Array).length < Voices.NUM_VOICES_PER_STAFF);
    }

    /**
     * Executed when the "synthProxy" triggers an annotation (typical use includes highlighting notes
     * on the musical score as they are played back).
     *
     * @param   event
     *          @see eu.claudius.iacob.synth.events.PlaybackAnnotationEvent
     */
    private function _onPlaybackAnnotation(event:PlaybackAnnotationEvent):void {
        var payload:AnnotationTask = (event.payload as AnnotationTask);
        var i:int;
        var actions:Vector.<AnnotationAction> = payload.actions;
        var numActions:uint = actions.length;
        var action:AnnotationAction;
        var clusterId:String;
        var $type:String;
        for (i = 0; i < numActions; i++) {
            action = actions[i];
            $type = action.type;
            clusterId = action.targetId;
            switch ($type) {
                case OperationTypes.TYPE_HIGHLIGHT_SCORE_ITEM:
                    GLOBAL_PIPE.send(ViewKeys.EXTERNALLY_HIGHLIGHTED_SCORE_ITEM, clusterId);
                    break;
                case OperationTypes.TYPE_UNHIGHLIGHT_SCORE_ITEM:
                    GLOBAL_PIPE.send(ViewKeys.EXTERNALLY_UNHIGHLIGHTED_SCORE_ITEM, clusterId);
                    break;
                case OperationTypes.TYPE_CLOSE_SCORE:
                    Time.delay(1, _onStopRequested);
                    break;
            }
        }
    }

    /**
     * Executed when the audio streaming util dispatches a SystemStatusEvent (typical use includes notifying the user
     * when an audio dropout occurs).
     * @param event
     */
    private function _onStreamingEvent(event:SystemStatusEvent):void {
        _synthProxy.computeCachedAudioLength();
        var report:ProgressReport = event.report;
        switch (report.state) {
            case ProgressReport.STATE_STREAMING_DONE:
                if (report.subState == ProgressReport.SUBSTATE_NOTHING_TO_DO) {

                    // Only grant a session ID when streaming completed successfully.
                    _midiSessionUid = Strings.UUID;
                }
                break;
            case ProgressReport.STATE_CANNOT_STREAM:
                switch (report.subState) {
                    case ProgressReport.SUBSTATE_DROPOUT:
                        showStatus(StaticTokens.AUDIO_DROPOUT_NOTICE, PromptColors.WARNING, false);
                        _cleanupHighlights();
                        break;
                    case ProgressReport.SUBSTATE_EMPTY_TRACKS:
                        showStatus(StaticTokens.NO_CONTENT_TO_STREAM, PromptColors.WARNING);
                        if (_renderWindowUid) {
                            RENDER_PIPE.send(AudioKeys.RENDER_ABORT_REQUESTED);
                        }
                        if (_isMidiPlaying) {
                            GLOBAL_PIPE.send(ModelKeys.MIDI_PLAYBACK_STOPPED);
                            _isMidiPlaying = false;
                        }
                        break;
                        // Add more sub-states here as needed.
                }
                break;

                // When starting or resuming playback, we want all currently shown status messages hidden (since they
                // essentially are only there to explain to the user why the program isn't playing back yet). The
                // delay is there to prevent the closing animation of the Prompt UI component from stuttering, as
                // beginning//resuming playback implies a temporary peak of work on the main thread.
            case ProgressReport.STATE_PLAYING:
                Time.delay(0.6, function ():void {
                    hideStatus();
                });
                break;
                // Add more states here as needed.
        }
    }

    /**
     * Executed when the "synthProxy" reports progress with internal activities, such as preloading sound fonts.
     * @param event
     */
    private function _onSoundsLoaderReport(event:SystemStatusEvent):void {
        var progress:ProgressReport = event.report;
        switch (progress.state) {

                // Notify user about loading instrument samples, as they complete: one notification per completed instrument.
            case ProgressReport.STATE_PENDING:
                if (progress.subState == ProgressReport.SUBSTATE_LOADING_SOUNDS &&
                        progress.itemState == ProgressReport.ITEM_STATE_DONE) {
                    showStatus(Strings.sprintf(StaticTokens.LOADING_SOUNDS, progress.itemDetail),
                            PromptColors.INFORMATION, false);
                }
                break;

                // Once all required assets completed loading, stream the score (e.g., render a portion of it, then playback
                // while rendering the reminder using background thread(s).
            case ProgressReport.STATE_READY_TO_RENDER:
                _loadedSounds = _soundLoader.sounds;

                // Initialize the streaming utility class if not already done so.
                if (!_audioStreamer) {
                    var workerBytes:ByteArray = (_loadedSounds[FileAssets.AUDIO_WORKER_FILE_KEY] as ByteArray);
                    _audioStreamer = new StreamingUtils(workerBytes, _synthProxy, true, true);
                    _audioStreamer.addEventListener(SystemStatusEvent.REPORT_EVENT, _onStreamingEvent);
                }
                _audioStreamer.clearDropoutState();

                // Start streaming; the exact means of doing so depend on the method currently pointed to by
                // `_streamingRoutine`: if it points to `_doOnlineStreaming`, then we deal with a playback request, so
                // the score will be rendered while it is playing; if it points to `_doOfflineStreaming`, then we deal
                // with a "dry audio export" scenario, meaning that the score was never rendered to audio, yet the user
                // wants to "blindly" save it to a *.wav file -- so we need to render it first, and, since this usually
                // takes a lot of time, we display a progress window to "justify" this elapsed time.
                showStatus(StaticTokens.PREPARING_AUDIO, PromptColors.INFORMATION, false);
                if (_streamingRoutine == _doOfflineStreaming) {
                    _showRenderWindow();
                    Time.delay(STREAMING_DELAY, _streamingRoutine);
                } else {
                    GLOBAL_PIPE.send(ModelKeys.MIDI_PLAYBACK_STARTED);
                    _isMidiPlaying = true;
                    _streamingRoutine();
                }
                break;
        }
    }

    /**
     * Constructs an instance of the `FileUtils` class and stores it globally as `_audioFileUtils`. Assumes the global
     * `_audioStreamer` class member to point to a valid `StreamingUtils` instance.
     */
    private function _ensureFileUtils():void {
        if (!_audioFileUtils) {
            _audioFileUtils = new FileUtils;
            _audioFileUtils.addEventListener(SystemStatusEvent.REPORT_EVENT, _onFileUtilsReport);
        }
    }

    /**
     * Causes the current score to be streamed in "online mode", i.e., playing it back while it's being rendered.
     */
    private function _doOnlineStreaming():void {
        _audioStreamer.stream(_loadedSounds, _tracksInfo);
    }

    /**
     * Causes the current score to be streamed in "offline mode", i.e., storing the resulting audio silently, and
     * transferring it to disk when done.
     */
    private function _doOfflineStreaming():void {
        _ensureFileUtils();
        _audioFileUtils.streamToDisk(_audioStreamer, _loadedSounds, _tracksInfo, _targetWaveFile);
    }

    /**
     * Displays a "render window", to improve perceived application performance by reporting audio rendering
     * progress in real time.
     */
    private function _showRenderWindow():void {
        var ui:RenderProgressUI = new RenderProgressUI;
        ui.pipe = RENDER_PIPE;
        registerColorizableUi(ui);
        _renderWindowUid = windowsManager.createWindow(ui, WindowStyle.PROMPT | WindowStyle.NATIVE, true);

        // Executed when user closes the render window by its "x" button, thus cancelling the process. Mirrors
        // the effects of the user having pressed the "Abort" button inside the render window.
        _onRenderWindowExiting = function (...args):Boolean {
            RENDER_PIPE.send(AudioKeys.RENDER_ABORT_REQUESTED);
            return false;
        }

        // Executed when user presses the "Minimize" button inside the render window.
        _onRenderMinimize = function (...args):void {
            windowsManager.hideWindow(windowsManager.mainWindow);
        }

        // Executed when user presses the "Abort" button inside the render window.
        _onRenderAbort = function (...args):void {
            RENDER_PIPE.send(AudioKeys.RENDER_STATUS_CHANGED, {
                state: AudioKeys.RENDER_ABORT_REQUESTED
            });
            _audioStreamer.cancelStreaming();
            _updateRenderWindowTitle(StaticTokens.RECORDING_CANCELLED);
            hideStatus();
            Time.delay(RENDER_WINDOW_CLOSE_DELAY, _closeRenderWindow);
        }

        RENDER_PIPE.subscribe(AudioKeys.RENDER_MINIMIZE_REQUESTED, _onRenderMinimize);
        RENDER_PIPE.subscribe(AudioKeys.RENDER_ABORT_REQUESTED, _onRenderAbort);
        windowsManager.observeWindowActivity(_renderWindowUid, WindowActivity.BEFORE_DESTROY, _onRenderWindowExiting);
        windowsManager.updateWindowTitle(_renderWindowUid, StaticTokens.RENDER_WINDOW_TITLE);
        windowsManager.showWindow(_renderWindowUid);
        windowsManager.updateWindowBounds(_renderWindowUid, Sizes.RENDER_PROGRESS_WINDOW_BOUNDS, true);
        windowsManager.alignWindows(_renderWindowUid, windowsManager.mainWindow, 0.5, 0.5);
    }

    /**
     * Closes the "render window", if available.
     */
    private function _closeRenderWindow():void {
        if (_renderWindowUid && windowsManager.isWindowVisible(_renderWindowUid)) {
            if (_onRenderWindowExiting != null) {
                windowsManager.stopObservingWindowActivity(_renderWindowUid, WindowActivity.BEFORE_DESTROY,
                        _onRenderWindowExiting);
                _onRenderWindowExiting = null;
            }
            if (_onRenderMinimize != null) {
                RENDER_PIPE.unsubscribe(AudioKeys.RENDER_MINIMIZE_REQUESTED, _onRenderMinimize);
                _onRenderMinimize = null;
            }
            if (_onRenderAbort != null) {
                RENDER_PIPE.unsubscribe(AudioKeys.RENDER_ABORT_REQUESTED, _onRenderAbort);
                _onRenderAbort = null;
            }
            windowsManager.destroyWindow(_renderWindowUid);
            _renderWindowUid = null;
        }
    }

    /**
     * Changes the title displayed by the audio render title, if available.
     * @param title
     */
    private function _updateRenderWindowTitle(title:String):void {
        if (_renderWindowUid && windowsManager.isWindowAvailable(_renderWindowUid)) {
            windowsManager.updateWindowTitle(_renderWindowUid, title);
        }
    }

    /**
     * Executed when the FileUtils instance used to export the project in WAVE format dispatches a SystemStatus event.
     * @param event
     */
    private function _onFileUtilsReport(event:SystemStatusEvent):void {
        var report:ProgressReport = event.report;
        var reportState:String = report.state;
        var info:Object = {
            state: reportState,
            audioBytes: _audioStreamer.renderedAudioStorage
        };
        switch (reportState) {
            case ProgressReport.STATE_STREAMING_START:
                info.percentComplete = 0;
                RENDER_PIPE.send(AudioKeys.RENDER_STATUS_CHANGED, info);
                break;
            case ProgressReport.STATE_STREAMING_PROGRESS:
                info.percentComplete = report.globalPercent;
                RENDER_PIPE.send(AudioKeys.RENDER_STATUS_CHANGED, info);
                break;
            case ProgressReport.STATE_STREAMING_DONE:
                _midiSessionUid = Strings.UUID;
                info.state = ProgressReport.STATE_STREAMING_DONE;
                info.percentComplete = 1;
                RENDER_PIPE.send(AudioKeys.RENDER_STATUS_CHANGED, info);
                _updateRenderWindowTitle(StaticTokens.RECORDING_COMPLETE);
                Time.delay(RENDER_WINDOW_CLOSE_DELAY, _closeRenderWindow);
                break;
            case ProgressReport.STATE_CANNOT_SAVE:
                if (report.subState == ProgressReport.SUBSTATE_ERROR) {
                    _deferFileBrowserClose = true;
                    _showUnwritableFileError(report.itemState);
                }
                break;
            case ProgressReport.STATE_SAVING_PROGRESS:
                if (report.subState == ProgressReport.SUBSTATE_SAVING_WAV_FILE) {
                    if (report.globalPercent == 1) {
                        _showSuccessfullySavedPrompt(_targetWaveFile.nativePath, _targetWaveFile.size);
                    }
                }
                break;
        }
    }

    /**
     * Loads an empty project in the application. Attempts to load the default template if found,
     * otherwise falls back to creating a project from scratch.
     */
    private function _loadDefaultProject():void {
        var defaultProject:Object = _model.getDefaultProject();
        if (defaultProject is File) {
            _onProjectFileSelectedForOpen(defaultProject as File, true);
        } else {
            _loadProject((defaultProject as ProjectData));
            showStatus(Strings.sprintf(StaticTokens.COLD_START_NOTICE,
                    _model.getDefaultContentFile().nativePath), PromptColors.WARNING);
            _model.resetReferenceData();
            _updateProjectInfo();
            _resetSnapshotsHistory();

        }
    }

    /**
     * Loads a project in the application.
     */
    private function _loadProject(project:ProjectData, bypassViewReset:Boolean = false, silentMode:Boolean = false):void {

        // Stop playback
        _stopMidi();

        // Replace the current model
        _model.currentProject = project;

        // Update the views
        queryEngine.resetCache();
        ModelUtils.updateUnifiedPartsList(project);
        updateAllViews();
        if (bypassViewReset) {
            if (lastSelection) {
                var oldSelectionId:String = lastSelection.route;
                var restoredSelection:ProjectData = project.getElementByRoute(oldSelectionId) as ProjectData;
                setSelection(restoredSelection);
            }
        } else {
            Time.delay(0, function ():void {
                setSelection(project);
            });
        }

        // Initialize the generators used by this project (if any)
        _generatorUtils.wiringsMap.clear();
        var generatorsManager:GeneratorsManager = _generatorUtils.generatorsManager;
        generatorsManager.reset();
        if (!silentMode) {
            PTT.getPipe(GeneratorPipes.STATUS).subscribe(GeneratorKeys.PROJECT_GENERATORS_READY, _generatorUtils.onProjectGeneratorsReady);
        }
        generatorsManager.initializeGeneratorsUsedBy(project);

        // Signal the score renderer to reset scroll position and zoom
        if (!bypassViewReset) {
            GLOBAL_PIPE.send(ViewKeys.NEW_SCORE_LOADED);
        }
    }

    /**
     * Prepares a MIDI file from current score. Stores a pointer to it and fires some given callback when ready.
     */
    private function _prepareMidi(readyCallback:Function):void {
        showStatusOrPrompt(StaticTokens.PREPARING_MIDI, PromptColors.INFORMATION);
        var project:ProjectData = _model.currentProject;
        ModelUtils.updateUnifiedPartsList(project);
        var abc:String = project.exportToFormat(DataFormats.AUDIO_ABC_DATA_PROVIDER);
        _produceMidiFile(abc, function (...args):void {
            readyCallback();
        });
    }

    private function _getPartByMirrorId(mirrorUid:String):ProjectData {
        var parentSection:ProjectData = _currentSection as ProjectData || queryEngine.getAllSectionNodes()[0] as ProjectData;
        __beingSearchedForPartUuid = mirrorUid;
        var allPartsInSection:Array = ModelUtils.getChildrenOfType(parentSection, DataFields.PART);
        var matchingParts:Array = allPartsInSection.filter(__partsByUuid);
        __beingSearchedForPartUuid = null;
        return (matchingParts[0] as ProjectData);
    }

    /**
     * Returns a data provider that is suitable for displaying a contextual menu for the
     * currently right-clicked score item (or for the score itself if there is no item selected);
     */
    private function _getPopUpMenuSrcFor(item:ProjectData):Array {
        if (item) {
            return _contextualMenusManager.getMenuFor(item);
        }
        return null;
    }

    /**
     * TODO: document
     * @return
     */
    private function _doCopy():Boolean {
        var succeeded:Boolean = false;
        if (lastSelection) {
            var selectionType:String = lastSelection.getContent(DataFields.DATA_TYPE) as String;
            var isAcceptableType:Boolean = (selectionType == DataFields.CLUSTER || selectionType == DataFields.VOICE ||
                    selectionType == DataFields.MEASURE);
            var isAcceptableContent:Boolean = (lastSelection.numDataChildren > 0 || selectionType == DataFields.CLUSTER);
            if (isAcceptableType && isAcceptableContent) {
                if (_pasteSource) {
                    _pasteSource = null;
                }
                _pasteSource = ProjectData(lastSelection.clone());
                succeeded = _pasteSource != null;
            }
        }
        _pasteType = PASTE_MULTIPLE;
        _updateStructureOperationsStatus();
        return succeeded;
    }

    /**
     * TODO: document
     * @return
     */
    private function _doCut():void {
        if (_doCopy()) {
            _pasteType = PASTE_SINGLE;
            _onStructureItemRemove(lastSelection.route);
        }
    }

    /**
     * TODO: document
     * @return
     */
    private function _doPaste():void {
        if (_checkIfCanPaste()) {
            var pasteTarget:ProjectData = lastSelection;
            var sourceType:String = _pasteSource.getContent(DataFields.DATA_TYPE) as String;

            // Clear children of target element, if any
            pasteTarget.empty();

            // Transfer copiable elements from cloned source to target, if any
            var copiableFieldNames:Array = CopiableProperties[sourceType] as Array;
            for (var i:int = 0; i < copiableFieldNames.length; i++) {
                var fieldName:String = copiableFieldNames[i] as String;
                var srcValue:* = _pasteSource.getContent(fieldName);
                pasteTarget.setContent(fieldName, srcValue);
            }

            // Transfer clones of cloned element's children to target, if any
            for (var j:int = 0; j < _pasteSource.numDataChildren; j++) {
                var srcChild:ProjectData = _pasteSource.getDataChildAt(j) as ProjectData;
                pasteTarget.addDataChild(srcChild.clone());
            }

            // Add recover point
            _snapshotsManager.takeSnapshot(_model.currentProject,
                    Strings.sprintf(
                            StaticTokens.ITEM_PASTE_OPERATION, pasteTarget.getContent(DataFields.DATA_TYPE)
                    )
            );
            updateUndoRedoUi();

            // If operation was initiated via `cut`, discard the clone
            if (_pasteType == PASTE_SINGLE) {
                _pasteSource = null;
                _pasteType = PASTE_MULTIPLE;
            }

            // Make changes visible
            updateAllViews();
            lastSelection = null;
            setSelection(pasteTarget);
        }
    }

    /**
     * TODO: document
     * @return
     */
    private function _doTranspose():void {

        // Opens the dedicated UI in a new window; the dedicated UI will take it from there.
        if (lastSelection != null && lastSelection.numDataChildren > 0) {
            var selectionType:String = lastSelection.getContent(DataFields.DATA_TYPE) as String;
            if (!_windowsManager.isWindowAvailable(_transpositionWindowUid)) {
                var wContent:IWindowContent = new TranspositionUi;
                if (_transpositionUserConfig) {
                    (wContent as TranspositionUi).initialData = _transpositionUserConfig;
                }
                registerColorizableUi(wContent);
                _transpositionWindowUid = _windowsManager.createWindow(wContent, WindowStyle.HEADER | WindowStyle.TOP | WindowStyle.NATIVE, true, _mainWindowUid);
                var wTitle:String = Strings.sprintf(StaticTokens.TRANSPOSE_WINDOW_TITLE, selectionType);
                _windowsManager.updateWindowTitle(_transpositionWindowUid, wTitle);
                var wSize:Rectangle = Sizes.MIN_TRANSPOSITION_WINDOW_BOUNDS;
                _windowsManager.updateWindowBounds(_transpositionWindowUid, wSize, false);
                _windowsManager.showWindow(_transpositionWindowUid);
                _windowsManager.alignWindows(_transpositionWindowUid, _windowsManager.mainWindow, 0.5, 0.5);
            }
        }
    }

    /**
     * TODO: document
     * @return
     */
    private function _doScaleIntervals():void {

        // Opens the dedicated UI in a new window; the dedicated UI will take it from there.
        if (lastSelection != null && lastSelection.numDataChildren > 0) {
            var selectionType:String = lastSelection.getContent(DataFields.DATA_TYPE) as String;
            if (!_windowsManager.isWindowAvailable(_scaleIntervalsWindowUid)) {
                var wContent:IWindowContent = new ScaleIntervalsUI;
                if (_scaleIntervalsUserConfig) {
                    (wContent as ScaleIntervalsUI).initialData = _scaleIntervalsUserConfig;
                }
                registerColorizableUi(wContent);
                _scaleIntervalsWindowUid = _windowsManager.createWindow(wContent, WindowStyle.HEADER | WindowStyle.TOP | WindowStyle.NATIVE, true, _mainWindowUid);
                var wTitle:String = Strings.sprintf(StaticTokens.SCALE_INTERVALS_WINDOW_TITLE, selectionType);
                _windowsManager.updateWindowTitle(_scaleIntervalsWindowUid, wTitle);
                var wSize:Rectangle = Sizes.MIN_SCALE_INTERVALS_WINDOW_BOUNDS;
                _windowsManager.updateWindowBounds(_scaleIntervalsWindowUid, wSize);
                _windowsManager.showWindow(_scaleIntervalsWindowUid);
                _windowsManager.alignWindows(_scaleIntervalsWindowUid, _windowsManager.mainWindow, 0.5, 0.5);
            }
        }
    }

    /**
     * Scales all melodic intervals in the given selection by a constant factor.
     */
    private static function _scaleIntervalsByConstantFactor(clusters:Array, config:Object):Array {
        var hasMusic:Boolean = clusters[ViewKeys.PITCH_BOUNDS_INFO][ViewKeys.SELECTION_HAS_MUSIC] as Boolean;
        if (hasMusic) {
            var factor:Number = config[ViewKeys.SCALE_CONSTANT_FACTOR] as Number;
            var mustReverse:Boolean = config[ViewKeys.SCALE_REVERSE_DIRECTION] as Boolean;
            if (mustReverse) {
                factor *= -1;
            }
            var prevBasePitch:int = 0;
            for (var i:int = 0; i < clusters.length; i++) {
                var item:Object = clusters[i] as Object;
                var basePitch:int = item[ViewKeys.BASE_PITCH] as int;
                if (prevBasePitch) {

                    // TODO: let the user decide what rounding function to use.
                    // Auto could also be used:
                    // var roundFunc : Function = (factor > 1)? Math.ceil : Math.floor;
                    var roundFunc:Function = Math.round;
                    var originalDelta:int = (prevBasePitch - basePitch);
                    var computedDelta:int = roundFunc.call(null, originalDelta * factor * -1) as int;
                    item[ViewKeys.DELTA] = computedDelta;
                }
                prevBasePitch = basePitch;
            }
            return clusters;
        }
        return null;
    }

    /**
     * Scales all melodic intervals in the given selection by a movable factor. The process starts off with
     * a value (used at the beginning of the selection) and linearly interpolates toward another (used at
     * the end of the selection).
     */
    private static function _scaleIntervalsProgressively(clusters:Array, config:Object):Array {
        var hasMusic:Boolean = clusters[ViewKeys.PITCH_BOUNDS_INFO][ViewKeys.SELECTION_HAS_MUSIC] as Boolean;
        if (hasMusic) {
            var startFactor:Number = config[ViewKeys.SCALE_START_FACTOR] as Number;
            var endFactor:Number = config[ViewKeys.SCALE_END_FACTOR] as Number;
            var mustReverse:Boolean = config[ViewKeys.SCALE_REVERSE_DIRECTION] as Boolean;
            var prevBasePitch:int = 0;
            var lastClusterIndex:int = clusters.length - 1;
            for (var i:int = 0; i < clusters.length; i++) {
                var progress:Number = (i / lastClusterIndex) as Number;
                var factor:Number = progress * (endFactor - startFactor) + startFactor;
                if (mustReverse) {
                    factor *= -1;
                }
                var item:Object = clusters[i] as Object;
                var basePitch:int = item[ViewKeys.BASE_PITCH] as int;
                if (prevBasePitch) {

                    // TODO: let the user decide what rounding function to use.
                    // Auto could also be used:
                    // var roundFunc : Function = (factor > 1)? Math.ceil : Math.floor;
                    var roundFunc:Function = Math.round;
                    var originalDelta:int = (prevBasePitch - basePitch);
                    var computedDelta:int = roundFunc.call(null, originalDelta * factor * -1) as int;
                    item[ViewKeys.DELTA] = computedDelta;
                }
                prevBasePitch = basePitch;
            }
            return clusters;
        }
        return null;
    }

    /**
     * Scales all melodic intervals in the given selection by a constant factor, but only if they fall below or
     * above a given threshold.
     */
    private static function _scaleIntervalsByThreshold(clusters:Array, config:Object):Array {
        var hasMusic:Boolean = clusters[ViewKeys.PITCH_BOUNDS_INFO][ViewKeys.SELECTION_HAS_MUSIC] as Boolean;
        if (hasMusic) {
            var factor:Number = config[ViewKeys.SCALE_CONSTANT_FACTOR] as Number;
            var mustReverse:Boolean = config[ViewKeys.SCALE_REVERSE_DIRECTION] as Boolean;
            var threshold:int = config[ViewKeys.SCALE_THRESHOLD] as int;
            var thresholdRealm:String = config[ViewKeys.SCALE_THRESHOLD_REALM] as String;
            if (mustReverse) {
                factor *= -1;
            }
            var prevBasePitch:int = 0;
            for (var i:int = 0; i < clusters.length; i++) {
                var item:Object = clusters[i] as Object;
                var basePitch:int = item[ViewKeys.BASE_PITCH] as int;
                if (prevBasePitch) {
                    var originalDelta:int = (prevBasePitch - basePitch);
                    var compare:Function = (thresholdRealm == Direction.ABOVE) ? _greaterThan : _lessThan;
                    var passesThreshold:Boolean = compare.call(null, Math.abs(originalDelta), threshold);
                    if (passesThreshold) {

                        // TODO: let the user decide what rounding function to use.
                        // Auto could also be used:
                        // var roundFunc : Function = (factor > 1)? Math.ceil : Math.floor;
                        var roundFunc:Function = Math.round;
                        var computedDelta:int = roundFunc.call(null, originalDelta * factor * -1) as int;
                        item[ViewKeys.DELTA] = computedDelta;
                    }
                }
                prevBasePitch = basePitch;
            }
            return clusters;
        }
        return null;
    }

    /**
     * TODO: document
     * @return
     */
    private static function _greaterThan(a:Object, b:Object, orEqual:Boolean = false):Boolean {
        return orEqual ? (a >= b) : (a > b);
    }

    /**
     * TODO: document
     * @return
     */
    private static function _lessThan(a:Object, b:Object, orEqual:Boolean = false):Boolean {
        return orEqual ? (a <= b) : (a < b);
    }

    /**
     * Resolves a given Cluster to its "tuplet root" (first Cluster in the tuplet),
     * or to `null` if given Cluster is not, in fact inside any tuplet.
     */
    private static function _getTupletRootOf(tupletMember:ProjectData):ProjectData {
        if (tupletMember) {
            if (tupletMember.getContent(DataFields.STARTS_TUPLET) as Boolean) {
                return tupletMember;
            }
            var tupletRootId:String = (tupletMember.getContent(DataFields.TUPLET_ROOT_ID) as String);
            if (tupletRootId != DataFields.VALUE_NOT_SET) {
                var parentVoice:ProjectData = tupletMember.dataParent as ProjectData;
                return (parentVoice.getElementByRoute(tupletRootId) as ProjectData) || null;
            }
        }
        return null;
    }

    /**
     * Converts all members of a tuplet to regular Clusters, erasing their "starts tuplet" or
     * "tuplet root id" information, as appropriate.
     */
    private static function _decommissionTupletOf(tupletRoot:ProjectData, discardRoot:Boolean = true):void {
        var rootId:String = tupletRoot.route;
        var startIndex:int = tupletRoot.index;
        var parentVoice:ProjectData = tupletRoot.dataParent as ProjectData;
        var maxIndex:int = parentVoice.numDataChildren;
        if (discardRoot) {
            tupletRoot.setContent(DataFields.TUPLET_BEAT_DURATION, DataFields.VALUE_NOT_SET);
            tupletRoot.setContent(DataFields.TUPLET_SRC_NUM_BEATS, DataFields.VALUE_NOT_SET);
            tupletRoot.setContent(DataFields.TUPLET_TARGET_NUM_BEATS, DataFields.VALUE_NOT_SET);
            tupletRoot.setContent(DataFields.STARTS_TUPLET, false);
        }
        for (var i:int = startIndex; i < maxIndex; i++) {
            var cluster:ProjectData = parentVoice.getDataChildAt(i) as ProjectData;
            if (cluster == tupletRoot) {
                continue;
            }
            if ((cluster.getContent(DataFields.TUPLET_ROOT_ID) as String) == rootId) {
                cluster.setContent(DataFields.TUPLET_ROOT_ID, DataFields.VALUE_NOT_SET);
                cluster.setContent(DataFields.TUPLET_BEAT_DURATION, DataFields.VALUE_NOT_SET);
                cluster.setContent(DataFields.TUPLET_SRC_NUM_BEATS, DataFields.VALUE_NOT_SET);
                cluster.setContent(DataFields.TUPLET_TARGET_NUM_BEATS, DataFields.VALUE_NOT_SET);
            } else {
                break;
            }
        }
    }

    /**
     * TODO: document
     * @return
     */
    private static function _openContactUrl():void {
        navigateToURL(new URLRequest(URLs.GITHUB_ISSUES_PAGE));
    }

    /**
     * TODO: document
     * @return
     */
    private static function _openDocumentationUrl():void {
        navigateToURL(new URLRequest(URLs.ONLINE_DOCUMENTATION));
    }

    /**
     * Triggered when user selects 'Open' from the application menu.
     */
    private function _openExistingProject():void {
        var title:String = StaticTokens.CHOOSE_OPEN_FILE;
        var folder:File = _model.currentProjectFile ? _model.currentProjectFile.parent : File.documentsDirectory;
        var fileTypes:Array = [new FileFilterEntry(FileAssets.PROJECT_FILE_DESCRIPTION, FileAssets.PROJECT_FILE_EXTENSION)];
        _fileSelectedCallback = _onProjectFileSelectedForOpen;
        _openFileBrowser(title, folder, fileTypes);
    }

    /**
     * Triggered when user selects "New from template..." from the application menu.
     */
    private function _openProjectFromTemplate():void {
        var title:String = StaticTokens.CHOOSE_TEMPLATE_FILE;
        var folder:File = FileAssets.CONTENT_DIR;
        var fileTypes:Array = [new FileFilterEntry(FileAssets.PROJECT_FILE_DESCRIPTION, FileAssets.PROJECT_FILE_EXTENSION)];
        _fileSelectedCallback = _onTemplateFileSelectedForOpen;
        _openFileBrowser(title, folder, fileTypes);
    }

    /**
     * Displays the FileBrowser component in a new window, letting the user to
     * select or create a file on the file system.
     *
     * @param    windowTitle
     *            The string to display in the window title bar.
     *
     * @param    location
     *            A File object pointing to a folder in the filesystem. This folder
     *            must exist.
     *
     * @param    fileTypesAllowed
     *            An optional Array with FileFilterEntry instances, defining the
     *            type(s) of files user is allow to select or create from within the
     *            file browser.
     */
    private function _openFileBrowser(windowTitle:String, location:File, fileTypesAllowed:Array = null):void {
        // There cannot be multiple file browser instances at the same time
        if (!_windowsManager.isWindowAvailable(_fileBrowserWindowUid)) {
            // Create and Configure the component
            var windowContent:WindowableFileBrowser = (_fileBrowserWindowFactory.newInstance() as WindowableFileBrowser);
            windowContent.addEventListener(FileSelectionEvent.FILE_SELECTED, _onFileBrowserSelect);
            windowContent.addEventListener(FileSelectionEvent.FILE_CANCELLED, _onFileBrowserCancel);
            windowContent.home = location;
            windowContent.fileFilter = fileTypesAllowed;
            // Create and configure the window that will display the component
            registerColorizableUi(windowContent);
            _fileBrowserWindowUid = _windowsManager.createWindow(windowContent, WindowStyle.TOOL | WindowStyle.TOP | WindowStyle.NATIVE, true, _mainWindowUid);
            _windowsManager.updateWindowTitle(_fileBrowserWindowUid, windowTitle);
            _windowsManager.updateWindowBounds(_fileBrowserWindowUid, Sizes.MIN_FILE_BROWSER_WINDOW_BOUNDS, false);
            _windowsManager.updateWindowMinSize(_fileBrowserWindowUid, Sizes.MIN_FILE_BROWSER_WINDOW_BOUNDS.width, Sizes.MIN_FILE_BROWSER_WINDOW_BOUNDS.height, true);
            _windowsManager.observeWindowActivity(_fileBrowserWindowUid, WindowActivity.BEFORE_DESTROY, _onFileBrowserXClose);
            _windowsManager.showWindow(_fileBrowserWindowUid);
            _windowsManager.alignWindows(_fileBrowserWindowUid, _windowsManager.mainWindow, 0.5, 0.5);
        }
    }

    /**
     * TODO: document
     * @return
     */
    private static function _openNewsUrl():void {
        navigateToURL(new URLRequest(URLs.GITHUB_RELEASES_PAGE));
    }

    /**
     * TODO: document
     * @return
     */
    private static function _openPatreonUrl():void {
        navigateToURL(new URLRequest(URLs.SPONSORS_HOME_PAGE));
    }

    /**
     * TODO: document
     * @return
     */
    private static function _produceMidiFile(abcMarkup:String, callback:Function):void {
        NativeAppsWrapper.instance.abcToMIDI(abcMarkup, null, callback);
    }

    /**
     * Saves the current project and wipes undo history.
     */
    private function _saveCurrentProject(force:Boolean = false):void {
        _deferFileBrowserClose = false;
        if (force || _model.haveUnsavedData()) {
            var destination:File = _model.currentProjectFile;
            if (destination == null) {
                _saveCurrentProjectAs();
            } else {
                var currProject:ProjectData = _model.currentProject;
                currProject.setContent(DataFields.MODIFICATION_TIMESTAMP, Time.timestamp);
                var currentData:ByteArray = currProject.toSerialized();
                var error:String;
                var onWriteError:Function = function (event:ErrorEvent):void {
                    writer.removeEventListener(ErrorEvent.ERROR, onWriteError);
                    error = event.text;
                    _deferFileBrowserClose = true;
                }
                var writer:AbstractDiskWritter = new RawDiskWritter;
                writer.addEventListener(ErrorEvent.ERROR, onWriteError);
                var bytesWritten:int = writer.write(currentData, destination);
                if (bytesWritten > 0) {
                    _showSuccessfullySavedPrompt(destination.nativePath, bytesWritten);
                    _model.resetReferenceData();
                    _updateProjectInfo();
                    _resetSnapshotsHistory();
                } else {
                    _showUnwritableFileError(error);
                }
            }
        } else {
            _showProjectAlreadySavedPrompt();
        }
    }

    /**
     * Triggered when user selects 'Save As' from the application menu.
     */
    private function _saveCurrentProjectAs():void {
        var title:String = StaticTokens.CHOOSE_SAVE_FILE;
        var folder:File = _model.currentProjectFile ? _model.currentProjectFile.parent : File.documentsDirectory;
        var fileTypes:Array = [new FileFilterEntry(FileAssets.PROJECT_FILE_DESCRIPTION, FileAssets.PROJECT_FILE_EXTENSION)];
        _fileSelectedCallback = _onProjectFileSelectedForSave;
        _openFileBrowser(title, folder, fileTypes);
    }

    /**
     * New approach, uses the new, AS3 renderer.
     * Broadcast the generated ABC markup for the ABC to SVG parser to parse, and
     * the SVG renderer to draw. In the new implementation, the two are encapsulated
     * in a dedicated, AS3/MXML only component, namely the "MusicScoreViewer".
     */
    private function _sendScoreABC(abcMarkup:String):void {
        if (_scoreRendererReady) {
            GLOBAL_PIPE.send(ViewKeys.ABC_MARKUP_READY, abcMarkup);
        } else {
            _bufferedABC = abcMarkup;
        }
    }

    /**
     * TODO: document
     * @return
     */
    private function _sendTreeData(data:Object):void {
        if (_structureTreeReady) {
            PTT.getPipe(ViewPipes.PROJECT_TREE_PIPE).send(ViewKeys.TREE_DATA_READY, data);
        } else {
            _bufferedTreeData = data;
        }
    }

    /**
     * Causes a general-purpose confirmation to display, to let the user know he needs to make a decision about something.
     */
    private function _showConfirmationPrompt(
            text:String,
            deferredFunc:Function,
            title:String = null
    ):void {
        var observer:IObserver = _promptsManager.yesNoConfirmation(text, title);
        var callback:Function = function (response:String):void {
            observer.stopObserving(PromptDefaults.USER_INTERRACTION, callback);
            if (response == PromptDefaults.YES_LABEL) {
                deferredFunc();

                // In the case of a Yes/No confirmation prompt, the underlying file browser window (if any)
                // should only close when the user has clicked on "yes" inside the prompt.
                _closePendingBrowserWindow();
            }
        }
        observer.observe(PromptDefaults.USER_INTERRACTION, callback);
    }

    /**
     * Certain prompt windows open on top of the file browser window (such as the "Discard Changes?" or  "Overwrite file?"
     * prompts). This establishes a conditional relationship between the prompt window and the  browser window, the general
     * rule of thumb being that the underlying browser window should close when a button in the prompt is clicked. This
     * function encapsulates the closing mechanism for this particular situation.
     */
    private function _closePendingBrowserWindow():void {
        if (_deferFileBrowserClose) {
            if (_fileBrowser) {
                _fileBrowser.removeEventListener(FileSelectionEvent.FILE_SELECTED, _onFileBrowserSelect);
                _fileBrowser.removeEventListener(FileSelectionEvent.FILE_CANCELLED, _onFileBrowserCancel);
                Time.delay(0.2, _closeFileBrowserWindow);
            }
            _fileSelectedCallback = null;
            _fileSelectedCallbackContext = null;
            _deferFileBrowserClose = false;
        }
    }

    /**
     * Cases a highly customizable prompt window to be displayed. This is really a wrapper over `_promptsManager.prompt()`.
     * @param    text
     *            @see PromptsManager.prompt()
     *
     * @param    title
     *            @see PromptsManager.prompt()
     *
     * @param    deferredFunctionsMap
     *            Object with button labels as keys and Function objects as values. When a button with a matching label is
     *            clicked, the corresponding function will be executed. To target the two states of the prompt's checkbox
     *            (if any), use the PromptDefaults.CHECKED and PromptDefaults.UNCHECKED constants as keys, respectively.
     *
     * @param    buttonLabels
     *            @see PromptsManager.prompt()
     *
     * @param    image
     *            @see PromptsManager.prompt()
     *
     * @param    checkBoxLabel
     *            @see PromptsManager.prompt()
     *
     * @param    progressBarObserver
     *            @see PromptsManager.prompt()
     */
    private function _showCustomPrompt(text:String, title:String, deferredFunctionsMap:Object, buttonLabels:Vector.<String>,
                                       image:Class = null, checkBoxLabel:String = null, progressBarObserver:IObserver = null):void {
        var observer:IObserver = _promptsManager.prompt(text, title, image, buttonLabels, checkBoxLabel, progressBarObserver);
        var callBack:Function = function (response:String):void {
            observer.stopObserving(PromptDefaults.USER_INTERRACTION, callBack);
            if (deferredFunctionsMap) {
                var respondingFunction:Function = (deferredFunctionsMap[response] as Function);
                if (respondingFunction != null) {
                    respondingFunction();

                    // In the case of a general prompt, the underlying file browser window (if any) should close when the user
                    // has clicked on anything but the "checkbox" button inside the prompt, PROVIDED THAT THE CLICKED BUTTON
                    // HAD A FUNCTION ASSOCIATED.
                    if (response != PromptDefaults.CHECKED && response != PromptDefaults.UNCHECKED) {
                        _closePendingBrowserWindow();
                    }
                }
            }
        }
        observer.observe(PromptDefaults.USER_INTERRACTION, callBack);
    }

    /**
     * Triggered when the file user tries to write to already exists. Upon
     * choosing to override the file, the given `deferredFunction` is executed.
     *
     * @param   path
     *          Path to file being overwritten.
     *
     * @param    deferredFunction
     *           A function to execute on overwrite.
     */
    private function _showOverwriteFilePrompt(path:String, deferredFunction:Function):void {
        var text:String = StaticTokens.OVERWRITE_FILE_QUESTION.replace('%s', path);
        _showConfirmationPrompt(text, deferredFunction);
    }

    /**
     * Triggered when the project user tries to write over has unsaved data.
     * Upon choosing to override the project, the deferred function given is
     * executed.
     *
     * @param    deferredFunc
     *           A function to execute on overwrite.
     */
    private function _showDiscardChangesPrompt(deferredFunc:Function):void {
        var text:String = Strings.sprintf(StaticTokens.OVERWRITE_PROJECT_QUESTION,
                _model.currentProject.getContent(DataFields.PROJECT_NAME));
        _showCustomPrompt(text, StaticTokens.DISCARD_CHANGES,
                {
                    "Discard": deferredFunc, "Don't close": function dummy():void {
                    }
                },
                Vector.<String>(["Discard", "Don't close"]),
                RasterImages.PAPER_SHREDDER
        );
    }

    /**
     * Yields a status notice that the project is already saved. Triggered when saving
     * was attempted with no intervening changes.
     */
    private static function _showProjectAlreadySavedPrompt():void {
        var data:Object = [];
        data[PromptKeys.TEXT] = StaticTokens.PROJECT_ALREADY_SAVED;
        data[PromptKeys.BACKGROUND_COLOR] = PromptColors.NOTICE;
        GLOBAL_PIPE.send(ViewKeys.NEED_PROMPT, data);
    }

    /**
     * Shown when reading of a file was attempted that is not readable.
     */
    private function _showUnreadableFileError(error:String):void {
        Time.delay(0.2, function ():void {
            _promptsManager.error(error);
        });
    }

    /**
     * Shown when writing to a file was attempted that is not writeable.
     */
    private function _showUnwritableFileError(error:String):void {
        _promptsManager.error(Strings.sprintf(StaticTokens.CANNOT_WRITE_FILE, error));
    }

    /**
     * Shown when opening of a project file was attempted that uses an old file format.
     */
    private function _showUnsupportedProjectNotice(file:File):void {
        var text:String = Strings.sprintf(StaticTokens.UNSUPPORTED_PROJECT_NOTICE, file.nativePath);
        _promptsManager.error(text, StaticTokens.UNSUPPORTED_FILE_FORMAT);
    }

    /**
     * Yields a status notification that a project was successfully saved.
     */
    private static function _showSuccessfullySavedPrompt(path:String, numBytesWritten:int):void {
        var data:Object = [];
        data[PromptKeys.TEXT] = StaticTokens.FILE_SAVED_TEMPLATE.replace('%s', path).replace('%d', numBytesWritten);
        data[PromptKeys.BACKGROUND_COLOR] = PromptColors.NOTICE;
        GLOBAL_PIPE.send(ViewKeys.NEED_PROMPT, data);
    }

    /**
     * TODO: document
     * @return
     */
    private static function _sortDurationItems(itemA:Object, itemB:Object):int {
        var fractionA:Fraction = itemA[DataKeys.SOURCE];
        var fractionB:Fraction = itemB[DataKeys.SOURCE];
        return Fraction.compare(fractionA, fractionB);
    }

    /**
     * TODO: document
     * @return
     */
    private function _stopMidi():void {
        if (_isMidiPlaying) {
            _onStopRequested();
        }
    }

    /**
     * TODO: document
     * @return
     */
    private function _terminateApplication():void {
        // Destroy the "scratch disk" folder
        NativeAppsWrapper.instance.deleteScratchDisk();
        // Close main window; the window manager will know to close all
        // the other windows.
        _windowsManager.destroyWindow(_mainWindowUid);
        // Actually end execution
        NativeApplication.nativeApplication.exit();
    }

    /**
     * TODO: document
     * @return
     */
    private function _updateMainAppTitle(...values):void {
        if (values.length > 1) {
            values.splice(values.length - 1, 0, CommonStrings.DASH);
        }
        var title:String = values.join(CommonStrings.SPACE);
        if (_windowsManager && _mainWindowUid && _windowsManager.isWindowAvailable(_mainWindowUid)) {
            _windowsManager.updateWindowTitle(_mainWindowUid, title);
        }
    }

    /**
     * Shows info about a given project in the application title and tab bar.
     */
    private function _updateProjectInfo(...ignore):void {
        var titleData:Array = [Descriptor.getAppSignature(), Descriptor.getAppVersion(true)];
        var currFileName:String = StaticTokens.NEW_FILE;
        if (_model.currentProject != null) {
            if (_model.currentProjectFile != null) {
                var projectFileName:String = _model.currentProjectFile.name;
                if (projectFileName) {
                    currFileName = projectFileName;
                }
            }
        }
        titleData.push(currFileName);
        _updateMainAppTitle.apply(this, titleData);
        _updateTabs();
        GLOBAL_PIPE.send(ViewKeys.PROJECT_INFO_CHANGED, _model.currentProject);
    }

    /**
     * TODO: document
     * @return
     */
    private function _updateProjectScore():void {
        GLOBAL_PIPE.send(ViewKeys.INVALIDATE_CURRENT_SCORE);
        ModelUtils.updateUnifiedPartsList(_model.currentProject);
        var abc:String = _model.currentProject.exportToFormat(DataFormats.SCREEN_ABC_DATA_PROVIDER);
        _sendScoreABC(abc);
    }

    /**
     * TODO: document
     * @return
     */
    private function _updateProjectStructure():void {
        var data:Object = (_model.currentProject.exportToFormat(DataFormats.TREE_DATA_PROVIDER) as Object);
        _sendTreeData(data);
    }

    /**
     * Analyzes a ProjectData instance and returns an Object with contextual information, such as:
     *  {
     *      'isEmpty' : Boolean,
     *      'isFirstChild' : Boolean,
     *      'isFirstChildOfFirstParent' : Boolean,
     *      'isLastChild' : Boolean,
     *      'isLastChildOfLastParent' : Boolean,
     *      'isLastAvailableChild' : Boolean
     *  }
     */
    private function _getElementContext(element:ProjectData):Object {
        var context : Object = {
            'isEmpty': false,
            'isFirstChild': false,
            'isFirstChildOfFirstParent': false,
            'isLastChild': false,
            'isLastChildOfLastParent': false,
            'isLastAvailableChild': false
        };
        if (!element) {
            return context;
        }
        var elementParent:ProjectData = ProjectData(element.dataParent);
        var elementIndex:int = element.index;
        var isEmpty:Boolean = (element.numDataChildren == 0);
        var isFirstChild:Boolean = (elementIndex == 0);
        var isFirstChildOfFirstParent:Boolean = _nudgeLock ? false : _isAbsoluteFirstOfType(element);
        var isLastChild:Boolean = (elementParent != null && elementIndex == elementParent.numDataChildren - 1);
        var isLastChildOfLastParent:Boolean = _nudgeLock ? false : _isAbsoluteLastOfType(element);
        var isLastAvailableChild:Boolean = (elementParent != null && elementParent.numDataChildren == 1);
        context = {
            'isEmpty': isEmpty,
            'isFirstChild': isFirstChild,
            'isFirstChildOfFirstParent': isFirstChildOfFirstParent,
            'isLastChild': isLastChild,
            'isLastChildOfLastParent': isLastChildOfLastParent,
            'isLastAvailableChild': isLastAvailableChild
        };
        return context;
    }

    /**
     * Returns `true` if provided `element` is the first element of its type, which implies being the first child of
     * its parent, and that parent being the first child of its parent, and so on, recursively, until the top-most node
     * in the hierarchy is reached. Returns `false` otherwise. Note that quirks are employed in specific situations, such
     * as Clusters (we will disregard/treat transparently their parent Voice), Measures (same for their parent Part) or
     * Sections (same for their parent Score).
     *
     * @param   element
     *          Element to test. MUST BE NOT NULL.
     *
     * @return  True if element is the absolute first element of its type in the hierarchy.
     */
    private function _isAbsoluteFirstOfType(element:ProjectData):Boolean {
        var elementIndex:int = element.index;

        // Handle top of hierarchy case.
        if (elementIndex == -1) {
            return true;
        }
        var elementParent:ProjectData = ProjectData(element.dataParent);
        var isFirstChild:Boolean = (elementIndex == 0);

        // Optimization (don't check upper hierarchy if element itself fails condition)
        if (!isFirstChild) {
            return false;
        }

        if (!_nudgeLock && elementParent) {
            if (ModelUtils.isCluster(element) || ModelUtils.isMeasure(element) || ModelUtils.isSection(element)) {
                elementParent = (elementParent.dataParent as ProjectData);
            }
        }
        if (elementParent) {
            return isFirstChild && _isAbsoluteFirstOfType(elementParent);
        }
        return isFirstChild;
    }

    /**
     * Returns `true` if provided `element` is the last element of its type, which implies being the last child of
     * its parent, and that parent being the last child of its parent, and so on, recursively, until the top-most node
     * in the hierarchy is reached. Returns `false` otherwise. Note that quirks are employed in specific situations, such
     * as Clusters (we will disregard/treat transparently their parent Voice), Measures (same for their parent Part) or
     * Sections (same for their parent Score).
     *
     * @param   element
     *          Element to test. MUST BE NOT NULL.
     *
     * @return  True if element is the absolute last element of its type in the hierarchy.
     */
    private function _isAbsoluteLastOfType(element:ProjectData):Boolean {
        var elementIndex:int = element.index;

        // Handle top of hierarchy case.
        if (elementIndex == -1) {
            return true;
        }
        var elementParent:ProjectData = ProjectData(element.dataParent);
        var isLastChild:Boolean = (elementParent != null && elementIndex == elementParent.numDataChildren - 1);

        // Optimization (don't check upper hierarchy if element itself fails condition)
        if (!isLastChild) {
            return false;
        }

        if (!_nudgeLock && elementParent) {
            if (ModelUtils.isCluster(element) || ModelUtils.isMeasure(element) || ModelUtils.isSection(element)) {
                elementParent = (elementParent.dataParent as ProjectData);
            }
        }
        if (elementParent) {
            return isLastChild && _isAbsoluteLastOfType(elementParent);
        }
        return isLastChild;
    }

    /**
     * Updates the enablement state of UI commands (toolbar or menu buttons) related to creating, deleting or nudging
     * nodes. Does not return a value, instead, it sends information through the global pipe, under the
     * "ViewKeys.STRUCTURE_OPERATIONS_STATUS" key.
     */
    private function _updateStructureOperationsStatus():void {

        var selContext:Object = _getElementContext(lastSelection);
        var isEmpty:Boolean = (selContext.isEmpty as Boolean);
        var canAddChild:Boolean = false;
        var canRemoveSelf:Boolean = false;
        var canNudgeSelfUp:Boolean = false;
        var canNudgeSelfDown:Boolean = false;
        var canCopySelfToClipboard:Boolean = false;
        var canCutSelfToClipboard:Boolean = false;

        if (lastSelection != null) {

            // Parts can be stacked (e.g., two Violins will count as one Part of "type" Violin).
            // As it only makes sense to move the stack, as a whole, we disable the "nudge" functions for all
            // subsequent instruments in the stack (e.g., one will not be able to directly "nudge" up or down
            // the second Violin, but only by means of doing so to the first Violin).
            var isFirstPartInStack:Boolean = true;
            if (ModelUtils.isPart(lastSelection)) {
                isFirstPartInStack = lastSelection.getContent(DataFields.PART_ORDINAL_INDEX) == 0;
                if (isFirstPartInStack) {
                    if (!selContext.isLastAvailableChild) {
                        selContext.isFirstChild = lastSelection.getContent(ViewKeys.FIRST_PART_IN_SCORE) as Boolean;
                        selContext.isLastChild = lastSelection.getContent(ViewKeys.LAST_PART_IN_SCORE) as Boolean;
                    }
                }
            }
            if (ModelUtils.isProject(lastSelection)) {
                canAddChild = !ModelUtils.projectHasScore(lastSelection);
                canRemoveSelf = canNudgeSelfUp = canNudgeSelfDown = canCopySelfToClipboard = canCutSelfToClipboard = false;
            }
            if (ModelUtils.isGenerators(lastSelection)) {
                canAddChild = true;
                canRemoveSelf = canNudgeSelfUp = canNudgeSelfDown = canCopySelfToClipboard = canCutSelfToClipboard = false;
            }
            if (ModelUtils.isGenerator(lastSelection)) {
                canAddChild = canNudgeSelfUp = canNudgeSelfDown = canCopySelfToClipboard = canCutSelfToClipboard = false;
                canRemoveSelf = true;
            }
            if (ModelUtils.isScore(lastSelection)) {
                canAddChild = true;
                canRemoveSelf = canNudgeSelfUp = canNudgeSelfDown = canCopySelfToClipboard = canCutSelfToClipboard = false;
            }
            if (ModelUtils.isSection(lastSelection)) {
                canAddChild = canRemoveSelf = true;
                canCopySelfToClipboard = canCutSelfToClipboard = false;
                canNudgeSelfUp = !ModelUtils.isFirstChildOfItsType(lastSelection);
                canNudgeSelfDown = !ModelUtils.isLastChildOfItsType(lastSelection);

            }
            if (ModelUtils.isPart(lastSelection)) {
                canAddChild = true;
                canRemoveSelf = !selContext.isLastAvailableChild;
                canNudgeSelfUp = isFirstPartInStack && !selContext.isFirstChild;
                canNudgeSelfDown = isFirstPartInStack && !selContext.isLastChild;
                canCopySelfToClipboard = canCutSelfToClipboard = false;
            }
            if (ModelUtils.isMeasure(lastSelection)) {

                // Voices cannot be manually added
                canAddChild = false;
                canRemoveSelf = true;
                canNudgeSelfUp = _nudgeLock ? !selContext.isFirstChild : !selContext.isFirstChildOfFirstParent;
                canNudgeSelfDown = _nudgeLock ? !selContext.isLastChild : !selContext.isLastChildOfLastParent;
                canCopySelfToClipboard = canCutSelfToClipboard = !selContext.isEmpty;
            }
            if (ModelUtils.isVoice(lastSelection)) {

                // Voices can be nudged up or down. As a side effect, nudging also alters the
                // voice's index and assigned staff.
                canNudgeSelfUp = !ModelUtils.isFirstChildOfItsType(lastSelection);
                canNudgeSelfDown = !ModelUtils.isLastChildOfItsType(lastSelection);
                canAddChild = true;

                // Voices cannot be manually removed
                canRemoveSelf = canCutSelfToClipboard = false;
                canCopySelfToClipboard = !selContext.isEmpty;
            }
            if (ModelUtils.isCluster(lastSelection)) {
                canAddChild = canRemoveSelf = canCopySelfToClipboard = canCutSelfToClipboard = true;
                canNudgeSelfUp = _nudgeLock ? !selContext.isFirstChild : !selContext.isFirstChildOfFirstParent;
                canNudgeSelfDown = _nudgeLock ? !selContext.isLastChild : !selContext.isLastChildOfLastParent;
            }
            if (ModelUtils.isNote(lastSelection)) {
                canAddChild = canCopySelfToClipboard = canCutSelfToClipboard = false;
                canRemoveSelf = true;
                canNudgeSelfUp = canNudgeSelfDown = false;
            }
        }
        var status:Object = {};
        status[ViewKeys.SELECTION_TYPE] = lastSelection ? lastSelection.getContent(DataFields.DATA_TYPE) : null;
        status[ViewKeys.PASTE_SOURCE_TYPE] = _pasteSource ? _pasteSource.getContent(DataFields.DATA_TYPE) : null;
        status[ViewKeys.ADD_ELEMENT_AVAILABLE] = canAddChild;
        status[ViewKeys.REMOVE_ELEMENT_AVAILABLE] = canRemoveSelf;
        status[ViewKeys.NUDGE_ELEMENT_UP_AVAILABLE] = canNudgeSelfUp;
        status[ViewKeys.NUDGE_ELEMENT_DOWN_AVAILABLE] = canNudgeSelfDown;
        status[ViewKeys.COPY_ELEMENT_AVAILABLE] = canCopySelfToClipboard;
        status[ViewKeys.CUT_ELEMENT_AVAILABLE] = canCutSelfToClipboard;
        status[ViewKeys.PASTE_ELEMENT_AVAILABLE] = _checkIfCanPaste();
        status[ViewKeys.ELEMENT_EMPTY] = isEmpty;
        GLOBAL_PIPE.send(ViewKeys.STRUCTURE_OPERATIONS_STATUS, status);
    }

    /**
     * TODO: document
     * @return
     */
    private function _checkIfCanPaste():Boolean {
        if (_pasteSource && lastSelection) {
            var sourceType:String = _pasteSource.getContent(DataFields.DATA_TYPE) as String;
            var targetType:String = lastSelection.getContent(DataFields.DATA_TYPE) as String;
            if (sourceType == targetType) {
                return true;
            }
        }
        return false;
    }

    /**
     * Applies given color matrix to given ui element.
     */
    private static function _colorizeUi(ui:DisplayObject, colorMatrix:ColorMatrixFilter):void {
        ui.filters = [colorMatrix];
    }

    /**
     * Removes any color matrix that might have been applied to given ui element via
     * `colorizeUi()`.
     * @param ui
     */
    private static function _resetUiColor(ui:DisplayObject):void {
        ui.filters = null;
    }

    /**
     * Applies the current color matrix to all ui elements collected so far. If there
     * is currently no color matrix, any previously colorized ui is reset. If nothing was
     * ever colorized, or all collected ui is already colorized, or there is no ui collected
     * in the first place, nothing happens.
     */
    public function applyCurrentColorization():void {
        if (_colorizableUi) {
            var uiId:String;
            var uiInfo:Object;
            for (uiId in _colorizableUi) {
                uiInfo = _colorizableUi[uiId];
                if (currColorMatrix) {
                    _colorizeUi(uiInfo.object, currColorMatrix);
                    uiInfo.colorized = true;
                } else {
                    if (uiInfo.colorized) {
                        _resetUiColor(uiInfo.object);
                        uiInfo.colorized = false;
                    }
                }
            }
        }
    }

    /**
     * Maintains a registry of Stage instances various windows use to show the application UI.
     * If a colorization flag is currently in effect, also colorizes that stage upon adding
     * it to the registry. Otherwise, it will be colorized when user selects a different
     * UI theme. Used by the themes mechanism added in v. 1.5.0.
     * @param    uiElement
     *            A DisplayObject, used as an entry point into its Stage.
     */
    public function registerColorizableUi(uiElement:Object):void {
        var displayObject:DisplayObject = (uiElement as DisplayObject);
        if (displayObject) {

            // Helper: called to add given UI to the list of elements that can be colorized.
            function addToColorizationList(stage:Stage, ui:DisplayObject):void {
                if (!_colorizableUi) {
                    _colorizableUi = [];
                }
                var uiUid:String = UIDUtil.getUID(ui);
                if (!(uiUid in _colorizableUi)) {
                    var colorized:Boolean = false;
                    if (currColorMatrix) {
                        _colorizeUi(ui, currColorMatrix);
                        colorized = true;
                    }
                    _colorizableUi[uiUid] = {
                        'stage': stage,
                        'colorized': colorized,
                        'object': ui
                    };
                }
            }

            // Helper: called to remove given UI from the list of elements that can be colorized.
            function removeFromColorizationList(ui:DisplayObject):void {
                if (_colorizableUi) {
                    var uiUid:String = UIDUtil.getUID(ui);
                    if (uiUid in _colorizableUi) {
                        delete (_colorizableUi[uiUid]);
                    }
                }
            }

            // Helper: called when observed uiElement has been added to the stage.
            function onObjAddedToStage(event:Event):void {
                displayObject.removeEventListener(Event.ADDED_TO_STAGE, onObjAddedToStage);
                displayObject.addEventListener(Event.REMOVED_FROM_STAGE, onObjRemovedFromStage);
                addToColorizationList(displayObject.stage, displayObject);
            }

            // Helper: called when observed uiElement has been removed from stage.
            function onObjRemovedFromStage(event:Event):void {
                displayObject.removeEventListener(Event.REMOVED_FROM_STAGE, onObjRemovedFromStage);
                _resetUiColor(displayObject);
                removeFromColorizationList(displayObject);
            }

            // MAIN LOGIC
            var parentStage:Stage = displayObject.stage;
            if (parentStage) {
                addToColorizationList(parentStage, displayObject);
            } else {
                displayObject.addEventListener(Event.ADDED_TO_STAGE, onObjAddedToStage);
            }
        }
    }

    /**
     * Used to visually reinstate the score selection removed by the score-following mechanism. Note that the selection
     * is still semantically valid while visually hidden during playback.
     */
    private function _restoreSelection():void {
        if (lastSelection) {
            GLOBAL_PIPE.send(ViewKeys.EXTERNALLY_SELECTED_SCORE_ITEM, lastSelection.route);
        }
    }

    /**
     * Used to remove any highlights that might be left in the score by prematurely ending playback.
     */
    private function _cleanupHighlights():void {
        GLOBAL_PIPE.send(ViewKeys.EXTERNALLY_REMOVED_HIGHLIGHTS);
    }

    /**
     * TODO: document
     * @return
     */
    private function onSectionToggleStateChange(stateInfo:Object):void {
        switch (stateInfo.id) {
            case 'projectEditor':
                _persistenceEngine.persistence(PersistenceKeys.EDITOR_TOGGLE_STATE, stateInfo.state);
                break;
            case 'projectTree':
                _persistenceEngine.persistence(PersistenceKeys.PROJECT_TOGGLE_STATE, stateInfo.state);
                break;
        }
    }

    /**
     * TODO: support several projects each open in its own tab.
     * "TAB_INDEX" is hardcoded to 0, for now.
     */
    private function _updateTabs():void {
        if (_model.currentProject != null) {
            var projectName:String = queryEngine.getProjectName();
            var data:Object = {};
            data[ViewKeys.TAB_LABEL] = projectName;
            data[ViewKeys.TAB_INDEX] = 0;
            GLOBAL_PIPE.send(ViewKeys.TAB_LABEL_CHANGE, data);
        } else {
            // TODO: hide all tabs
        }
    }


    // ------------------
    // Listener functions
    // ------------------
    /**
     * Executed when the main application window is closing.
     */
    private function _onMainWindowClosing(event:Event):void {
        event.preventDefault();
        _exitApplication();
    }

    /**
     * Runs when a Voice node has been changed by user, but before the change is written to the data model.
     * Prevents two voices from landing on the same slot (same staff, same index) by swapping them.
     * DOES NOT, actually, modify the new Voice node --`_commitData()` does that.
     */
    private static function _onVoiceChanging(info:Object):void {
        var voice:ProjectData = info[DataFields.VOICE] as ProjectData;
        var currentIndex:int = voice.getContent(DataFields.VOICE_INDEX) as int;
        var currentStaff:int = voice.getContent(DataFields.STAFF_INDEX) as int;
        var newIndex:int = info[DataFields.VOICE_INDEX] as int;
        var newStaff:int = info[DataFields.STAFF_INDEX] as int;
        if (currentStaff != newStaff || currentIndex != newIndex) {
            var measure:ProjectData = (voice.dataParent as ProjectData);
            var exchangeVoice:ProjectData = ModelUtils.getVoiceByPlacement(measure, newStaff, newIndex);
            if (exchangeVoice != null) {
                exchangeVoice.setContent(DataFields.VOICE_INDEX, currentIndex);
                exchangeVoice.setContent(DataFields.STAFF_INDEX, currentStaff);
            }
        }
    }

    /**
     * Triggered when user has determined an ABC file to export the current project
     * to, via the FileBrowser component.
     * @param    selectedFile
     *           The ABC file to export the current project to.
     */
    private function _onAbcFileSelectedForSave(selectedFile:File):void {
        _deferFileBrowserClose = false;
        var doIt:Function = function ():void {
            var error:String;
            var onWriteError:Function = function (event:ErrorEvent):void {
                writer.removeEventListener(ErrorEvent.ERROR, onWriteError);
                error = event.text;
                _deferFileBrowserClose = true;
            }

            // Mark generated MIDI as dirty.
            _midiSessionUid = null;
            ModelUtils.updateUnifiedPartsList(_model.currentProject);
            var abcMarkup:String = _model.currentProject.exportToFormat(DataFormats.PRINT_ABC_DATA_PROVIDER);
            var writer:TextDiskWritter = new TextDiskWritter;
            writer.addEventListener(ErrorEvent.ERROR, onWriteError);
            var bytesWritten:int = writer.write(abcMarkup, selectedFile);
            if (bytesWritten > 0) {
                _showSuccessfullySavedPrompt(selectedFile.nativePath, selectedFile.size);
            } else {
                _showUnwritableFileError(error);
            }
        }
        if (selectedFile.exists) {
            _deferFileBrowserClose = true;
            _showOverwriteFilePrompt(selectedFile.nativePath, doIt);
        } else {
            doIt();
        }
    }

    /**
     * TODO: document
     * @return
     */
    private function _onAppExitRequested(...ignore):void {
        _exitApplication();
    }

    /**
     * TODO: document
     * @return
     */
    private function _onAppMenuTriggered(info:Object):void {
        var commandName:String = (info is String) ? (info as String) : info.commandName;
        var commandArgs:Array = ('commandArgs' in info) ? info.commandArgs : [];
        switch (commandName) {

                // File operations
            case MenuCommandNames.SAVE_PROJECT:
                _saveCurrentProject();
                break;
            case MenuCommandNames.SAVE_PROJECT_AS:
                _saveCurrentProjectAs();
                break;
            case MenuCommandNames.OPEN_EXISTING_PROJECT:
                _openExistingProject();
                break;
            case MenuCommandNames.CREATE_NEW_PROJECT:
                _loadDefaultProject();
                break;
            case MenuCommandNames.CREATE_PROJECT_FROM_TEMPLATE:
                _openProjectFromTemplate();
                break;
            case MenuCommandNames.EXIT_APPLICATION:
                _exitApplication();
                break;
            case MenuCommandNames.EXPORT_PROJECT_TO_MIDI:
                _exportCurrentProjectToMIDI();
                break;
            case MenuCommandNames.EXPORT_PROJECT_TO_ABC:
                _exportCurrentProjectToABC();
                break;
            case MenuCommandNames.EXPORT_PROJECT_TO_XML:
                _exportCurrentProjectToXML();
                break;
            case MenuCommandNames.EXPORT_PROJECT_TO_PDF:
                _exportCurrentProjectToPDF();
                break;
            case MenuCommandNames.EXPORT_PROJECT_TO_WAV:
                _exportCurrentProjectToWAV();
                break;

                // Edit operations
            case MenuCommandNames.ADD_ITEM:
                if (lastSelection) {
                    _onStructureItemAdd(lastSelection.route);
                }
                break;
            case MenuCommandNames.DELETE_ITEM:
                if (lastSelection) {
                    _onStructureItemRemove(lastSelection.route);
                }
                break;
            case MenuCommandNames.NUDGE_ITEM_AFTER:
                if (lastSelection) {
                    _onStructureItemNudgeDown(lastSelection.route);
                }
                break;
            case MenuCommandNames.NUDGE_ITEM_BEFORE:
                if (lastSelection) {
                    _onStructureItemNudgeUp(lastSelection.route);
                }
                break;
            case MenuCommandNames.NUDGE_LOCK_ON:
                _nudgeLock = true;
                _updateStructureOperationsStatus();
                break;
            case MenuCommandNames.NUDGE_LOCK_OFF:
                _nudgeLock = false;
                _updateStructureOperationsStatus();
                break;
            case MenuCommandNames.UNDO:
                _undo();
                break;
            case MenuCommandNames.REDO:
                _redo();
                break;
            case MenuCommandNames.COPY:
                _doCopy();
                break;
            case MenuCommandNames.CUT:
                _doCut();
                break;
            case MenuCommandNames.PASTE:
                _doPaste();
                break;

                // View operations
            case MenuCommandNames.APPLY_THEME:
                var themeName:String = (commandArgs[0] as String);
                _persistenceEngine.persistence(PersistenceKeys.THEME, themeName);
                currColorMatrix = UiColorizationThemes[themeName];
                applyCurrentColorization();
                GLOBAL_PIPE.send(ViewKeys.COLORIZATION_UPDATED, themeName);
                break;

                // Macros operations
            case MenuCommandNames.TRANSPOSE:
                _doTranspose();
                break;
            case MenuCommandNames.SCALE_INTERVALS:
                _doScaleIntervals();
                break;

                // Playback
            case MenuCommandNames.START_PLAYBACK:
                _onPlaybackRequested();
                break;
            case MenuCommandNames.STOP_PLAYBACK:
                _onStopRequested();
                break;

                // Help operations
            case MenuCommandNames.OPEN_DOCUMENTATION_URL:
                _openDocumentationUrl();
                break;
            case MenuCommandNames.OPEN_ISSUES_URL:
                _openContactUrl();
                break;
            case MenuCommandNames.OPEN_RELEASES_URL:
                _openNewsUrl();
                break;
            case MenuCommandNames.BECOME_SPONSOR_URL:
                _openPatreonUrl();
                break;
        }
    }

    /**
     * TODO: document
     * @return
     */
    private static function _onBarTypesRequested(...ignore):void {
        var barTypes:Array = BarTypes.getAllTypes();
        GLOBAL_PIPE.send(ViewKeys.BAR_TYPES_LIST, barTypes);
    }

    /**
     * TODO: document
     * @return
     */
    private static function _onBracketTypesRequested(...ignore):void {
        var bracketTypes:Array = ConstantUtils.getAllValues(BracketTypes);
        GLOBAL_PIPE.send(ViewKeys.BRACKETS_TYPES_LIST, bracketTypes);
    }

    /**
     * TODO: document
     */
    private static function _onClefTypesRequested(...ignore):void {
        var clefTypes:Array = ClefTypes.getAllTypes();
        GLOBAL_PIPE.send(ViewKeys.CLEF_TYPES_LIST, clefTypes);
    }

    /**
     * TODO: document
     */
    private function _onCurrentPartNameRequested(...ignore):void {
        var name:String = null;
        if (_currentPart != null) {
            name = _currentPart.getContent(DataFields.PART_NAME) as String;
        }
        GLOBAL_PIPE.send(ViewKeys.CURRENT_PART_NAME, name);
    }

    /**
     * TODO: document
     */
    private function _onDivisionsListRequested(clusterUid:String):void {
        var test:Object;
        var currCluster:ProjectData = ProjectData(_model.currentProject.getElementByRoute(clusterUid));
        if (currCluster != null && ModelUtils.isCluster(currCluster)) {
            var measure:ProjectData = ProjectData(currCluster.dataParent.dataParent);
            var timeSignature:Array = [];
            test = (measure.getContent(DataFields.BEATS_NUMBER) as Object);
            if (test != DataFields.VALUE_NOT_SET) {
                timeSignature[0] = (test as int);
            }
            test = (measure.getContent(DataFields.BEAT_DURATION) as Object);
            if (test != DataFields.VALUE_NOT_SET) {
                timeSignature[1] = (test as int);
            }
            if (timeSignature.length < 2) {
                timeSignature = queryEngine.getClosestTimeSignatureTo(measure.route);
            }
            var isCompoundSignature:Boolean = (timeSignature != null) ? ConstantUtils.hasValue(CompoundTimeSignatures, timeSignature) : false;
            var tupletsSet:Class = isCompoundSignature ? DivisionsUsedInCompoundSignatures : DivisionsUsedInSimpleSignatures;
            var list:Array = [];
            var keys:Array = ConstantUtils.getAllNames(tupletsSet);
            for (var i:int = 0; i < keys.length; i++) {
                var key:String = keys[i];
                var obj:Object = {};
                var equivalency:String = DivisionsEquivalency[tupletsSet[key]] as String;
                obj[Common.LABEL] = DivisionTypes[key];
                obj[Common.VALUE] = key;
                obj[DataKeys.METADATA] = equivalency;
                list.push(obj);
            }
            GLOBAL_PIPE.send(ViewKeys.DIVISIONS_LIST, list);
        }
    }

    /**
     * TODO: document
     */
    private static function _onDurationsListRequested(...ignore):void {
        var list:Array = [];
        var keys:Array = ConstantUtils.getAllNames(DurationFractions);
        for (var i:int = 0; i < keys.length; i++) {
            var key:String = keys[i];
            var item:Object = {};
            if (key in DurationSymbols) {
                item[ViewKeys.DESCRIPTION] = Strings.fromAS3ConstantCase(key).concat('s');
                item[DataKeys.SOURCE] = DurationFractions[key];
                item[Common.VALUE] = (DurationFractions[key] as Fraction).toString();
                item[Common.LABEL] = DurationSymbols[key];
                list.push(item);
            }
        }
        list.sort(_sortDurationItems);
        list.reverse();
        GLOBAL_PIPE.send(ViewKeys.DURATIONS_LIST, list);
    }

    /**
     * Triggered when user has given up selecting a file or folder in the
     * FileBrowser component.
     */
    private function _onFileBrowserCancel(event:FileSelectionEvent):void {
        _fileBrowser = (event.target as FileBrowser);
        _fileBrowser.removeEventListener(FileSelectionEvent.FILE_SELECTED, _onFileBrowserSelect);
        _fileBrowser.removeEventListener(FileSelectionEvent.FILE_CANCELLED, _onFileBrowserCancel);
        _closeFileBrowserWindow();
        _fileSelectedCallback = null;
        _fileSelectedCallbackContext = null;
    }

    /**
     * Triggered when the user has confirmed a file or folder in the
     * FileBrowser component.
     */
    private function _onFileBrowserSelect(event:FileSelectionEvent):void {
        _fileBrowser = (event.target as FileBrowser);
        var selectedFile:File = event.file;
        _fileSelectedCallback.call(_fileSelectedCallbackContext, selectedFile);
        if (!_deferFileBrowserClose) {
            _fileBrowser.removeEventListener(FileSelectionEvent.FILE_SELECTED, _onFileBrowserSelect);
            _fileBrowser.removeEventListener(FileSelectionEvent.FILE_CANCELLED, _onFileBrowserCancel);
            _closeFileBrowserWindow();
            _fileSelectedCallback = null;
            _fileSelectedCallbackContext = null;
        }
    }

    /**
     * TODO: document
     */
    private function _onFileBrowserXClose(...ignore):void {
        _closeFileBrowserWindow();
        _fileSelectedCallback = null;
        _fileSelectedCallbackContext = null;
    }

    /**
     * TODO: document
     */
    private function _onInheritedTimeSignatureRequested(measureUid:String):void {
        var result:Array = queryEngine.getClosestTimeSignatureTo(measureUid);
        GLOBAL_PIPE.send(ViewKeys.INHERITED_TIME_SIGNATURE, result);
    }

    /**
     * TODO: document
     */
    private function _onLabelForTreeElementRequested(inData:Object):void {
        var treeItem:Object = inData[ViewKeys.TARGET_OBJECT];
        var node:ProjectData = inData[ViewKeys.DATA_SOURCE];
        var label:String = ModelUtils.getNodeLabel(ProjectData(node));
        // Some nodes require extra processing
        var nodeType:String = node.getContent(DataFields.DATA_TYPE);
        switch (nodeType) {
            case DataFields.MEASURE:
                var globalNumber:int = queryEngine.uidToMeasureNumber(node.route);
                var localNumber:int = (node.index + 1);
                label = label.concat(CommonStrings.SPACE, globalNumber);
                if (localNumber != globalNumber) {
                    label = label.concat(CommonStrings.SPACE, CommonStrings.LEFT_PAREN, localNumber, CommonStrings.RIGHT_PAREN);
                }
                break;
        }
        var outData:Object = {};
        outData[ViewKeys.TARGET_OBJECT] = treeItem;
        outData[ViewKeys.RESULTING_LABEL] = label;
        GLOBAL_PIPE.send(ViewKeys.ELEMENT_LABEL_READY, outData);
    }

    /**
     * TODO: document
     */
    private function _onLastVoiceOfStaffCheckRequested(voiceUid:String):void {
        var voice:ProjectData = _model.currentProject.getElementByRoute(voiceUid) as ProjectData;
        var measure:ProjectData = voice.dataParent as ProjectData;
        var isLastVoice:Boolean = _isLastVoiceOnItsStaff(voice, measure);
        GLOBAL_PIPE.send(ViewKeys.LAST_VOICE_OF_STAFF_ANSWER, isLastVoice);
    }

    /**
     * TODO: document
     */
    private static function _onMaxVoicesPerStaffRequested(...ignore):void {
        GLOBAL_PIPE.send(ViewKeys.MAX_VOICES_PER_STAFF_NUMBER, Voices.NUM_VOICES_PER_STAFF);
    }

    /**
     * TODO: document
     */
    private function _onMeasureNumberToUidRequested(inData:Object):void {
        var measureNumber:int = inData[ViewKeys.MEASURE_NUMBER_TO_CONVERT];
        var targetFieldName:String = inData[ViewKeys.TARGET_FIELD_NAME];
        var measureUid:String = queryEngine.measureNumberToUid(measureNumber);
        var outData:Object = {};
        outData[ViewKeys.TARGET_FIELD_NAME] = targetFieldName;
        outData[ViewKeys.RESULTING_MEASURE_UID] = measureUid;
        GLOBAL_PIPE.send(ViewKeys.MEASURE_NUMBER_CONVERTED_TO_UID, outData);
    }

    /**
     * Called in response to a pipe request asking data about a measure's time
     * signature. Data requested is: the number of beats, the beat duration, and
     * whether the measure defines its own time signature, or inherits it.
     * Data is queried and sent back through the public pipe, to the address
     * `TIME_SIGNATURE_DATA_READY`.
     */
    private function _onMeasureTimeSignatureDataRequired(measureUid:String):void {
        // Set up
        var hasOwnTimeSignature:Boolean = false;

        // Query data
        var measure:ProjectData = ProjectData(_model.currentProject.getElementByRoute(measureUid));
        var qe:QueryEngine = queryEngine;
        var timeSignature:Array = qe.getMeasureTimeSignature(measure);
        if (timeSignature == null) {
            timeSignature = qe.getOwnOrInheritedTimeSignature(measure);
        } else {
            hasOwnTimeSignature = true;
        }
        var numBeats:uint = timeSignature[0];
        var beatDuration:uint = timeSignature[1];

        // Reply
        var data:Object = {};
        data[ViewKeys.HAS_OWN_TIME_SIGNATURE] = hasOwnTimeSignature;
        data[DataFields.BEATS_NUMBER] = numBeats;
        data[DataFields.BEAT_DURATION] = beatDuration;
        GLOBAL_PIPE.send(ViewKeys.TIME_SIGNATURE_DATA_READY, data);
    }

    /**
     * Retrieves and sends back (through the public pipe) the time signature of the
     * given measure, or `null` if not set.
     */
    private function _onMeasureTimeSignatureRequested(measure:ProjectData):void {
        var timeSignature:Array = queryEngine.getMeasureTimeSignature(measure);
        GLOBAL_PIPE.send(ViewKeys.MEASURE_TIME_SIGNATURE_READY, timeSignature);
    }

    /**
     * TODO: document
     */
    private function _onMeasureUidToNumberRequested(inData:Object):void {
        var measureUid:String = inData[ViewKeys.MEASURE_UID_TO_CONVERT];
        var targetFieldName:String = inData[ViewKeys.TARGET_FIELD_NAME];
        var measureNumber:int = queryEngine.uidToMeasureNumber(measureUid);
        var outData:Object = {};
        outData[ViewKeys.TARGET_FIELD_NAME] = targetFieldName;
        outData[ViewKeys.RESULTING_MEASURE_NUMBER] = measureNumber;
        GLOBAL_PIPE.send(ViewKeys.UID_CONVERTED_TO_MEASURE_NUMBER, outData);
    }

    /**
     * Triggered when user has determined a MIDI file to export the current project
     * to, via the FileBrowser component.
     * @param    selectedFile
     *           The MIDI file to export the current project to.
     */
    private function _onMidiFileSelectedForSave(selectedFile:File):void {
        _deferFileBrowserClose = false;
        var doIt:Function = function ():void {
            var error:String;

            // Mark generated MIDI as dirty.
            _midiSessionUid = null;
            try {
                NativeAppsWrapper.instance.currMIDIFile.copyTo(selectedFile, true);
                _showSuccessfullySavedPrompt(selectedFile.nativePath, selectedFile.size);
            } catch (e:Error) {
                error = e.message;
                _deferFileBrowserClose = true;
            }
            if (error) {
                _showUnwritableFileError(error);
            }
        }
        if (selectedFile.exists) {
            _deferFileBrowserClose = true;
            _showOverwriteFilePrompt(selectedFile.nativePath, doIt);
        } else {
            doIt();
        }
    }

    /**
     * Called when the application has been `invoked`, i.e., a registered file has
     * been double clicked, or a second launch was attempted with the application
     * running.
     */
    private function _onNativeInvocation(event:InvokeEvent):void {
        var args:Array = event.arguments;
        var reason:String = event.reason;
        // var dir:File = event.currentDirectory;
        switch (reason) {
            case InvokeEventReason.LOGIN:
                // TODO: implement in the future if needed
                break;
            case InvokeEventReason.STANDARD:
                if (args != null && args.length > 0) {

                    // If first argument is a valid, fully qualified path to a local
                    // file, we call a file invocation routine.
                    var firstArg:String = (args[0] as Object).toString();
                    if (Files.isPathOfType(firstArg, [FileAssets.PROJECT_FILE_EXTENSION], true)) {
                        var invokedFile:File = new File(firstArg.toString());
                        _handleFileInvocation(invokedFile);
                    }
                }
                break;
        }
    }


    /**
     * We will DYNAMICALLY bind part annotations to last touched section's Part nodes. This is why,
     * for parts, we use their "mirror UID" instead of their "route" (since mirror UIDs transcend
     * sections -- they refer to, say, "the first violin across all sections").
     */
    private static function _onPartAnnotationUidRequested(partMirrorUid:String):void {
        // var uid:String=_queryEngine.getShortUidFor(partMirrorUid);
        // GLOBAL_PIPE.send(ViewKeys.UID_FOR_ANNOTATION_READY, uid);
        // FIXME: Properly decommission this obsolete functionality
        GLOBAL_PIPE.send(ViewKeys.UID_FOR_ANNOTATION_READY, partMirrorUid.concat(CommonStrings.BROKEN_VERTICAL_BAR));
    }

    /**
     * TODO: document
     */
    private static function _onPartDefaultDataRequested(partName:String):void {
        var partDefaultData:ProjectData = new ProjectData;
        var details:Object = {};
        details[DataFields.DATA_TYPE] = DataFields.PART;
        partDefaultData.populateWithDefaultData(details);
        partDefaultData.setContent(DataFields.PART_NAME, partName);
        partDefaultData.setContent(DataFields.ABBREVIATED_PART_NAME, ConstantUtils.getValueByMatchingName(PartAbbreviatedNames, partName));
        partDefaultData.setContent(DataFields.PART_NUM_STAVES, ConstantUtils.getValueByMatchingName(PartDefaultStavesNumber, partName));
        partDefaultData.setContent(DataFields.PART_OWN_BRACKET_TYPE, ConstantUtils.getValueByMatchingName(PartDefaultBrackets, partName));
        partDefaultData.setContent(DataFields.PART_CLEFS_LIST, ConstantUtils.getValueByMatchingName(PartDefaultClefs, partName));
        partDefaultData.setContent(DataFields.PART_TRANSPOSITION, ConstantUtils.getValueByMatchingName(PartTranspositions, partName));
        partDefaultData.setContent(DataFields.CONCERT_PITCH_RANGE, ConstantUtils.getValueByMatchingName(PartRanges, partName));
        GLOBAL_PIPE.send(ViewKeys.PART_DEFAULT_DATA, partDefaultData);
    }

    /**
     * TODO: document
     */
    private static function _onPartNamesRequested(...ignore):void {
        var partNames:Array = PartNames.getAllPartNames();
        GLOBAL_PIPE.send(ViewKeys.PART_NAMES_LIST, partNames);
    }

    /**
     * TODO: document
     */
    private function _onPartStaffsNumberRequested(...ignore):void {
        var selection:ProjectData = _getSelection();
        if (selection != null) {
            if (ModelUtils.isVoice(selection)) {
                var numStaves:int = queryEngine.getNumAvailableStavesForVoice(_getSelection());
                GLOBAL_PIPE.send(ViewKeys.CURRENT_PART_STAFFS_NUMBER, numStaves);
            }
        }
    }

    /**
     * Triggered when user has determined a PDF file to export the current project
     * to, via the FileBrowser component.
     * @param    selectedFile
     *            The PDF file to export the current project to.
     */
    private function _onPdfFileSelectedForSave(selectedFile:File):void {
        _deferFileBrowserClose = false;
        var on_pdf_ready:Function = function (pdfFile:File):void {
            var error:String;
            try {
                pdfFile.copyTo(selectedFile);
                _showSuccessfullySavedPrompt(selectedFile.nativePath, selectedFile.size);
            } catch (e:Error) {
                error = e.message;
                _deferFileBrowserClose = true;
            }
            if (error) {
                _showUnwritableFileError(error);
            }
        }
        var doIt:Function = function ():void {

            // Mark generated MIDI as dirty.
            _midiSessionUid = null;
            ModelUtils.updateUnifiedPartsList(_model.currentProject);
            var abcMarkup:String = _model.currentProject.exportToFormat(DataFormats.PRINT_ABC_DATA_PROVIDER);
            var naWrapper:NativeAppsWrapper = NativeAppsWrapper.instance;
            naWrapper.abcToPdf(abcMarkup, null, on_pdf_ready);
        }
        if (selectedFile.exists) {
            _deferFileBrowserClose = true;
            _showOverwriteFilePrompt(selectedFile.nativePath, doIt);
        } else {
            doIt();
        }
    }

    /**
     * Triggered when user has determined an XML file to export the current project
     * to, via the FileBrowser component.
     * @param    selectedFile
     *            The PDF file to export the current project to.
     */
    private function _onXmlFileSelectedForSave(selectedFile:File):void {
        _deferFileBrowserClose = false;
        var on_xml_ready:Function = function (xmlFile:File):void {
            var error:String;
            try {
                xmlFile.copyTo(selectedFile, true);
                _showSuccessfullySavedPrompt(selectedFile.nativePath, selectedFile.size);
            } catch (e:Error) {
                error = e.message;
                _deferFileBrowserClose = true;
            }
            if (error) {
                _showUnwritableFileError(error);
            }
        }
        var do_it:Function = function ():void {

            // Mark generated MIDI as dirty.
            _midiSessionUid = null;
            ModelUtils.updateUnifiedPartsList(_model.currentProject);
            var abcMarkup:String = _model.currentProject.exportToFormat(DataFormats.PRINT_ABC_DATA_PROVIDER);
            var naWrapper:NativeAppsWrapper = NativeAppsWrapper.instance;
            naWrapper.abcToXml(abcMarkup, null, on_xml_ready);
        }
        if (selectedFile.exists) {
            _deferFileBrowserClose = true;
            _showOverwriteFilePrompt(selectedFile.nativePath, do_it);
        } else {
            do_it();
        }
    }

    /**
     * TODO: document
     */
    private function _onPickupWindowClosed(...ignore):void {
        if (_windowsManager.isWindowAvailable(_pickupWindowUid)) {
            _windowsManager.stopObservingWindowActivity(_pickupWindowUid, WindowActivity.BEFORE_DESTROY, _onPickupWindowClosing);
            GLOBAL_PIPE.unsubscribe(ViewKeys.PICKUP_WINDOW_CLOSE, _onPickupWindowClosed);
            _windowsManager.destroyWindow(_pickupWindowUid);
        }
    }

    /**
     * TODO: document
     */
    private static function _onPickupWindowClosing(...ignore):Boolean {
        GLOBAL_PIPE.send(ViewKeys.PICKUP_WINDOW_CLOSING);
        return false;
    }

    /**
     * TODO: document
     */
    private function _onPickupWindowForceCloseRequested(...ignore):void {
        _onPickupWindowClosed();
        GLOBAL_PIPE.send(ViewKeys.PICKUP_WINDOW_CLOSE);
    }

    /**
     * TODO: document
     */
    private function _onPickupWindowRequested(inData:Object):void {
        var windowData:Object = inData[ViewKeys.PICKUP_WINDOW_DATA];
        var windowTitle:String = (inData[ViewKeys.WINDOW_TITLE] as String);
        var properties:Object = {};
        properties[ViewKeys.PTT_PIPE_NAME] = null;
        properties[ViewKeys.PICKUP_WINDOW_DATA] = windowData;
        _pickupComponentWindowFactory.properties = properties;
        var windowContent:IWindowContent = (_pickupComponentWindowFactory.newInstance() as IWindowContent);

        // If the "genCfgWindowUid" is available, then the "pick-up window" will be launched as a child of
        // the "generator configuration" window, since this is an application modal window, and there is no
        // way to order it from anywhere else, except from "generator configuration".
        if (_windowsManager.isWindowAvailable(genCfgWindowUid)) {
            registerColorizableUi(windowContent);
            _pickupWindowUid = _windowsManager.createWindow(windowContent, WindowStyle.TOOL | WindowStyle.TOP | WindowStyle.NATIVE, true, genCfgWindowUid);
        } else {
            registerColorizableUi(windowContent);
            _pickupWindowUid = _windowsManager.createWindow(windowContent, WindowStyle.TOOL | WindowStyle.TOP | WindowStyle.NATIVE, true, _mainWindowUid);
        }
        _windowsManager.updateWindowTitle(_pickupWindowUid, windowTitle);
        _windowsManager.updateWindowBounds(_pickupWindowUid, Sizes.MIN_PICKUP_WINDOW_BOUNDS, false);
        _windowsManager.updateWindowMinSize(_pickupWindowUid, Sizes.MIN_PICKUP_WINDOW_BOUNDS.width, Sizes.MIN_PICKUP_WINDOW_BOUNDS.height, true);
        _windowsManager.observeWindowActivity(_pickupWindowUid, WindowActivity.BEFORE_DESTROY, _onPickupWindowClosing, this);
        _windowsManager.showWindow(_pickupWindowUid);
        _windowsManager.alignWindows(_pickupWindowUid, _windowsManager.mainWindow, 0.5, 0.5);
        GLOBAL_PIPE.send(ViewKeys.PICKUP_WINDOW_OPEN, windowData);
        GLOBAL_PIPE.subscribe(ViewKeys.PICKUP_WINDOW_CLOSE, _onPickupWindowClosed);
    }

    /**
     * Responds to a global playback requests.
     */
    private function _onPlaybackRequested(...ignore):void {
        _streamingRoutine = _doOnlineStreaming;

        // If score has changed, or was never played back, re-generate audio and play it back.
        if (!_midiSessionUid) {
            _synthProxy.stopStreamedPlayback();
            _synthProxy.stopPrerenderedPlayback();
            _audioStorage.clear();
            _synthProxy.invalidateAudioCache();
            _prepareScoreForAudio();
        } else {

            // If score has not changed, simply play it back.
            _synthProxy.computeCachedAudioLength();
            _synthProxy.playBackPrerenderedAudio();
            GLOBAL_PIPE.send(ModelKeys.MIDI_PLAYBACK_STARTED);
            _isMidiPlaying = true;
        }
    }

    /**
     * Converts the musical score of the current project into a proprietary, MIDI-like format (a list of note pitches
     * and start/stop times), loads samples for all involved instruments and feeds it all into a separate routine that
     * will produce an annotated audio recording of the score.
     */
    private function _prepareScoreForAudio():void {

        // Put the current project in a format our synthesizer understands; timeouts are only needed so that our
        // Prompt UI component can fully unfold (it has animations) before heavy work starts on the sam thread.
        showStatus(StaticTokens.PREPARING_MIDI, PromptColors.INFORMATION, false);
        Time.delay(0.6, function ():void {
            var project:ProjectData = _model.currentProject;
            ModelUtils.updateUnifiedPartsList(project);
            var tracksProducer:SynthTracksProducer = new SynthTracksProducer;
            tracksProducer.source = project;
            if (lastSelection && ModelUtils.isCluster(lastSelection)) {
                tracksProducer.startLabel = lastSelection.route;
            }
            _tracksInfo = tracksProducer.produce();

            // Load needed sound assets; still here, load the bytes for the background worker(s) we will be using
            // for rendering audio. The rest of the work will be carried out in the `_onSoundsLoaderReport()` event
            // handler.
            showStatus(Strings.sprintf(StaticTokens.LOADING_SOUNDS, CommonStrings.ELLIPSIS),
                    PromptColors.INFORMATION, false);
            var presetDescriptors:Vector.<PresetDescriptor> = tracksProducer.presetDescriptors;
            presetDescriptors.unshift(new PresetDescriptor(FileAssets.AUDIO_WORKER_FILE_KEY,
                    FileAssets.AUDIO_WORKER_FILE_LABEL));
            _soundLoader.preloadSounds(presetDescriptors, FileAssets.AUDIO_ASSETS_HOME,
                    FileAssets.AUDIO_ASSET_FILE_TYPE);
        });
    }

    /**
     * Performs the actual work of reading a MAID file from disk and loading it as a project.
     * @param    file
     *            The MAID file to load.
     * @param    treatAsTemplate
     *            Whether to force the user to Save As (in order to protect the original file).
     *            Useful for templates. Default `false`. Also, this will overwrite the "created"
     *            and "modified" timestamps of the loaded file.
     */
    private function _actuallyLoadFile(file:File, treatAsTemplate:Boolean = false):void {

        // Attempt to read the file
        var byteArray:ByteArray = null;
        var error:String = '';
        var reader:AbstractDiskReader = new RawDiskReader;
        reader.addEventListener(ErrorEvent.ERROR, function (event:ErrorEvent):void {
            error = event.text;
        });
        try {
            byteArray = (reader.readContent(file) as ByteArray);
        } catch (e:Error) {
            if (!error && e.message) {
                error = e.message;
            }
        }
        if (!byteArray) {
            _showUnreadableFileError(error);
            return;
        }

        // Attempt to load the project
        var proj:ProjectData = ProjectData(DataElement.fromSerialized(byteArray, ProjectData, getQualifiedClassName(ProjectData)));
        if (proj) {
            proj.resetIntrinsicMeta();
            _model.currentProjectFile = file;
        } else {
            Time.advancedDelay(_showUnsupportedProjectNotice, this, Time.SHORT_DURATION, file);
            _model.currentProjectFile = null;
        }
        _loadProject(proj);
        if (treatAsTemplate) {
            if (_model.currentProject) {
                var currProject:ProjectData = _model.currentProject;
                var timeStamp:String = Time.timestamp;
                currProject.setContent(DataFields.MODIFICATION_TIMESTAMP, timeStamp);
                currProject.setContent(DataFields.CREATION_TIMESTAMP, timeStamp);
            }
            _model.currentProjectFile = null;
        }
        _model.resetReferenceData();
        _updateProjectInfo();
        _resetSnapshotsHistory();
    }

    /**
     * Triggered when user has selected a file to load content from, via the
     * FileBrowser component.
     * @param    file
     *            The file to load content form.
     * @param    treatAsTemplate
     *            If `true`, will force user to use "Save as..." instead of "Save" on first save operation.
     *            Default: false.
     */
    private function _onProjectFileSelectedForOpen(file:File, treatAsTemplate:Boolean = false):void {
        var doIt:Function = function ():void {
            _actuallyLoadFile(file, treatAsTemplate);
        }
        if (_model.haveUnsavedData()) {
            _deferFileBrowserClose = true;
            _showDiscardChangesPrompt(doIt);
        } else {
            doIt();
        }
    }

    /**
     * Triggered when user has selected a template file to start a new project from,
     * via the FileBrowser component.
     * @param    templateFile
     *            A MAID file to use as a template.
     */
    private function _onTemplateFileSelectedForOpen(templateFile:File):void {
        _onProjectFileSelectedForOpen(templateFile, true);
        _updateProjectInfo();
    }

    /**
     * Triggered when user has determined a file to save the current project in,
     * via the FileBrowser component.
     * @param    file
     *            The file to save the current project in.
     */
    private function _onProjectFileSelectedForSave(file:File):void {
        var doIt:Function = function ():void {
            _model.currentProjectFile = file;
            _saveCurrentProject(true);
        }
        if (file.exists) {
            _deferFileBrowserClose = true;
            _showOverwriteFilePrompt(file.nativePath, doIt);
        } else {
            doIt();
        }
    }

    /**
     * Called when a score item gets selected. Updates the tree and editor to point
     * to the selected element.
     * @param   itemUid
     *          The id of the selected item.
     */
    private function _onScoreItemClicked(itemUid:String):void {
        if (itemUid != null) {

            // When clicked, Part hotspots do not broadcast the "route" UID of a
            // specific Part node; instead, they send the "mirror" UID of that part,
            //  and we need to decide which of the Part nodes having that "mirror UID"
            // to resolve to.
            //
            // For the time being, we will consider the part that lives in the Section
            // node most recently interacted with.
            if (ModelUtils.isMirrorUid(itemUid)) {
                var partItem:ProjectData = _getPartByMirrorId(itemUid);
                itemUid = partItem ? partItem.route : null;
            }
            if (itemUid != null) {
                var element:ProjectData = ProjectData(_model.currentProject.getElementByRoute(itemUid));
                if (element) {
                    _currentSection = ModelUtils.getClosestAscendantByType(element, DataFields.SECTION);

                    // There is functionality in need of knowing the last part that was touched
                    _currentPart = ModelUtils.getClosestAscendantByType(element, DataFields.PART) || _currentPart;

                    // Select/load the corresponding data-model object (whichever
                    // it is) in all the other views
                    setSelection(element, true);
                } else {
                    setSelection(null);
                }
            }
        } else {
            setSelection(null);
        }
    }

    /**
     * Called when a score item (or the score itself) gets right-clicked. Causes a contextual menu to appear.
     */
    private function _onScoreRightClicked(info:Object):void {
        // Only one pop-up menu is allowed a time
        if (_popUpMenu) {
            _popUpMenu.removeEventListener(MenuEvent.ITEM_CLICK, _onPopUpMenuClick);
            _popUpMenu.hide();
        }

        // Gather data for the new menu to be created
        var scoreItemUid:String = info[ViewKeys.SCORE_ITEM_UID] as String;
        if (!scoreItemUid) {
            return;
        }
        var item:ProjectData = (ModelUtils.isMirrorUid(scoreItemUid)) ?
                _getPartByMirrorId(scoreItemUid) :
                ProjectData(_model.currentProject.getElementByRoute(scoreItemUid));
        if (!item) {
            return;
        }

        // Actually build the menu
        var menuSrc:Array = _getPopUpMenuSrcFor(item);
        if (!menuSrc) {
            return;
        }
        var x:Number = info[ViewKeys.ANCHOR_X] as Number;
        var y:Number = info[ViewKeys.ANCHOR_Y] as Number;
        var menuContainer:DisplayObjectContainer = _mainView;
        _popUpMenu = Menu.createMenu(menuContainer, menuSrc, false);
        registerColorizableUi(_popUpMenu);
        _popUpMenu.show(x, y);

        // If the menu does not fit in the main view we close it, adjust its position and open it again.
        // Unfortunately, we cannot measure a menu until it was open.
        var menuWidth:Number = _popUpMenu.measuredWidth;
        var menuHeight:Number = _popUpMenu.measuredHeight;
        var needsAdjustments:Boolean = false;
        if (x + menuWidth > menuContainer.width) {
            x = (menuContainer.width - menuWidth);
            needsAdjustments = true;
        }
        if (y + menuHeight > menuContainer.height) {
            y = menuContainer.height - menuHeight;
            needsAdjustments = true;
        }
        if (needsAdjustments) {
            _popUpMenu.hide();
            _popUpMenu.show(x, y);
        }

        // Listen to clicks on menu items
        _popUpMenu.addEventListener(MenuEvent.ITEM_CLICK, _onPopUpMenuClick);
    }

    /**
     * Called when a score item (or the score itself) gets middle-clicked.
     * Causes the default action in the related contextual menu to be executed.
     */
    private function _onScoreMiddleClicked(info:Object):void {

        // Gather data about the clicked item
        var scoreItemUid:String = info[ViewKeys.SCORE_ITEM_UID] as String;
        if (!scoreItemUid) {
            return;
        }
        var item:ProjectData = (ModelUtils.isMirrorUid(scoreItemUid)) ?
                _getPartByMirrorId(scoreItemUid) :
                ProjectData(_model.currentProject.getElementByRoute(scoreItemUid));
        if (!item) {
            return;
        }

        // Retrieve the default action in the related contextual menu
        var menuSrc:Array = _getPopUpMenuSrcFor(item);
        if (!menuSrc) {
            return;
        }
        var defaultItem:Object = menuSrc.filter(
                function (menuItem:Object, ...rest):Boolean {
                    return menuItem.isDefault;
                }
        )[0];
        if (defaultItem) {
            var defaultCmd:String = Strings.trim(defaultItem.commandName as String);
            if (defaultCmd) {
                _onAppMenuTriggered({'commandName': defaultCmd});
            }
        }
    }

    /**
     * Triggered when an item in the pop-up event gets triggered
     */
    private function _onPopUpMenuClick(event:Object):void {
        var item:Object = event.item as Object;
        if (item) {
            var commandName:String = Strings.trim(item.commandName);
            if (!Strings.isEmpty(commandName)) {
                _onAppMenuTriggered(commandName);
            }
        }
    }

    /**
     * Triggered when the score is scrolled in the view by either mouse or keyboard.
     */
    private function _onScoreScrolled(...ignore):void {

        // Hide the pop-up menu (if any). We could as well readjust its position, but it's not customary to do so.
        if (_popUpMenu) {
            _popUpMenu.hide();
        }
    }

    /**
     * TODO: document
     */
    private function _onScoreRendererAvailable(...ignore):void {
        _scoreRendererReady = true;
        if (_bufferedABC != null) {
            _sendScoreABC(_bufferedABC);
            _bufferedABC = null;
        }
    }

    /**
     * TODO: document
     */
    private function _onSectionNameValidationRequested(details:Object):void {
        var name:String = details[ViewKeys.NEW_NAME] as String;

        // We support the scenario where the user sends-in the current, unchanged name of tje current section
        // for verification
        if (lastSelection && ModelUtils.isSection(lastSelection)) {
            var currentName:String = lastSelection.getContent(DataFields.UNIQUE_SECTION_NAME) as String;
            if (name == currentName) {
                GLOBAL_PIPE.send(ViewKeys.SECTION_NAME_VALIDATION_RESULT, true);
                return;
            }
        }

        // Other than that, the section name sent for verification must not already exist in the score
        var result:Boolean = (!queryEngine.haveSectionName(name));
        GLOBAL_PIPE.send(ViewKeys.SECTION_NAME_VALIDATION_RESULT, result);
    }

    /**
     * TODO: document
     */
    private function _onShortUidInfoRequested(shortUid:String):void {
        var elementUid:String = queryEngine.getFullUidFor(shortUid);
        var element:ProjectData = (_model.currentProject.getElementByRoute(elementUid) as ProjectData);
        var data:Object = {};
        data[GenericFieldNames.GUID] = elementUid;
        data[GenericFieldNames.ITEM] = element;
        GLOBAL_PIPE.send(ViewKeys.SHORT_UID_INFO_READY, data);
    }

    /**
     * TODO: document
     */
    private function _onShortenedUidRequested(fullUid:String):void {
        var shortUid:String = queryEngine.getShortUidFor(fullUid);
        GLOBAL_PIPE.send(ViewKeys.REQUESTED_SHORT_UID_READY, shortUid);
    }

    /**
     * TODO: document
     */
    private function _onSplitDurationRequested(rawDuration:Fraction):void {
        var durations:Array = queryEngine.splitIntoCommonFractions(rawDuration);
        PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).send(ViewKeys.DURATION_SPLIT_READY, durations);
    }

    /**
     * Executed when the "Stop" button in the main toolbar is clicked by the user, or when score playback reaches end.
     */
    private function _onStopRequested(...ignore):void {
        if (_audioStreamer) {
            _synthProxy.stopStreamedPlayback(true);
            _audioStreamer.cancelStreaming();
        }
        _synthProxy.stopPrerenderedPlayback(true);
        GLOBAL_PIPE.send(ModelKeys.MIDI_PLAYBACK_STOPPED);
        _isMidiPlaying = false;
        _cleanupHighlights();
        _restoreSelection()
    }

    /**
     * TODO: document
     */
    private function _onStructureItemAdd(parentUid:String, staffIndex:int = -1, skipUpdatingModel:Boolean = false):ProjectData {
        if (_model && _model.currentProject) {

            // Making sure playback is stopped
            _stopMidi();

            // Creating the child
            var parent:ProjectData = ProjectData(_model.currentProject.getElementByRoute(parentUid));
            var child:ProjectData = queryEngine.createChildOf(ProjectData(parent));

            // Add recover point
            _snapshotsManager.takeSnapshot(_model.currentProject,
                    Strings.sprintf(
                            StaticTokens.ITEM_ADD_OPERATION, child.getContent(DataFields.DATA_TYPE)
                    )
            );
            updateUndoRedoUi();

            // Additional configuration for Parts
            if (ModelUtils.isPart(child) || ModelUtils.isSection(child)) {
                ModelUtils.updateUnifiedPartsList(_model.currentProject);
            }

            // Refreshing the model
            if (!skipUpdatingModel) {
                updateAllViews();
                setSelection(child);
            }

            // Side effect: returning the created child
            return child;
        }
        return null;
    }

    /**
     * TODO: document
     */
    private function _onStructureItemNudgeDown(uid:String):void {
        if (_model && _model.currentProject) {
            var movable:ProjectData = ProjectData(model.currentProject.getElementByRoute(uid));

            // Stop playback
            _stopMidi();

            // Actually nudge the item
            var replacement:ProjectData = queryEngine.nudgeElementDown(ProjectData(movable), _nudgeLock);
            lastSelection = null;
            updateAllViews();
            setSelection(replacement);

            // Add recover point
            _snapshotsManager.takeSnapshot(_model.currentProject,
                    Strings.sprintf(
                            StaticTokens.ITEM_NUDGE_AFTER, movable.getContent(DataFields.DATA_TYPE)
                    )
            );
            updateUndoRedoUi();
        }
    }

    /**
     * TODO: document
     */
    private function _onStructureItemNudgeUp(uid:String):void {
        if (_model && _model.currentProject) {
            var movable:ProjectData = ProjectData(model.currentProject.getElementByRoute(uid));

            // Stop playback
            _stopMidi();

            // Actually nudge the item
            var replacement:ProjectData = queryEngine.nudgeElementUp(ProjectData(movable), _nudgeLock);
            lastSelection = null;
            updateAllViews();
            setSelection(replacement);

            // Add recover point
            _snapshotsManager.takeSnapshot(_model.currentProject,
                    Strings.sprintf(
                            StaticTokens.ITEM_NUDGE_BEFORE, movable.getContent(DataFields.DATA_TYPE)
                    )
            );
            updateUndoRedoUi();
        }
    }

    /**
     * TODO: document
     */
    private function _onStructureItemRemove(uid:String):void {
        if (_model && _model.currentProject) {
            _stopMidi();
            var deletable:ProjectData = (model.currentProject.getElementByRoute(uid) as ProjectData);

            // Add recover point
            _snapshotsManager.takeSnapshot(_model.currentProject,
                    Strings.sprintf(
                            StaticTokens.ITEM_REMOVE_OPERATION, deletable.getContent(DataFields.DATA_TYPE)
                    )
            );
            updateUndoRedoUi();
            var replacementSelection:ProjectData = null;

            // Deleting a Part node requires special handling, as part nodes transcend
            // their parent Section nodes. The node to be selected instead of the deleted Part
            // will always be the part's parent Section. However, this is handled inside the
            // `_deletePartNode()` method.
            if (ModelUtils.isPart(deletable)) {
                _deletePartNode(deletable);
                return;
            }

            // Deleting a Voice node requires special handling, due to specific voices
            // restrictions, as detailed in MAID-21
            // (https://ciacob.atlassian.net/projects/MAID/issues/MAID-21?filter=allopenissues).
            // Especially, we need to make sure that the parent measure is always left with a
            // valid "voice 1" to host musical content. Deleting a Voice always causes its previous
            // sibling node to be selected. This is handled inside the `_deleteVoiceNode()` method.
            if (ModelUtils.isVoice(deletable)) {
                replacementSelection = _deleteVoiceNode(deletable);
                if (replacementSelection && replacementSelection.dataParent) {
                    var info:Object = _getMeasureSelectionInfo(replacementSelection.dataParent as ProjectData);
                    GLOBAL_PIPE.send(ViewKeys.MEASURE_SELECTION_INFO_READY, info);
                }
            }

            // Deleting a Cluster requires special care, as it could be a member of a tuplet.
            // If this is the case, we must decommission the tuplet.
            if (ModelUtils.isCluster(deletable)) {

                // This Cluster starts a tuplet (tuplet root)
                var isTupletRoot:Boolean = (deletable.getContent(DataFields.STARTS_TUPLET) as Boolean);
                if (isTupletRoot) {
                    _decommissionTupletOf(deletable);
                } else {

                    // This Cluster continues a tuplet (tuplet member)
                    var continuesTuplet:Boolean = ((deletable.getContent(DataFields.TUPLET_ROOT_ID) as String) !=
                            DataFields.VALUE_NOT_SET);
                    if (continuesTuplet) {
                        var tupletRoot:ProjectData = _getTupletRootOf(deletable);
                        _decommissionTupletOf(tupletRoot, false);
                    }
                }
            }
            replacementSelection = (replacementSelection || queryEngine.deleteElement(deletable));
            updateAllViews();
            setSelection(replacementSelection);
        }
    }

    /**
     * TODO: document
     */
    private function _onStructureTreeReady(...ignore):void {
        _structureTreeReady = true;
        if (_bufferedTreeData != null) {
            _sendTreeData(_bufferedTreeData);
            _bufferedTreeData = null;
        }
    }

    /**
     * TODO: document
     */
    private function _onTreeItemClick(uid:String):void {
        var selection:ProjectData = null;
        if (uid != null) {
            selection = ProjectData(_model.currentProject.getElementByRoute(uid));

            // There is functionality in need of knowing the last section that was touched
            _currentSection = ModelUtils.getClosestAscendantByType(selection, DataFields.SECTION) || _currentSection;

            // When the selected node is a Measure or Voice, supplemental processing is needed,
            // due to the fact that these two type of nodes share the same interactive area
            // (aka "hotspot") in the score editor.
            var isMeasure:Boolean = ModelUtils.isMeasure(selection);
            var isVoice:Boolean = ModelUtils.isVoice(selection);
            if (isMeasure || isVoice) {
                var info:Object;
                if (isMeasure) {
                    _measureSelectionType = MeasureSelectionKeys.SELECT_MEASURE_NODE;
                    _measureSelectionStaffIndex = 1;
                    info = _getMeasureSelectionInfo(selection as ProjectData);
                } else if (isVoice) {
                    var voiceIndex:int = selection.getContent(DataFields.VOICE_INDEX) as int;
                    _measureSelectionType = (voiceIndex == 1) ? MeasureSelectionKeys.SELECT_VOICE_ONE_NODE : MeasureSelectionKeys.SELECT_VOICE_TWO_NODE;
                    _measureSelectionStaffIndex = selection.getContent(DataFields.STAFF_INDEX) as int;
                    info = _getMeasureSelectionInfo(selection.dataParent as ProjectData);
                }
                GLOBAL_PIPE.send(ViewKeys.MEASURE_SELECTION_INFO_READY, info);
            }

            // There is functionality in need of knowing the last part that was touched
            _currentPart = ModelUtils.getClosestAscendantByType(selection, DataFields.PART) || _currentPart;
        }
        setSelection(selection, false, true);
    }

    /**
     * TODO: document
     */
    private static function _onUidForAnnotationRequested(element:ProjectData):void {
        // var uid:String=_queryEngine.getShortUidFor(element.route);
        GLOBAL_PIPE.send(ViewKeys.UID_FOR_ANNOTATION_READY, element.route.concat(CommonStrings.BROKEN_VERTICAL_BAR));
    }

    // New way of committing user changes, meant to supersede the event
    // based one
    private function _onUserCommit(userData:Object):void {
        _stopMidi();
        var committedData:ProjectData = (userData[ViewKeys.COMMITTED_DATA] as ProjectData);
        var targetRoute:String = (userData[ViewKeys.EDITED_ELEMENT_ROUTE] as String);
        if (committedData != null && !Strings.isEmpty(targetRoute)) {
            var test:Object = (committedData.getContent(DataFields.DATA_TYPE) as Object);
            if (test != DataFields.VALUE_NOT_SET) {
                var dataType:String = test.toString();

                // Add recover point
                _snapshotsManager.takeSnapshot(_model.currentProject,
                        Strings.sprintf(StaticTokens.ITEM_EDIT_OPERATION, dataType)
                );
                updateUndoRedoUi();
                switch (dataType) {
                    case DataFields.PART:
                        _commitPartData(committedData, targetRoute);
                        break;
                    case DataFields.MEASURE:
                        _commitMeasureData(committedData, targetRoute);
                        break;
                    case DataFields.VOICE:
                        _commitData(committedData, targetRoute);
                        if (committedData && committedData.dataParent) {
                            var info:Object = _getMeasureSelectionInfo(committedData.dataParent as ProjectData);
                            GLOBAL_PIPE.send(ViewKeys.MEASURE_SELECTION_INFO_READY, info);
                        }
                        break;
                    case DataFields.CLUSTER:
                        var clusterDuration:String = (committedData.getContent(DataFields.CLUSTER_DURATION_FRACTION) as String);
                        queryEngine.lastEnteredDuration = clusterDuration;
                        _commitData(committedData, targetRoute);
                        break;
                    case DataFields.NOTE:
                        var parentCluster:ProjectData = model.currentProject.getElementByRoute(targetRoute)
                                .dataParent as ProjectData;

                        // Starting with v.1.5 we don't allow same-voice unison anymore
                        if (!queryEngine.causesPitchCollision(committedData, parentCluster)) {
                            var notePitch:int = MusicUtils.noteToMidiNumber(committedData);
                            queryEngine.lastEnteredPitch = notePitch;
                            queryEngine.usingNotesRatherThanRests = true;
                            var commitedContent:Object = committedData.getContentMap();
                            if (queryEngine.updateContentOf(targetRoute, commitedContent)) {
                                var newSelection:ProjectData = queryEngine.orderChildNotesByPitch(parentCluster, lastSelection);
                                updateAllViews();
                                if (newSelection) {
                                    targetRoute = newSelection.route;
                                }
                            }
                        } else {
                            _undo();
                            snapshotsManager.deleteRedoHistory();
                            Time.delay(1, function ():void {
                                showStatusOrPrompt(StaticTokens.UNISONS_FORBIDDEN, PromptColors.WARNING);
                            });
                        }
                        break;
                    default:
                        _commitData(committedData, targetRoute);
                        break;
                }
                lastSelection = null;
                setSelection(ProjectData(_model.currentProject.getElementByRoute(targetRoute)));
            }
        }
    }

    /**
     * Fired when a "DECOMMISSION_TUPLET" is received through a PTT pipe.
     */
    private static function _onTupletDecommissioningRequested(tupletMember:ProjectData):void {
        var tupletRoot:ProjectData = _getTupletRootOf(tupletMember);
        if (tupletRoot) {
            _decommissionTupletOf(tupletRoot);
        }
    }

    /**
     * Fired when a "RESET_TUPLET" is received through a PTT pipe.
     */
    private static function _onTupletResetRequested(tupletMember:ProjectData):void {
        var tupletRoot:ProjectData = _getTupletRootOf(tupletMember);
        if (tupletRoot) {
            _decommissionTupletOf(tupletRoot, false);
        }
    }

    /**
     * TODO: document
     */
    private function _onVoiceDataRequested(voice:ProjectData):void {
        var measure:ProjectData = ProjectData(voice.dataParent);
        var measureNumber:uint = queryEngine.uidToMeasureNumber(measure.route);
        var measureSpan:Fraction = queryEngine.computeMeasureSpan(measure as ProjectData);
        var voiceDuration:Fraction = queryEngine.computeVoiceDuration(voice as ProjectData);
        var data:Object = {};
        data[ViewKeys.MEASURE_NUMBER] = measureNumber;
        data[ViewKeys.VOICE_DURATION] = voiceDuration;
        data[ViewKeys.MEASURE_SPAN] = measureSpan;
        PTT.getPipe(ViewPipes.MEASURE_PADDING_PIPE).send(ViewKeys.VOICE_DATA_READY, data);
    }

    /**
     * Triggered when user has determined a WAV file to export the current project
     * to, via the FileBrowser component.
     * @param    selectedFile
     *           The WAV file to export the current project to.
     */
    private function _onWavFileSelectedForSave(selectedFile:File):void {
        _targetWaveFile = selectedFile;
        _deferFileBrowserClose = false;
        var doIt:Function = function ():void {

            // If current score was never played back fully, we need to render it to audio prior to saving it to disk.
            // This is an asynchronous, three-step process, and involves running, in this order:
            // 1. _prepareScoreForAudio();
            // 2. _onSoundsLoaderReport();
            // 3. _doOfflineStreaming();
            if (!_midiSessionUid) {
                _streamingRoutine = _doOfflineStreaming;
                _prepareScoreForAudio();
            } else {

                // If current score WAS played back fully, then we already have an audio rendition we can use; we will
                // simply transfer that to disk. Note that, by this time, we already have a ready to use `FileUtils`
                // instance.
                _ensureFileUtils();
                _audioFileUtils.dumpToDisk(_audioStreamer.renderedAudioStorage, selectedFile);
            }
        }
        if (selectedFile.exists) {
            _deferFileBrowserClose = true;
            _showOverwriteFilePrompt(selectedFile.nativePath, doIt);
        } else {
            doIt();
        }
    }

    /**
     * TODO: document
     */
    private function _onTranspositionRequested(config:Object):void {

        // Validate operation
        if (lastSelection != null && lastSelection.numDataChildren > 0) {

            // Extract transposition parameters
            var delta:int = config[ViewKeys.TRANSPOSITION_INTERVAL] as int;
            if (delta) {
                delta += config[ViewKeys.ADDITIONAL_OCTAVES] as int;
                delta *= ((config[ViewKeys.TRANSPOSITION_DIRECTION] as String) == Direction.DOWN) ? -1 : 1;
                var mustCloneNotes:Boolean = config[ViewKeys.KEEP_EXISTING_NOTES] as Boolean;

                // Save configuration and load it as default on next transpose operation
                _transpositionUserConfig = config;

                // Extract and act upon target nodes
                var clusters:Array = [];
                var walker:Function = function (element:ProjectData):void {
                    var elType:String = element.getContent(DataFields.DATA_TYPE) as String;
                    if (elType == DataFields.CLUSTER) {
                        clusters.push(element);
                    }
                };
                lastSelection.walk(walker);
                if (clusters.length) {
                    MusicUtils.transposeBy(clusters, delta, mustCloneNotes);
                }

                // Add recovery point
                _snapshotsManager.takeSnapshot(_model.currentProject, Strings.sprintf(
                        StaticTokens.TRANSPOSITION_OPERATION,
                        lastSelection.getContent(DataFields.DATA_TYPE)
                ));
                updateUndoRedoUi();

                // Make changes visible
                updateAllViews();

                // Restate the same selection;
                var selection:ProjectData = lastSelection;
                lastSelection = null;
                setSelection(selection);
            }
        }
    }

    /**
     * Scales all melodic intervals in a given selection based on a configuration object. The configuration
     * determines the strategy to apply when scaling and can carry out post processing "clean up" tasks too, such
     * as vertically align the resulting melodic line or reducing the number of subsequent notes of same pitch
     * (which can occur when "shrinking" a melody vertically).
     */
    private function _onScaleIntervalsRequested(config:Object):void {
        var haveChanges:Boolean = false;

        // Validate operation
        if (lastSelection != null &&
                lastSelection.getContent(DataFields.DATA_TYPE) !== DataFields.CLUSTER &&
                lastSelection.numDataChildren > 0) {

            // Save the configuration to load it next time
            _scaleIntervalsUserConfig = config;

            // Extract the target nodes
            var clusters:Array = [];
            var pitchBoundsInfo:Object = {};
            pitchBoundsInfo[ViewKeys.LOWEST_ORIGINAL_PITCH] = MIDI.MAX;
            pitchBoundsInfo[ViewKeys.HIGHEST_ORIGINAL_PITCH] = MIDI.MIN;
            pitchBoundsInfo[ViewKeys.SELECTION_HAS_MUSIC] = false;
            var walker:Function = function (element:ProjectData):void {
                var elType:String = element.getContent(DataFields.DATA_TYPE) as String;
                if (elType == DataFields.CLUSTER) {
                    var item:Object = {};
                    item[ViewKeys.CLUSTER] = element;
                    if (element.numDataChildren == 0) {
                        item[ViewKeys.BASE_PITCH] = 0;
                    } else {
                        pitchBoundsInfo[ViewKeys.SELECTION_HAS_MUSIC] = true;
                        var basePitch:int = MIDI.MAX;
                        for (var j:int = 0; j < element.numDataChildren; j++) {
                            var note:ProjectData = ProjectData(element.getDataChildAt(j));
                            var notePitch:int = MusicUtils.noteToMidiNumber(ProjectData(note));
                            if (notePitch < basePitch) {
                                basePitch = notePitch;
                            }
                            if (notePitch < pitchBoundsInfo[ViewKeys.LOWEST_ORIGINAL_PITCH]) {
                                pitchBoundsInfo[ViewKeys.LOWEST_ORIGINAL_PITCH] = notePitch;
                                pitchBoundsInfo[ViewKeys.LOWEST_CLUSTER] = element;
                            }
                            if (notePitch > pitchBoundsInfo[ViewKeys.HIGHEST_ORIGINAL_PITCH]) {
                                pitchBoundsInfo[ViewKeys.HIGHEST_ORIGINAL_PITCH] = notePitch;
                                pitchBoundsInfo[ViewKeys.HIGHEST_CLUSTER] = element;
                            }
                        }
                        item[ViewKeys.BASE_PITCH] = basePitch;
                    }
                    clusters.push(item);
                }
            };
            lastSelection.walk(walker);
            if (clusters.length) {
                if (!pitchBoundsInfo[ViewKeys.SELECTION_HAS_MUSIC]) {
                    pitchBoundsInfo[ViewKeys.LOWEST_ORIGINAL_PITCH] = 0;
                    pitchBoundsInfo[ViewKeys.HIGHEST_ORIGINAL_PITCH] = 0;
                }
                clusters[ViewKeys.PITCH_BOUNDS_INFO] = pitchBoundsInfo;

                // Delegate execution based on the `scaleStrategy` parameter: compute the transposition to apply
                // to each Cluster node in the selection.
                var strategy:String = config[ViewKeys.SCALE_STRATEGY] as String;
                var transpositionMap:Array = null;
                switch (strategy) {
                    case StaticFieldValues.CONSTANT:
                        transpositionMap = _scaleIntervalsByConstantFactor(clusters, config);
                        break;
                    case StaticFieldValues.PROGRESSIVELLY:
                        transpositionMap = _scaleIntervalsProgressively(clusters, config);
                        break;
                    case StaticFieldValues.THRESHOLD:
                        transpositionMap = _scaleIntervalsByThreshold(clusters, config);
                        break;
                }

                // Actually transpose pitches observing the vertical alignment of resulting material
                if (transpositionMap && transpositionMap.length > 0) {
                    var startEntry:Object = transpositionMap[0] as Object;
                    var startCluster:ProjectData = startEntry[ViewKeys.CLUSTER] as ProjectData;
                    var startPitch:int = startEntry[ViewKeys.BASE_PITCH] as int;
                    var startDelta:int = 0;
                    switch (config[ViewKeys.SCALE_VERTICAL_ALIGN]) {
                        case StaticFieldValues.ALIGN_TO_CEILING:
                            startDelta = pitchBoundsInfo[ViewKeys.HIGHEST_ORIGINAL_PITCH] - startPitch;
                            break;
                        case StaticFieldValues.ALIGN_TO_FLOOR:
                            startDelta = pitchBoundsInfo[ViewKeys.LOWEST_ORIGINAL_PITCH] - startPitch;
                            break;
                        case StaticFieldValues.CENTER_ON_PIVOT_PITCH:
                            var pivotPitch:int = pitchBoundsInfo[ViewKeys.LOWEST_ORIGINAL_PITCH] +
                                    (pitchBoundsInfo[ViewKeys.HIGHEST_ORIGINAL_PITCH] - pitchBoundsInfo[ViewKeys.LOWEST_ORIGINAL_PITCH]) * 0.5;
                            startDelta = pivotPitch - startPitch;
                            break;
                    }
                    if (startDelta) {
                        startPitch += startDelta;
                        MusicUtils.transposeBaseTo(startCluster, startPitch);
                        startEntry[ViewKeys.BASE_PITCH] = startPitch;
                        haveChanges = true;
                    }
                    var prevItem:Object = null;
                    for (var i:int = 0; i < transpositionMap.length; i++) {
                        var item:Object = transpositionMap[i] as Object;
                        if (prevItem) {
                            if (ViewKeys.DELTA in item) {
                                var delta:int = item[ViewKeys.DELTA] as int;
                                var cluster:ProjectData = item[ViewKeys.CLUSTER] as ProjectData;
                                if (cluster && cluster.numDataChildren > 0) {
                                    var prevPitch:int = prevItem[ViewKeys.BASE_PITCH] as int;
                                    var newPitch:int = delta + prevPitch;
                                    haveChanges = true;
                                    MusicUtils.transposeBaseTo(cluster, newPitch);
                                    item[ViewKeys.BASE_PITCH] = newPitch;
                                }
                            }
                        }
                        prevItem = item;
                    }
                }

                // Consolidate prime intervals if requested
                var mustConsolidatePrimes:Boolean = config[ViewKeys.SCALE_CONSOLIDATE_PRIMES] === StaticFieldValues.CONSOLIDATE_PRIMES;
                if (mustConsolidatePrimes) {
                    haveChanges = true;
                    MusicUtils.consolidatePrimeIntervals(lastSelection);
                }
            }
        }
        if (haveChanges) {

            // Add recovery point
            _snapshotsManager.takeSnapshot(_model.currentProject, Strings.sprintf(
                    StaticTokens.SCALE_INTERVALS_OPERATION,
                    lastSelection.getContent(DataFields.DATA_TYPE)
            ));
            updateUndoRedoUi();

            // Make changes visible
            updateAllViews();

            // Restate the same selection;
            var selection:ProjectData = lastSelection;
            lastSelection = null;
            setSelection(selection);
        }
    }
}
}
