local addonName, UVL = ...

-- =====================================================================
-- Helpers partagés pour les modules à affichage texte (groupe, durabilité)
-- =====================================================================
local Text = {}
UVL.Text = Text

Text.OUTLINE_OPTIONS = {
    { text = "SET_OUTLINE_NONE",  value = "NONE" },
    { text = "SET_OUTLINE_THIN",  value = "OUTLINE" },
    { text = "SET_OUTLINE_THICK", value = "THICK" },
}

local OUTLINE_FLAGS = { NONE = "", OUTLINE = "OUTLINE", THICK = "THICKOUTLINE" }

function Text.Style(fontString, db, r, g, b)
    fontString:SetFont(STANDARD_TEXT_FONT, db.fontSize, OUTLINE_FLAGS[db.outline] or "OUTLINE")
    fontString:SetTextColor(r, g, b)
end

local TextMixin = {}

function TextMixin:Fit()
    local w, h = self.text:GetStringWidth(), self.text:GetStringHeight()
    self:SetSize(math.max(40, w + 16), math.max(20, h + 8))
end

--- r,g,b : couleur du texte ; alpha vient de db.alpha (0-100)
function TextMixin:SetStyle(db, r, g, b)
    Text.Style(self.text, db, r, g, b)
    self:SetAlpha(db.alpha / 100)
    self:Fit()
end

function TextMixin:SetLabel(str)
    self.text:SetText(str)
    self:Fit()
end

--- Visuel Edit Mode : fond sombre (actif) ou rougeâtre + texte grisé (désactivé)
function TextMixin:SetEditVisual(active)
    if active == nil then
        self:SetBackdropColor(0, 0, 0, 0)
    elseif active then
        self:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    else
        self:SetBackdropColor(0.3, 0.1, 0.1, 0.5)
        self.text:SetTextColor(0.5, 0.5, 0.5)
    end
end

function Text.Create(globalName)
    local f = CreateFrame("Frame", globalName, UIParent, "BackdropTemplate")
    f:SetBackdrop({ bgFile = "Interface/Tooltips/UI-Tooltip-Background" })
    f:SetBackdropColor(0, 0, 0, 0)
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    f.text:SetPoint("CENTER")
    f:SetSize(120, 40)
    return Mixin(f, TextMixin)
end

--- Aperçu pour l'interface de l'addon. sample(db) -> texte, r, g, b
function Text.CreatePreview(parent, module, sample)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    fs:SetPoint("CENTER")

    local preview = {}
    function preview:Update()
        local db = module.db
        if not db then return end
        local text, r, g, b = sample(db)
        Text.Style(fs, db, r, g, b)
        fs:SetText(text)
        fs:SetAlpha(db.enabled and db.alpha / 100 or 0.3)
    end
    return preview
end
