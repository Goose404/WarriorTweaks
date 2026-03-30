local ADDON_NAME = "WarriorTweaks"

--modules
local TTD = WarriorTweaksTTD

WarriorTweaks = {}
updateIntervalInSec = 0.2

local playerClass = string.upper(UnitClass('player'));
WarriorTweaks.addonName = 'WarriorTweaks'
WarriorTweaks.addonVersion = '2.0.0'

-- Interface MainFrame
WarriorTweaks.mainframe = CreateFrame("Frame","MainFrame",UIParent)
WarriorTweaks.mainframe:SetMovable(false)
WarriorTweaks.mainframe:EnableMouse(false)
WarriorTweaks.mainframe:SetWidth(100) 
WarriorTweaks.mainframe:SetHeight(100)
WarriorTweaks.mainframe:SetPoint("CENTER",0,0)
WarriorTweaks.mainframe:SetAlpha(.90);

-- Test Mode Variables
local testMode = false
local testExpiration = 0

local sunderSpellIDs = {
    [7386] = true,  -- Rank 1
    [7405] = true,  -- Rank 2
    [8380] = true,  -- Rank 3
    [11596] = true, -- Rank 4
    [11597] = true, -- Rank 5
}

local demoSpellIDs = {
    [1160] = true,  -- Rank 1
    [6190] = true,  -- Rank 2
    [11554] = true, -- Rank 3
    [11555] = true, -- Rank 4
    [11556] = true, -- Rank 5
}

local sunderDB = {} 
local demoDB = {}

local DebuffTracker = CreateFrame("Frame")
DebuffTracker:RegisterEvent("RAW_COMBATLOG")
DebuffTracker:RegisterEvent("UNIT_CASTEVENT")
DebuffTracker:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
DebuffTracker:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
DebuffTracker:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")
DebuffTracker:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE") 
DebuffTracker:RegisterEvent("PLAYER_REGEN_ENABLED")

local function GetFailedSpellAndTarget(text)
    local s, t
    _, _, s, t = string.find(text, "^Your (.-) was resisted by (.-)%.?$")
    if s then return s, t end
    _, _, s, t = string.find(text, "^Your (.-) missed (.-)%.?$")
    if s then return s, t end
    _, _, s, t = string.find(text, "^Your (.-) was dodged by (.-)%.?$")
    if s then return s, t end
    _, _, s, t = string.find(text, "^Your (.-) was parried by (.-)%.?$")
    if s then return s, t end
    _, _, s, t = string.find(text, "^Your (.-) failed%. (.-) is immune%.?$")
    if s then return s, t end
    _, _, s, t = string.find(text, "^Your (.-) failed%. (.-) is evading%.?$")
    if s then return s, t end
    return nil, nil
end

