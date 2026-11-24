local addonName, UVL = ...
local L = UVL.L

local Quest = {
    nameKey = "QUEST_NAME",
    descKey = "QUEST_DESC",
    hintKey = "QUEST_HINT",
    scope   = "global",
    defaults = {
        enabled    = true,
        autoAccept = true,
        autoTurnIn = true,
        autoGossip = true,
        rewardMode = "manual",
    },
}

Quest.settings = {
    { key = "enabled",    kind = "checkbox", label = "SET_ENABLE" },
    { key = "autoAccept", kind = "checkbox", label = "QUEST_SET_ACCEPT" },
    { key = "autoTurnIn", kind = "checkbox", label = "QUEST_SET_TURNIN" },
    { key = "autoGossip", kind = "checkbox", label = "QUEST_SET_GOSSIP" },
    { key = "rewardMode", kind = "dropdown", label = "QUEST_SET_REWARD",
      disabledIf = function(db) return not db.autoTurnIn end,
      options = {
          { text = "QUEST_REWARD_MANUAL", value = "manual" },
          { text = "QUEST_REWARD_PRICE",  value = "price" },
      } },
}

-- Options à ne jamais automatiser (téléportations accidentelles, etc.)
local IGNORE_GOSSIP = {
    [122442] = true,
    [44733]  = true,
    [125350] = true,
    [125351] = true,
    [131324] = true,
    [131325] = true,
}

local RED_PREFIX = "|cFFFF0000"
local DELAY = 0.2

local function IsQuestOption(option)
    local flags = Enum.GossipOptionRecFlags
    return FlagsUtil and flags and flags.QuestLabelPrepend
        and FlagsUtil.IsSet(option.flags, flags.QuestLabelPrepend)
end

local function IsSelectable(option)
    return option.gossipOptionID
        and not IGNORE_GOSSIP[option.gossipOptionID]
        and not (option.name and option.name:find(RED_PREFIX, 1, true))
end

-- Sélection d'un dialogue : option "quête" unique, sinon option unique sans quête proposée
local function SelectDialog()
    local options = C_GossipInfo.GetOptions()
    if not options or #options == 0 then return end

    local questOptions = {}
    for _, option in ipairs(options) do
        if IsSelectable(option) and IsQuestOption(option) then
            questOptions[#questOptions + 1] = option.gossipOptionID
        end
    end
    if #questOptions == 1 then
        C_GossipInfo.SelectOption(questOptions[1])
        return
    end
    if #questOptions > 1 then return end

    if C_GossipInfo.GetNumActiveQuests() + C_GossipInfo.GetNumAvailableQuests() > 0 then return end
    if #options ~= 1 or not IsSelectable(options[1]) then return end

    -- En instance de raid, uniquement en solo
    local _, instanceType = GetInstanceInfo()
    if instanceType == "raid" and GetNumGroupMembers() > 1 then return end

    C_GossipInfo.SelectOption(options[1].gossipOptionID)
end

local function BestPriceChoice(count)
    local best, bestPrice = nil, 0
    for i = 1, count do
        local link = GetQuestItemLink("choice", i)
        local price = link and select(11, C_Item.GetItemInfo(link)) or 0
        if price > bestPrice then
            best, bestPrice = i, price
        end
    end
    return best
end

local HANDLERS = {}

function HANDLERS.GOSSIP_SHOW(db)
    if db.autoTurnIn then
        for _, quest in ipairs(C_GossipInfo.GetActiveQuests()) do
            if quest.isComplete and quest.questID then
                C_GossipInfo.SelectActiveQuest(quest.questID)
                return
            end
        end
    end
    if db.autoAccept then
        for _, quest in ipairs(C_GossipInfo.GetAvailableQuests()) do
            if quest.questID then
                C_GossipInfo.SelectAvailableQuest(quest.questID)
                return
            end
        end
    end
    if db.autoGossip then
        SelectDialog()
    end
end

function HANDLERS.QUEST_GREETING(db)
    if db.autoTurnIn then
        for i = 1, GetNumActiveQuests() do
            local title, isComplete = GetActiveTitle(i)
            if title and isComplete then
                SelectActiveQuest(i)
                return
            end
        end
    end
    if db.autoAccept and GetNumAvailableQuests() > 0 then
        SelectAvailableQuest(1)
    end
end

function HANDLERS.QUEST_DETAIL(db)
    if not db.autoAccept then return end
    if QuestGetAutoAccept() then
        C_Timer.After(DELAY, function() CloseQuest() end)
    else
        C_Timer.After(DELAY, function() AcceptQuest() end)
    end
end

function HANDLERS.QUEST_PROGRESS(db)
    if db.autoTurnIn and IsQuestCompletable() then
        CompleteQuest()
    end
end

function HANDLERS.QUEST_COMPLETE(db)
    if not db.autoTurnIn then return end
    local count = GetNumQuestChoices()
    if count <= 1 then
        GetQuestReward(1)
    elseif db.rewardMode == "price" then
        local choice = BestPriceChoice(count)
        if choice then GetQuestReward(choice) end
    end
end

function HANDLERS.QUEST_AUTOCOMPLETE(db, questID)
    if db.autoTurnIn and questID then
        ShowQuestComplete(questID)
    end
end

Quest.events = {
    "GOSSIP_SHOW", "QUEST_GREETING", "QUEST_DETAIL",
    "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_AUTOCOMPLETE",
}

function Quest:OnEvent(event, ...)
    local db = self.db
    if not db.enabled or IsModifierKeyDown() then return end
    HANDLERS[event](db, ...)
end

UVL:RegisterModule("AutoQuest", Quest)
