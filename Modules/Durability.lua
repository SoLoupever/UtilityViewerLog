local addonName, UVL = ...
local L = UVL.L

local Durability = {
    nameKey = "DUR_NAME",
    descKey = "DUR_DESC",
    defaults = {
        point     = "CENTER",
        x         = 0,
        y         = 150,
        enabled   = true,
        fontSize  = 20,
        color     = { r = 1, g = 0.8, b = 0 },
        outline   = "OUTLINE",
        alpha     = 100,
        showLabel = true,
        autoColor = false,
        hideFull  = false,
    },
}

Durability.settings = {
    { key = "enabled",   kind = "checkbox", label = "SET_ENABLE" },
    { key = "fontSize",  kind = "slider",   label = "SET_FONT_SIZE", min = 10, max = 48, step = 1 },
    { key = "color",     kind = "color",    label = "SET_COLOR", disabledIf = function(db) return db.autoColor end },
    { key = "autoColor", kind = "checkbox", label = "DUR_SET_AUTOCOLOR" },
    { key = "outline",   kind = "dropdown", label = "SET_OUTLINE", options = UVL.Text.OUTLINE_OPTIONS },
    { key = "alpha",     kind = "slider",   label = "SET_OPACITY", min = 20, max = 100, step = 5, format = "%d%%" },
    { key = "showLabel", kind = "checkbox", label = "SET_SHOW_LABEL" },
    { key = "hideFull",  kind = "checkbox", label = "DUR_SET_HIDEFULL" },
}

local SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17, 18 } -- 18 : distance (forever)
local COLOR_GOOD, COLOR_MID, COLOR_LOW = { 0.2, 1, 0.2 }, { 1, 0.6, 0 }, { 1, 0.2, 0.2 }

-- Les données d'objets peuvent être nil pendant un chargement de zone
local RETRY_DELAY, RETRY_MAX = 0.5, 6

local frame
local percent        -- dernier pourcentage calculé
local retryTimer
local retryCount = 0

local function LevelColor(p)
    local c = p >= 60 and COLOR_GOOD or (p >= 30 and COLOR_MID or COLOR_LOW)
    return c[1], c[2], c[3]
end

local function ResolveColor(db, p)
    if db.autoColor then
        return LevelColor(p)
    end
    return db.color.r, db.color.g, db.color.b
end

local function Label(db, p)
    if db.showLabel then
        return L["DUR_LABEL"]:format(p)
    end
    return p .. "%"
end

local function CancelRetry()
    if retryTimer then
        retryTimer:Cancel()
        retryTimer = nil
    end
end

local function Compute()
    local cur, max = 0, 0
    for _, slot in ipairs(SLOTS) do
        local c, m = GetInventoryItemDurability(slot)
        if c and m and m > 0 then
            cur, max = cur + c, max + m
        end
    end
    if max == 0 then return nil end
    return math.floor(cur / max * 100)
end

function Durability:Init()
    frame = UVL.Text.Create("UtilityViewerLogDurabilityFrame")
    UVL:RegisterEditFrame(self, frame, self.nameKey)
end

function Durability:ApplyStyle()
    local p = percent or 100
    frame:SetStyle(self.db, ResolveColor(self.db, p))
end

function Durability:OnLayoutChanged()
    UVL:ApplyPosition(self, frame)
    self:ApplyStyle()
end

local function Evaluate(self)
    CancelRetry()
    local db = self.db

    if not db.enabled then
        frame:Hide()
        return
    end

    local p = Compute()
    if not p and retryCount < RETRY_MAX then
        retryCount = retryCount + 1
        retryTimer = C_Timer.NewTimer(RETRY_DELAY, function()
            retryTimer = nil
            Evaluate(self)
        end)
        return
    end
    retryCount = 0

    if not p or (db.hideFull and p >= 100) then
        frame:Hide()
        return
    end

    percent = p
    if db.autoColor then
        frame.text:SetTextColor(LevelColor(p))
    end
    frame:SetLabel(Label(db, p))
    frame:Show()
end

function Durability:Refresh()
    retryCount = 0
    Evaluate(self)
end

function Durability:OnEnterEditMode()
    local db = self.db
    if not db then return end
    CancelRetry()
    frame:SetStyle(db, ResolveColor(db, 87))
    frame:SetLabel(Label(db, 87))
    frame:Show()
    frame:SetEditVisual(db.enabled)
end

function Durability:OnExitEditMode()
    frame:SetEditVisual(nil)
    self:ApplyStyle()
    self:Refresh()
end

function Durability:CreatePreview(parent)
    return UVL.Text.CreatePreview(parent, self, function(db)
        local r, g, b = ResolveColor(db, 87)
        return Label(db, 87), r, g, b
    end)
end

Durability.events = { "PLAYER_ENTERING_WORLD", "PLAYER_EQUIPMENT_CHANGED", "UPDATE_INVENTORY_DURABILITY" }
function Durability:OnEvent()
    self:Refresh()
end

UVL:RegisterModule("Durability", Durability)
