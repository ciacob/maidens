package ro.ciacob.maidens.view.components {
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import mx.controls.listClasses.BaseListData;
	import mx.controls.listClasses.IDropInListItemRenderer;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.controls.listClasses.ListBase;
	import mx.controls.listClasses.ListData;
	import mx.core.IDataRenderer;
	import mx.core.IFlexDisplayObject;
	import mx.core.IFlexModuleFactory;
	import mx.core.IFontContextComponent;
	import mx.core.IToolTip;
	import mx.core.IUITextField;
	import mx.core.UIComponent;
	import mx.core.UITextField;
	import mx.core.mx_internal;
	import mx.events.FlexEvent;
	import mx.events.ToolTipEvent;
	import mx.styles.CSSStyleDeclaration;
	import mx.utils.PopUpUtil;

	use namespace mx_internal;

	[Event(name = "dataChange", type = "mx.events.FlexEvent")]
	[Style(name = "color", type = "uint", format = "Color", inherit = "yes")]
	[Style(name = "disabledColor", type = "uint", format = "Color", inherit = "yes")]
	public class PickupComponentItemRenderer extends UIComponent implements IDataRenderer,
		IDropInListItemRenderer, IListItemRenderer, IFontContextComponent {

		public function PickupComponentItemRenderer() {
			super();

			addEventListener(ToolTipEvent.TOOL_TIP_SHOW, toolTipShowHandler);
		}

		protected var icon:IFlexDisplayObject;
		protected var label:IUITextField;

		private var _data:Object;
		private var _listData:ListData;
		private var listOwner:ListBase;

		override public function get baselinePosition():Number {
			if (!validateBaselinePosition())
				return NaN;
			return label.y + label.baselinePosition;
		}

		[Bindable("dataChange")]
		public function get data():Object {
			return _data;
		}

		public function set data(value:Object):void {
			_data = value;
			invalidateProperties();
			dispatchEvent(new FlexEvent(FlexEvent.DATA_CHANGE));
		}

		public function get fontContext():IFlexModuleFactory {
			return moduleFactory;
		}

		public function set fontContext(moduleFactory:IFlexModuleFactory):void {
			this.moduleFactory = moduleFactory;
		}

		[Bindable("dataChange")]
		public function get listData():BaseListData {
			return _listData;
		}

		public function set listData(value:BaseListData):void {
			_listData = ListData(value);
			invalidateProperties();
		}
		
		private var _css : CSSStyleDeclaration;

		private function _getLabelCss () : CSSStyleDeclaration {
			if(_css == null) {
				_css = (owner.hasOwnProperty('itemStyleName')? 
					styleManager.getStyleDeclaration(owner['itemStyleName']) :
					null);
			}
			return _css;
		}
		
		override protected function commitProperties():void {
			super.commitProperties();
			var childIndex:int = -1;
			if (hasFontContextChanged() && label != null) {
				childIndex = getChildIndex(DisplayObject(label));
				removeChild(DisplayObject(label));
				label = null;
			}
			if (!label) {
				label = IUITextField(createInFontContext(UITextField));
				var css : CSSStyleDeclaration = _getLabelCss ();
				label.styleName = css;
				if (childIndex == -1) {
					addChild(DisplayObject(label));
				} else {
					addChildAt(DisplayObject(label), childIndex);
				}
			}
			if (icon) {
				removeChild(DisplayObject(icon));
				icon = null;
			}
			if (_data != null) {
				listOwner = ListBase(_listData.owner);
				if (_listData.icon) {
					var iconClass:Class = _listData.icon;
					icon = new iconClass();
					addChild(DisplayObject(icon));
				}
				label.text = _listData.label ? _listData.label : " ";
				label.multiline = listOwner.variableRowHeight;
				label.wordWrap = listOwner.wordWrap;
				if (listOwner.showDataTips) {
					if (label.textWidth > label.width || listOwner.dataTipFunction !=
						null) {
						toolTip = listOwner.itemToDataTip(_data);
					} else {
						toolTip = null;
					}
				} else {
					toolTip = null;
				}
			} else {
				label.text = " ";
				toolTip = null;
			}
		}

		override protected function createChildren():void {
			super.createChildren();
			if (!label) {
				label = IUITextField(createInFontContext(UITextField));
				var css : CSSStyleDeclaration = _getLabelCss ();
				label.styleName = css;
				addChild(DisplayObject(label));
			}
		}

		override protected function measure():void {
			super.measure();
			var w:Number = 0;
			if (icon) {
				w = icon.measuredWidth;
			}
			// Guarantee that label width isn't zero
			// because it messes up ability to measure.
			if (label.width < 4 || label.height < 4) {
				label.width = 4;
				label.height = 16;
			}
			if (isNaN(explicitWidth)) {
				w += label.getExplicitOrMeasuredWidth();
				measuredWidth = w;
				measuredHeight = label.getExplicitOrMeasuredHeight();
			} else {
				measuredWidth = explicitWidth;
				label.setActualSize(Math.max(explicitWidth - w, 4), label.height);
				measuredHeight = label.getExplicitOrMeasuredHeight();
				if (icon && icon.measuredHeight > measuredHeight) {
					measuredHeight = icon.measuredHeight;
				}
			}
		}

		protected function toolTipShowHandler(event:ToolTipEvent):void {
			var toolTip:IToolTip = event.toolTip;
			// We need to position the tooltip at same x coordinate, 
			// center vertically and make sure it doesn't overlap the screen.
			// Call the helper function to handle this for us.
			var pt:Point = PopUpUtil.positionOverComponent(DisplayObject(label),
				systemManager, toolTip.width, toolTip.height, height / 2);
			toolTip.move(pt.x, pt.y);
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			var startX:Number = 0;
			if (icon) {
				icon.x = startX;
				startX = icon.x + icon.measuredWidth;
				icon.setActualSize(icon.measuredWidth, icon.measuredHeight);
			}
			label.x = startX;
			label.setActualSize(unscaledWidth - startX, measuredHeight);
			var verticalAlign:String = getStyle("verticalAlign");
			if (verticalAlign == "top") {
				label.y = 0;
				if (icon)
					icon.y = 0;
			} else if (verticalAlign == "bottom") {
				label.y = unscaledHeight - label.height + 2; // 2 for gutter
				if (icon) {
					icon.y = unscaledHeight - icon.height;
				}
			} else {
				label.y = (unscaledHeight - label.height) / 2;
				if (icon) {
					icon.y = (unscaledHeight - icon.height) / 2;
				}
			}
			
			// Set the text color of this item
			if (data && parent) {
				var labelColor:Number;
				
				var inheritedColor : Number = getStyle("color");
				var inheritedDisabledColor : Number = getStyle("disabledColor");
				var inheritedRollOverColor : Number = getStyle("textRollOverColor");
				var inheritedSelectedColor : Number = getStyle("textSelectedColor");
				
				var ownColor : Number = (_css? _css.getStyle("color") : NaN);
				var ownDisabledColor : Number = (_css? _css.getStyle("disabledColor") : NaN);
				var ownRollOverColor : Number = (_css? _css.getStyle("textRollOverColor") : NaN);
				var ownSelectedColor : Number = (_css? _css.getStyle("textSelectedColor") : NaN);
				
				
				if (!enabled) {
					labelColor = isNaN (ownDisabledColor)? inheritedDisabledColor : ownDisabledColor;
				} else if (listOwner.isItemHighlighted(listData.uid)) {
					labelColor = isNaN(ownRollOverColor)? inheritedRollOverColor : ownRollOverColor;
				} else if (listOwner.isItemSelected(listData.uid)) {
					labelColor = isNaN (ownSelectedColor)? inheritedSelectedColor : ownSelectedColor;
				} else {
					labelColor = isNaN (ownColor)? inheritedColor : ownColor;
				}
				
				label.setColor(labelColor);
			}
		}

		mx_internal function getLabel():IUITextField {
			return label;
		}
	}

}

