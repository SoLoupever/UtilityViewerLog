local addonName, UVL = ...
local L = UVL.L

-- =====================================================================
-- Schéma de réglages : déclaré UNE fois par module (module.settings),
-- utilisé pour la fenêtre Edit Mode ET pour l'interface de l'addon.
-- Entrée : { key, kind = "checkbox"|"slider"|"color"|"dropdown", label,
--   min, max, step, format, options = { {text, value} }, disabledIf(db) }
-- =====================================================================

local floor = math.floor

local function Round(value, step)
    step = step or 1
    return floor(value / step + 0.5) * step
end

function UVL:GetDB(module, layout)
    if module.scope == "global" or not layout then
        return module.db
    end
    return self:GetModuleDB(layout, module.key, module.defaults)
end

--- Écrit un réglage et répercute le changement sur le module actif.
function UVL:SetSetting(module, entry, value, layout)
    local db = self:GetDB(module, layout)
    if not db then return end

    if entry.kind == "slider" then
        value = Round(value, entry.step)
    end
    db[entry.key] = value

    if db ~= module.db then return end
    if module.ApplyStyle then module:ApplyStyle() end
    if self:IsEditing() then
        if module.OnEnterEditMode then module:OnEnterEditMode() end
    elseif module.Refresh then
        module:Refresh()
    end
    if self.OnSettingApplied then self:OnSettingApplied(module, entry) end
end

--- Remet les réglages du schéma aux valeurs par défaut (position conservée).
function UVL:ResetModule(module)
    local db = module.db
    if not db or not module.settings then return end
    for _, entry in ipairs(module.settings) do
        local v = module.defaults[entry.key]
        db[entry.key] = type(v) == "table" and CopyTable(v) or v
    end
    if module.ApplyStyle then module:ApplyStyle() end
    if self:IsEditing() then
        if module.OnEnterEditMode then module:OnEnterEditMode() end
    elseif module.Refresh then
        module:Refresh()
    end
    if self.OnSettingApplied then self:OnSettingApplied(module) end
end

--- Convertit le schéma d'un module en réglages LibEditMode.
function UVL:BuildLEMSettings(module)
    local lem = self:GetLEM()
    local T = lem.SettingType
    local out = {}

    for _, entry in ipairs(module.settings) do
        local key = entry.key
        local default = module.defaults[key]
        local s = { name = L[entry.label], default = default }

        s.get = function(layout)
            local db = UVL:GetDB(module, layout)
            local v = db and db[key]
            if entry.kind == "color" then
                v = v or default
                return CreateColor(v.r, v.g, v.b)
            end
            return v
        end

        if entry.kind == "checkbox" then
            s.kind = T.Checkbox
        elseif entry.kind == "slider" then
            s.kind      = T.Slider
            s.minValue  = entry.min
            s.maxValue  = entry.max
            s.valueStep = entry.step or 1
        elseif entry.kind == "color" then
            s.kind    = T.ColorPicker
            s.default = CreateColor(default.r, default.g, default.b)
        elseif entry.kind == "dropdown" then
            s.kind   = T.Dropdown
            s.values = {}
            for i, opt in ipairs(entry.options) do
                s.values[i] = { text = L[opt.text], value = opt.value }
            end
        end

        s.set = function(layout, value)
            if entry.kind == "color" then
                local r, g, b = value:GetRGB()
                value = { r = r, g = g, b = b }
            end
            UVL:SetSetting(module, entry, value, layout)
        end

        out[#out + 1] = s
    end

    return out
end

--- Enregistre le frame d'un module dans l'Edit Mode (position + réglages).
function UVL:RegisterEditFrame(module, frame, nameKey)
    local lem = self:GetLEM()
    local d = module.defaults

    lem:AddFrame(frame, function(_, layout, point, x, y)
        local db = UVL:GetDB(module, layout)
        db.point, db.x, db.y = point, x, y
    end, { point = d.point, x = d.x, y = d.y }, L[nameKey])

    lem:AddFrameSettings(frame, self:BuildLEMSettings(module))
end

function UVL:ApplyPosition(module, frame)
    local db = module.db
    frame:ClearAllPoints()
    frame:SetPoint(db.point, UIParent, db.point, db.x, db.y)
end
