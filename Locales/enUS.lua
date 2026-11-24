local addonName, UVL = ...

-- Fallback locale, must load first
UVL.L = UVL.L or {}
local L = UVL.L
setmetatable(L, { __index = function(_, key) return key end })

-- Core / UI
L["ADDON_TITLE"]        = "UtilityViewerLog"
L["ADDON_AUTHOR"]       = "By Soloup_ever"
L["UI_OPEN_EDIT_MODE"]  = "Open Edit Mode"
L["UI_RESET"]           = "Reset"
L["UI_PREVIEW"]         = "Preview"
L["UI_VERSION"]         = "Version %s"
L["UI_EDITMODE_HINT"]   = "Move this element in Edit Mode."
L["UI_COMBAT"]          = "Unavailable in combat."
L["UI_LAYOUT_PENDING"]  = "Edit Mode layout not loaded yet, try again in a moment."
L["UI_CLOSE"]           = "X"
L["UI_ACTIVE_MODULES"]  = "Active modules: %d / %d"
L["UI_TIP_LEFT"]        = "Left-click: open settings"
L["UI_TIP_RIGHT"]       = "Right-click: open Edit Mode"

-- Shared settings
L["SET_ENABLE"]         = "Enable module"
L["SET_FONT_SIZE"]      = "Text size"
L["SET_COLOR"]          = "Color"
L["SET_OUTLINE"]        = "Outline"
L["SET_OUTLINE_NONE"]   = "None"
L["SET_OUTLINE_THIN"]   = "Thin"
L["SET_OUTLINE_THICK"]  = "Thick"
L["SET_OPACITY"]        = "Opacity"
L["SET_SHOW_LABEL"]     = "Show label"

-- Module: raid group
L["GROUP_NAME"]         = "Raid group"
L["GROUP_DESC"]         = "Displays the raid group (1-8) you are in."
L["GROUP_LABEL"]        = "Group: %d"

-- Module: durability
L["DUR_NAME"]           = "Durability"
L["DUR_DESC"]           = "Displays the average durability of your equipment."
L["DUR_LABEL"]          = "Durability %d%%"
L["DUR_SET_AUTOCOLOR"]  = "Color by level"
L["DUR_SET_HIDEFULL"]   = "Hide at 100%"

-- Module: healer mana
L["HEAL_NAME"]          = "Healer mana"
L["HEAL_DESC"]          = "Shows a mana bar for each healer in your group."
L["HEAL_SET_WIDTH"]     = "Bar width"
L["HEAL_SET_HEIGHT"]    = "Bar height"
L["HEAL_SET_SPACING"]   = "Bar spacing"
L["HEAL_SET_CLASSCOLOR"] = "Class colors"
L["HEAL_SET_SHOWNAME"]  = "Show name"
L["HEAL_SET_SHOWPCT"]   = "Show percent"
L["HEAL_SET_RAIDONLY"]  = "Only in raid"
L["HEAL_SAMPLE_NAME"]   = "Healer %d"

-- Module: quests
L["QUEST_NAME"]          = "Quests"
L["QUEST_DESC"]          = "Accepts and turns in quests, and selects dialogues automatically."
L["QUEST_SET_ACCEPT"]    = "Auto-accept quests"
L["QUEST_SET_TURNIN"]    = "Auto turn-in quests"
L["QUEST_SET_GOSSIP"]    = "Auto-select dialogues"
L["QUEST_SET_REWARD"]    = "Reward choice"
L["QUEST_REWARD_MANUAL"] = "Manual"
L["QUEST_REWARD_PRICE"]  = "Highest vendor price"
L["QUEST_HINT"]          = "Hold Shift, Ctrl or Alt to pause the automation."

-- Settings (general)
L["GENERAL_NAME"]       = "Settings"
L["GENERAL_DESC"]       = "General options of the addon."
L["GENERAL_SET_HIDE_MINIMAP"] = "Hide minimap icon"
