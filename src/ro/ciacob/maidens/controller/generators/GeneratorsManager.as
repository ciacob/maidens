package ro.ciacob.maidens.controller.generators {
import flash.utils.getDefinitionByName;

import ro.ciacob.desktop.signals.PTT;
import ro.ciacob.maidens.controller.Controller;
import ro.ciacob.maidens.controller.constants.GeneratorKeys;
import ro.ciacob.maidens.controller.constants.GeneratorPipes;
import ro.ciacob.maidens.controller.constants.GeneratorsTable;
import ro.ciacob.maidens.model.ModelUtils;
import ro.ciacob.maidens.model.ProjectData;
import ro.ciacob.maidens.model.constants.DataFields;
import ro.ciacob.maidens.view.constants.PromptColors;
import ro.ciacob.utils.Strings;

/**
 * Organizer and dispatcher of Generator datasets and entry points. Works with Generator
 * definitions, NOT "generator instances".
 */
public class GeneratorsManager {

    /**
     * @constructor
     */
    public function GeneratorsManager(controller:Controller) {
        // Store a link to the main controller class
        _controller = controller;
    }

    private static const PIPE:String = 'GeneratorsManager_internal';

    /**
     * Storage for the main controller instance.
     */
    private var _controller:Controller;

    /**
     * Storage for the AS3 class definitions of each initialized Generator.
     * They are indexed by the Generator's UID.
     */
    private var _generatorClasses:Object = {};

    /**
     * Storage for Generator definitions indexed by their respective UID;
     */
    private var _generatorsByUid:Object = {};

    /**
     * List of all available Generators' UIDs.
     */
    private var _allGeneratorUids:Vector.<String>;

    /**
     * List of all initialized Generator's UIDs.
     */
    private var _initializedGeneratorUids:Vector.<String>;

    /**
     * List of all available Generators.
     */
    private var _allGenerators:Vector.<ProjectData>;

    /**
     * A list with generator UIDs to initialize.
     */
    private var _initializationQueue:Vector.<String>;

    /**
     * A list with generator uids that are required by the current Project (regardless
     * of whether they are available or not).
     */
    private var _requiredGeneratorUids:Vector.<String>;

    /**
     * Returns a copy of the list with the full dataset of every available generators.
     * Each Generator is represented by a ProjectData instance.
     */
    public function getGeneratorsList():Vector.<ProjectData> {
        return _allGenerators.concat();
    }

    /**
     * Convenience way to return a Generator's dataset based on its UID.
     */
    public function getGeneratorByUid(uid:String):ProjectData {
        return (_generatorsByUid [uid] as ProjectData);
    }

    /**
     * Returns a Generator's main entry point based on that Generator's UID.
     */
    public function getGeneratorClassByUid(uid:String):Class {
        return (_generatorClasses[uid] as Class);
    }

    /**
     * Initializes a Generator.
     *
     * @param    genUid
     *            The UID of the generator to be initialized.
     *
     * @sends    GeneratorKeys.INITIALIZED_GENERATOR, through the GeneratorPipes.INITIALIZATION pipe.
     *            The listening function receives the UID of the generator that has been initialized.
     *
     * @sends    GeneratorKeys.QUEUE_POSITION_EXHAUSTED, through the local (private) pipe. The listening
     *            function receives no data, but must accomodate for a single `null` argument. This is
     *            consummed locally, by the batch initialization process.
     */
    public function initializeGenerator(genUid:String):Boolean {

        // Retrieve the Generator by its UID
        var dataset:ProjectData = _generatorsByUid[genUid];
        if (dataset) {

            // Obtain the Generator's class by its qualified name, and store it under the Generator's UID
            var generatorClassName:String = (dataset.getContent(GeneratorKeys.MAIN_CLASS) as String);
            var generatorClass:Class = (getDefinitionByName(generatorClassName) as Class);
            _generatorClasses[genUid] = generatorClass;
            _initializedGeneratorUids.push(genUid);
            PTT.getPipe(GeneratorPipes.INITIALIZATION).send(GeneratorKeys.INITIALIZED_GENERATOR, genUid);
            PTT.getPipe(PIPE).send(GeneratorKeys.QUEUE_POSITION_EXHAUSTED);
            return true;
        }

        // Loading old projects with unsupported generators will cause initialization to fail.
        _controller.showStatus(Strings.sprintf(GeneratorKeys.UNRECOGNIZED_GENERATOR, genUid),
                PromptColors.ERROR);
        return false;
    }

    /**
     * Initializes all Generators used by given `project` (to minimize impact on CPU and RAM, we
     * only initialize a Generator when the user explicitely requests it, or when a Project has been
     * loaded that uses an instance of that Generator).
     *
     * @param    project
     *            The project to initialize referenced generator modules of.
     *
     * @sends    GeneratorKeys.PROJECT_GENERATORS_READY through the GeneratorPipes.STATUS pipe.
     *            The listing function will receive an Object with the status quo of the initialization
     *            process.
     */
    public function initializeGeneratorsUsedBy(project:ProjectData):void {

        // Internal callback to be triggered when the current queue position has been exhausted, either by
        // success, or by failure.
        var _on_queue_position_exhausted:Function = function (...args):void {
            _initializeNextGeneratorInQueue();
        }

        // Internal callback to be triggered when all the items in the queue were processed
        var _on_queue_exhausted:Function = function (...args):void {
            PTT.getPipe(PIPE).unsubscribe(GeneratorKeys.QUEUE_POSITION_EXHAUSTED, _on_queue_position_exhausted);
            PTT.getPipe(PIPE).unsubscribe(GeneratorKeys.QUEUE_EXHAUSTED, _on_queue_exhausted);

            // Report status quo
            var data:Object = {};
            data[GeneratorKeys.AVAILABLE_GENERATORS_LIST] = _allGeneratorUids;
            data[GeneratorKeys.REQUIRED_GENERATORS_LIST] = _requiredGeneratorUids;
            data[GeneratorKeys.INITIALIZED_GENERATORS_LIST] = _initializedGeneratorUids;
            PTT.getPipe(GeneratorPipes.STATUS).send(GeneratorKeys.PROJECT_GENERATORS_READY, data);
        }

        // Setup the initialization queue
        if (_initializationQueue) {
            _initializationQueue.length = 0;
        } else {
            _initializationQueue = new Vector.<String>;
        }
        var generatorsNode:ProjectData = (ModelUtils.getChildrenOfType(project, DataFields.GENERATORS)[0] as ProjectData);
        if (generatorsNode != null) {
            var generatorNodes:Array = ModelUtils.getChildrenOfType(generatorsNode, DataFields.GENERATOR);
            for (var i:int = 0; i < generatorNodes.length; i++) {
                var generator:ProjectData = (generatorNodes[i] as ProjectData);
                var generatorUid:String = (generator.getContent(GeneratorKeys.GLOBAL_UID) as String);
                if (generatorUid == DataFields.VALUE_NOT_SET) {
                    continue;
                }
                _requiredGeneratorUids.push(generatorUid);
                if (!isGeneratorInitialized(generatorUid)) {
                    _initializationQueue.push(generatorUid);
                }
            }
        }

        // Run the queue
        if (_initializationQueue.length > 0) {
            PTT.getPipe(PIPE).subscribe(GeneratorKeys.QUEUE_POSITION_EXHAUSTED, _on_queue_position_exhausted);
            PTT.getPipe(PIPE).subscribe(GeneratorKeys.QUEUE_EXHAUSTED, _on_queue_exhausted);
            _initializeNextGeneratorInQueue();
        }
    }

    public function isGeneratorInitialized(generatorUid:String):Boolean {
        return (_initializedGeneratorUids.indexOf(generatorUid) >= 0);
    }

    /**
     * Fully resets the internal state of the manager. Useful when loading a new Project
     * (unless running several Projects in paralel is supported, which may be the case
     * in the future).
     */
    public final function reset():void {
        _generatorClasses = {};
        _generatorsByUid = {};
        if (_requiredGeneratorUids) {
            _requiredGeneratorUids.length = 0;
        } else {
            _requiredGeneratorUids = new Vector.<String>;
        }
        if (_initializedGeneratorUids) {
            _initializedGeneratorUids.length = 0;
        } else {
            _initializedGeneratorUids = new Vector.<String>;
        }
        _reIndexBultinGenerators();
    }

    /**
     * Causes the next generator in the queue, if any, to be initialized.
     *
     * @sends    GeneratorKeys.QUEUE_EXHAUSTED, through the local pipe.
     *            The listening function receives no data (it must accept one
     *            `null` argument though).
     */
    private function _initializeNextGeneratorInQueue():void {
        var uidToInitialize:String = _initializationQueue.shift();
        if (uidToInitialize != null) {
            initializeGenerator(uidToInitialize);
        } else {
            PTT.getPipe(PIPE).send(GeneratorKeys.QUEUE_EXHAUSTED);
        }
    }

    /**
     * Re-reads the list of available Generators and recreats any dependent lists.
     */
    private function _reIndexBultinGenerators():void {
        if (_allGeneratorUids) {
            _allGeneratorUids.length = 0;
        } else {
            _allGeneratorUids = new Vector.<String>;
        }
        if (_allGenerators) {
            _allGenerators.length = 0;
        } else {
            _allGenerators = new Vector.<ProjectData>;
        }
        var generators:Array = GeneratorsTable.LIST;
        for (var i:int = 0; i < generators.length; i++) {
            var data:ProjectData = (generators[i] as ProjectData);
            var uid:String = (data.getContent(GeneratorKeys.GLOBAL_UID) as String);
            _allGeneratorUids.push(uid);
            _allGenerators.push(data);
            _generatorsByUid[uid] = data;
        }
    }
}
}
