-- Bluu :: OMLFarm  (split from Sb2-0mlg.lua)

-- ===================== OML AUTO FARM LOOP =====================
-- Floor 9 / Va' Rok: wait for load, detect the target mobs, let the autofarm kill them,
-- then teleport to the hub so the floor re-instances and we repeat.
local TeleportService = game:GetService('TeleportService')

local OML_TARGET_MOBS = {
    ['Undead Berserker'] = false,
    ['Mortis the Flaming Sear'] = true,
    ['Gold Chest'] = false,
}

local omlHopping = false

local function omlCountTargets()
    local n = 0
    for _, mob in ipairs(Mobs:GetChildren()) do
        if OML_TARGET_MOBS[mob.Name] and not isDead(mob) then
            n += 1
        end
    end
    return n
end

local function omlOtherPlayers()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr)
        end
    end
    return list
end

-- Kill every active toggle so we stop farming/moving while others are around.
local function omlDisableEverything()
    for _, toggle in next, Toggles do
        if toggle.Value then
            pcall(function() toggle:SetValue(false) end)
        end
    end
end

-- Any other player here -> stop everything, block them ALL (verified each), then hop servers.
local function omlBlockAllAndHop()
    if omlHopping then return end
    local others = omlOtherPlayers()
    if #others == 0 then return end

    omlHopping = true
    omlDisableEverything()
    Library:Notify(`[OML] {#others} player(s) detected - blocking & hopping.`, 5)

    for _, plr in ipairs(others) do
        if plr and plr.Parent then
            if not blockPlayer(plr) then
                warn(`[OML] Failed to block {plr.Name}`)
            end
            task.wait(1)
        end
    end

    TeleportService:Teleport(OML_RELOAD_PLACE, LocalPlayer)
end

if game.PlaceId == OML_FARM_PLACE then
    -- Safety monitor: react to anyone already here or joining mid-farm.
    task.spawn(function()
        Players.PlayerAdded:Connect(function()
            omlBlockAllAndHop()
        end)
        task.wait(1) -- let the game load, then sweep the current player list
        omlBlockAllAndHop()
    end)

    -- Farm loop (only runs while the server is ours).
    task.spawn(function()
        task.wait(1)

        -- Don't start farming if someone's already here; the monitor will block + hop.
        if omlHopping or #omlOtherPlayers() > 0 then return end

        -- wait until the target mobs actually exist (re-roll the server if they never show)
        Library:Notify('[OML] Waiting for target mobs...', 4)
        local waited = 0
        while not omlHopping and omlCountTargets() == 0 and waited < 90 do
            task.wait(1)
            waited += 1
        end
        if omlHopping then return end

        if omlCountTargets() > 0 then
            -- let the whole script kill them (Autofarm OnChanged is a blocking loop -> spawn it)
            Library:Notify('[OML] Targets found - farming!', 4)
            if Toggles.Killaura then
                task.spawn(function() Toggles.Killaura:SetValue(true) end)
            end
            if Toggles.Autofarm then
                task.spawn(function() Toggles.Autofarm:SetValue(true) end)
            end

            -- wait until all targets are dead / gone (bail instantly if the monitor takes over)
            while not omlHopping and omlCountTargets() > 0 do
                task.wait(0.1)
            end
            if omlHopping then return end
            Library:Notify('[OML] Targets cleared - teleporting to reload.', 4)
        else
            Library:Notify('[OML] No targets found - re-rolling server.', 4)
        end

        if omlHopping then return end
        omlHopping = true
        if Toggles.Autofarm then Toggles.Autofarm:SetValue(false) end
        if Toggles.Killaura then Toggles.Killaura:SetValue(false) end
        task.wait(0.1)
        TeleportService:Teleport(OML_RELOAD_PLACE, LocalPlayer)
    end)
end
