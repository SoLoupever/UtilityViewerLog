local addonName, UVL = ...
local L = UVL.L

-- =====================================================================
-- Interface de l'addon (style AltViewerLog) : sidebar (un bouton par module)
-- + panneau généré depuis module.settings, avec aperçu si CreatePreview.
-- =====================================================================

local C = {
    win        = { 0.03, 0.03, 0.04, 0.98 },
    winBorder  = { 0.36, 0.28, 0.08, 1 },
    box        = { 0.025, 0.025, 0.035, 1 },
    boxBorder  = { 0.30, 0.24, 0.08, 1 },
    card       = { 0.055, 0.055, 0.07, 1 },
    cardBorder = { 0.17, 0.17, 0.21, 1 },
    btn        = { 0.02, 0.02, 0.03, 1 },
    btnBorder  = { 0.28, 0.22, 0.07, 1 },
    btnHover   = { 0.65, 0.50, 0.12, 1 },
    line       = { 0.45, 0.35, 0.10, 1 },
    gold       = { 1.00, 0.82, 0.00 },
    green      = { 0.72, 0.92, 0.45 },
    blue       = { 0.30, 0.62, 1.00 },
    pink       = { 1.00, 0.27, 0.60 },
    text       = { 0.90, 0.90, 0.90 },
    dim        = { 0.50, 0.50, 0.55 },
}

local WHITE = "Interface/Buttons/WHITE8x8"
local FLAT  = { bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 }

local WIN_W, WIN_H = 1000, 660
local SIDEBAR_W, TOP_H, BOTTOM_H, MARGIN = 190, 40, 54, 10
local CONTENT_W = WIN_W - SIDEBAR_W - 3 * MARGIN
local COL_W, ROW_H, LABEL_W = 345, 38, 120

local window, sidebar, content
local buttons, panels = {}, {}
local selected

local function Skin(frame, bg, border)
    frame:SetBackdrop(FLAT)
    frame:SetBackdropColor(unpack(bg))
    frame:SetBackdropBorderColor(unpack(border))
end

local function Msg(text)
    print(("|cff40a6ff%s|r: %s"):format(L["ADDON_TITLE"], text))
end

local function Tint(fontString, enabled)
    fontString:SetTextColor(unpack(enabled and C.text or C.dim))
end

local function SetSelected(btn, on)
    btn.selected = on
    btn:SetBackdropBorderColor(unpack(on and C.gold or C.btnBorder))
    btn.label:SetTextColor(unpack(on and C.gold or C.green))
end

local function NewButton(parent, text, width, height, onClick)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width, height)
    Skin(b, C.btn, C.btnBorder)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.label:SetPoint("CENTER")
    b.label:SetText(text)
    b.label:SetTextColor(unpack(C.green))
    b:SetScript("OnEnter", function(self)
        if not self.selected then self:SetBackdropBorderColor(unpack(C.btnHover)) end
    end)
    b:SetScript("OnLeave", function(self)
        if not self.selected then self:SetBackdropBorderColor(unpack(C.btnBorder)) end
    end)
    b:SetScript("OnClick", onClick)
    return b
end

function UVL:OpenEditMode()
    if InCombatLockdown() then
        Msg(L["UI_COMBAT"])
        return
    end
    EditModeManagerFrame:Show()
end

-- ── Contrôles (un par type du schéma) : { Refresh(), SetEnabled(bool) } ──

local function AddLabel(row, key)
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT")
    fs:SetWidth(LABEL_W)
    fs:SetJustifyH("LEFT")
    fs:SetText(L[key])
    Tint(fs, true)
    return fs
end

local Builders = {}

function Builders.checkbox(row, module, entry)
    local cb = CreateFrame("Button", nil, row, "BackdropTemplate")
    cb:SetSize(18, 18)
    cb:SetPoint("LEFT")
    Skin(cb, C.btn, C.btnHover)
    local mark = cb:CreateTexture(nil, "OVERLAY")
    mark:SetSize(10, 10)
    mark:SetPoint("CENTER")
    mark:SetColorTexture(unpack(C.gold))

    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("LEFT", cb, "RIGHT", 8, 0)
    fs:SetText(L[entry.label])
    Tint(fs, true)

    local checked = false
    local function Set(value)
        checked = value and true or false
        mark:SetShown(checked)
    end
    cb:SetScript("OnClick", function()
        Set(not checked)
        UVL:SetSetting(module, entry, checked)
    end)

    return {
        Refresh    = function() Set(module.db[entry.key]) end,
        SetEnabled = function(on) cb:SetEnabled(on) Tint(fs, on) end,
    }
end

