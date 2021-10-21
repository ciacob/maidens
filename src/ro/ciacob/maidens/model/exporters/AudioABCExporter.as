package ro.ciacob.maidens.model.exporters {
	import flash.filesystem.File;
	
	import ro.ciacob.desktop.data.DataElement;
	import ro.ciacob.maidens.generators.constants.MIDI;
	import ro.ciacob.maidens.generators.constants.parts.PartMidiPatches;
	import ro.ciacob.maidens.model.constants.DataFields;
	import ro.ciacob.maidens.model.constants.FileAssets;
	import ro.ciacob.utils.Strings;

	public class AudioABCExporter extends BaseABCExporter {
		
		private var _percChOffset : int;
		private var _staffHeaderDataTarget:Object;

		public function AudioABCExporter() {
			super();
		}

		/**
		 * Overriden, to reset local state before each export
		 */
		override public function export(project:DataElement, shallow:Boolean=false, isRecursiveCall : Boolean = false):* {
			_percChOffset = 0;
			_staffHeaderDataTarget={};
			return super.export(project, shallow);
		}

		override protected function get abcTemplateFile():File {
			return FileAssets.TEMPLATES_DIR.resolvePath(FileAssets.ABC_AUDIO);
		}

		/**
		 * Overriden to set up patch names
		 */
		override protected function buildStaffHeaderData(partData:Object, target:Object, staffIndex:int):void {
			_staffHeaderDataTarget=target;
			super.buildStaffHeaderData(partData, target, staffIndex);
			var staves:Array=(target['staves'] as Array);
			var lastAddedStaff:Object=staves[staves.length - 1];
			var midiPatch : int = (PartMidiPatches[Strings.toAS3ConstantCase(partData[DataFields.PART_NAME])] as int);
			lastAddedStaff['patchNumber'] = midiPatch.toString();
		}

		/**
		 * Overriden to skip the channel 10, which is reserved for percussion in general MIDI. MAIDENS doesn't
		 * curently provide any percussion support.
		 */
		override protected function sortStaves(staves:Array):void {
			if (staves.length > 0) {
				super.sortStaves(staves);
				var firstStaff:Object=staves[0];
				var firstStaffUid:String=firstStaff['uid'];
				_staffHeaderDataTarget['firstStaffUid']=firstStaffUid;
				var staves:Array=(_staffHeaderDataTarget['staves'] as Array);
				for (var i:int=0; i < staves.length; i++) {
					var staff:Object=(staves[i] as Object);
					var channelIndex:int=(i + 1);
					if (MIDI.isPercussionChannel (channelIndex)) {
						_percChOffset++;
					}
					channelIndex += _percChOffset;
					staff['channelIndex']=channelIndex.toString();
				}
			}
		}
	}
}