DebuffTracker:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_ENABLED" then
        sunderDB = {}
        demoDB = {}
        return
    end

    if event == "UNIT_CASTEVENT" then
        local casterGUID = arg1
        local targetGUID = arg2
        local castType = arg3
        local spellId = arg4
        
        if castType == "CAST" and spellId then
            if sunderSpellIDs[spellId] and targetGUID then
                if not sunderDB[targetGUID] then sunderDB[targetGUID] = {} end
                sunderDB[targetGUID].prevExpiration = sunderDB[targetGUID].expiration
                sunderDB[targetGUID].prevStacks = sunderDB[targetGUID].stacks
                sunderDB[targetGUID].expiration = GetTime() + 30
            elseif demoSpellIDs[spellId] then
                local tGuid = UnitExists("target")
                if tGuid then
                    if type(tGuid) ~= "string" then tGuid = UnitName("target") end
                    if UnitCanAttack("player", "target") then
                        if not demoDB[tGuid] then demoDB[tGuid] = {} end
                        demoDB[tGuid].prevExpiration = demoDB[tGuid].expiration
                        demoDB[tGuid].expiration = GetTime() + 30
                    end
                end
            end
        end
        return
    end

    local logEvent = event
    local logText = arg1
    local isRaw = false

    if event == "RAW_COMBATLOG" then
        isRaw = true
        logEvent = arg1
        logText = arg2
    end

    if not logText then return end

    if logEvent == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        local spellName, target = GetFailedSpellAndTarget(logText)
        if spellName and target then
            if spellName == "Demoralizing Shout" then
                if demoDB[target] then
                    demoDB[target].expiration = demoDB[target].prevExpiration
                    if not demoDB[target].expiration or demoDB[target].expiration < GetTime() then
                        demoDB[target] = nil 
                    end
                end
            elseif spellName == "Sunder Armor" then
                if sunderDB[target] then
                    sunderDB[target].expiration = sunderDB[target].prevExpiration
                    if sunderDB[target].prevStacks then
                        sunderDB[target].stacks = sunderDB[target].prevStacks
                    end
                    if not sunderDB[target].expiration or sunderDB[target].expiration < GetTime() then
                        sunderDB[target] = nil
                    end
                end
            end
        end
        return
    end

    if logEvent == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" or logEvent == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE" then
        local _, _, identifier, stacks = string.find(logText, "^(.+) is afflicted by Sunder Armor %((%d+)%).")
        if identifier and stacks then
            if not sunderDB[identifier] then sunderDB[identifier] = {} end
            sunderDB[identifier].stacks = tonumber(stacks)
            sunderDB[identifier].expiration = GetTime() + 30
            return
        end
        
        local _, _, singleIdentifier = string.find(logText, "^(.+) is afflicted by Sunder Armor.")
        if singleIdentifier then
            if not sunderDB[singleIdentifier] then sunderDB[singleIdentifier] = {} end
            sunderDB[singleIdentifier].stacks = 1
            sunderDB[singleIdentifier].expiration = GetTime() + 30
            return
        end

        local _, _, demoTarget = string.find(logText, "^(.+) is afflicted by Demoralizing Shout.")
        if demoTarget then
            if not demoDB[demoTarget] then demoDB[demoTarget] = {} end
            demoDB[demoTarget].expiration = GetTime() + 30
            return
        end
    end

    if logEvent == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then
        local _, _, fadeIdSunder = string.find(logText, "^(.+)'s Sunder Armor fades.")
        if fadeIdSunder and sunderDB[fadeIdSunder] then
            sunderDB[fadeIdSunder] = nil
            return
        end

        local _, _, fadeIdDemo = string.find(logText, "^(.+)'s Demoralizing Shout fades.")
        if fadeIdDemo and demoDB[fadeIdDemo] then
            demoDB[fadeIdDemo] = nil
            return
        end
    end

    if not isRaw and string.find(event, "CHAT_MSG_SPELL") then
        if string.find(logText, "uses Sunder Armor") then
            local tGuid = UnitExists("target")
            if tGuid then
                if type(tGuid) ~= "string" then tGuid = UnitName("target") end
                if not sunderDB[tGuid] then sunderDB[tGuid] = {} end
                sunderDB[tGuid].prevExpiration = sunderDB[tGuid].expiration
                sunderDB[tGuid].prevStacks = sunderDB[tGuid].stacks
                sunderDB[tGuid].expiration = GetTime() + 30
            end
        elseif string.find(logText, "uses Demoralizing Shout") then
            local tGuid = UnitExists("target")
            if tGuid and UnitCanAttack("player", "target") then
                if type(tGuid) ~= "string" then tGuid = UnitName("target") end
                if not demoDB[tGuid] then demoDB[tGuid] = {} end
                demoDB[tGuid].prevExpiration = demoDB[tGuid].expiration
                demoDB[tGuid].expiration = GetTime() + 30
            end
        end
    end
end)

-- setOpts
local function resetOpts()
    wt_opts = {
        ap_active = true,
        ap_point = "CENTER",
        ap_rel_point = "CENTER",
        ap_x_offset = 350,
        ap_y_offset = -100,
        BattleShout_active = true,
        BattleShout_threshold = 15, 
        BattleShout_point = "CENTER",
        BattleShout_rel_point = "CENTER",
        BattleShout_x_offset = 0,
        BattleShout_y_offset = -200,
        sunder_active = true,
        sunder_point = "CENTER",
        sunder_rel_point = "CENTER",
        sunder_x_offset = 300,
        sunder_y_offset = 100,
        demo_active = true,
        demo_point = "CENTER",
        demo_rel_point = "CENTER",
        demo_x_offset = 250,
        demo_y_offset = 100,
        ttd_active = true,
        ttd_point = "CENTER",
        ttd_rel_point = "CENTER",
        ttd_x_offset = 0,
        ttd_y_offset = -150,
        lock_frames = false,
        ttd_background = true,
    }
end

function wtprint(a)
    DEFAULT_CHAT_FRAME:AddMessage(" |cC69B6D4A[WarriorTweaks] |cffffffff" .. a)
end

