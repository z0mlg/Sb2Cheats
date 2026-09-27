-- Bluu :: Crystals  (split from Sb2-0mlg.lua)

do

local inTrade = Instance.new('BoolValue')
local tradeLastSent = 0

local Crystals = Window:AddTab('Crystals', 'gem')

local Trading = Crystals:AddLeftGroupbox('Trading')
Trading:AddDropdown('TargetAccount', { Text = 'Target account', Values = {}, SpecialType = 'Player' })
:OnChanged(function()
    tradeLastSent = 0
end)

local CrystalCounter
CrystalCounter = {
    Given = {
        Value = 0,
        ThisCycle = 0,
        Label = Trading:AddLabel(),
        Update = function()
            CrystalCounter.Given.Label:SetText(
                `{CrystalCounter.Given.Value} ({math.floor(CrystalCounter.Given.Value / 64 * 10 ^ 5) / 10 ^ 5} stacks) given`
            )
        end
    },
    Received = {
        Value = 0,
        Label = Trading:AddLabel(),
        Update = function()
            CrystalCounter.Received.Label:SetText(
                `{CrystalCounter.Received.Value} ({math.floor(CrystalCounter.Received.Value / 64 * 10 ^ 5) / 10 ^ 5} stacks) received`
            )
        end
    }
}

CrystalCounter.Given.Update()
CrystalCounter.Received.Update()

Trading:AddButton({ Text = 'Reset counter', Func = function()
        CrystalCounter.Given.Value = 0
        CrystalCounter.Received.Value = 0
        CrystalCounter.Given.Update()
        CrystalCounter.Received.Update()
end })

Giving = Crystals:AddRightGroupbox('Giving')

Giving:AddToggle('SendTrades', { Text = 'Send trades', Default = false }):OnChanged(function()
    CrystalCounter.Given.ThisCycle = 0
    while Toggles.SendTrades.Value do
        local target = Options.TargetAccount.Value
        if target and not inTrade.Value and tick() - tradeLastSent >= 0.5 then
            tradeLastSent = InvokeFunction('Trade', 'Request', { target }) and tick() or tick() - 0.4
        end
        task.wait()
    end
end)

Giving:AddInput('CrystalAmount', { Text = 'Crystal amount', Numeric = true, Finished = true, Placeholder = 1 })
:OnChanged(function(value)
    Options.CrystalAmount.Value = tonumber(value) or 1
end)

Giving:AddButton({ Text = 'Convert stacks to crystals', Func = function()
    Options.CrystalAmount:SetValue(math.ceil(Options.CrystalAmount.Value * 64))
end })

Giving:AddDropdown('CrystalType', { Text = 'Crystal type', Values = Rarities, AllowNull = true })
:OnChanged(function(crystalType)
    if not crystalType then return end
    if Inventory:FindFirstChild(crystalType .. ' Upgrade Crystal') then return end
    Library:Notify(`You need to have at least 1 {crystalType:lower()} upgrade crystal`)
end)

Giving:AddButton({
    Text = 'Add crystals to trade',
    Func = function()
        if not Options.CrystalType.Value then
            return Library:Notify('Select the crystal type first')
        end

        local item = Inventory:FindFirstChild(Options.CrystalType.Value .. ' Upgrade Crystal')

        if not item then
            return Library:Notify(`You need to have at least 1 {Options.CrystalType.Value:lower()} upgrade crystal`)
        end

        for value = 1, item:FindFirstChild('Count') and item.Count.Value or 1 do
            Event:FireServer('Trade', 'TradeAddItem', { item })
            if value == Options.AmountToAdd.Value then break end
        end
    end
})

Giving:AddSlider('AmountToAdd', { Text = 'Amount to add', Default = 128, Min = 0, Max = 128, Rounding = 0, Compact = true })

Receiving = Crystals:AddRightGroupbox('Receiving')

Receiving:AddToggle('AcceptTrades', {
    Text = 'Accept trades',
    Default = false
})

inTrade.Changed:Connect(function(enteredTrade)
    if not enteredTrade then return end
    if not Toggles.SendTrades.Value then return end
    if not Options.CrystalType.Value then
        return Library:Notify('Select the crystal type first')
    end

    local item = Inventory:FindFirstChild(Options.CrystalType.Value .. ' Upgrade Crystal')

    if not item then
        Library:Notify(`You need to have at least 1 {Options.CrystalType.Value:lower()} upgrade crystal`)
        return Toggles.SendTrades:SetValue(false)
    end

    for _ = 1, (item:FindFirstChild('Count') and math.min(128, item.Count.Value, Options.CrystalAmount.Value - CrystalCounter.Given.ThisCycle) or 1) do
        Event:FireServer('Trade', 'TradeAddItem', { item })
    end

    Event:FireServer('Trade', 'TradeConfirm', {})
    Event:FireServer('Trade', 'TradeAccept', {})
end)

local lastTradeChange
Event.OnClientEvent:Connect(function(...)
    local args = {...}
    if not (args[1] == 'UI' and args[2][1] == 'Trade') then return end
    if args[2][2] == 'Request' then
        if not (Toggles.AcceptTrades.Value or Toggles.SendTrades.Value) then return end
        if Options.TargetAccount.Value.Name == args[2][3].Name then
            Event:FireServer('Trade', 'RequestAccept', {})
            inTrade.Value = true
        else
            Event:FireServer('Trade', 'RequestDecline', {})
        end
    elseif args[2][2] == 'TradeChanged' then
        lastTradeChange = args[2][3]
        if not (Toggles.AcceptTrades.Value or Toggles.SendTrades.Value) then return end
        local targetRole = lastTradeChange.Requester == LocalPlayer and 'Partner' or 'Requester'
        local ourRole = targetRole == 'Partner' and 'Requester' or 'Partner'
        if not (lastTradeChange[targetRole .. 'Confirmed'] and not lastTradeChange[ourRole .. 'Accepted']) then return end
        Event:FireServer('Trade', 'TradeConfirm', {})
        Event:FireServer('Trade', 'TradeAccept', {})
    elseif args[2][2] == 'RequestAccept' then
        inTrade.Value = true
    elseif args[2][2] == 'RequestDecline' then
        tradeLastSent = 0
    elseif args[2][2] == 'TradeCompleted' then
        local targetRole = lastTradeChange.Requester == LocalPlayer and 'Partner' or 'Requester'
        local ourRole = targetRole == 'Partner' and 'Requester' or 'Partner'
        for _, itemData in next, lastTradeChange[targetRole .. 'Items'] do
            if not itemData.item.Name:find('Upgrade Crystal') then continue end
            CrystalCounter.Received.Value += 1
        end
        CrystalCounter.Received.Update()
        for _, itemData in next, lastTradeChange[ourRole .. 'Items'] do
            if not itemData.item.Name:find('Upgrade Crystal') then continue end
            CrystalCounter.Given.Value += 1
            if not Toggles.SendTrades.Value then continue end
            CrystalCounter.Given.ThisCycle += 1
            if CrystalCounter.Given.ThisCycle ~= Options.CrystalAmount.Value then continue end
            Toggles.SendTrades:SetValue(false)
        end
        CrystalCounter.Given.Update()
        inTrade.Value = false
    elseif args[2][2] == 'TradeCancel' then
        inTrade.Value = false
    end
end)

end
