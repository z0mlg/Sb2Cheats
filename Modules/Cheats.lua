-- Bluu :: Cheats  (split from Sb2-0mlg.lua)

local AdditionalCheats = Main:AddRightGroupbox('Additional cheats')

if RequiredServices then
    local SetSprintingOld = RequiredServices.Actions.SetSprinting
    local isSprinting = false
    RequiredServices.Actions.SetSprinting = function(enabled)
        if not Toggles.NoSprintAndRollCost.Value then
            SetSprintingOld(enabled)
            enabled = Humanoid.WalkSpeed ~= Character:GetAttribute('Walkspeed') and Humanoid.WalkSpeed ~= Options.WalkSpeed.Value
        end

        isSprinting = enabled
        Humanoid.WalkSpeed = enabled and Options.SprintSpeed.Value or Options.WalkSpeed.Value

        if Toggles.NoSprintAndRollCost.Value then
            RequiredServices.Graphics.DoEffect('Sprint Trail', { Enabled = enabled, Character = Character })
            Event:FireServer('Actions', { 'Sprint', enabled and 'Enabled' or 'Disabled' })
        end
    end

    local rollSkillHandler = RequiredServices.Skills.skillHandlers.Roll
    local rollCost = Skills.Roll.Cost.Value

    AdditionalCheats:AddToggle('NoSprintAndRollCost', { Text = 'No sprint & roll cost' })
    :OnChanged(function(value)
        debug.setconstant(rollSkillHandler, 6, value and '' or 'UseSkill')
        Skills.Roll.Cost.Value = value and 0 or rollCost
    end)

    AdditionalCheats:AddSlider('SprintSpeed', {
        Text = 'Sprint speed',
        Default = 27,
        Min = 27,
        Max = 100,
        Rounding = 0,
        Suffix = 'mps',
        FormatDisplayValue = function(slider, value)
            if value == slider.Min then return 'Default' end
        end
    })

    AdditionalCheats:AddSlider('WalkSpeed', { Text = 'Walk speed', Default = 20, Min = 20, Max = 100, Rounding = 0, Suffix = 'mps' })
    :OnChanged(function(value)
        if not isSprinting then
            Humanoid.WalkSpeed = value
        end
    end)
else
    UserInputService.InputEnded:Connect(function(key, gameProcessed)
        if gameProcessed or key.KeyCode.Name ~= Profile.Settings.SprintKey.Value then return end
        Humanoid.WalkSpeed = Options.WalkSpeed.Value
    end)

    AdditionalCheats:AddSlider('WalkSpeed', { Text = 'Walk speed', Default = 20, Min = 20, Max = 100, Rounding = 0, Suffix = 'mps' })
    :OnChanged(function(value)
        Humanoid.WalkSpeed = value
    end)
end

AdditionalCheats:AddToggle('Fly', { Text = 'Fly' }):OnChanged(function()
    toggleLerp(Toggles.Fly)
    enableLinearVelocity(Toggles.Fly.Value)
    while Toggles.Fly.Value do
        local deltaTime = task.wait()
        if not (controls.D - controls.A == 0 and controls.S - controls.W == 0) then
            local flySpeed = 80 -- math.max(Humanoid.WalkSpeed, 60)
            local targetPos = Camera.CFrame.Rotation
                * Vector3.new(controls.D - controls.A, 0, controls.S - controls.W)
                * flySpeed * deltaTime
            HumanoidRootPart.CFrame += targetPos
                * math.clamp(deltaTime * flySpeed / targetPos.Magnitude, 0, 1)
            continue
        end
    end
end)

AdditionalCheats:AddToggle('Noclip', { Text = 'Noclip' }):OnChanged(function()
    toggleNoclip(Toggles.Noclip)
end)

AdditionalCheats:AddToggle('ClickTeleport', { Text = 'Click teleport' }):OnChanged((function()
    local mouse = LocalPlayer:GetMouse()
    local Button1DownConnection
    local teleporting = false
    local onButton1Down = function()
        if not Toggles.ClickTeleport.Value then return end
        if teleporting then return end
        teleporting = true
        HumanoidRootPart.CFrame = HumanoidRootPart.CFrame.Rotation + mouse.Hit.Position + Vector3.new(0, 3, 0)
        teleporting = false
    end
    return function(value)
        toggleLerp(Toggles.ClickTeleport)
        enableLinearVelocity(false)
        if value then
            if Button1DownConnection then return end
            Button1DownConnection = mouse.Button1Down:Connect(onButton1Down)
        elseif Button1DownConnection then
            Button1DownConnection:Disconnect()
            Button1DownConnection = nil
        end
    end
end)())

