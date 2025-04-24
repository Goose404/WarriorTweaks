local TTD = {
    History = {},               -- Speichert {time = zeit, health = gesundheit} Paare
    HadTargetLastUpdate = false,-- Hatten wir im letzten Frame ein gültiges Ziel?
    LastTargetMaxHealth = 0,    -- Max HP des Ziels im letzten Frame (0 wenn kein Ziel)
    WINDOW_DURATION = 5,        -- Zeitfenster in Sekunden für Durchschnittsberechnung (anpassbar)
    MIN_DATAPOINTS = 3,         -- Mindestanzahl Datenpunkte für stabile Berechnung (anpassbar)
    UPDATE_INTERVAL = 0.5,      -- Mindestintervall zum Speichern von Datenpunkten
    LastRecordTime = 0,         -- Zeitstempel der letzten Datenaufnahme
    -- Referenz auf das Text-Anzeige-Objekt (muss hier oder später zugewiesen werden)
    -- Beispiel: textFrame = nil
}
local frame, text
local lastHealth = 0
local lastUpdate = 0

function TTD:Create(parent)
    WarriorTweaks.ttdFrame = CreateFrame("Frame", "ttdframe", parent)
    frame = WarriorTweaks.ttdFrame
    frame:SetHeight(24)
    frame:SetWidth(100)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetPoint("CENTER",200,0)
    frame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.8)
    -- frame moveable
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() frame:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, rel_point, x_offset, y_offset = frame:GetPoint()
    
        if x_offset < 20 and x_offset > -20 then
            x_offset = 0
        end
    
        wt_opts.ttd_rel_point = point
        wt_opts.ttd_x_offset = floor(x_offset / 1) * 1
        wt_opts.ttd_y_offset = floor(y_offset / 1) * 1
    end);

    text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetText("TTD: N/A")

end

function TTD:Update()
    if not text then
        return
    end

    local now = GetTime()

    -- 1. Prüfen, ob aktuell ein gültiges Ziel existiert
    local currentTargetExists = UnitExists("target") and not UnitIsDead("target") and not UnitIsGhost("target")
    local currentMaxHealth = 0
    local currentHealth = 0

    if currentTargetExists then
        currentMaxHealth = UnitHealthMax("target")
        currentHealth = UnitHealth("target")
    end

    -- 2. Zielwechsel-Erkennung und Reset
    local resetNeeded = false
    if currentTargetExists ~= self.HadTargetLastUpdate then
        resetNeeded = true
    elseif currentTargetExists and currentMaxHealth ~= self.LastTargetMaxHealth then
        resetNeeded = true
    end

    self.HadTargetLastUpdate = currentTargetExists
    self.LastTargetMaxHealth = currentMaxHealth

    if resetNeeded then
        self.History = {}
        self.LastRecordTime = 0
        if currentTargetExists then
            text:SetText("TTD: Calc...")
            table.insert(self.History, { time = now, health = currentHealth })
            self.LastRecordTime = now
        else
            text:SetText("TTD: N/A")
        end
        return
    end

    if not currentTargetExists then
         text:SetText("TTD: N/A")
         return
    end

    -- 4. Datenpunkt hinzufügen (Intervall-basiert + Gesundheitsänderung)
    local addData = false
    if now - self.LastRecordTime >= self.UPDATE_INTERVAL then
        -- Verwende table.getn() statt #
        if table.getn(self.History) == 0 then
             addData = true
        else
            -- Verwende table.getn() statt #
            local lastEntry = self.History[table.getn(self.History)]
            if lastEntry.health ~= currentHealth then
                 addData = true
            end
        end
    end

    if addData then
        table.insert(self.History, { time = now, health = currentHealth })
        self.LastRecordTime = now
        -- print("TTD: Added data point. Count:", table.getn(self.History)) -- Debug mit table.getn()
    end

    -- 5. Alte Datenpunkte entfernen
    local oldestTimeAllowed = now - self.WINDOW_DURATION
    -- Verwende table.getn() statt #
    while table.getn(self.History) > 0 and self.History[1].time < oldestTimeAllowed do
        table.remove(self.History, 1)
    end

    -- 6. Genug Daten für eine Berechnung vorhanden?
    -- Verwende table.getn() statt #
    if table.getn(self.History) < self.MIN_DATAPOINTS then
        text:SetText("TTD: Calc...")
        return
    end

    -- 7. Durchschnitts-DPS berechnen
    local oldestEntry = self.History[1]
    -- Verwende table.getn() statt #
    local newestEntry = self.History[table.getn(self.History)]

    if newestEntry.time == oldestEntry.time then
        text:SetText("TTD: Calc...")
        return
    end

    local healthAtStartOfWindow = oldestEntry.health
    local healthAtEndOfWindow = newestEntry.health
    local totalDeltaTime = newestEntry.time - oldestEntry.time
    local totalDamage = healthAtStartOfWindow - healthAtEndOfWindow

    if totalDeltaTime > 0.5 and totalDamage > 0 then
        local averageDPS = totalDamage / totalDeltaTime
        local timeToDie = currentHealth / averageDPS

        if timeToDie < 0 or timeToDie > 3600 then -- Plausibilitätscheck (z.B. nicht länger als 1 Stunde)
            text:SetText("TTD: --")
        else
            -- Berechne Minuten und Sekunden
            local minutes = math.floor(timeToDie / 60)
            local seconds = math.floor(math.mod(timeToDie, 60))
            -- Formatiere als mm:ss mit führenden Nullen
            text:SetText(string.format("%02d:%02d", minutes, seconds))
            -- *************************
        end
    elseif totalDamage <= 0 and totalDeltaTime > 0.5 then
        text:SetText("TTD: ---")
    else
        text:SetText("Calc...")
    end
end

function TTD:Show()
    if frame then frame:Show() end
end

function TTD:Hide()
    if frame then frame:Hide() end
end

function TTD:IsVisible()
    return frame and frame:IsVisible()
end

-- wichtig für externen Zugriff
WarriorTweaksTTD = TTD
