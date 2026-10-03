-- Bluu :: Settings  (split from Sb2-0mlg.lua)

Settings = Window:AddTab('Settings', 'settings')

Menu = Settings:AddLeftGroupbox('Menu', 'menu')

Menu:AddLabel('Menu keybind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true })

Library.ToggleKeybind = Options.MenuKeybind

autoexecute = true
if isfile('Bluu/Swordburst 2/autoexec') and readfile('Bluu/Swordburst 2/autoexec') == 'false' then
    autoexecute = false
end

Menu:AddToggle('Autoexecute', { Text = 'Auto execute', Default = autoexecute }):OnChanged(function(value)
    writefile('Bluu/Swordburst 2/autoexec', tostring(value))
end)

Menu:AddButton("Unload script", function()
    for _, toggle in next, Toggles do
        if toggle.Value then
            toggle:SetValue(false)
        end
    end

    pcall(function()
        linearVelocity.Parent = nil
        waypoint:Destroy()
        if radiusDisc then radiusDisc:Destroy() end
        local espFolder = game:GetService('CoreGui'):FindFirstChild('BluuEsp')
        if espFolder then espFolder:Destroy() end
        local espGuiOld = game:GetService('CoreGui'):FindFirstChild('BluuEspGui')
        if espGuiOld then espGuiOld:Destroy() end
        Humanoid.WalkSpeed = 20
        Camera.CameraSubject = Character
        LocalPlayer.CameraMaxZoomDistance = defaultCameraMaxZoomDistance
        LocalPlayer.DevCameraOcclusionMode = 0
        Chat.Size = chatSize
        Library:Unload()
    end)

    getgenv().Bluu = false
end)

ThemeManager = loadstring(game:HttpGet(UIRepo .. 'addons/ThemeManager.lua'))()
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder('Bluu/Swordburst 2')
ThemeManager:ApplyToTab(Settings)

SaveManager = loadstring(game:HttpGet(UIRepo .. 'addons/SaveManager.lua'))()
SaveManager:SetLibrary(Library)
SaveManager:SetFolder('Bluu/Swordburst 2')
SaveManager:IgnoreThemeSettings()

-- Per-account autoload: each account gets its own autoload marker
-- (autoload_<UserId>.txt) while the config pool itself stays shared.
-- An account with no marker falls back to the shared autoload.txt so
-- nothing changes until that account picks its own config.
if writefile and readfile and isfile and delfile then
    local function autoloadPath(shared)
        local base = SaveManager.Folder .. '/settings/'
        if SaveManager:CheckSubFolder(true) then
            base ..= SaveManager.SubFolder .. '/'
        end
        return base .. (shared and 'autoload' or 'autoload_' .. LocalPlayer.UserId) .. '.txt'
    end

    local function readAutoloadName(path)
        local ok, name = pcall(readfile, path)
        if not ok then return 'none' end
        name = tostring(name)
        return name == '' and 'none' or name
    end

    function SaveManager:GetAutoloadConfig()
        SaveManager:CheckFolderTree()
        if isfile(autoloadPath()) then
            return readAutoloadName(autoloadPath())
        end
        if isfile(autoloadPath(true)) then
            return readAutoloadName(autoloadPath(true))
        end
        return 'none'
    end

    function SaveManager:LoadAutoloadConfig()
        SaveManager:CheckFolderTree()
        local path = isfile(autoloadPath()) and autoloadPath() or autoloadPath(true)
        if isfile(path) then
            local ok, name = pcall(readfile, path)
            if not ok then
                Library:Notify('Failed to load autoload config: write file error')
                return
            end
            local success, err = self:Load(name)
            if not success then
                Library:Notify('Failed to load autoload config: ' .. err)
                return
            end
            Library:Notify(string.format('Auto loaded config %q', name))
        end
    end

    function SaveManager:SaveAutoloadConfig(name)
        SaveManager:CheckFolderTree()
        if not pcall(writefile, autoloadPath(), name) then
            return false, 'write file error'
        end
        return true, ''
    end

    function SaveManager:DeleteAutoLoadConfig()
        SaveManager:CheckFolderTree()
        -- clears only THIS account's marker - the shared autoload.txt is left
        -- alone so the account falls back to the shared pick afterwards
        if not pcall(delfile, autoloadPath()) then
            return false, 'delete file error'
        end
        return true, ''
    end

    Menu:AddDivider({ Text = `Autoload is per-account ({LocalPlayer.Name})` })
end

SaveManager:BuildConfigSection(Settings)

-- After any config load (manual or autoload), snap the waypoint back to where it was
-- on this floor and re-enable path farming if it was saved on.
local _origSaveManagerLoad = SaveManager.Load
SaveManager.Load = function(self, name, ...)
    -- Suppress the UseWaypoint OnChanged during load so it can't overwrite our saved
    -- coords with the current (spawn) position before restoreFloorData runs.
    waypointRestoring = true
    local a, b = _origSaveManagerLoad(self, name, ...)
    task.spawn(function()
        task.wait(0.3)
        restoreFloorData()
    end)
    return a, b
end

SaveManager:LoadAutoloadConfig()

Credits = Settings:AddRightGroupbox('Credits')

Credits:AddLabel('de_Neuublue - Script')
Credits:AddLabel('Inori - UI library')
Credits:AddLabel('wally - UI addons')

-- Auto-refresh the theme/config dropdowns every time they're opened
for _, pair in next, {
    { Options.SaveManager_ConfigList, function() return SaveManager:RefreshConfigList() end },
    { Options.ThemeManager_CustomThemeList, function() return ThemeManager:ReloadCustomThemes() end },
} do
    local dropdown, reload = pair[1], pair[2]
    if dropdown and dropdown.Menu then
        local open = dropdown.Menu.Open
        dropdown.Menu.Open = function(self, ...)
            dropdown:SetValues(reload())
            return open(self, ...)
        end
    end
end

-- Strip dividers + 'Refresh list' buttons, shorten addon button labels
local buttonRenames = {
    ['Load selected'] = 'Load',
    ['Load config'] = 'Load',
    ['Save config'] = 'Save',
    ['Overwrite config'] = 'Overwrite',
    ['Set autoload'] = 'Autoload',
    ['Delete'] = 'Delete',
}
for _, tab in next, Library.Tabs do
    local function stripElements(container)
        local stripped = false
        for _, element in next, container.Elements do
            if element.Type == 'Divider' or (element.Type == 'Button' and element.Text == 'Refresh list') then
                element.Holder.Visible = false
                stripped = true
            elseif element.Type == 'Button' and buttonRenames[element.Text] then
                for _, descendant in next, element.Holder:GetDescendants() do
                    if descendant:IsA('TextLabel') then
                        descendant.Text = buttonRenames[element.Text]
                    end
                end
            end
        end
        if stripped and container.Resize then
            container:Resize()
        end
    end

    for _, groupbox in next, tab.Groupboxes do
        stripElements(groupbox)
    end
    for _, tabbox in next, tab.Tabboxes do
        for _, subtab in next, tabbox.Tabs do
            stripElements(subtab)
        end
    end
end

