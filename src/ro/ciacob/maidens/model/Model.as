package ro.ciacob.maidens.model {
import flash.filesystem.File;

import ro.ciacob.maidens.controller.QueryEngine;
import ro.ciacob.maidens.legacy.ProjectData;
import ro.ciacob.maidens.legacy.constants.DataFields;
import ro.ciacob.maidens.legacy.constants.FileAssets;
import ro.ciacob.utils.constants.CommonStrings;

public class Model {

    public function Model() {
    }

    /**
     * The project currently loaded by the application. Can contain
     * application specific settings, which override the default ones.
     * @default
     */
    private var _currentProject:ProjectData;

    private var _currentProjectFile:File;

    private var _queryEngine:QueryEngine;

    public function get currentProject():ProjectData {
        return _currentProject;
    }

    public function set currentProject(value:ProjectData):void {
        _currentProject = value;
        refreshCurrentProject();
    }

    public function get currentProjectFile():File {
        return _currentProjectFile;
    }

    public function set currentProjectFile(value:File):void {
        _currentProjectFile = value;
    }

    /**
     * Returns the a default file to be opened when application
     * starts, if it is to be found in a specific location; returns some
     * empty project data otherwise.
     */
    public function getDefaultProject():Object {
        var defaultFile:File = getDefaultContentFile();
        if (defaultFile.exists) {
            return defaultFile;
        }
        var defaultData:ProjectData = new ProjectData;
        var details:Object = {};
        details[DataFields.DATA_TYPE] = DataFields.PROJECT;
        defaultData.populateWithDefaultData(details);
        return defaultData;
    }

    /**
     * Checks whether there currently is unsaved data.
     */
    public function haveUnsavedData():Boolean {
        return (_currentProject != null && !_currentProject.getContent (DataFields.IS_PRISTINE));
    }

    public function get queryEngine():QueryEngine {
        return _queryEngine;
    }

    public function refreshCurrentProject(alsoDiscardChanges:Boolean = true):void {
        _queryEngine = new QueryEngine(_currentProject);
    }

    public function getDefaultContentFile():File {
        return FileAssets.CONTENT_DIR.resolvePath(FileAssets.DEFAULT_PROJECT_FILE_NAME.concat(CommonStrings.DOT, FileAssets.PROJECT_FILE_EXTENSION));
    }
}
}
