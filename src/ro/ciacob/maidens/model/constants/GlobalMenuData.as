package ro.ciacob.maidens.model.constants {
import ro.ciacob.maidens.view.constants.MenuCommandNames;
import ro.ciacob.maidens.view.constants.MenuIds;
import ro.ciacob.maidens.view.constants.UiColorizationThemes;
import ro.ciacob.utils.constants.CommonStrings;

public class GlobalMenuData {
    public function GlobalMenuData() {
    }

    private static function _generateThemesSubmenu():Array {
        var themes:Array = UiColorizationThemes.getAllThemes();
        return themes.map (
            function (themeInfo:Object, ...ignore):Object {
                var itemData : Object = {
                    label: themeInfo.name,
                    cmdName: [MenuCommandNames.APPLY_THEME, themeInfo.key]
                            .join(CommonStrings.BROKEN_VERTICAL_BAR)
                };
                return itemData;
            }
        );
    }

    public static const STRUCTURE : Object = {
        "menu": [
            {
                "label": StaticTokens.FILE,
                "children": [
                    {
                        "label": StaticTokens.NEW,
                        "cmdName": MenuCommandNames.CREATE_NEW_PROJECT,
                        "kbShortcuts":{
                            "win":[ "ctrl", "n" ],
                            "mac":[ "cmd", "n" ]
                        }
                    },
                    {
                        "label": StaticTokens.NEW_FROM_TEMPLATE,
                        "cmdName": MenuCommandNames.CREATE_PROJECT_FROM_TEMPLATE,
                        "kbShortcuts":{
                            "win":[ "ctrl", "alt", "n" ],
                            "mac":[ "cmd", "alt", "n" ]
                        }
                    },
                    {
                        "label": StaticTokens.OPEN + '...',
                        "cmdName": MenuCommandNames.OPEN_EXISTING_PROJECT,
                        "kbShortcuts":{
                            "win":[ "ctrl", "o" ],
                            "mac":[ "cmd", "o" ]
                        }
                    },
                    {
                        "isSeparator": true
                    },
                    {
                        "label": StaticTokens.SAVE,
                        "cmdName": MenuCommandNames.SAVE_PROJECT,
                        "kbShortcuts":{
                            "win":[ "ctrl", "s" ],
                            "mac":[ "cmd", "s" ]
                        }
                    },
                    {
                        "label": StaticTokens.SAVE_AS + '...',
                        "cmdName": MenuCommandNames.SAVE_PROJECT_AS,
                        "kbShortcuts":{
                            "win":[ "ctrl", "alt", "s" ],
                            "mac":[ "cmd", "alt", "s" ]
                        }
                    },
                    {
                        "isSeparator": true
                    },
                    {
                        "label": StaticTokens.EXPORT,
                        "children": [
                            {
                                "label": StaticTokens.TO_MIDI_FILE + '...',
                                "cmdName": MenuCommandNames.EXPORT_PROJECT_TO_MIDI,
                                "kbShortcuts":{
                                    "win":[ "ctrl", "alt", "m" ],
                                    "mac":[ "cmd", "alt", "m" ]
                                }
                            },
                            {
                                "label": StaticTokens.TO_ABC_NOTATION_FILE + '...',
                                "cmdName": MenuCommandNames.EXPORT_PROJECT_TO_ABC,
                                "kbShortcuts":{
                                    "win":[ "ctrl", "alt", "a" ],
                                    "mac":[ "cmd", "alt", "a" ]
                                }
                            },
                            {
                                "label": StaticTokens.TO_XML_NOTATION_FILE + '...',
                                "cmdName": MenuCommandNames.EXPORT_PROJECT_TO_XML,
                                "kbShortcuts":{
                                    "win":[ "ctrl", "alt", "x" ],
                                    "mac":[ "cmd", "alt", "x" ]
                                }
                            },
                            {
                                "label": StaticTokens.TO_PDF_FILE + '...',
                                "cmdName": MenuCommandNames.EXPORT_PROJECT_TO_PDF,
                                "enabled": false,
                                "kbShortcuts":{
                                    "win":[ "ctrl", "alt", "p" ],
                                    "mac":[ "cmd", "alt", "p" ]
                                }
                            },
                            {
                                "label": StaticTokens.TO_WAV_FILE + '...',
                                "cmdName": MenuCommandNames.EXPORT_PROJECT_TO_WAV,
                                "kbShortcuts":{
                                    "win":[ "ctrl", "alt", "w" ],
                                    "mac":[ "cmd", "alt", "w" ]
                                }
                            }
                        ]
                    },
                    {
                        "isSeparator": true
                    },
                    {
                        "label": StaticTokens.EXIT,
                        "cmdName": MenuCommandNames.EXIT_APPLICATION,
                        "isHomeItem": true,
                        "kbShortcuts":{
                            "win":[ "alt", "f4" ],
                            "mac":[ "cmd", "q" ]
                        }
                    }
                ]
            },
            {
                "label": StaticTokens.EDIT,
                "children": [
                    {
                        "label": StaticTokens.UNDO_PLACEHOLDER,
                        "cmdName": MenuCommandNames.UNDO,
                        "id": MenuIds.UNDO_ITEM,
                        "disabled": true,
                        "kbShortcuts":{
                            "win":[ "ctrl", "z" ],
                            "mac":[ "cmd", "z" ]
                        }
                    },
                    {
                        "label": StaticTokens.REDO_PLACEHOLDER,
                        "cmdName": MenuCommandNames.REDO,
                        "id": MenuIds.REDO_ITEM,
                        "disabled": true,
                        "kbShortcuts":{
                            "win":[ "ctrl", "y" ],
                            "mac":[ "cmd", "y" ]
                        }
                    },
                    {
                        "isSeparator": true
                    },
                    {
                        "label": StaticTokens.COPY_PLACEHOLDER,
                        "cmdName": MenuCommandNames.COPY,
                        "id": MenuIds.COPY_ITEM,
                        "disabled": true,
                        "kbShortcuts":{
                            "win":[ "ctrl", "c" ],
                            "mac":[ "cmd", "c" ]
                        }
                    },
                    {
                        "label": StaticTokens.CUT_PLACEHOLDER,
                        "cmdName": MenuCommandNames.CUT,
                        "id": MenuIds.CUT_ITEM,
                        "disabled": true,
                        "kbShortcuts":{
                            "win":[ "ctrl", "x" ],
                            "mac":[ "cmd", "x" ]
                        }
                    },
                    {
                        "label": StaticTokens.PASTE_PLACEHOLDER,
                        "cmdName": MenuCommandNames.PASTE,
                        "id": MenuIds.PASTE_ITEM,
                        "disabled": true,
                        "kbShortcuts":{
                            "win":[ "ctrl", "v" ],
                            "mac":[ "cmd", "v" ]
                        }
                    }
                ]
            },
            {
                "label": StaticTokens.VIEW,
                "children": [
                    {
                        "label": StaticTokens.THEME,
                        "id": MenuIds.THEME_SUBMENU,
                        "children": _generateThemesSubmenu()
                    }
                ]
            },
            {
                "label": StaticTokens.MACROS,
                "children": [
                    {
                        "label": StaticTokens.TRANSPOSE + '...',
                        "cmdName": MenuCommandNames.TRANSPOSE,
                        "id": MenuIds.TRANSPOSE_ITEM,
                        "kbShortcuts": ["alt", "T" ]
                    },
                    {
                        "label": StaticTokens.SCALE_INTERVALS + '...',
                        "cmdName": MenuCommandNames.SCALE_INTERVALS,
                        "id": MenuIds.SCALE_INTERVALS_ITEM,
                        "kbShortcuts": ["alt", "S" ]
                    }
                ]
            },
            {
                "label": StaticTokens.HELP,
                "children": [
                    {
                        "label": StaticTokens.DOCUMENTATION,
                        "cmdName": MenuCommandNames.OPEN_DOCUMENTATION_URL,
                        "id": MenuIds.DOC_ITEM
                    },
                    {
                        "label": StaticTokens.REPORT_ISSUES,
                        "cmdName": MenuCommandNames.OPEN_ISSUES_URL,
                        "id": MenuIds.ISSUES_ITEM
                    },
                    {
                        "label": StaticTokens.CHECK_RELEASES,
                        "cmdName": MenuCommandNames.OPEN_RELEASES_URL,
                        "id": MenuIds.RELEASES_ITEM
                    },
                    {
                        "isSeparator": true
                    },
                    {
                        "label": StaticTokens.BECOME_A_SPONSOR,
                        "cmdName": MenuCommandNames.BECOME_SPONSOR_URL,
                        "id": MenuIds.SPONSOR_ITEM
                    }
                ]
            }
        ]
    };
}
}