local function createConfigGUI()
    local cfg = CreateFrame("Frame", "WarriorTweaksConfigFrame", UIParent)
    cfg:SetWidth(300)
    cfg:SetHeight(420)
    cfg:SetPoint("CENTER", 0, 0)
    cfg:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    cfg:SetMovable(true)
    cfg:EnableMouse(true)
    cfg:RegisterForDrag("LeftButton")
    cfg:SetScript("OnDragStart", function() cfg:StartMoving() end)
    cfg:SetScript("OnDragStop", function() cfg:StopMovingOrSizing() end)
    cfg:Hide()
    
    table.insert(UISpecialFrames, "WarriorTweaksConfigFrame")

    local title = cfg:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("Warrior Tweaks Options")
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")

    local function CreateCB(name, labelText, yOffset, optKey, callback)
        local cb = CreateFrame("CheckButton", "WTCB_"..name, cfg, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 20, yOffset)
        getglobal(cb:GetName().."Text"):SetText(labelText)
        cb:SetScript("OnShow", function()
            if wt_opts[optKey] then cb:SetChecked(1) else cb:SetChecked(nil) end
        end)
        cb:SetScript("OnClick", function()
            if cb:GetChecked() then wt_opts[optKey] = true else wt_opts[optKey] = false end
            if callback then callback() end
        end)
        return cb
    end

    CreateCB("AP", "Attack Power Tracker", -40, "ap_active")
    CreateCB("Sunder", "Sunder Armor Tracker", -70, "sunder_active")
    CreateCB("Demo", "Demoralizing Shout Tracker", -100, "demo_active")
    CreateCB("BS", "Battle Shout Tracker", -130, "BattleShout_active")
    CreateCB("TTD", "Time Till Death Tracker", -160, "ttd_active")
    CreateCB("TTDBG", "TTD Background", -190, "ttd_background", function()
        if TTD and TTD.ApplyBackground then TTD:ApplyBackground() end
    end)

    -- Slider for Battle Shout Threshold
    local bsSlider = CreateFrame("Slider", "WT_BSSlider", cfg, "OptionsSliderTemplate")
    bsSlider:SetPoint("TOPLEFT", 25, -240)
    bsSlider:SetWidth(250)
    bsSlider:SetMinMaxValues(1, 120)
    bsSlider:SetValueStep(1)
    getglobal(bsSlider:GetName().."Text"):SetText("Battle Shout Threshold")
    getglobal(bsSlider:GetName().."Low"):SetText("1s")
    getglobal(bsSlider:GetName().."High"):SetText("120s")
    
    local valText = bsSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    valText:SetPoint("TOP", bsSlider, "BOTTOM", 0, -3)
    
    bsSlider:SetScript("OnShow", function() 
        local v = wt_opts.BattleShout_threshold or 15
        bsSlider:SetValue(v) 
        valText:SetText(v.."s")
    end)
    bsSlider:SetScript("OnValueChanged", function()
        local v = math.floor(bsSlider:GetValue())
        wt_opts.BattleShout_threshold = v
        valText:SetText(v.."s")
    end)

    -- Lock Frames Button
    cfg.lockBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    cfg.lockBtn:SetWidth(120)
    cfg.lockBtn:SetHeight(22)
    cfg.lockBtn:SetPoint("BOTTOMLEFT", 20, 50)
    cfg.lockBtn:SetScript("OnShow", function() 
        if wt_opts.lock_frames then cfg.lockBtn:SetText("Unlock Frames") else cfg.lockBtn:SetText("Lock Frames") end
    end)
    cfg.lockBtn:SetScript("OnClick", function()
        wt_opts.lock_frames = not wt_opts.lock_frames
        WarriorTweaks:ApplyFrameLock()
        if wt_opts.lock_frames then cfg.lockBtn:SetText("Unlock Frames") else cfg.lockBtn:SetText("Lock Frames") end
    end)

    --Test Mode
    local showBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    showBtn:SetWidth(140)
    showBtn:SetHeight(22)
    showBtn:SetPoint("TOP", 0, -290)
    showBtn:SetText("Show Elements")
    showBtn:SetScript("OnShow", function()
        if testMode then showBtn:SetText("Hide Elements") else showBtn:SetText("Show Elements") end
    end)
    showBtn:SetScript("OnClick", function()
        testMode = not testMode
        if testMode then
            showBtn:SetText("Hide Elements")
            wt_opts.lock_frames = false -- Auto-Unlock!
            WarriorTweaks:ApplyFrameLock()
            if cfg.lockBtn then cfg.lockBtn:SetText("Lock Frames") end
            testExpiration = GetTime() + 30
        else
            showBtn:SetText("Show Elements")
        end
        updateAll() -- Force UI Update immediately
    end)

    local resetBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    resetBtn:SetWidth(120)
    resetBtn:SetHeight(22)
    resetBtn:SetPoint("BOTTOMRIGHT", -20, 50)
    resetBtn:SetText("Reset Defaults")
    resetBtn:SetScript("OnClick", function()
        resetOpts()
        ReloadUI()
    end)

    local closeBtn = CreateFrame("Button", nil, cfg, "UIPanelButtonTemplate")
    closeBtn:SetWidth(100)
    closeBtn:SetHeight(22)
    closeBtn:SetPoint("BOTTOM", 0, 20)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() cfg:Hide() end)
