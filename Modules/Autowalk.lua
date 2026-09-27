-- Bluu :: Autowalk  (split from Sb2-0mlg.lua)

local Autowalk = Farming:AddTab('Autowalk')

local autowalkRayParams = RaycastParams.new()
autowalkRayParams.FilterType = Enum.RaycastFilterType.Exclude
autowalkRayParams.IgnoreWater = true

local autowalkStrafeBias = 0
local autowalkClearTime = 0
local autowalkLastPos
local autowalkStuckFor = 0
local autowalkStrafeUntil = 0

local autowalkProbe = function(origin, dir, angleDeg, dist)
    local rotated = (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(0, math.rad(angleDeg), 0)).LookVector
    local hit = workspace:Raycast(origin, rotated * dist, autowalkRayParams)
    return rotated, hit and (hit.Position - origin).Magnitude or dist
end

local UpdateAutowalkTarget = function()
    local target
    local radius = Options.AutofarmRadius.Value
    radius = (radius == Options.AutofarmRadius.Max) and math.huge or radius
    local distance = radius
    local prioritizedDistance = distance
    for _, mob in next, Mobs:GetChildren() do
        if Options.IgnoreMobs.Value[mob.Name] then continue end
        if isDead(mob) then continue end
        if not assistRequirement(mob) then continue end
        if Toggles.UseWaypoint.Value and (mob.HumanoidRootPart.Position - waypoint.Position).Magnitude > radius then continue end

        local newDistance = (mob.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
        if Options.PrioritizeMobs.Value[mob.Name] then
            if newDistance < prioritizedDistance then
                prioritizedDistance = newDistance
                target = mob
            end
        elseif not (target and Options.PrioritizeMobs.Value[target.Name]) then
            if newDistance < distance then
                distance = newDistance
                target = mob
            end
        end
    end

    if not target then return end

    local rootPart = target.HumanoidRootPart
    local targetPos = rootPart.CFrame.Position
    if rootPart:FindFirstChild('BodyVelocity') and rootPart.BodyVelocity.VectorVelocity.Magnitude > 0 then
        targetPos += rootPart.BodyVelocity.VectorVelocity.Unit
    end

    local horizontalOffset = Options.AutowalkHorizontalOffset.Value

    local myPosition = HumanoidRootPart.CFrame.Position

    if horizontalOffset == Options.AutowalkHorizontalOffset.Max then
        local targetSize = rootPart.Size
        local boundingRadius = math.max(targetSize.X, targetSize.Z) * 0.5 + 19
        local targetY, myY = targetPos.Y, myPosition.Y
        local verticalOffset = targetY > myY and targetY - myY or myY - targetY
        horizontalOffset = math.sqrt(boundingRadius ^ 2 - verticalOffset ^ 2)
    end

    if horizontalOffset > 0 then
        local difference = myPosition - targetPos
        difference -= Vector3.new(0, difference.Y, 0)
        if difference.Magnitude ~= 0 then
            targetPos += difference.Unit * horizontalOffset
        end
    end

    return targetPos, target
end

local getAutowalkDirection = function(destPos, deltaTime)
    local rootPos = HumanoidRootPart.Position
    local flatDiff = Vector3.new(destPos.X - rootPos.X, 0, destPos.Z - rootPos.Z)
    if flatDiff.Magnitude < 2.5 then return end
    local dir = flatDiff.Unit

    local filter = { Character, Mobs }
    for _, player in next, Players:GetPlayers() do
        if player.Character then table.insert(filter, player.Character) end
    end
    autowalkRayParams.FilterDescendantsInstances = filter

    local grounded = Humanoid.FloorMaterial ~= Enum.Material.Air
    local hit = workspace:Raycast(rootPos, dir * 4.5, autowalkRayParams)

    if hit then
        -- low obstacle → hop it; tall wall → strafe around the more open side
        local overhead = workspace:Raycast(rootPos + Vector3.new(0, 6, 0), dir * 4.5, autowalkRayParams)
        if not overhead then
            if grounded then Humanoid.Jump = true end
        else
            if autowalkStrafeBias == 0 then
                local _, leftClear = autowalkProbe(rootPos, dir, -55, 4.5)
                local _, rightClear = autowalkProbe(rootPos, dir, 55, 4.5)
                autowalkStrafeBias = leftClear > rightClear and -1 or 1
            end
            local strafeDir, strafeClear = autowalkProbe(rootPos, dir, autowalkStrafeBias * 55, 4.5)
            if strafeClear < 2 then
                strafeDir = autowalkProbe(rootPos, dir, autowalkStrafeBias * 90, 4.5)
            end
            dir = strafeDir
            autowalkClearTime = 0
        end
    else
        autowalkClearTime += deltaTime
        if autowalkClearTime > 0.5 then
            autowalkStrafeBias = 0
        end
    end

    -- wedged on something → force a hard strafe for a moment
    if grounded and autowalkLastPos then
        if (rootPos - autowalkLastPos).Magnitude < Humanoid.WalkSpeed * deltaTime * 0.2 then
            autowalkStuckFor += deltaTime
            if autowalkStuckFor > 0.7 then
                if autowalkStrafeBias == 0 then autowalkStrafeBias = 1 end
                autowalkStrafeUntil = os.clock() + 0.6
                Humanoid.Jump = true
                autowalkStuckFor = 0
            end
        else
            autowalkStuckFor = 0
        end
    end
    autowalkLastPos = rootPos

    if os.clock() < autowalkStrafeUntil then
        dir = (CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(0, math.rad(90 * autowalkStrafeBias), 0)).LookVector
    end

    -- gap/cliff ahead → hop it
    if grounded and not workspace:Raycast(rootPos + dir * 2.5, Vector3.new(0, -8, 0), autowalkRayParams) then
        Humanoid.Jump = true
    end

    return dir
end

Autowalk:AddToggle('Autowalk', { Text = 'Enabled' }):OnChanged(function()
    toggleLerp(Toggles.Autowalk)
    enableLinearVelocity(false)
    Humanoid.AutoRotate = false
    local destPos
    local shouldRefreshTarget = true
    local target
    while Toggles.Autowalk.Value do
        local deltaTime = RenderStepped:Wait()

        if Humanoid.Health == 0 then continue end

        if not (controls.D - controls.A == 0 and controls.S - controls.W == 0) then
            continue
        end

        if shouldRefreshTarget then
            shouldRefreshTarget = false
            task.spawn(function()
                destPos, target = UpdateAutowalkTarget()
            end)
            task.delay(0.3, function()
                shouldRefreshTarget = true
            end)
        end

        if not target then
            if not Toggles.UseWaypoint.Value then continue end
        elseif target ~= waypoint and isDead(target) or Options.IgnoreMobs.Value[target.Name] then
            shouldRefreshTarget = true
            continue
        end

        local moveDir
        if destPos then
            if Toggles.Pathfind.Value then
                moveDir = getAutowalkDirection(destPos, deltaTime)
            else
                local flatDiff = destPos - HumanoidRootPart.Position
                flatDiff = Vector3.new(flatDiff.X, 0, flatDiff.Z)
                if flatDiff.Magnitude > 2.5 then
                    moveDir = flatDiff.Unit
                end
            end
        end
        if moveDir then
            LocalPlayer:Move(moveDir)
        end

        -- face the mob (or travel direction when idle) with a smooth turn
        -- instead of instantly snapping rotation when the target switches
        local lookTarget
        if target and target ~= waypoint then
            lookTarget = target.HumanoidRootPart.Position
        elseif moveDir then
            lookTarget = HumanoidRootPart.Position + moveDir
        end
        if lookTarget then
            local rootPos = HumanoidRootPart.Position
            local goal = CFrame.lookAt(rootPos, Vector3.new(lookTarget.X, rootPos.Y, lookTarget.Z))
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame:Lerp(goal, math.clamp(deltaTime * 7, 0, 1))
        end
    end
    Humanoid.AutoRotate = true
end)

Autowalk:AddToggle('Pathfind', { Text = 'Pathfind', Default = true })
Autowalk:AddSlider('AutowalkHorizontalOffset', {
    Text = 'Horizontal offset',
    Default = 30,
    Min = 0,
    Max = 30,
    Rounding = 0,
    Suffix = 'm',
    FormatDisplayValue = function(slider, value)
        if value == slider.Max then return 'Auto' end
	end
})
Autowalk:AddLabel('Remaining settings in Autofarm')