local mapTeleports = {}

AdditionalCheats:AddDropdown('MapTeleports', { Text = 'Map teleports', Values = { 'Spawn' }, AllowNull = true })
:OnChanged(function(value)
    if not value then return end
    Options.MapTeleports:SetValue()

    local disabledToggle = toggleLerp()

    if value == 'Spawn' then
        Event:FireServer('Checkpoints', { 'TeleportToSpawn' })
    elseif firetouchinterest then
        firetouchinterest(HumanoidRootPart, mapTeleports[value], 0)
        firetouchinterest(HumanoidRootPart, mapTeleports[value], 1)
    end

    if disabledToggle then
        task.wait()
        awaitEventTimeout(HumanoidRootPart:GetPropertyChangedSignal('CFrame'), function()
            return true
        end, 0.5)
        disabledToggle:SetValue(true)
    end
end)

local mobSpawns = {}
local mobSpawnLabels = {}
do
    local index = 1
    for _, instance in next, workspace:GetChildren() do
        if not instance.Name:find("ASpawn") then
            continue
        end
        mobSpawns[instance.Name] = instance.WorldPivot
        mobSpawnLabels[index] = instance.Name
        index += 1
    end
end


AdditionalCheats:AddDropdown('MapMobSpawns', { Text = 'Map mob spawns', Values = mobSpawnLabels, AllowNull = true })
:OnChanged(function(value)
    if not value then return end
    Options.MapMobSpawns:SetValue()

    local disabledToggle = toggleLerp()

    HumanoidRootPart.CFrame = mobSpawns[value]

    if disabledToggle then
        disabledToggle:SetValue(true)
    end
end)