function Builders.slider(row, module, entry)
    local fs = AddLabel(row, entry.label)
    local fmt = entry.format or "%d"

    local s = CreateFrame("Slider", nil, row)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(150, 16)
    s:SetPoint("LEFT", LABEL_W, 0)
    s:EnableMouse(true)

    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0.20, 0.17, 0.08, 1)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    track:SetHeight(4)

    s:SetThumbTexture(WHITE)
    local thumb = s:GetThumbTexture()
    thumb:SetSize(8, 16)
    thumb:SetVertexColor(unpack(C.gold))

    s:SetMinMaxValues(entry.min, entry.max)
    s:SetValueStep(entry.step or 1)
    s:SetObeyStepOnDrag(true)

    local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("LEFT", s, "RIGHT", 10, 0)
    valueText:SetTextColor(unpack(C.blue))

    local updating = false
    s:SetScript("OnValueChanged", function(_, v)
        if updating then return end
        valueText:SetText(fmt:format(math.floor(v + 0.5)))
        UVL:SetSetting(module, entry, v)
    end)

    return {
        Refresh = function()
            local v = module.db[entry.key]
            updating = true
            s:SetValue(v)
            updating = false
            valueText:SetText(fmt:format(v))
        end,
        SetEnabled = function(on)
            s:EnableMouse(on)
            s:SetAlpha(on and 1 or 0.5)
            Tint(fs, on)
        end,
    }
end

function Builders.color(row, module, entry)
    local fs = AddLabel(row, entry.label)
    local swatch = CreateFrame("Button", nil, row, "ColorSwatchTemplate")
    swatch:SetSize(26, 26)
    swatch:SetPoint("LEFT", LABEL_W, 0)

    local function Apply(r, g, b)
        swatch:SetColorRGB(r, g, b)
        UVL:SetSetting(module, entry, { r = r, g = g, b = b })
    end

    swatch:SetScript("OnClick", function()
        local c = module.db[entry.key]
        local r, g, b = c.r, c.g, c.b
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b,
            hasOpacity = false,
            swatchFunc = function() Apply(ColorPickerFrame:GetColorRGB()) end,
            cancelFunc = function() Apply(r, g, b) end,
        })
    end)

    return {
        Refresh = function()
            local c = module.db[entry.key]
            swatch:SetColorRGB(c.r, c.g, c.b)
        end,
        SetEnabled = function(on) swatch:SetEnabled(on) Tint(fs, on) end,
    }
end

function Builders.dropdown(row, module, entry)
    local fs = AddLabel(row, entry.label)
    local dd = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dd:SetSize(170, 26)
    dd:SetPoint("LEFT", LABEL_W, 0)

    dd:SetupMenu(function(_, root)
        for _, opt in ipairs(entry.options) do
            root:CreateRadio(L[opt.text],
                function() return module.db[entry.key] == opt.value end,
                function() UVL:SetSetting(module, entry, opt.value) end)
        end
    end)

    return {
        Refresh    = function() dd:GenerateMenu() end,
        SetEnabled = function(on) dd:SetEnabled(on) Tint(fs, on) end,
    }
end

-- ── Statut (boîte du bas) ──

local function RefreshStatus()
    if not window then return end
    local active, total = 0, 0
    for _, m in ipairs(UVL.moduleList) do
        if m.defaults.enabled ~= nil and m.db then
            total = total + 1
            if m.db.enabled then active = active + 1 end
        end
    end
    window.status:SetText(L["UI_ACTIVE_MODULES"]:format(active, total))
end

-- ── Panneau d'un module ──

local function NewCard(parent, width, height)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetSize(width, height)
    Skin(card, C.card, C.cardBorder)
    return card
end

local function BuildPanel(module)
    local panel = CreateFrame("Frame", nil, content)
    panel:SetAllPoints()
    panel:Hide()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 20, -16)
    title:SetText(L[module.nameKey])
    title:SetTextColor(unpack(C.gold))

    local desc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    desc:SetWidth(CONTENT_W - 180)
    desc:SetJustifyH("LEFT")
    desc:SetText(L[module.descKey])
    desc:SetTextColor(unpack(C.dim))

    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(unpack(C.line))
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", 16, -72)
    line:SetPoint("TOPRIGHT", -16, -72)

    local reset = NewButton(panel, L["UI_RESET"], 110, 24, function()
        UVL:ResetModule(module)
        panel:Refresh()
    end)
    reset:SetPoint("TOPRIGHT", -20, -22)

    local y = -88
    local cardW = CONTENT_W - 40

    if module.CreatePreview then
        local height = module.previewHeight or 100
        local box = NewCard(panel, cardW, height)
        box:SetPoint("TOPLEFT", 20, y)
        local caption = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        caption:SetPoint("TOPLEFT", 10, -8)
        caption:SetText(L["UI_PREVIEW"])
        caption:SetTextColor(unpack(C.blue))
        panel.preview = module:CreatePreview(box)
        y = y - height - 14
    end

    local widgets = {}
    local count = #module.settings
    local lines = math.ceil(count / 2)
    local card = NewCard(panel, cardW, lines * ROW_H + 20)
    card:SetPoint("TOPLEFT", 20, y)

    for i, entry in ipairs(module.settings) do
        local col, ln = (i - 1) % 2, math.floor((i - 1) / 2)
        local row = CreateFrame("Frame", nil, card)
        row:SetSize(COL_W, ROW_H)
        row:SetPoint("TOPLEFT", 16 + col * (COL_W + 10), -10 - ln * ROW_H)
        widgets[i] = Builders[entry.kind](row, module, entry)
    end
    y = y - lines * ROW_H - 20 - 10

    local hintKey = module.hintKey or (module.OnEnterEditMode and "UI_EDITMODE_HINT")
    if hintKey then
        local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", 22, y)
        hint:SetText(L[hintKey])
        hint:SetTextColor(unpack(C.dim))
    end

    function panel:UpdateState()
        local db = module.db
        if not db then return end
        for i, entry in ipairs(module.settings) do
            widgets[i].SetEnabled(not (entry.disabledIf and entry.disabledIf(db)))
        end
        if self.preview then self.preview:Update() end
    end

    function panel:Refresh()
        if not module.db then return end
        for _, w in ipairs(widgets) do w.Refresh() end
        self:UpdateState()
    end

    return panel