end

SLASH_WT1 = "/wt"
SlashCmdList["WT"] = function(cmd)
    if cmd == "reset" then
        resetOpts()
        ReloadUI()
        wtprint("Options resetted.")
    else
        if WarriorTweaksConfigFrame and WarriorTweaksConfigFrame:IsVisible() then
            WarriorTweaksConfigFrame:Hide()
        else
            WarriorTweaksConfigFrame:Show()
        end
    end
end

-- Frame Creation
function createBattleShoutFrame()
    WarriorTweaks.battleShoutFrame = CreateFrame("Frame",nil,MainFrame)
    WarriorTweaks.battleShoutFrame:SetMovable(true)
    WarriorTweaks.battleShoutFrame:EnableMouse(true)
    WarriorTweaks.battleShoutFrame:SetWidth(70) 
    WarriorTweaks.battleShoutFrame:SetHeight(70) 
    WarriorTweaks.battleShoutFrame:SetAlpha(.90)
    WarriorTweaks.battleShoutFrame:SetPoint("CENTER",0,-200)

    BSIcon = WarriorTweaks.battleShoutFrame:CreateTexture(nil, "BACKGROUND")
    BSIcon:SetWidth(70) 
    BSIcon:SetHeight(70) 
    BSIcon:SetPoint("CENTER", WarriorTweaks.battleShoutFrame, "CENTER", 0, 0)
    BSIcon:SetTexture("Interface\\Icons\\ability_warrior_battleshout")

    WarriorTweaks.battleShoutFrame.cooldown = CreateFrame("Model", "BSCooldownModel", WarriorTweaks.battleShoutFrame, "CooldownFrameTemplate")
    WarriorTweaks.battleShoutFrame.cooldown:ClearAllPoints()
    WarriorTweaks.battleShoutFrame.cooldown:SetHeight(70)
    WarriorTweaks.battleShoutFrame.cooldown:SetWidth(70)
    WarriorTweaks.battleShoutFrame.cooldown:SetModelScale(1.40)
    WarriorTweaks.battleShoutFrame.cooldown:SetPoint("CENTER", WarriorTweaks.battleShoutFrame, "CENTER", 0, 0)
    WarriorTweaks.battleShoutFrame.cooldown:SetFrameLevel(WarriorTweaks.battleShoutFrame:GetFrameLevel() + 1)

    WarriorTweaks.battleShoutFrame:RegisterForDrag("LeftButton")
    WarriorTweaks.battleShoutFrame:SetScript("OnDragStart", function() WarriorTweaks.battleShoutFrame:StartMoving() end)
    WarriorTweaks.battleShoutFrame:SetScript("OnDragStop", function()
        WarriorTweaks.battleShoutFrame:StopMovingOrSizing()
        local point, _, rel_point, x_offset, y_offset = WarriorTweaks.battleShoutFrame:GetPoint()
        if x_offset < 20 and x_offset > -20 then x_offset = 0 end
        wt_opts.BattleShout_point = point
        wt_opts.BattleShout_rel_point = rel_point
        wt_opts.BattleShout_x_offset = floor(x_offset / 1) * 1
        wt_opts.BattleShout_y_offset = floor(y_offset / 1) * 1
    end);
    WarriorTweaks.battleShoutFrame:Hide()
end

function createApFrame()
    WarriorTweaks.aPframe = CreateFrame("Frame",nil,MainFrame)
    WarriorTweaks.aPframe:SetMovable(true)
    WarriorTweaks.aPframe:EnableMouse(true)
    WarriorTweaks.aPframe:SetWidth(200) 
    WarriorTweaks.aPframe:SetHeight(80) 
    WarriorTweaks.aPframe:SetAlpha(.90);
    WarriorTweaks.aPframe:SetPoint("CENTER",350,-100)
    WarriorTweaks.aPframe.text = WarriorTweaks.aPframe:CreateFontString(nil,"ARTWORK") 
    WarriorTweaks.aPframe.text:SetFont("Fonts\\ARIALN.ttf", 24, "OUTLINE")
    WarriorTweaks.aPframe.text:SetPoint("LEFT",50,0)
    ApIcon = WarriorTweaks.aPframe:CreateTexture()
    ApIcon:SetWidth(40) 
    ApIcon:SetHeight(40) 
    ApIcon:SetPoint("LEFT", WarriorTweaks.aPframe, "LEFT", 0, 0)
    WarriorTweaks.aPframe:RegisterForDrag("LeftButton")
    WarriorTweaks.aPframe:SetScript("OnDragStart", function() WarriorTweaks.aPframe:StartMoving() end)
    WarriorTweaks.aPframe:SetScript("OnDragStop", function()
        WarriorTweaks.aPframe:StopMovingOrSizing()
        local point, _, rel_point, x_offset, y_offset = WarriorTweaks.aPframe:GetPoint()
        if x_offset < 20 and x_offset > -20 then x_offset = 0 end
        wt_opts.ap_point = point
        wt_opts.ap_rel_point = rel_point
        wt_opts.ap_x_offset = floor(x_offset / 1) * 1
        wt_opts.ap_y_offset = floor(y_offset / 1) * 1
    end);
    WarriorTweaks.aPframe:Hide()