task.spawn(function()
    local mapTeleportLabels = ({
        [542351431] = { -- floor 1
            Boss = Vector3.new(-2942.51099, -125.638321, 336.995087),
            Portal = Vector3.new(-2940.8562, -207.597794, 982.687012),
            Miniboss = Vector3.new(139.343933, 225.040985, -132.926147)
        },
        [548231754] = { -- floor 2
            Boss = Vector3.new(-2452.30371, 411.394135, -8925.62598),
            Portal = Vector3.new(-2181.09204, 466.482727, -8955.31055)
        },
        [555980327] = { -- floor 3
            Boss = Vector3.new(448.331146, 4279.3374, -385.050385),
            Portal = Vector3.new(-381.196564, 4184.99902, -327.238312)
        },
        [572487908] = { -- floor 4
            Boss = Vector3.new(-2318.12964, 2280.41992, -514.067749),
            Portal = Vector3.new(-2319.54028, 2091.30078, -106.37648),
            Miniboss = Vector3.new(-1361.35596, 5173.21387, -390.738007)
        },
        [580239979] = { -- floor 5
            Boss = Vector3.new(2189.17822, 1308.125, -121.071182),
            Portal = Vector3.new(2188.29614, 1255.37036, -407.864594)
        },
        [582198062] = { -- floor 7
            Boss = Vector3.new(3347.78955, 800.043884, -804.310425),
            Portal = Vector3.new(3336.35645, 747.824036, -614.307983)
        },
        [548878321] = { -- floor 8
            Boss = Vector3.new(1848.35413, 4110.43945, 7723.38623),
            Portal = Vector3.new(1665.46252, 4094.20312, 7722.29443),
            Miniboss = Vector3.new(-811.7854, 3179.59814, -949.255676)
        },
        [573267292] = { -- floor 9
            Boss = Vector3.new(12241.4648, 461.776215, -3655.09009),
            Portal = Vector3.new(12357.0059, 439.948914, -3470.23218),
            Miniboss = Vector3.new(-255.197311, 3077.04272, -4604.19238),
            ['Second miniboss'] = Vector3.new(1973.94238, 2986.00952, -4486.8125)
        },
        [2659143505] = { -- floor 10
            Boss = Vector3.new(45.494194, 1003.77246, 25432.9902),
            Portal = Vector3.new(110.383698, 940.75531, 24890.9922),
            Miniboss = Vector3.new(-894.185791, 467.646698, 6505.85254)
        },
        [5287433115] = { -- floor 11
            Boss = Vector3.new(4916.49414, 2312.97021, 7762.28955),
            Portal = Vector3.new(5224.18994, 2602.94019, 6438.44678),
            Miniboss = Vector3.new(4801.12695, 1646.30347, 2083.19116),
            ['Za, the Eldest'] = Vector3.new(4001.55908, 421.515015, -3794.19727),
            ['Wa, the Curious'] = Vector3.new(4821.5874, 3226.32788, 5868.81787),
            ['Duality Reaper  '] = Vector3.new(4763.06934, 501.713593, -4344.83838),
            ['Neon chest       '] = Vector3.new(5204.35449, 2294.14502, 5778.00195)
        },
        [6144637080] = { -- floor 12
            ['Suspended Unborn'] = Vector3.new(-5324.62305, 427.934784, 3754.23682),
            ['Limor the Devourer'] = Vector3.new(-1093.02625, -169.141785, 7769.1875),
            ['Radioactive Experiment'] = Vector3.new(-4643.86816, 425.090515, 3782.8252)
        }
    })[game.PlaceId] or {}

    local unstreamedMapTeleports = ({
        [555980327] = { -- floor 3
            Vector3.new(-381, 4185, -327), Vector3.new(448, 4279, -385), Vector3.new(-375, 3938, 502), Vector3.new(1180, 6738, 1675)
        },
        [582198062] = { -- floor 7
            Vector3.new(3336, 748, -614), Vector3.new(3348, 800, -804), Vector3.new(1219, 1084, -274), Vector3.new(1905, 729, -327)
        },
        [5287433115] = { -- floor 11
            Vector3.new(5087, 217, 298), Vector3.new(5144, 1035, 298), Vector3.new(4510, 419, -2418), Vector3.new(3457, 465, -3474), Vector3.new(4632, 155, 950),
            Vector3.new(4629, 138, 1008), Vector3.new(5445, 2587, 6324), Vector3.new(5226, 2356, 6451), Vector3.new(5134, 1630, 2501), Vector3.new(5151, 1953, 4508),
            Vector3.new(5505, 1000, -5552), Vector3.new(4247, 507, -4774), Vector3.new(4977, 118, 1495), Vector3.new(5138, 416, 1676), Vector3.new(10827, 1565, -2375),
            Vector3.new(3633, 1767, 2662), Vector3.new(4208, 369, 939), Vector3.new(1029, 13, 686), Vector3.new(4835, 2543, 5275), Vector3.new(5204, 2294, 5778),
            Vector3.new(6054, 182, 965), Vector3.new(5354, 1001, -5465), Vector3.new(4626, 119, 960), Vector3.new(4617, 138, 1008), Vector3.new(521, 123, 346),
            Vector3.new(1034, 9, -345), Vector3.new(4801, 1646, 2083), Vector3.new(4846, 1640, 2091), Vector3.new(5182, 200, 1227), Vector3.new(5075, 127, 1287),
            Vector3.new(5174, 2035, 5702), Vector3.new(5205, 2259, 5684), Vector3.new(4684, 220, 215), Vector3.new(4476, 1245, -26), Vector3.new(3469, 405, -3555),
            Vector3.new(11911, 1572, -2100), Vector3.new(720, 139, 109), Vector3.new(3194, 1764, 647), Vector3.new(4642, 2337, 5969), Vector3.new(5161, 3230, 6034),
            Vector3.new(5208, 2290, 6370), Vector3.new(4916, 2400, 7751), Vector3.new(4655, 405, -3199), Vector3.new(4690, 462, -3423), Vector3.new(5209, 2350, 5915),
            Vector3.new(5334, 3231, 5589), Vector3.new(5225, 2602, 6434), Vector3.new(4916, 2310, 7764), Vector3.new(5224, 2603, 6438), Vector3.new(4916, 2313, 7762),
            Vector3.new(5542, 1001, -5465), Vector3.new(4565, 405, -2917), Vector3.new(4563, 405, -2621), Vector3.new(4528, 405, -2396), Vector3.new(4982, 2587, 6321),
            Vector3.new(5215, 2356, 6451), Vector3.new(4763, 502, -4345), Vector3.new(5900, 853, -4256), Vector3.new(4822, 3226, 5869), Vector3.new(5292, 3224, 6044),
            Vector3.new(5055, 3224, 5706), Vector3.new(5389, 3224, 5774), Vector3.new(4002, 422, -3794), Vector3.new(2094, 939, -6307)
        },
        [6144637080] = { -- floor 12
            Vector3.new(-182, 178, 6148), Vector3.new(-939, -171, 6885), Vector3.new(-714, 143, 4961), Vector3.new(-418, 183, 5650), Vector3.new(-1093, -169, 7769),
            Vector3.new(-301, -319, 7953), Vector3.new(-2290, 242, 3090), Vector3.new(-3163, 221, 3284), Vector3.new(-4268, 217, 3785), Vector3.new(-4644, 425, 3783),
            Vector3.new(-2446, 49, 4145), Vector3.new(-5325, 428, 3754), Vector3.new(-404, 198, 5562), Vector3.new(-419, 177, 5648)
        }
    })[game.PlaceId] or {}

    for _, position in next, unstreamedMapTeleports do
        LocalPlayer:RequestStreamAroundAsync(position)
    end

    local teleportSystems = {}
    for _, instance in next, workspace:GetChildren() do
        if instance.Name ~= 'TeleportSystem' then continue end
        table.insert(teleportSystems, {})
        for _, part in next, instance:GetChildren() do
            if part.Name ~= 'Part' then continue end
            table.insert(teleportSystems[#teleportSystems], part)
            local locationName = #mapTeleports + 1
            for name, position in next, mapTeleportLabels do
                if part.CFrame.Position ~= position then continue end
                locationName = name
                break
            end
            mapTeleports[locationName] = part
            table.insert(Options.MapTeleports.Values, locationName)
        end
    end

    if game.PlaceId == 566212942 then -- floor 6
        mapTeleports['Undershroud'] = workspace:WaitForChild('Portal'):WaitForChild('TouchPart')
        table.insert(Options.MapTeleports.Values, 'Undershroud')
    elseif game.PlaceId == 6144637080 then -- floor 12
        LocalPlayer:RequestStreamAroundAsync(Vector3.new(-2415.14258, 128.760483, 6343.8584))
        mapTeleports['Atheon'] = workspace:WaitForChild('AtheonPortal')
        table.insert(Options.MapTeleports.Values, 'Atheon')
    end

    table.sort(Options.MapTeleports.Values, function(a, b)
        if type(a) == 'string' then
            if type(b) == 'string' then
                return #a < #b
            else
                return true
            end
        elseif type(b) == 'number' then
            return a < b
        end
    end)

    Options.MapTeleports:SetValues(Options.MapTeleports.Values)
end)

-- local proximityPromptIndex = 0
-- local proximityPrompts = {}
-- local proximityPromptNames = {}
-- for _, proximityPrompt in next, game:GetDescendants() do
--     if proximityPrompt.ClassName ~= 'ProximityPrompt' then continue end
--     proximityPromptIndex += 1
--     local name = `{proximityPrompt.Parent.Parent.Name} {proximityPromptIndex}`
--     proximityPrompts[name] = proximityPrompt
--     table.insert(proximityPromptNames, name)
-- end

-- AdditionalCheats:AddDropdown('FireProximityPrompts', {
--     Text = 'Fire proximityprompts',
--     Values = proximityPromptNames,
--     AllowNull = true
-- }):OnChanged(function(proximityPromptName)
--     if not proximityPromptName then return end
--     Options.FireProximityPrompts:SetValue()

--     local proximityPrompt = proximityPrompts[proximityPromptName]
--     if proximityPrompt.Parent and proximityPrompt.Parent.Parent then
--         HumanoidRootPart.CFrame = proximityPrompt.Parent.Parent.CFrame
--         fireproximityprompt(proximityPrompt)
--     end
-- end)

