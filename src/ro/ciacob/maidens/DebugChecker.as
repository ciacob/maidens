package ro.ciacob.maidens {
    import flash.utils.describeType;
    import flash.system.Capabilities;

    public class DebugChecker {
        /** Custom metadata tag that gets stripped in Release mode */

        [CustomMeta304796]
        public var debugMarker:int;

        /** Cached results to avoid redundant checks */
        private var _isDebugBuild:Boolean = detectDebugBuild();
        private var _runsInDebugger:Boolean = Capabilities.isDebugger;

        /**
         * Checks if the code was compiled in Debug mode.
         * @return true if compiled in Debug mode, false otherwise.
         */
        public function isDebugBuild():Boolean {
            return _isDebugBuild;
        }

        /**
         * Checks if the application is running inside a debugger.
         * @return true if running in a debugger, false otherwise.
         */
        public function runsInDebugger():Boolean {
            return _runsInDebugger;
        }

        /**
         * Performs the actual metadata check once and caches the result.
         */
        private function detectDebugBuild():Boolean {
            var typeInfo:XML = describeType(this);

            // Look for the custom metadata tag
            for each (var variable:XML in typeInfo.variable) {
                for each (var metadata:XML in variable.metadata) {
                    if (metadata.@name == "CustomMeta304796") {
                        return true; // Metadata found → debug build
                    }
                }
            }
            return false; // Metadata stripped → release build
        }
    }
}