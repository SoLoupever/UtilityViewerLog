local addonName, UVL = ...
local L = UVL.L

local General = {
    nameKey = "GENERAL_NAME",
    descKey = "GENERAL_DESC",
    scope   = "global",
    defaults = {
        hide = false,
    },
}

General.settings = {
    { key = "hide", kind = "checkbox", label = "GENERAL_SET_HIDE_MINIMAP" },
}

local LDB_NAME = "UtilityViewerLog"
local icon

function General:Init()
    local ldb = LibStub("LibDataBroker-1.1")
    icon = LibStub("LibDBIcon-1.0")

    local object = ldb:NewDataObject(LDB_NAME, {
        type = "launcher",
        icon = "Interface\\AddOns\\" .. addonName .. "\\Media\\UVL_Logo",
        OnClick = function(_, button)
            if button == "RightButton" then
                UVL:OpenEditMode()
            else
                UVL:ToggleConfig()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine(L["ADDON_TITLE"])
            tooltip:AddLine(L["UI_TIP_LEFT"], 1, 1, 1)
            tooltip:AddLine(L["UI_TIP_RIGHT"], 1, 1, 1)
        end,
    })

    icon:Register(LDB_NAME, object, self.db)
end

function General:ApplyStyle()
    if self.db.hide then
        icon:Hide(LDB_NAME)
    else
        icon:Show(LDB_NAME)
    end
end

UVL:RegisterModule("General", General)
