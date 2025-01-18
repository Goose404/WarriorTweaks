local ADDON_NAME = "WarriorTweaks"

WarriorTweaks = {}
updateIntervalInSec = 0.2

local playerClass = string.upper(UnitClass('player'));
WarriorTweaks.addonName = 'WarriorTweaks'
WarriorTweaks.addonVersion = '1.0.2'

-- Interface
WarriorTweaks.mainframe = CreateFrame("Frame","MainFrame",UIParent)
WarriorTweaks.mainframe:SetMovable(false)
WarriorTweaks.mainframe:EnableMouse(false)
WarriorTweaks.mainframe:SetWidth(100) 
WarriorTweaks.mainframe:SetHeight(100)
WarriorTweaks.mainframe:SetPoint("CENTER",0,0)
WarriorTweaks.mainframe:SetAlpha(.90);

-- setOpts
local function resetOpts()
    wt_opts = {
        -- AP options
        ap_active = true,
        ap_point = "CENTER",
        ap_rel_point = "CENTER",
        ap_x_offset = 350,
        ap_y_offset = -100,
        -- BS options
        BattleShout_active = true,
        BattleShout_point = "CENTER",
        BattleShout_rel_point = "CENTER",
        BattleShout_x_offset = 0,
        BattleShout_y_offset = -200,
        -- Sunder options
        sunder_active = true,
        sunder_point = "CENTER",
        sunder_rel_point = "CENTER",
        sunder_x_offset = 300,
        sunder_y_offset = 100,
    }
end

function wtprint(a)
    DEFAULT_CHAT_FRAME:AddMessage(" |cC69B6D4A[WarriorTweaks] |cffffffff" .. a)
end

-- Slashcommands
SLASH_WT1 = "/wt"
SlashCmdList["WT"] = function(cmd)
    if cmd then
        cmd = string.lower(cmd) -- convert to lowercase
        if string.sub(cmd, 1, 2) == 'ap' then
            if string.sub(cmd, 4, 6) == 'off' then
                wt_opts.ap_active = false
                wtprint('ap frame deactivated')
            else
                wt_opts.ap_active = true
                wtprint('ap frame activated')
            end
        end
        if string.sub(cmd, 1, 6) == 'sunder' then
            if string.sub(cmd, 8, 10) == 'off' then
                wt_opts.sunder_active = false
                wtprint('sunder frame deactivated')
            else
                wt_opts.sunder_active = true
                wtprint('sunder frame activated')
            end
        end
        if string.sub(cmd, 1, 2) == 'bs' then
            if string.sub(cmd, 4, 6) == 'off' then
                wt_opts.BattleShout_active = false
                wtprint('Battle Shout frame deactivated')
            else
                wt_opts.BattleShout_active = true
                wtprint('Battle Shout frame activated')
            end
        end
        if string.sub(cmd, 1, 5) == 'reset' then
            resetOpts()
            ReloadUI()
            wtprint('options resetted')
        end
        -- hints if input is invalid
        if string.sub(cmd, 1, 1) == "" then
            wtprint(WarriorTweaks.addonName .. ' |cffabd473v' .. WarriorTweaks.addonVersion .. '|cffffffff available commands:')
            wtprint("/wt reset - Resets all options to default and reloads UI")
            wtprint("/wt ap on - Activates AP frame")
            wtprint("/wt ap off - Deactivates AP frame")
            wtprint("/wt sunder on - Activates Sunder frame")
            wtprint("/wt sunder off - Deactivates Sunder frame")
            wtprint("/wt bs on - Activates Battle Shout frame")
            wtprint("/wt bs off - Deactivates Battle Shout frame")
        end
                
    end
end

-- Frame Creation
function createBattleShoutFrame()
    WarriorTweaks.battleShoutFrame = CreateFrame("Frame",nill,MainFrame)
    WarriorTweaks.battleShoutFrame = CreateFrame("Frame",nil,MainFrame)
    WarriorTweaks.battleShoutFrame:SetMovable(true)
    WarriorTweaks.battleShoutFrame:EnableMouse(true)
    WarriorTweaks.battleShoutFrame:SetWidth(70) 
    WarriorTweaks.battleShoutFrame:SetHeight(70) 
    WarriorTweaks.battleShoutFrame:SetAlpha(.90);
    WarriorTweaks.battleShoutFrame:SetPoint("CENTER",0,-200)
        -- create Icon textures
        BSIcon = WarriorTweaks.battleShoutFrame:CreateTexture()
        BSIcon:SetWidth(70) -- Size of the icon
        BSIcon:SetHeight(70) -- Size of the icon
        BSIcon:SetPoint("CENTER", WarriorTweaks.battleShoutFrame, "CENTER", 0, 0)
        BSIcon:SetTexture("Interface\\Icons\\ability_warrior_battleshout")
        -- frame moveable
    WarriorTweaks.battleShoutFrame:RegisterForDrag("LeftButton")
    WarriorTweaks.battleShoutFrame:SetScript("OnDragStart", function() WarriorTweaks.battleShoutFrame:StartMoving() end)
    WarriorTweaks.battleShoutFrame:SetScript("OnDragStop", function()
        WarriorTweaks.battleShoutFrame:StopMovingOrSizing()
        point, _, rel_point, x_offset, y_offset = WarriorTweaks.battleShoutFrame:GetPoint()
    
        if x_offset < 20 and x_offset > -20 then
            x_offset = 0
        end
    
        wt_opts.BattleShout_point = point
        wt_opts.BattleShout_rel_point = rel_point
        wt_opts.BattleShout_x_offset = floor(x_offset / 1) * 1
        wt_opts.BattleShout_y_offset = floor(y_offset / 1) * 1
    end);
    WarriorTweaks.battleShoutFrame:Hide()