end

function createSunderFrame()
    WarriorTweaks.sunderframe = CreateFrame("Frame",nil,MainFrame)
    WarriorTweaks.sunderframe:SetMovable(true)
    WarriorTweaks.sunderframe:EnableMouse(true)
    WarriorTweaks.sunderframe:SetWidth(70) 
    WarriorTweaks.sunderframe:SetHeight(40) 
    WarriorTweaks.sunderframe:SetAlpha(.90);
    WarriorTweaks.sunderframe:SetPoint("CENTER",300,100)

    WarriorTweaks.sunderframe.text = WarriorTweaks.sunderframe:CreateFontString(nil,"OVERLAY") 
    WarriorTweaks.sunderframe.text:SetFont("Fonts\\ARIALN.ttf", 24, "OUTLINE")
    WarriorTweaks.sunderframe.text:SetPoint("LEFT",50,0)

    SunderIcon = WarriorTweaks.sunderframe:CreateTexture(nil, "BACKGROUND")
    SunderIcon:SetWidth(40) 
    SunderIcon:SetHeight(40) 
    SunderIcon:SetPoint("LEFT", WarriorTweaks.sunderframe, "LEFT", 0, 0)
    SunderIcon:SetTexture("Interface\\Icons\\ability_warrior_sunder")

    WarriorTweaks.sunderframe.cooldown = CreateFrame("Model", "SunderCooldownModel", WarriorTweaks.sunderframe, "CooldownFrameTemplate")
    WarriorTweaks.sunderframe.cooldown:ClearAllPoints()
    WarriorTweaks.sunderframe.cooldown:SetHeight(40)
    WarriorTweaks.sunderframe.cooldown:SetWidth(40)
    WarriorTweaks.sunderframe.cooldown:SetModelScale(1)
    WarriorTweaks.sunderframe.cooldown:SetPoint("LEFT", WarriorTweaks.sunderframe, "LEFT", 0, -1)
    WarriorTweaks.sunderframe.cooldown:SetFrameLevel(WarriorTweaks.sunderframe:GetFrameLevel() + 1)

    WarriorTweaks.sunderframe:RegisterForDrag("LeftButton")
    WarriorTweaks.sunderframe:SetScript("OnDragStart", function() WarriorTweaks.sunderframe:StartMoving() end)
    WarriorTweaks.sunderframe:SetScript("OnDragStop", function()
        WarriorTweaks.sunderframe:StopMovingOrSizing()
        local point, _, rel_point, x_offset, y_offset = WarriorTweaks.sunderframe:GetPoint()
        if x_offset < 20 and x_offset > -20 then x_offset = 0 end
        wt_opts.sunder_point = point
        wt_opts.sunder_rel_point = rel_point
        wt_opts.sunder_x_offset = floor(x_offset / 1) * 1
        wt_opts.sunder_y_offset = floor(y_offset / 1) * 1
    end);
    WarriorTweaks.sunderframe:Hide()
end