end

local function SelectModule(module)
    selected = module
    for m, btn in pairs(buttons) do
        SetSelected(btn, m == module)
    end
    for _, p in pairs(panels) do p:Hide() end
    panels[module] = panels[module] or BuildPanel(module)
    panels[module]:Show()
    panels[module]:Refresh()
    RefreshStatus()
end

-- Appelé par Settings.lua après chaque changement de réglage
function UVL:OnSettingApplied(module)
    local p = panels[module]
    if p and p:IsVisible() then p:UpdateState() end
    RefreshStatus()
end

-- ── Fenêtre ──

local function CreateWindow()
    window = CreateFrame("Frame", "UtilityViewerLogConfig", UIParent, "BackdropTemplate")
    window:SetSize(WIN_W, WIN_H)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    Skin(window, C.win, C.winBorder)
    tinsert(UISpecialFrames, "UtilityViewerLogConfig")

    -- Titre
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText(L["ADDON_TITLE"]:upper())
    title:SetTextColor(unpack(C.blue))

    local author = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    author:SetPoint("LEFT", title, "RIGHT", 10, 0)
    author:SetText(L["ADDON_AUTHOR"])
    author:SetTextColor(unpack(C.pink))

    local close = NewButton(window, L["UI_CLOSE"], 26, 26, function() window:Hide() end)
    close:SetPoint("TOPRIGHT", -MARGIN, -7)
    close.label:SetTextColor(unpack(C.text))

    -- Sidebar
    sidebar = CreateFrame("Frame", nil, window, "BackdropTemplate")
    sidebar:SetPoint("TOPLEFT", window, "TOPLEFT", MARGIN, -TOP_H)
    sidebar:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", MARGIN, BOTTOM_H)
    sidebar:SetWidth(SIDEBAR_W)
    Skin(sidebar, C.box, C.boxBorder)

    local previous
    for _, module in ipairs(UVL.moduleList) do
        if module.settings then
            local btn = NewButton(sidebar, L[module.nameKey], SIDEBAR_W - 24, 34, function() SelectModule(module) end)
            btn:ClearAllPoints()
            if previous then
                btn:SetPoint("TOP", previous, "BOTTOM", 0, -8)
            else
                btn:SetPoint("TOP", sidebar, "TOP", 0, -20)
            end
            previous = btn
            buttons[module] = btn
            selected = selected or module
        end
    end

    -- Contenu
    content = CreateFrame("Frame", nil, window, "BackdropTemplate")
    content:SetPoint("TOPLEFT", window, "TOPLEFT", SIDEBAR_W + 2 * MARGIN, -TOP_H)
    content:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -MARGIN, BOTTOM_H)
    Skin(content, C.box, C.boxBorder)

    -- Boîtes du bas : version | modules actifs | mode édition
    local boxW = (WIN_W - 2 * MARGIN - 16) / 3
    local function NewInfoBox(anchorTo, point, relPoint, x)
        local b = CreateFrame("Frame", nil, window, "BackdropTemplate")
        b:SetSize(boxW, 36)
        b:SetPoint(point, anchorTo, relPoint, x, anchorTo == window and MARGIN or 0)
        Skin(b, C.box, C.boxBorder)
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        b.text:SetPoint("CENTER")
        b.text:SetTextColor(unpack(C.blue))
        return b
    end

    local version = NewInfoBox(window, "BOTTOMLEFT", "BOTTOMLEFT", MARGIN)
    version.text:SetText(L["UI_VERSION"]:format(C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"))

    local status = NewInfoBox(version, "LEFT", "RIGHT", 8)
    window.status = status.text

    local edit = NewButton(window, L["UI_OPEN_EDIT_MODE"], boxW, 36, function() UVL:OpenEditMode() end)
    edit:SetPoint("LEFT", status, "RIGHT", 8, 0)
    edit.label:SetTextColor(unpack(C.blue))

    window:Hide()
    window:SetScript("OnShow", function()
        if selected then SelectModule(selected) end
    end)
end

function UVL:ToggleConfig()
    if window and window:IsShown() then
        window:Hide()
        return
    end
    if not self.activeLayout then
        Msg(L["UI_LAYOUT_PENDING"])
        return
    end
    if not window then CreateWindow() end
    window:Show()
end

function UVL:HideConfig()
    if window then window:Hide() end
end
