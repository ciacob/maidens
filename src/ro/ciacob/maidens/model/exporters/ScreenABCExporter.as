package ro.ciacob.maidens.model.exporters {
	import flash.filesystem.File;
	
	import ro.ciacob.desktop.data.DataElement;
	import ro.ciacob.desktop.signals.PTT;
	import ro.ciacob.maidens.model.ModelUtils;
	import ro.ciacob.maidens.model.ProjectData;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.maidens.model.constants.FileAssets;
	import ro.ciacob.maidens.view.constants.ViewKeys;
	import ro.ciacob.utils.Strings;
	import ro.ciacob.utils.constants.CommonStrings;

	public class ScreenABCExporter extends VisualABCExporter {

		public function ScreenABCExporter() {
			super();
		}

		private var _uidForClusterAnnotation:String=null;
		private var _uidForMeasureAnnotation:String=null;
		private var _uidForPartAnnotation:String=null;
		private var _uidForProjectAnnotation:String = null;
		private var _uidForSectionAnnotation:String = null;
		private var _annotatedSections : Object = null;
		private var _prevMeasureStorage : Object = null;

		/**
		 * Overriden, to allow us to run preparation and clean-up code, before and after the actual export takes place.
		 */
		override public function export(project:DataElement, shallow:Boolean=false, isRecursiveCall : Boolean = false):* {
			
			// Prepare
			_uidForClusterAnnotation=null;
			_annotatedSections = {};
			
			// Export
			var ret : * = super.export(project, shallow);
			
			// Clean-up
			project.setContent (DataFields.PROJECT_NAME, project.getMetadata(DataFields.PROJECT_NAME));
			project.setContent (DataFields.COMPOSER_NAME, project.getMetadata(DataFields.COMPOSER_NAME));
			return ret;
		}

		override protected function get abcTemplateFile():File {
			return FileAssets.TEMPLATES_DIR.resolvePath(FileAssets.ABC_SCREEN);
		}

		override protected function provideMeasuresStorage (staff : Object) : Array {
			var measuresStorage : Array = [];
			var sectionsStorage:Array = (staff[SECTIONS] as Array);
			var isFirstSection : Boolean = (sectionsStorage.length == 0);
			if (isFirstSection) {
				var phantomMeasure:Object = {};
				phantomMeasure[BAR] = ABCTranslator.INVISIBLE_BAR;
				measuresStorage.push(phantomMeasure);
				_prevMeasureStorage = phantomMeasure;
			}
			return measuresStorage;
		}

		/**
		 * Overriden to provide annotations to measures and sections
		 * @see onBeforeClusterTranslation()
		 */
		override protected function onAfterMeasureTranslation(measure:ProjectData, storage:Object):void {
			PTT.getPipe().subscribe(ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForMeasureAnnotationReady);
			PTT.getPipe().send(ViewKeys.NEED_UID_FOR_ANNOTATION, measure);

			// Annotate right barline
			storage[BAR]=ABCTranslator.buildAnnotation(_uidForMeasureAnnotation, ABCTranslator.TOP_MARK).concat(storage[BAR]);
			var events:Array=(storage[EVENTS] as Array);
			
			// If this is the first measure of its section, add the section name as an inline annotation, BUT ADD IT TO
			// THE MEASURE BEFORE, so that the section name is left aligned instead of right aligned. If this is the
			// absolute first measure of the piece, add a "ghost measure" whose single job will be to host the section
			// annotation for the first "real" measure.
			if (measure.index == 0) {
				var section : ProjectData = ModelUtils.getClosestAscendantByType(measure, DataFields.SECTION) as ProjectData;
				var uid : String = section.route;
				if (!(uid in _annotatedSections)) {
					_annotatedSections[uid] = true;
					PTT.getPipe().subscribe (ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForSectionAnnotationReady);
					PTT.getPipe().send (ViewKeys.NEED_UID_FOR_ANNOTATION, section);					
					var sectionName : String = section.getContent (DataFields.UNIQUE_SECTION_NAME) as String;
					var annotation : String = ABCTranslator.buildAnnotation(_uidForSectionAnnotation.concat(sectionName), ABCTranslator.TOP_MARK);
					if (_prevMeasureStorage) {
						_prevMeasureStorage[BAR] = annotation.concat(_prevMeasureStorage[BAR]);
					}
				}
			}
			_prevMeasureStorage = storage;
		}

		/**
		 * Overriden to provide annotations for staff/part labels. 
		 * 
		 * We will postpone resolving a staff label to a Part node as much as possible, since there is no
		 * efficient way of knowing wich section's Part nodes to target until the score has been drawn,
		 * and the clickable regions processed.
		 */
		override protected function buildStaffHeaderData(partData:Object, target:Object, staffIndex:int):void {
			var mirrorUid : String = partData.partMirrorUid;
			PTT.getPipe().subscribe(ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForPartAnnotationReady);
			PTT.getPipe().send(ViewKeys.NEED_UID_FOR_PART_ANNOTATION, mirrorUid);
			var abrevName : String = partData.abbreviatedPartName.split (CommonStrings.BROKEN_VERTICAL_BAR).pop() as String;			
			partData.abbreviatedPartName = 	_uidForPartAnnotation.concat(abrevName);
			var fullName : String = partData.partName.split (CommonStrings.BROKEN_VERTICAL_BAR).pop() as String;
			partData.partName = _uidForPartAnnotation.concat(fullName);
			super.buildStaffHeaderData (partData, target, staffIndex);
		}
		
		/**
		 * Overriden to provide annotations for project title and composer name.
		 */
		override protected function buildHeaderData(project:ProjectData, target:Object):void {
			PTT.getPipe().subscribe (ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForProjectAnnotationReady);
			PTT.getPipe().send (ViewKeys.NEED_UID_FOR_ANNOTATION, project);
			var projectName : String = project.getContent(DataFields.PROJECT_NAME) as String;
			project.setMetadata (DataFields.PROJECT_NAME, projectName);
			project.setContent (DataFields.PROJECT_NAME, _uidForProjectAnnotation.concat (projectName));
			var composer : String = project.getContent(DataFields.COMPOSER_NAME) as String;
			project.setMetadata (DataFields.COMPOSER_NAME, composer);
			project.setContent (DataFields.COMPOSER_NAME, _uidForProjectAnnotation.concat (composer));
			super.buildHeaderData (project, target);
		}
		
		/**
		 * Overriden to account for (and ignore) inline annotations.
		 */
		override protected function buildStaffUid (abbrevPartName:String, partOrdNum:int, staffIndex:int):String {
			abbrevPartName = abbrevPartName.split (CommonStrings.BROKEN_VERTICAL_BAR).pop() as String;
			return super.buildStaffUid (abbrevPartName, partOrdNum, staffIndex);
		}
		
		/**
		 * Overriden to provide annotations to clusters. Annotations is what
		 * we use to figure out where an element in the model is drawn on the score.
		 *
		 * @see ScreenABCExporter.onBeforeClusterTranslation()
		 */
		override protected function onBeforeClusterTranslation(clusterNode:ProjectData, storage:Array):void {
//			if (clusterNode.hasContentKey(DataFields.DEBUG_ANNOTATION)) {
//				var debugAnnotation : String = (clusterNode.getContent(DataFields.DEBUG_ANNOTATION) as String);
//				debugAnnotation = Strings.trim(debugAnnotation);
//				var clusterRouteTokens : Array =  clusterNode.route.split('_');
//				var isInFirstVoice : Boolean = (clusterRouteTokens[clusterRouteTokens.length - 2] == 0);
//				if (debugAnnotation && isInFirstVoice) {
//					storage.push(ABCTranslator.buildAnnotation(debugAnnotation, ABCTranslator.TOP_MARK) + ' ');
//				}
//			}

			PTT.getPipe().subscribe(ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForClusterAnnotationReady);
			PTT.getPipe().send(ViewKeys.NEED_UID_FOR_ANNOTATION, clusterNode);
			storage.push(ABCTranslator.buildAnnotation(_uidForClusterAnnotation, ABCTranslator.TOP_MARK));
		}

		private function _onUidForClusterAnnotationReady(data:String):void {
			PTT.getPipe().unsubscribe(ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForClusterAnnotationReady);
			_uidForClusterAnnotation=data;
		}

		private function _onUidForMeasureAnnotationReady(data:String):void {
			PTT.getPipe().unsubscribe(ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForMeasureAnnotationReady);
			_uidForMeasureAnnotation=data;
		}
		
		private function _onUidForPartAnnotationReady (data:String) : void {
			PTT.getPipe().unsubscribe(ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForPartAnnotationReady);
			_uidForPartAnnotation = data;
		}
		
		private function _onUidForProjectAnnotationReady (data : String) : void {
			PTT.getPipe().unsubscribe(ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForProjectAnnotationReady);
			_uidForProjectAnnotation = data;
		}
		
		private function _onUidForSectionAnnotationReady (data : String) : void {
			PTT.getPipe().unsubscribe(ViewKeys.UID_FOR_ANNOTATION_READY, _onUidForSectionAnnotationReady);
			_uidForSectionAnnotation = data;
		}
	}
}
