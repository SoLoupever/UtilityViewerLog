local addonName, UVL = ...
local L = UVL.L

local Mana = {
    nameKey = "HEAL_NAME",
    descKey = "HEAL_DESC",
    previewHeight = 150,
    defaults = {
        point          = "TOP",
        x              = 0,
        y              = -600,
        enabled        = true,
        width          = 250,
        height         = 30,
        spacing        = 0,
        fontSize       = 14,
        classColor     = true,
        color          = { r = 0, g = 0, b = 0.7 },
        showName       = true,
        showPercent    = true,
        onlyInsideRaid = false,
    },
}

Mana.settings = {
    { key = "enabled",        kind = "checkbox", label = "SET_ENABLE" },
    { key = "width",          kind = "slider",   label = "HEAL_SET_WIDTH",   min = 30, max = 300, step = 1 },
    { key = "height",         kind = "slider",   label = "HEAL_SET_HEIGHT",  min = 5,  max = 40,  step = 1 },
    { key = "spacing",        kind = "slider",   label = "HEAL_SET_SPACING", min = 0,  max = 10,  step = 1 },
    { key = "fontSize",       kind = "slider",   label = "SET_FONT_SIZE",    min = 8,  max = 24,  step = 1 },
    { key = "classColor",     kind = "checkbox", label = "HEAL_SET_CLASSCOLOR" },
    { key = "color",          kind = "color",    label = "SET_COLOR", disabledIf = function(db) return db.classColor end },
    { key = "showName",       kind = "checkbox", label = "HEAL_SET_SHOWNAME" },
    { key = "showPercent",    kind = "checkbox", label = "HEAL_SET_SHOWPCT" },
    { key = "onlyInsideRaid", kind = "checkbox", label = "HEAL_SET_RAIDONLY" },
}

local MANA = Enum.PowerType.Mana
local SAMPLE_CLASSES = { "SHAMAN", "PALADIN", "PRIEST", "DRUID" }
local DARKEN = 0.7

local container
local rows = {}      -- pool de barres (les `active` premières sont utilisées)
local unitRow = {}   -- unit -> index dans rows
local active = 0

-- ── Barres (partagées entre l'affichage réel et l'aperçu) ──

local function CreateRow(parent)
    local row = {}
    row.bar = CreateFrame("StatusBar", nil, parent)
    row.bar:SetStatusBarTexture("Interface/Buttons/WHITE8x8")

    local bg = row.bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 1)

    row.name = row.bar:CreateFontString(nil, "OVERLAY")
    row.name:SetFont(STANDARD_TEXT_FONT, 14, "")
    row.name:SetPoint("LEFT", 5, 0)
    row.name:SetShadowColor(0, 0, 0, 1)
    row.name:SetShadowOffset(-1, -1)

    row.percent = row.bar:CreateFontString(nil, "OVERLAY")
    row.percent:SetFont(STANDARD_TEXT_FONT, 14, "")
    row.percent:SetPoint("RIGHT", -5, 0)
    row.percent:SetShadowColor(0, 0, 0, 1)
    row.percent:SetShadowOffset(-1, -1)

    row.bar:Hide()
    return row
end

local function ApplyRowColor(row, db)
    local r, g, b = db.color.r, db.color.g, db.color.b
    if db.classColor and row.class then
        local c = C_ClassColor.GetClassColor(row.class)
        if c then
            r, g, b = c.r * DARKEN, c.g * DARKEN, c.b * DARKEN
        end
    end
    row.bar:SetStatusBarColor(r, g, b, 1)
end

local function ApplyRowStyle(row, db)
    row.bar:SetSize(db.width, db.height)
    row.name:SetFont(STANDARD_TEXT_FONT, db.fontSize, "")
    row.percent:SetFont(STANDARD_TEXT_FONT, db.fontSize, "")
    row.name:SetShown(db.showName)
    row.percent:SetShown(db.showPercent)
    ApplyRowColor(row, db)
end

local function PlaceRow(row, anchor, index, db)
    row.bar:ClearAllPoints()
    row.bar:SetPoint("TOP", anchor, "TOP", 0, -(index - 1) * (db.height + db.spacing))
end

local function ContentHeight(db, count)
    count = math.max(1, count)
    return count * db.height + (count - 1) * db.spacing
end

local function Relayout()
    local db = Mana.db
    for i, row in ipairs(rows) do
        ApplyRowStyle(row, db)
        PlaceRow(row, container, i, db)
    end
    container:SetSize(db.width, ContentHeight(db, active))
