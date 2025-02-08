package ro.ciacob.maidens.view.constants {
    import flash.filters.ColorMatrixFilter;
    import flash.utils.describeType;

    import ro.ciacob.utils.Strings;

    public class UiColorizationThemes {
        public function UiColorizationThemes() {}

        /**
         * To be used for displaying the UI with no colorization. Results in a light theme being applied.
         * The '$' prefix denotes the default theme.
         */
        [Index(value="1")]
        public static const $LIGHT:ColorMatrixFilter = null;

        /**
         * Same as the "Light" theme, only lighter and with improved contrast.
         */
        [Index(value="2")]
        public static const LIGHT_HIGH_CONTRAST:ColorMatrixFilter = new ColorMatrixFilter([
                    1.2, 0, 0, 0, -40,
                    0, 1.2, 0, 0, -40,
                    0, 0, 1.2, 0, -40,
                    0, 0, 0, 1, 0
                ]);

        /**
         * To be used for displaying the UI with a selective inversion filter. Saturated colors
         * and mid-grays are kept intact, while white and light grays are reverted (turned to black
         * and dark grays). Results in a dark theme being applied.
         */
        [Index(value="3")]
        public static const DARK:ColorMatrixFilter = new ColorMatrixFilter([
                    1, -0.95, -0.95, 0, 255,
                    -0.95, 1, -0.95, 0, 255,
                    -0.95, -0.95, 1, 0, 255,
                    0, 0, 0, 1, 0
                ]);

        /**
         * Same as the "Dark" theme, only darker, and with improved contrast.
         */
        [Index(value="4")]
        public static const DARK_HIGH_CONTRAST:ColorMatrixFilter = new ColorMatrixFilter([
                    0.9, -1, -1, 0, 260,
                    -1, 0.9, -1, 0, 260,
                    -1, -1, 0.9, 0, 260,
                    0, 0, 0, 1, 0
                ]);

        /**
         * Returns all the themes defined in this class in an Array of Objects with `name` and `matrix`
         * keys.
         */
        public static function getAllThemes():Array {
            var list:Array = [];
            var info:XML = describeType(UiColorizationThemes);
            for each (var node:XML in info..constant) {
                var typeName:String = ('' + node.@name);
                var friendlyName:String = Strings.fromAS3ConstantCase(typeName);
                var isDefault:Boolean = false;
                var order:int = (parseInt(node.metadata.(@name == "Index").arg[0].@value) || 0);
                if (Strings.beginsWith(friendlyName, '$')) {
                    isDefault = true;
                    friendlyName = Strings.remove(friendlyName, '$');
                }
                friendlyName = Strings.capitalize(friendlyName, true);
                list.push({
                            'order': order,
                            'isDefault': isDefault,
                            'name': friendlyName + (isDefault ? ' (Default)' : ''),
                            'key': typeName,
                            'matrix': UiColorizationThemes[typeName],
                            'toString': function ():String {
                                return 'Theme: ' + this.name;
                            }
                        });
            }
            return list.sort(_byOrder);
        }

        /**
         * Sorting function used to order themes by their "Index" custom metadata.
         */
        private static function _byOrder(a:Object, b:Object):int {
            return (a.order - b.order);
        }
    }
}