function createDemoFrame()
    WarriorTweaks.demoframe = CreateFrame("Frame",nil,MainFrame)
    WarriorTweaks.demoframe:SetMovable(true)
    WarriorTweaks.demoframe:EnableMouse(true)
    WarriorTweaks.demoframe:SetWidth(40) 
    WarriorTweaks.demoframe:SetHeight(40) 
    WarriorTweaks.demoframe:SetAlpha(.90);
    WarriorTweaks.demoframe:SetPoint("CENTER",250,100)

    DemoIcon = WarriorTweaks.demoframe:CreateTexture(nil, "BACKGROUND")
    DemoIcon:SetWidth(40) 
    DemoIcon:SetHeight(40) 
    DemoIcon:SetPoint("CENTER", WarriorTweaks.demoframe, "CENTER", 0, 0)
    DemoIcon:SetTexture("Interface\\Icons\\ability_warrior_warcry")

    WarriorTweaks.demoframe.cooldown = CreateFrame("Model", "DemoCooldownModel", WarriorTweaks.demoframe, "CooldownFrameTemplate")
    WarriorTweaks.demoframe.cooldown:ClearAllPoints()
    WarriorTweaks.demoframe.cooldown:SetWidth(40)
    WarriorTweaks.demoframe.cooldown:SetHeight(40)
    --WarriorTweaks.demoframe.cooldown:SetModelScale(1.05)
    WarriorTweaks.demoframe.cooldown:SetPoint("CENTER", WarriorTweaks.demoframe, "CENTER", 0, 0)
    WarriorTweaks.demoframe.cooldown:SetFrameLevel(WarriorTweaks.demoframe:GetFrameLevel() + 1)

    WarriorTweaks.demoframe:RegisterForDrag("LeftButton")
    WarriorTweaks.demoframe:SetScript("OnDragStart", function() WarriorTweaks.demoframe:StartMoving() end)
    WarriorTweaks.demoframe:SetScript("OnDragStop", function()
        WarriorTweaks.demoframe:StopMovingOrSizing()
        local point, _, rel_point, x_offset, y_offset = WarriorTweaks.demoframe:GetPoint()
        if x_offset < 20 and x_offset > -20 then x_offset = 0 end
        wt_opts.demo_point = point
        wt_opts.demo_rel_point = rel_point
        wt_opts.demo_x_offset = floor(x_offset / 1) * 1
        wt_opts.demo_y_offset = floor(y_offset / 1) * 1
    end);
    WarriorTweaks.demoframe:Hide()
end

-- utility stuff
local function isTargetHostile()
    if UnitExists("target") and UnitCanAttack("player", "target") then      
        return true
    end
    return false
end

local lastSunderExpiration = 0
local lastDemoExpiration = 0
local lastBSExpiration = 0

-- Main Loop
function updateAll()
    -- TEST MODE LOGIC (Shows all frames and ignores combat status)
    if testMode then
        if wt_opts.ap_active then 
            APupdate(1, "|cffffffff AP 1337") 
        else 
            APupdate(2, "") 
        end
        
        if wt_opts.BattleShout_active then
            WarriorTweaks.battleShoutFrame:Show()
            local bsThresh = wt_opts.BattleShout_threshold or 15
            local bsExp = testExpiration - 30 + bsThresh
            if math.abs(lastBSExpiration - bsExp) > 0.5 then
                CooldownFrame_SetTimer(WarriorTweaks.battleShoutFrame.cooldown, bsExp - bsThresh, bsThresh, 1)
                lastBSExpiration = bsExp
            end
        else
            WarriorTweaks.battleShoutFrame:Hide()
        end
        
        if wt_opts.sunder_active then
            sunderUpdate(1, "5", testExpiration)
        else
            sunderUpdate(2, "0", 0)
        end
        
        if wt_opts.demo_active then
            demoUpdate(1, testExpiration)
        else
            demoUpdate(2, 0)
        end
        
        if wt_opts.ttd_active then
            if TTD and TTD.Show then TTD:Show() end
        else
            if TTD and TTD.Hide then TTD:Hide() end
        end
        return
    end

    -- NORMAL COMBAT LOGIC
    if UnitAffectingCombat("player") then
		if wt_opts.ap_active and isTargetHostile() then
            APupdate(1, displayString())
        else 
            APupdate(2, "")
        end
        if wt_opts.BattleShout_active then
            battleShoutUpdate(1)
        else
            battleShoutUpdate(2)
        end
        if wt_opts.sunder_active and isTargetHostile() then
            local sCount, sExp = sunderInfo()
            sunderUpdate(1, sCount, sExp)
        else
            sunderUpdate(2, "0", 0)
        end
        if wt_opts.demo_active and isTargetHostile() then
            local dActive, dExp = demoInfo()
            if dActive then
                demoUpdate(1, dExp)
            else
                demoUpdate(2, 0)
            end
        else
            demoUpdate(2, 0)
        end
        if wt_opts.ttd_active and isTargetHostile() then
            TTD:Update()
            TTD:Show()
        end
        if not isTargetHostile() then
            TTD:Hide()
            APupdate(2, "")
            sunderUpdate(2, "0", 0)
            demoUpdate(2, 0)
        end
	else --not in combat
        TTD:Hide()
		APupdate(2, "")
        battleShoutUpdate(2)
        sunderUpdate(2, "0", 0)
        demoUpdate(2, 0)
    end   
end

