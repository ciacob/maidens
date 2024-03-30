package ro.ciacob.maidens.controller.delegates {
import eu.claudius.iacob.maidens.constants.StaticTokens;
import eu.claudius.iacob.maidens.constants.ViewKeys;
import eu.claudius.iacob.maidens.skins.ClusterSkinDisabled;
import eu.claudius.iacob.maidens.skins.GeneratorSkinDisabled;
import eu.claudius.iacob.maidens.skins.MeasureSkinDisabled;
import eu.claudius.iacob.maidens.skins.NoteSkinDisabled;
import eu.claudius.iacob.maidens.skins.PartSkinDisabled;
import eu.claudius.iacob.maidens.skins.ProjectNodeSkinDisabled;
import eu.claudius.iacob.maidens.skins.ScoreSkinDisabled;
import eu.claudius.iacob.maidens.skins.SectionSkinDisabled;
import eu.claudius.iacob.maidens.skins.VoiceSkinDisabled;

import ro.ciacob.desktop.signals.PTT;
import ro.ciacob.maidens.controller.Controller;
import ro.ciacob.maidens.legacy.ModelUtils;
import ro.ciacob.maidens.legacy.ProjectData;
import ro.ciacob.maidens.legacy.constants.DataFields;
import ro.ciacob.maidens.view.constants.MenuCommandNames;
import ro.ciacob.utils.ByteArrays;
import ro.ciacob.utils.Strings;
import ro.ciacob.utils.constants.CommonStrings;

public final class ContextualMenusManager {
    private var _structureOperationStatus:Object;

    private const _menuTemplate:Array = [
        {
            role: "header",
            enabled: false,
            icon: null,
            label: "%s %s"
        },
        {
            role: "main",
            isDefault: true,
            icon: null,
            label: "Add %s",
            commandName: MenuCommandNames.ADD_ITEM
        },
        {
            role: "main",
            icon: null,
            label: "Delete %s",
            commandName: MenuCommandNames.DELETE_ITEM
        }
    ];

    public function ContextualMenusManager(ignore:Controller) {
        PTT.getPipe().subscribe(ViewKeys.STRUCTURE_OPERATIONS_STATUS, _onStatusChange);
    }

    /**
     * Returns an Array with data to use for populating the contextual menu of
     * a given Node instance. Each item in this Array must be an Object resembling
     * the following:
     *    {
     * 		role		: << String, optional >>,
     * 		isDefault 	: << Boolean, optional and unique >>,
     * 		icon		: << Class, optional >>,
     * 		label		: << String, mandatory >>,
     * 		commandName	: << String, mandatory >>
     * 	}
     */
    public function getMenuFor(item:ProjectData):Array {
        var menu:Array = [];
        var itemType:String = item.getContent(DataFields.DATA_TYPE) as String;
        var itemDetails:String = _getItemDetails(item);
        var itemIcon:Class = _getTypeIcon(itemType);

        // Build main menu section
        var mainItems:Array = ByteArrays.cloneObject(_menuTemplate) as Array;

        // The item at index `0` inside the template is always the menu header,
        // which we always want to include
        var header:Object = mainItems[0] as Object;
        var headerTpl:String = header.label as String;
        header.label = Strings.sprintf(headerTpl, itemType.toLocaleUpperCase(), itemDetails || '');
        if (itemIcon) {
            header.icon = itemIcon;
        }
        menu.push(header);

        // ADD child. Only shown where applicable
        var canAddChild:Boolean = (!_structureOperationStatus || _structureOperationStatus[ViewKeys.ADD_ELEMENT_AVAILABLE]);
        if (canAddChild) {
            var add:Object = _findItemByProperty(mainItems, 'commandName', MenuCommandNames.ADD_ITEM);
            if (add) {
                var addTpl:String = add.label as String;
                var childType:String = item.getContent(DataFields.CHILD_TYPE) as String;
                if (childType) {
                    add.label = Strings.sprintf(addTpl, Strings.capitalize(childType));
                } else {
                    add.label = StaticTokens.CREATE_ELEMENT;
                }
                menu.push(add);
            }
        }

        // DELETE self. Only shown where applicable
        var canDeleteNode:Boolean = !_structureOperationStatus || _structureOperationStatus[ViewKeys.REMOVE_ELEMENT_AVAILABLE];
        if (canDeleteNode) {
            var deleteItem:Object = _findItemByProperty(mainItems, 'commandName', MenuCommandNames.DELETE_ITEM);
            if (deleteItem) {
                var deleteTpl:String = (deleteItem.label as String);
                var elType:String = (item.getContent(DataFields.DATA_TYPE) as String);
                deleteItem.label = Strings.sprintf(deleteTpl, Strings.capitalize(elType));
                menu.push(deleteItem);
            }
        }
        return menu;
    }

    private static function _getTypeIcon(type:String):Class {
        switch (type) {
            case DataFields.PROJECT:
                return ProjectNodeSkinDisabled;
            case DataFields.GENERATORS:
            case DataFields.GENERATOR:
                return GeneratorSkinDisabled;
            case DataFields.SCORE:
                return ScoreSkinDisabled;
            case DataFields.SECTION:
                return SectionSkinDisabled;
            case DataFields.PART:
                return PartSkinDisabled;
            case DataFields.MEASURE:
                return MeasureSkinDisabled;
            case DataFields.VOICE:
                return VoiceSkinDisabled;
            case DataFields.CLUSTER:
                return ClusterSkinDisabled;
            case DataFields.NOTE:
                return NoteSkinDisabled;
        }
        return null;
    }

    /**
     * Returns an Object with all significant properties of the given
     * Node instance. The exact properties available for each Node
     * type are documented in the class `ProjectData`.
     */
    private function _getItemDetails(item:ProjectData):String {
        var itemData:Object = item.getContentMap();
        var itemType:String = itemData [DataFields.DATA_TYPE];
        var detailsSegments:Array = [];
        var details:String = '';
        var parent:ProjectData;
        var ancestor:ProjectData;
        switch (itemType) {

                // For notes, show qualified pitch (name, alteration, octave) and
                // voice
            case DataFields.NOTE:
                parent = item.dataParent as ProjectData;
                ancestor = parent.dataParent as ProjectData;
                detailsSegments = [
                    '(',
                    ModelUtils.getNodeLabel(item)
                            .split(CommonStrings.SPACE)
                            .slice(1)
                            .join((CommonStrings.SPACE)),
                    ', voice ',
                    ancestor.getContent(DataFields.VOICE_INDEX),
                    ')'
                ];
                details = detailsSegments.join(CommonStrings.EMPTY);
                break;

                // For Clusters, show duration, type based on number of contained notes
                // (rest, note, chord) and voice
            case DataFields.CLUSTER:
                parent = item.dataParent as ProjectData;
                detailsSegments = [
                    '(',
                    ModelUtils.getNodeLabel(item)
                            .split(/[\s\-]+/g)
                            .slice(1)
                            .join((CommonStrings.COMMA_SPACE)),
                    ', voice ',
                    parent.getContent(DataFields.VOICE_INDEX),
                    ')'
                ];
                details = detailsSegments.join(CommonStrings.EMPTY);
                break;

                // For Voices, show short Part name, staff index
                // (if part has several staves ) and global measure
                // number
            case DataFields.VOICE:
                parent = item.dataParent as ProjectData;
                ancestor = parent.dataParent as ProjectData;
                var numPartStaves:int = ancestor.getContent(DataFields.PART_NUM_STAVES) as int;
                var partIndex:int = parseInt(ancestor.getContent(DataFields.PART_ORDINAL_INDEX));
                var partSuffix:String = ((partIndex > 0) ? ' ' + (partIndex + 1) : '');
                detailsSegments = [
                    itemData[DataFields.VOICE_INDEX],
                    ' (',
                    (numPartStaves > 1) ? 'staff ' + itemData[DataFields.STAFF_INDEX] + ', ' : '',
                    'measure ' + _getMeasureNumber(parent),
                    ', ' + ancestor.getContent(DataFields.PART_NAME),
                    partSuffix,
                    ')'
                ];
                details = detailsSegments.join(CommonStrings.EMPTY);
                break;

                // For Measures, show global measure number and section name
            case DataFields.MEASURE:
                parent = item.dataParent as ProjectData;
                ancestor = parent.dataParent as ProjectData;
                detailsSegments = [
                    _getMeasureNumber(item),
                    ' (section ',
                    ancestor.getContent(DataFields.UNIQUE_SECTION_NAME),
                    ')'
                ];
                details = detailsSegments.join(CommonStrings.EMPTY);
                break;
        }
        return details;
    }

    private function _onStatusChange(status:Object):void {
        _structureOperationStatus = status;
    }

    /**
     * Returns the first matching item in the given Array that has a set property
     * named `propertyName` with a set value of `propertyValue`. Returns null if
     * nothing matches.
     */
    private function _findItemByProperty(items:Array, propertyName:String, propertyValue:Object):Object {
        return items.filter(function (item:Object, ...etc):Boolean {
            return item[propertyName] == propertyValue;
        })[0] || null;
    }

    /**
     * Returns the global number of the given Measure node. the value is 1-based.
     */
    private function _getMeasureNumber(measure:ProjectData):int {
        var data:Object = {};
        var pipe:PTT = PTT.getPipe();
        var callback:Function = function (response:Object):void {
            pipe.unsubscribe(ViewKeys.UID_CONVERTED_TO_MEASURE_NUMBER, callback);
            data.response = response[ViewKeys.RESULTING_MEASURE_NUMBER];
        }
        data[ViewKeys.MEASURE_UID_TO_CONVERT] = measure.route;
        pipe.subscribe(ViewKeys.UID_CONVERTED_TO_MEASURE_NUMBER, callback);
        pipe.send(ViewKeys.CONVERT_UID_TO_MEASURE_NUMBER, data);
        return data.response;
    }
}
}