end

function createApFrame()
    -- createFreame
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

    -- create Icon textures
    ApIcon = WarriorTweaks.aPframe:CreateTexture()
    ApIcon:SetWidth(40) -- Size of the icon
    ApIcon:SetHeight(40) -- Size of the icon
    ApIcon:SetPoint("LEFT", WarriorTweaks.aPframe, "LEFT", 0, 0)
    
    -- frame moveable
    WarriorTweaks.aPframe:RegisterForDrag("LeftButton")
    WarriorTweaks.aPframe:SetScript("OnDragStart", function() WarriorTweaks.aPframe:StartMoving() end)
    WarriorTweaks.aPframe:SetScript("OnDragStop", function()
        WarriorTweaks.aPframe:StopMovingOrSizing()
        point, _, rel_point, x_offset, y_offset = WarriorTweaks.aPframe:GetPoint()
    
        if x_offset < 20 and x_offset > -20 then
            x_offset = 0
        end
    
        wt_opts.ap_point = point
        wt_opts.ap_rel_point = rel_point
        wt_opts.ap_x_offset = floor(x_offset / 1) * 1
        wt_opts.ap_y_offset = floor(y_offset / 1) * 1
    end);
    WarriorTweaks.aPframe:Hide()
end

function createSunderFrame()
    -- createFreame
    WarriorTweaks.sunderframe = CreateFrame("Frame",nil,MainFrame)
    WarriorTweaks.sunderframe:SetMovable(true)
    WarriorTweaks.sunderframe:EnableMouse(true)
    WarriorTweaks.sunderframe:SetWidth(100) 
    WarriorTweaks.sunderframe:SetHeight(80) 
    WarriorTweaks.sunderframe:SetAlpha(.90);
    WarriorTweaks.sunderframe:SetPoint("CENTER",300,100)
    WarriorTweaks.sunderframe.text = WarriorTweaks.sunderframe:CreateFontString(nil,"ARTWORK") 
    WarriorTweaks.sunderframe.text:SetFont("Fonts\\ARIALN.ttf", 24, "OUTLINE")
    WarriorTweaks.sunderframe.text:SetPoint("LEFT",50,0)

    -- create Icon textures
    SunderIcon = WarriorTweaks.sunderframe:CreateTexture()
    SunderIcon:SetWidth(40) -- Size of the icon
    SunderIcon:SetHeight(40) -- Size of the icon
    SunderIcon:SetPoint("LEFT", WarriorTweaks.sunderframe, "LEFT", 0, 0)
    SunderIcon:SetTexture("Interface\\Icons\\ability_warrior_sunder")
    
    -- frame moveable
    WarriorTweaks.sunderframe:RegisterForDrag("LeftButton")
    WarriorTweaks.sunderframe:SetScript("OnDragStart", function() WarriorTweaks.sunderframe:StartMoving() end)
    WarriorTweaks.sunderframe:SetScript("OnDragStop", function()
        WarriorTweaks.sunderframe:StopMovingOrSizing()
        point, _, rel_point, x_offset, y_offset = WarriorTweaks.sunderframe:GetPoint()
    
        if x_offset < 20 and x_offset > -20 then
            x_offset = 0
        end
    
        wt_opts.sunder_point = point
        wt_opts.sunder_rel_point = rel_point
        wt_opts.sunder_x_offset = floor(x_offset / 1) * 1
        wt_opts.sunder_y_offset = floor(y_offset / 1) * 1
    end);
    WarriorTweaks.sunderframe:Hide()
end

-- utility stuff
local function isTargetHostile()
    if UnitExists("target") and UnitCanAttack("player", "target") then      
        return true
    end
    return false
end

