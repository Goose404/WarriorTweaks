local ADDON_NAME = "WarriorTweaks"

WarriorTweaks = {}

local playerClass = string.upper(UnitClass('player'));
WarriorTweaks.addonName = 'WarriorTweaks'
WarriorTweaks.addonVersion = '1.0.0'

-- Interface
WarriorTweaks.mainframe = CreateFrame("Frame","MainFrame",UIParent)
WarriorTweaks.mainframe:SetMovable(false)
WarriorTweaks.mainframe:EnableMouse(false)
WarriorTweaks.mainframe:SetWidth(4) 
WarriorTweaks.mainframe:SetHeight(4)
WarriorTweaks.mainframe:SetPoint("CENTER",0,0)

-- setOpts
local function resetOpts()
    wt_opts = {
        -- AP options
        ap_active = true,
        ap_point = "CENTER",
        ap_rel_point = "CENTER",
        ap_x_offset = 350,
        ap_y_offset = -100,
    }
end

function wtprint(a)
    DEFAULT_CHAT_FRAME:AddMessage(" |cC69B6D4A [WarriorTweaks] |cffffffff" .. a)
end

-- Slashcommands
SLASH_WT1 = "/wt"
SlashCmdList["WT"] = function(cmd)
    if cmd then
        cmd = string.lower(cmd) -- convert to lowercase
        if string.sub(cmd, 1, 2) == 'ap' then
            if string.sub(cmd, 4, 6) == 'off' then
                wt_opts.ap = false
                wtprint('ap frame deactivated')
            else
                wt_opts.ap = true
                wtprint('ap frame activated')
            end
        end
        if string.sub(cmd, 1, 5) == 'reset' then
            resetOpts()
            wtprint('options resetted')
        end
        -- hints if input is invalid
        if string.sub(cmd, 1, 1) == "" then
            wtprint(WarriorTweaks.addonName .. ' |cffabd473v' .. WarriorTweaks.addonVersion .. '|cffffffff available commands:')
            wtprint("/wt ap - Activates ap frame")
            wtprint("/wt ap off - Deactivates ap frame")
            wtprint("/wt reset - Resets everything to default")
        end
                
    end
end

function createApIcons()

end

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

function update()
    if UnitAffectingCombat("player") then
		APupdate(1, displayString())
        battleShoutUpdate(1)
	else --not in combat
		APupdate(2, "")
        battleShoutUpdate(2)
    end   
end

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
end

function battleShoutUpdate(show)
    if show == 1 then
        buffDuration = getBuffDuration()
        if buffDuration ~= nil and buffDuration <= 15 then
            WarriorTweaks.battleShoutFrame:Show()
        end
    else
        WarriorTweaks.battleShoutFrame:Hide()
    end
end

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

function WarriorTweaks:Init()
    createApFrame()
    createBattleShoutFrame()

    if not wt_opts then
        resetOpts()
    end
    if wt_opts.ap then
        WarriorTweaks.aPframe:SetPoint(wt_opts.ap_point, UIParent, wt_opts.ap_rel_point, wt_opts.ap_x_offset, wt_opts.ap_y_offset)
    end
    
end

-- Events
WarriorTweaks.mainframe:RegisterEvent("ADDON_LOADED")
WarriorTweaks.mainframe:RegisterEvent("UNIT_INVENTORY_CHANGED")
WarriorTweaks.mainframe:RegisterEvent("UNIT_AURA")

-- Init and Maintrigger
WarriorTweaks.mainframe:SetScript("OnEvent", function()
    if playerClass=="WARRIOR" then
        if event == "ADDON_LOADED" then
            if arg1 == ADDON_NAME then
                DEFAULT_CHAT_FRAME:AddMessage("|cC69B6D4A Warrior Tweaks:|r Loaded",1,1,1)
                WarriorTweaks:Init()   
            end
        end
        update()
    end
end);

