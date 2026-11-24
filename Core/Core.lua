local addonName, UVL = ...

UVL.GLOBAL       = "__global" -- clé DB des modules indépendants du layout
UVL.modules      = {}
UVL.moduleList   = {}
UVL.activeLayout = nil

--- Enregistre un module. Interface facultative :
--- Init, OnLayoutChanged, OnEnterEditMode, OnExitEditMode, Refresh, ApplyStyle,
--- OnEvent + events, settings (schéma), defaults, scope, CreatePreview.
function UVL:RegisterModule(key, module)
    if self.modules[key] then
        error(("UtilityViewerLog: module '%s' already registered"):format(key))
    end
    module.key = key
    self.modules[key] = module
    self.moduleList[#self.moduleList + 1] = module
end

local LEM
function UVL:GetLEM()
    LEM = LEM or LibStub("LibEditMode")
    return LEM
end

function UVL:IsEditing()
    return self:GetLEM():IsInEditMode()
end

--- Table de sauvegarde d'un module pour un layout, complétée avec ses défauts.
function UVL:GetModuleDB(layout, moduleKey, defaults)
    UtilityViewerLogDB = UtilityViewerLogDB or {}
    local root = UtilityViewerLogDB[layout]
    if not root then
        root = {}
        UtilityViewerLogDB[layout] = root
    end
    local db = root[moduleKey]
    if not db then
        db = {}
        root[moduleKey] = db
    end
    for k, v in pairs(defaults) do
        if db[k] == nil then
            db[k] = type(v) == "table" and CopyTable(v) or v
        end
    end
    return db
end

-- Un module qui plante ne doit jamais bloquer les autres
local function Call(module, method, ...)
    local fn = module[method]
    if fn then
        local ok, err = pcall(fn, module, ...)
        if not ok then geterrorhandler()(err) end
    end
end

local function OnLogin()
    local lem = UVL:GetLEM()
    local list = UVL.moduleList

    for _, m in ipairs(list) do
        if m.scope == "global" then
            m.db = UVL:GetModuleDB(UVL.GLOBAL, m.key, m.defaults)
        end
        Call(m, "Init", UVL, lem)
    end

    lem:RegisterCallback("enter", function()
        if UVL.HideConfig then UVL:HideConfig() end
        for _, m in ipairs(list) do Call(m, "OnEnterEditMode") end
    end)

    lem:RegisterCallback("exit", function()
        for _, m in ipairs(list) do Call(m, "OnExitEditMode") end
    end)

    lem:RegisterCallback("layout", function(layout, index)
        layout = layout or index -- nom nil : clé par index
        UVL.activeLayout = layout
        for _, m in ipairs(list) do
            if m.scope ~= "global" then
                m.db = UVL:GetModuleDB(layout, m.key, m.defaults)
                Call(m, "OnLayoutChanged", layout)
                Call(m, "Refresh")
            end
        end
    end)

    -- Un seul frame d'écoute ; chaque module ne reçoit que ses évènements
    local dispatch = {}
    local eventFrame = CreateFrame("Frame")
    for _, m in ipairs(list) do
        if m.events and m.OnEvent then
            for _, event in ipairs(m.events) do
                if not dispatch[event] then
                    dispatch[event] = {}
                    eventFrame:RegisterEvent(event)
                end
                local l = dispatch[event]
                l[#l + 1] = m
            end
        end
    end

    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if lem.isEditing then return end
        local listeners = dispatch[event]
        for i = 1, #listeners do
            local m = listeners[i]
            if m.db then
                local ok, err = pcall(m.OnEvent, m, event, ...)
                if not ok then geterrorhandler()(err) end
            end
        end
    end)

    for _, m in ipairs(list) do
        if m.scope == "global" then Call(m, "Refresh") end
    end
end

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    OnLogin()
end)

SLASH_UTILITYVIEWERLOG1 = "/uvl"
SLASH_UTILITYVIEWERLOG2 = "/utilityviewerlog"
SlashCmdList["UTILITYVIEWERLOG"] = function()
    UVL:ToggleConfig()
end
