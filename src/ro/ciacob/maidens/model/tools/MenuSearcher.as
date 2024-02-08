package ro.ciacob.maidens.model.tools {

/**
 * The MenuSearcher class provides functionality to search through a nested menu structure
 * to find a menu item by its unique identifier.
 */
public class MenuSearcher {

    /**
     * Searches for a menu item by its id within a given menu object. This function
     * recursively traverses through all menu items, including those nested within 'children' arrays.
     *
     * @param menu The menu object or a nested child menu where the search should start.
     * @param id The unique identifier of the menu item to search for.
     * @return The menu item object if found, otherwise null. The object structure includes
     * properties defined in the menu item, such as 'label', 'cmdName', and optionally 'children'.
     */
    public static function findMenuItemById(menu:Object, id:String):Object {
        // Check if the current menu item is the one we're looking for
        if (menu.hasOwnProperty("id") && menu.id == id) {
            return menu;
        }

        // If the menu item has children, search recursively in the children
        if (menu.hasOwnProperty("children")) {
            for each (var child:Object in menu.children) {
                var result:Object = findMenuItemById(child, id);
                if (result != null) {
                    return result;
                }
            }
        }

        // If the menu item doesn't match and has no children or wasn't found in children, return null
        return null;
    }

    /**
     * Initiates a search through the top-level structure of a menu to find a menu item by its id.
     * The structure is expected to have a 'menu' property that is an Array of menu items.
     *
     * @param structure The top-level menu structure object, typically containing a 'menu' Array.
     * @param id The unique identifier of the menu item to search for.
     * @return The menu item object if found, otherwise null. The object structure includes
     * properties defined in the menu item, such as 'label', 'cmdName', and optionally 'children'.
     */
    public static function findInStructure(structure:Object, id:String):Object {
        // Assuming the top-level structure is an Object with a "menu" Array property
        for each (var menuItem:Object in structure.menu) {
            var result:Object = findMenuItemById(menuItem, id);
            if (result != null) {
                return result;
            }
        }
        return null;
    }
}

}