end

-- ── Données en jeu ──

local function UpdateBar(unit)
    local row = rows[unitRow[unit]]
    row.bar:SetValue(UnitPower(unit, MANA))
    row.percent:SetText(format("%.0f", UnitPowerPercent(unit, MANA, false, CurveConstants.ScaleTo100)))
end

local function Assign(unit)
    local index = active + 1
    local row = rows[index]
    if not row then
        row = CreateRow(container)
        rows[index] = row
    end
    active = index
    row.class = UnitClassBase(unit)
    row.bar:SetMinMaxValues(0, UnitPowerMax(unit, MANA))
    row.name:SetText(UnitName(unit))
    unitRow[unit] = index
    ApplyRowColor(row, Mana.db)
    UpdateBar(unit)
    row.bar:Show()
end

local function Rebuild()
    local db = Mana.db
    for _, row in ipairs(rows) do row.bar:Hide() end
    wipe(unitRow)
    active = 0

    if db.enabled and IsInGroup() then
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do
                local unit = "raid" .. i
                if UnitGroupRolesAssigned(unit) == "HEALER" then Assign(unit) end
            end
        elseif not db.onlyInsideRaid then
            for i = 1, 4 do
                local unit = "party" .. i
                if UnitGroupRolesAssigned(unit) == "HEALER" then Assign(unit) end
            end
            if UnitGroupRolesAssigned("player") == "HEALER" then Assign("player") end
        end
    end

    Relayout()
end

-- ── Cycle de vie ──

function Mana:Init()
    container = CreateFrame("Frame", "UtilityViewerLogHealerMana", UIParent)
    container:SetSize(self.defaults.width, self.defaults.height)
    UVL:RegisterEditFrame(self, container, self.nameKey)
end

function Mana:ApplyStyle()
    Relayout()
end

function Mana:OnLayoutChanged()
    UVL:ApplyPosition(self, container)
    Relayout()
end

function Mana:Refresh()
    Rebuild()
end

function Mana:OnEnterEditMode()
    local db = self.db
    if not db then return end

    for _, row in ipairs(rows) do row.bar:Hide() end
    wipe(unitRow)
    active = #SAMPLE_CLASSES

    for i, class in ipairs(SAMPLE_CLASSES) do
        local row = rows[i]
        if not row then
            row = CreateRow(container)
            rows[i] = row
        end
        row.class = class
        row.name:SetText(L["HEAL_SAMPLE_NAME"]:format(i))
        row.bar:SetMinMaxValues(0, 100)
        row.bar:SetValue(125 - 25 * i)
        row.percent:SetText(125 - 25 * i)
        row.bar:Show()
    end

    Relayout()
    container:SetAlpha(db.enabled and 1 or 0.4)
end

function Mana:OnExitEditMode()
    container:SetAlpha(1)
    Rebuild()
end

function Mana:CreatePreview(parent)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetPoint("CENTER")
    local previewRows = {}
    for i, class in ipairs(SAMPLE_CLASSES) do
        local row = CreateRow(holder)
        row.class = class
        row.name:SetText(L["HEAL_SAMPLE_NAME"]:format(i))
        row.bar:SetMinMaxValues(0, 100)
        row.bar:SetValue(125 - 25 * i)
        row.percent:SetText(125 - 25 * i)
        row.bar:Show()
        previewRows[i] = row
    end

    local preview = {}
    function preview:Update()
        local db = Mana.db
        if not db then return end
        local count = #previewRows
        local height = ContentHeight(db, count)
        local scale = math.min(1, (parent:GetWidth() - 20) / db.width, (parent:GetHeight() - 16) / height)
        holder:SetScale(scale)
        holder:SetSize(db.width, height)
        holder:SetAlpha(db.enabled and 1 or 0.3)
        for i, row in ipairs(previewRows) do
            ApplyRowStyle(row, db)
            PlaceRow(row, holder, i, db)
        end
    end
    return preview
end

Mana.events = { "UNIT_POWER_UPDATE", "GROUP_ROSTER_UPDATE", "PLAYER_ROLES_ASSIGNED" }
function Mana:OnEvent(event, unit, powerType)
    if event == "UNIT_POWER_UPDATE" then
        if powerType == "MANA" and unitRow[unit] then
            UpdateBar(unit)
        end
    else
        Rebuild()
    end
end

UVL:RegisterModule("HealerMana", Mana)
