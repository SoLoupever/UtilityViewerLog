local addonName, UVL = ...
local L = UVL.L

local Group = {
    nameKey = "GROUP_NAME",
    descKey = "GROUP_DESC",
    defaults = {
        point     = "CENTER",
        x         = 0,
        y         = 200,
        enabled   = true,
        fontSize  = 28,
        color     = { r = 1, g = 1, b = 0 },
        outline   = "OUTLINE",
        alpha     = 100,
        showLabel = true,
    },
}

Group.settings = {
    { key = "enabled",   kind = "checkbox", label = "SET_ENABLE" },
    { key = "fontSize",  kind = "slider",   label = "SET_FONT_SIZE", min = 10, max = 60, step = 1 },
    { key = "color",     kind = "color",    label = "SET_COLOR" },
    { key = "outline",   kind = "dropdown", label = "SET_OUTLINE", options = UVL.Text.OUTLINE_OPTIONS },
    { key = "alpha",     kind = "slider",   label = "SET_OPACITY", min = 20, max = 100, step = 5, format = "%d%%" },
    { key = "showLabel", kind = "checkbox", label = "SET_SHOW_LABEL" },
}

local frame

local function Label(db, group)
    if db.showLabel then
        return L["GROUP_LABEL"]:format(group)
    end
    return tostring(group)
end

function Group:Init()
    frame = UVL.Text.Create("UtilityViewerLogGroupFrame")
    UVL:RegisterEditFrame(self, frame, self.nameKey)
end

function Group:ApplyStyle()
    local c = self.db.color
    frame:SetStyle(self.db, c.r, c.g, c.b)
end

function Group:OnLayoutChanged()
    UVL:ApplyPosition(self, frame)
    self:ApplyStyle()
end

function Group:Refresh()
    if not self.db.enabled or not IsInRaid() then
        frame:Hide()
        return
    end
    local index = UnitInRaid("player")
    local group = index and select(3, GetRaidRosterInfo(index))
    if group then
        frame:SetLabel(Label(self.db, group))
        frame:Show()
    else
        frame:Hide()
    end
end

function Group:OnEnterEditMode()
    local db = self.db
    if not db then return end
    self:ApplyStyle()
    frame:SetLabel(Label(db, 3))
    frame:Show()
    frame:SetEditVisual(db.enabled)
end

function Group:OnExitEditMode()
    frame:SetEditVisual(nil)
    self:ApplyStyle()
    self:Refresh()
end

function Group:CreatePreview(parent)
    return UVL.Text.CreatePreview(parent, self, function(db)
        local c = db.color
        return Label(db, 3), c.r, c.g, c.b
    end)
end

Group.events = { "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD" }
function Group:OnEvent()
    self:Refresh()
end

UVL:RegisterModule("RaidGroup", Group)