-- Sunder Cooldown Update Logik
function sunderUpdate(show, count, expiration)
    if show == 1 and count ~= "0" then
        WarriorTweaks.sunderframe.text:SetText(count)
        WarriorTweaks.sunderframe:Show()
        
        if expiration and expiration > 0 then
            if math.abs(lastSunderExpiration - expiration) > 0.5 then
                local startTime = expiration - 30
                CooldownFrame_SetTimer(WarriorTweaks.sunderframe.cooldown, startTime, 30, 1)
                lastSunderExpiration = expiration
            end
        else
            WarriorTweaks.sunderframe.cooldown:Hide()
            lastSunderExpiration = 0
        end
    else
        WarriorTweaks.sunderframe:Hide()
        lastSunderExpiration = 0
    end
end

function sunderInfo()
    local tGuid = UnitExists("target")
    if not tGuid then return "0", 0 end
    
    if type(tGuid) ~= "string" then tGuid = UnitName("target") end
    
    local now = GetTime()
    local clientStacks = 0
    local j = 1
    
    while true do
        local texture, count, _, spellId = UnitDebuff("target", j)
        if not texture then break end
        
        local isSunder = false
        if spellId and sunderSpellIDs[spellId] then
            isSunder = true 
        elseif string.find(string.lower(texture), "ability_warrior_sunder") then
            isSunder = true 
        end

        if isSunder then
            clientStacks = count or 1
            if not sunderDB[tGuid] then
                sunderDB[tGuid] = { stacks = clientStacks, expiration = now + 30 }
            elseif clientStacks > (sunderDB[tGuid].stacks or 0) then
                sunderDB[tGuid].stacks = clientStacks
                sunderDB[tGuid].expiration = now + 30
            else
                sunderDB[tGuid].stacks = clientStacks
            end
            break
        end
        j = j + 1
    end
    
    if sunderDB[tGuid] then
        if now <= (sunderDB[tGuid].expiration or 0) then
            return tostring(sunderDB[tGuid].stacks), sunderDB[tGuid].expiration
        else
            sunderDB[tGuid] = nil 
            return "0", 0
        end
    end

    return "0", 0 
end

-- Demo Shout Update Logik
function demoUpdate(show, expiration)
    if show == 1 then
        WarriorTweaks.demoframe:Show()
        
        if expiration and expiration > 0 then
            if math.abs(lastDemoExpiration - expiration) > 0.5 then
                local startTime = expiration - 30
                -- Demoshout timer prepare
                -- CooldownFrame_SetTimer(WarriorTweaks.demoframe.cooldown, startTime, 30, 1)
                lastDemoExpiration = expiration
            end
        else
            WarriorTweaks.demoframe.cooldown:Hide()
            lastDemoExpiration = 0
        end
    else
        WarriorTweaks.demoframe:Hide()
        lastDemoExpiration = 0
    end
end

function demoInfo()
    local tGuid = UnitExists("target")
    if not tGuid then return false, 0 end
    
    if type(tGuid) ~= "string" then tGuid = UnitName("target") end
    
    local now = GetTime()
    local isFound = false
    local j = 1
    
    while true do
        local texture, _, _, spellId = UnitDebuff("target", j)
        if not texture then break end
        
        local isDemo = false
        if spellId and demoSpellIDs[spellId] then
            isDemo = true 
        elseif string.find(string.lower(texture), "ability_warrior_warcry") then
            isDemo = true 
        end

        if isDemo then
            isFound = true
            if not demoDB[tGuid] then
                demoDB[tGuid] = { expiration = now + 30 }
            end
            break
        end
        j = j + 1
    end
    
    if isFound then
        return true, demoDB[tGuid].expiration
    end

    if demoDB[tGuid] then
        if now <= (demoDB[tGuid].expiration or 0) then
            return true, demoDB[tGuid].expiration
        else
            demoDB[tGuid] = nil 
            return false, 0
        end
    end

    return false, 0 
end

-- Battleshout Cooldown Logik
function getBuffDuration()
    local buffId = 0
    while GetPlayerBuff(buffId, "HELPFUL") >= 0 do
        local buffIndex = GetPlayerBuff(buffId, "HELPFUL")
        local texture = GetPlayerBuffTexture(buffIndex)
        local timeLeft = GetPlayerBuffTimeLeft(buffIndex)
        if string.find(texture, "BattleShout") then
           return timeLeft 
        end
        buffId = buffId + 1
    end
    return 254
end

