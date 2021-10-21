package ro.ciacob.maidens.model.exporters {
	import ro.ciacob.desktop.data.DataElement;
	import ro.ciacob.desktop.data.constants.DataKeys;
	import ro.ciacob.desktop.data.exporters.IExporter;
	import ro.ciacob.desktop.signals.PTT;
	import ro.ciacob.maidens.model.ModelUtils;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.maidens.model.constants.TreeFieldNames;
	import ro.ciacob.maidens.view.constants.ViewKeys;

	public class TreeDataProviderExporter implements IExporter {
		
		/*
		 * Helper, listing all Part "types" currently used in the score, but not Part "instances",
		 * e.g., if a score has two Violins and one Piano, the list will contain: ['Violin', 'Piano'].
		 * Helps sorting the parts in the tree, while maintaining Part "instances" (i.e., Violin 1 & Violin 2)
		 * grouped together.
		 */
		private var _coalescedParts : Array;

		public function TreeDataProviderExporter() {
			PTT.getPipe().subscribe(ViewKeys.ELEMENT_LABEL_READY, _onElementLabelReady); 
		}
		
		private function _onElementLabelReady (data : Object) : void {
			var treeItem : Object = data[ViewKeys.TARGET_OBJECT];
			var label : String = data[ViewKeys.RESULTING_LABEL];
			treeItem[TreeFieldNames.LABEL] = label;
		}

		public function export(data:DataElement, shallow : Boolean = false, isRecursiveCall : Boolean = false):* {
			
			// Reset the list previously coalesced parts
			if (!isRecursiveCall) {
				_coalescedParts = [];
			}
			
			// Skip relational assets while exporting
			if (data.getContent(DataFields.DATA_TYPE) == DataFields.RELATIONAL_ASSETS_CONTAINER) {
				return null;
			}

			// Export the current item
			var treeItem:Object = {};
			var childCount:int = 0;
			treeItem[DataKeys.SOURCE] = data;
			var pttData : Object = {};
			pttData[ViewKeys.TARGET_OBJECT] = treeItem;
			pttData[ViewKeys.DATA_SOURCE] = data;
			PTT.getPipe().send(ViewKeys.GET_LABEL_FOR_TREE_ELEMENT, pttData);

			// Export the children of the current item
			if (!shallow) {
				if (data.numDataChildren > 0) {
					for (var j:int = 0; j < data.numDataChildren; j++) {
						var childItem:ProjectData = ProjectData(data.getDataChildAt(j));
						if (ModelUtils.isPart(childItem)) {
							var partName : String = childItem.getContent(DataFields.PART_NAME) as String;
							if (_coalescedParts.indexOf(partName) == -1) {
								_coalescedParts.push(partName);
							}
						}
						var childItemExported:Object = export(childItem, false, true);
						if (childItemExported != null) {
							if (treeItem[DataKeys.CHILDREN] == null) {
								treeItem[DataKeys.CHILDREN] = [];
							}
							treeItem[DataKeys.CHILDREN][childCount] = childItemExported;
							treeItem[DataKeys.CHILDREN][childCount][DataKeys.PARENT] = treeItem;
							childCount++;
						}
					}
				}
			}
			
			// A number of children must be sorted by other traits than their "index" property
			if (treeItem[DataKeys.CHILDREN] != null) {
				if ((treeItem[DataKeys.CHILDREN] as Array).length > 1) {
					var firstChild : Object = (treeItem[DataKeys.CHILDREN] as Array)[0];
					var firstChildSrc : ProjectData = (firstChild[DataKeys.SOURCE] as ProjectData);
					if (firstChildSrc != null) {
						
						var exportedChildren : Array = (treeItem[DataKeys.CHILDREN] as Array);
						
						// Parts must be sorted by their child index, but the PArt instances must be taken 
						// into consideration too, so. e.g., if there sre several Violins playing in the score,
						// they need to be stacked together.
						if (ModelUtils.isPart(firstChildSrc)) {
							exportedChildren.sort (_comparePartChildren);
							if (_coalescedParts && _coalescedParts.length > 0) {
								exportedChildren.map (_stampPartsScoreOrder);
								firstChildSrc.reorderSiblings();
								firstChildSrc.dataParent.resetIntrinsicMeta();
							}
						}
						
						// Voices must be sorted by their specific `voiceIndex` rather than their generic
						// `ProjectData.index`.
						if (ModelUtils.isVoice(firstChildSrc)) {
							exportedChildren.sort (_compareVoiceChildren);
						}
					}
				}
			}
			return treeItem;
		}
		
		private function _compareVoiceChildren (operandA : Object, operandB : Object) : int {
			var voiceA : ProjectData = (operandA[DataKeys.SOURCE] as ProjectData);
			var voiceB : ProjectData = (operandB[DataKeys.SOURCE] as ProjectData);
			return ModelUtils.compareVoiceNodes(voiceA, voiceB);
		}
		
		private function _comparePartChildren (operandA : Object, operandB : Object) : int {
			var partA : ProjectData = (operandA[DataKeys.SOURCE] as ProjectData);
			var partAname : String = partA.getContent(DataFields.PART_NAME) as String;
			var partAprimaryIndex : int = _coalescedParts.indexOf(partAname);
			var partAsecondaryIndex : int = partA.getContent(DataFields.PART_ORDINAL_INDEX) as int;
			var partB : ProjectData = (operandB[DataKeys.SOURCE] as ProjectData);
			var partBname : String = partB.getContent(DataFields.PART_NAME) as String;
			var partBprimaryIndex : int = _coalescedParts.indexOf(partBname);
			var partBsecondaryIndex : int = partB.getContent(DataFields.PART_ORDINAL_INDEX) as int;
			return (partAprimaryIndex - partBprimaryIndex) || (partAsecondaryIndex - partBsecondaryIndex);
		}
		
		private function _stampPartsScoreOrder (item:Object, index:int, array:Array) : void {
			var src : ProjectData = item[DataKeys.SOURCE] as ProjectData;
			src.enforceIndex (index);
			var partName : String = src.getContent(DataFields.PART_NAME) as String;
			var scoreIndex : int = _coalescedParts.indexOf(partName);
			src.setContent (ViewKeys.FIRST_PART_IN_SCORE, scoreIndex == 0);
			src.setContent (ViewKeys.LAST_PART_IN_SCORE, scoreIndex == _coalescedParts.length - 1);
		}
		
	}
}