-- Main Loop
function update()
    if UnitAffectingCombat("player") then
		if wt_opts.ap_active and isTargetHostile() then
            APupdate(1, displayString())
        end
        if wt_opts.BattleShout_active then
            battleShoutUpdate(1)
        end
        if wt_opts.sunder_active and isTargetHostile() then
            sunderUpdate(1,sunderInfo())
        end
        if not isTargetHostile() then
            APupdate(2, "")
            sunderUpdate(2,"")
        end
	else --not in combat
		APupdate(2, "")
        battleShoutUpdate(2)
        sunderUpdate(2,"")
    end   
end

-- Sunder stuff
function sunderUpdate(show, count)
    if show == 1 then
        WarriorTweaks.sunderframe.text:SetText(count)
        WarriorTweaks.sunderframe:Show()
    elseif show == 2 then
        WarriorTweaks.sunderframe:Hide()
    else
        WarriorTweaks.sunderframe:Hide()
    end
end

function sunderInfo()
    local stackCount = 0
    local i = 1
    while true do
        local name, count, _3, spellId = UnitDebuff("target", i)
        if not name then -- end loop, no more debuff found
            break
        end
        if spellId == 11597 then -- name isnt really the name, its the icon path. Yet it has the name in it
            stackCount = count or 1 -- no stack means 1
            return tostring(stackCount)
        end
        i = i + 1 -- check next
    end
    return "0" -- no sunder found
end

-- Battleshout stuff
function getBuffDuration()
    local buffId = 0
    while GetPlayerBuff(buffId, "HELPFUL") >= 0 do
        local buffIndex = GetPlayerBuff(buffId, "HELPFUL") -- changes UI-Buff-ID to Index
        local texture = GetPlayerBuffTexture(buffIndex)
        local timeLeft = GetPlayerBuffTimeLeft(buffIndex)
        
        if string.find(texture, "BattleShout") then
           return floor(timeLeft)
        end

        buffId = buffId + 1
    end
    return 254
end

function battleShoutUpdate(show)
    if show == 1 then
        buffDuration = getBuffDuration()
        if buffDuration ~= nil and buffDuration <= 15 then
            WarriorTweaks.battleShoutFrame:Show()
        elseif buffDuration == 254 then
            WarriorTweaks.battleShoutFrame:Show()
        else
            WarriorTweaks.battleShoutFrame:Hide()
        end   
    else
        WarriorTweaks.battleShoutFrame:Hide()
    end
end

-- AttackPower Stuff
function APupdate(show, message)
    if show == 1 then
        WarriorTweaks.aPframe.text:SetText(message)
        WarriorTweaks.aPframe:Show()
    elseif show == 2 then
        WarriorTweaks.aPframe:Hide()
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
        return "|cffff0000 AP "..ap -- Rot, wenn AP > 2000
    else
        ApIcon:SetTexture("interface\\icons\\inv_sword_48")
        return "|cffffffff AP "..ap --ap -- Weiß, wenn AP <= 2000
    end
end

-- INIT
local function SetFramePosition(frame, opts_prefix)
    if not frame then
        return
    end

    local point = wt_opts[opts_prefix .. "_point"]
    local rel_point = wt_opts[opts_prefix .. "_rel_point"]
    local x_offset = wt_opts[opts_prefix .. "_x_offset"]
    local y_offset = wt_opts[opts_prefix .. "_y_offset"]

    frame:SetPoint(point, UIParent, rel_point, x_offset, y_offset)
end

function WarriorTweaks:Init()
    createApFrame()
    createBattleShoutFrame()
    createSunderFrame()

    if not wt_opts then
        resetOpts()
    else
        SetFramePosition(WarriorTweaks.aPframe, "ap")
        SetFramePosition(WarriorTweaks.battleShoutFrame, "BattleShout")
        SetFramePosition(WarriorTweaks.sunderframe, "sunder")
    end
    
end

-- Timer function (int:interval in seconds)
local function UpdateTimer(interval)
    -- updateinterval in seconds
    local time_elapsed = 0
    WarriorTweaks.mainframe:SetScript("OnUpdate", function()
        time_elapsed = time_elapsed + arg1 -- arg1 is time since last frameupdate
        if time_elapsed >= interval then
            update()
            time_elapsed = 0
        end
    end)
end

-- Events
WarriorTweaks.mainframe:RegisterEvent("ADDON_LOADED")

-- Init Addon Functions
WarriorTweaks.mainframe:SetScript("OnEvent", function()
    if playerClass=="WARRIOR" then
        if event == "ADDON_LOADED" then
            if arg1 == ADDON_NAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cC69B6D4A Warrior Tweaks:|r Loaded",1,1,1)
                WarriorTweaks:Init()
                UpdateTimer(updateIntervalInSec)   
            end
        end        
    end
end);