function battleShoutUpdate(show)
    if show == 1 then
        local buffDuration = getBuffDuration()
        
        local threshold = wt_opts.BattleShout_threshold or 15
        
        if buffDuration ~= nil and buffDuration <= threshold then
            WarriorTweaks.battleShoutFrame:Show()
            
            local expiration = GetTime() + buffDuration
            if math.abs(lastBSExpiration - expiration) > 0.5 then
                local startTime = expiration - threshold
                CooldownFrame_SetTimer(WarriorTweaks.battleShoutFrame.cooldown, startTime, threshold, 1)
                lastBSExpiration = expiration
            end
        elseif buffDuration == 254 then
            WarriorTweaks.battleShoutFrame:Show()
            WarriorTweaks.battleShoutFrame.cooldown:Hide()
            lastBSExpiration = 0
        else
            WarriorTweaks.battleShoutFrame:Hide()
            lastBSExpiration = 0
        end   
    else
        WarriorTweaks.battleShoutFrame:Hide()
        lastBSExpiration = 0
    end
end

-- AttackPower Stuff
function APupdate(show, message)
    if show == 1 then
        WarriorTweaks.aPframe.text:SetText(message)
        WarriorTweaks.aPframe:Show()
    else
        WarriorTweaks.aPframe:Hide()
    end
end

function displayString()
    local ret
    ret = displayAP()
    return ret
end

function displayAP()
    local base, posBuff, negBuff = UnitAttackPower("player");
    local ap = base + posBuff + negBuff;
    
    if ap > 1800 then
        ApIcon:SetTexture("Interface\\Icons\\spell_nature_bloodlust")
        return "|cffff0000 AP "..ap 
    else
        return "|cffffffff AP "..ap 
    end
end

-- INIT
local function SetFramePosition(frame, opts_prefix)
    if not frame then return end
    local point = wt_opts[opts_prefix .. "_point"]
    local rel_point = wt_opts[opts_prefix .. "_rel_point"]
    local x_offset = wt_opts[opts_prefix .. "_x_offset"]
    local y_offset = wt_opts[opts_prefix .. "_y_offset"]
    frame:SetPoint(point, UIParent, rel_point, x_offset, y_offset)
end

function WarriorTweaks:ApplyFrameLock()
    if not wt_opts then return end
    local locked = wt_opts.lock_frames
    local frames = {
        WarriorTweaks.aPframe,
        WarriorTweaks.battleShoutFrame,
        WarriorTweaks.sunderframe,
        WarriorTweaks.demoframe,
        WarriorTweaks.ttdFrame,
    }
    for _, f in ipairs(frames) do
        if f then
            f:SetMovable(not locked)
            f:EnableMouse(not locked)
            if locked then
                f:RegisterForDrag()
            else
                f:RegisterForDrag("LeftButton")
            end
        end
    end
end

function WarriorTweaks:Init()
    createConfigGUI()
    createApFrame()
    createBattleShoutFrame()
    createSunderFrame()
    createDemoFrame()
    TTD:Create(MainFrame)

    if not wt_opts then
        resetOpts()
    else
        if wt_opts.lock_frames == nil then wt_opts.lock_frames = false end
        if wt_opts.ttd_background == nil then wt_opts.ttd_background = true end
        if wt_opts.demo_active == nil then wt_opts.demo_active = true end
        if wt_opts.BattleShout_threshold == nil then wt_opts.BattleShout_threshold = 15 end
        if not wt_opts.demo_point then
            wt_opts.demo_point = "CENTER"
            wt_opts.demo_rel_point = "CENTER"
            wt_opts.demo_x_offset = 250
            wt_opts.demo_y_offset = 100
        end

        SetFramePosition(WarriorTweaks.aPframe, "ap")
        SetFramePosition(WarriorTweaks.battleShoutFrame, "BattleShout")
        SetFramePosition(WarriorTweaks.sunderframe, "sunder")
        SetFramePosition(WarriorTweaks.demoframe, "demo")
        SetFramePosition(WarriorTweaks.ttdFrame, "ttd")
    end

    WarriorTweaks:ApplyFrameLock()
    if TTD and TTD.ApplyBackground then
        TTD:ApplyBackground()
    end
end

-- Timer function
local function UpdateTimer(interval)
    local time_elapsed = 0
    WarriorTweaks.mainframe:SetScript("OnUpdate", function()
        time_elapsed = time_elapsed + arg1 
        if time_elapsed >= interval then
            updateAll()
            time_elapsed = 0
        end
    end)
end

WarriorTweaks.mainframe:RegisterEvent("ADDON_LOADED")

-- Init Addon Functions
WarriorTweaks.mainframe:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cC69B6D4A Warrior Tweaks:|r Loaded. Type /wt to open options.",1,1,1)
            WarriorTweaks:Init()
            UpdateTimer(updateIntervalInSec)
        end
    end
end);