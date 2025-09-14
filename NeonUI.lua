-- NeonUI (Extended Minimal Version with Config Manager)
local Player = game:GetService("Players")
local LocalPlayer = Player.LocalPlayer
local HttpService = game:GetService("HttpService")

local UI = {}
UI.Config = {}
UI.Tabs = {}
UI.ConfigsFolder = "Kour6anHubConfigs"
UI.SettingsFile = UI.ConfigsFolder .. "/settings.json"
UI.LastConfigFile = UI.ConfigsFolder .. "/lastConfig.json"

-- Ensure folder exists
if makefolder and not isfolder(UI.ConfigsFolder) then
    makefolder(UI.ConfigsFolder)
end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "Kour6anHubUI"

-- 📝 Notifications (minimal)
function UI:CreateNotify(opts)
    print("[NOTIFY]", opts.title, opts.description)
end

-- ⚙️ Settings
function UI:LoadSettings()
    if readfile and isfile and isfile(UI.SettingsFile) then
        local data = readfile(UI.SettingsFile)
        local decoded = HttpService:JSONDecode(data)
        if decoded then
            UI.Settings = decoded
            return
        end
    end
    UI.Settings = { AutoLoad = true }
end

function UI:SaveSettings()
    if writefile then
        writefile(UI.SettingsFile, HttpService:JSONEncode(UI.Settings))
    end
end

-- 📝 Save last used config
local function saveLastConfig(name)
    if writefile then
        writefile(UI.LastConfigFile, HttpService:JSONEncode({last = name}))
    end
end

-- 📖 Load last used config
local function loadLastConfig()
    if readfile and isfile and isfile(UI.LastConfigFile) then
        local data = readfile(UI.LastConfigFile)
        local decoded = HttpService:JSONDecode(data)
        if decoded and decoded.last then
            return decoded.last
        end
    end
    return nil
end

-- 💾 Save Config
function UI:SaveConfig(profileName)
    profileName = profileName or "Default"
    local path = UI.ConfigsFolder .. "/" .. profileName .. ".json"
    local json = HttpService:JSONEncode(UI.Config)
    if writefile then
        writefile(path, json)
    end
    saveLastConfig(profileName)
    UI:CreateNotify({title="Config", description="Saved as " .. profileName})
end

-- 📖 Load Config
function UI:LoadConfig(profileName)
    profileName = profileName or "Default"
    local path = UI.ConfigsFolder .. "/" .. profileName .. ".json"
    if readfile and isfile and isfile(path) then
        local data = readfile(path)
        local decoded = HttpService:JSONDecode(data)
        if decoded then
            UI.Config = decoded
            saveLastConfig(profileName)
            UI:CreateNotify({title="Config", description="Loaded " .. profileName})
        end
    else
        UI:CreateNotify({title="Config", description="No config named " .. profileName})
    end
end

-- 📂 Config Manager Tab
function UI:CreateConfigManager(tab)
    local section = UI:CreateSection({parent = tab, text = "Config Manager"})

    -- Selected label
    local selectedLabel = Instance.new("TextLabel", section)
    selectedLabel.Size = UDim2.new(0, 200, 0, 30)
    selectedLabel.Position = UDim2.new(0, 10, 0, 10)
    selectedLabel.BackgroundColor3 = Color3.fromRGB(40,40,40)
    selectedLabel.TextColor3 = Color3.new(1,1,1)
    selectedLabel.Text = "Selected: Default"

    -- Dropdown
    local dropdownFrame = Instance.new("Frame", section)
    dropdownFrame.Size = UDim2.new(0, 200, 0, 0)
    dropdownFrame.Position = UDim2.new(0, 10, 0, 45)
    dropdownFrame.BackgroundColor3 = Color3.fromRGB(25,25,25)
    dropdownFrame.ClipsDescendants = true
    local uiList = Instance.new("UIListLayout", dropdownFrame)

    local dropdownOpen = false
    selectedLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dropdownOpen = not dropdownOpen
            dropdownFrame.Size = dropdownOpen and UDim2.new(0,200,0,150) or UDim2.new(0,200,0,0)
        end
    end)

    -- Refresh configs
    local function refreshConfigs()
        for _, child in ipairs(dropdownFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        if listfiles and isfolder and isfolder(UI.ConfigsFolder) then
            local files = listfiles(UI.ConfigsFolder)
            for _, f in ipairs(files) do
                local configName = string.match(f, "([^/\\]+)%.json$")
                if configName and configName ~= "settings" and configName ~= "lastConfig" then
                    local btn = Instance.new("TextButton", dropdownFrame)
                    btn.Size = UDim2.new(1,0,0,25)
                    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
                    btn.TextColor3 = Color3.new(1,1,1)
                    btn.Text = configName
                    btn.MouseButton1Click:Connect(function()
                        selectedLabel.Text = "Selected: " .. configName
                        dropdownOpen = false
                        dropdownFrame.Size = UDim2.new(0,200,0,0)
                    end)
                end
            end
        end
    end
    refreshConfigs()

    -- Save
    UI:CreateButton({
        parent = section,
        text = "Save",
        callback = function()
            local name = string.gsub(selectedLabel.Text,"Selected: ","")
            UI:SaveConfig(name)
            refreshConfigs()
        end
    }).Position = UDim2.new(0, 220, 0, 10)

    -- Load
    UI:CreateButton({
        parent = section,
        text = "Load",
        callback = function()
            local name = string.gsub(selectedLabel.Text,"Selected: ","")
            UI:LoadConfig(name)
        end
    }).Position = UDim2.new(0, 220, 0, 50)

    -- Delete
    UI:CreateButton({
        parent = section,
        text = "Delete",
        callback = function()
            local name = string.gsub(selectedLabel.Text,"Selected: ","")
            local path = UI.ConfigsFolder .. "/" .. name .. ".json"
            if delfile and isfile(path) then
                delfile(path)
                UI:CreateNotify({title="Config", description="Deleted " .. name})
                selectedLabel.Text = "Selected: Default"
                refreshConfigs()
            end
        end
    }).Position = UDim2.new(0, 220, 0, 90)

    -- Save As
    local newConfigBox = Instance.new("TextBox", section)
    newConfigBox.Size = UDim2.new(0, 200, 0, 30)
    newConfigBox.Position = UDim2.new(0, 10, 0, 200)
    newConfigBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    newConfigBox.TextColor3 = Color3.new(1,1,1)
    newConfigBox.PlaceholderText = "Enter new config name"

    UI:CreateButton({
        parent = section,
        text = "Save As",
        callback = function()
            local name = newConfigBox.Text
            if name ~= "" then
                UI:SaveConfig(name)
                selectedLabel.Text = "Selected: " .. name
                newConfigBox.Text = ""
                refreshConfigs()
            else
                UI:CreateNotify({title="Config", description="Enter a name first!"})
            end
        end
    }).Position = UDim2.new(0, 220, 0, 200)

    -- Auto Load Toggle
    UI:CreateToggle({
        parent = section,
        text = "Auto Load Last Config",
        default = UI.Settings.AutoLoad,
        callback = function(state)
            UI.Settings.AutoLoad = state
            UI:SaveSettings()
            UI:CreateNotify({
                title="Config Manager",
                description="Auto Load Last Config is now " .. (state and "ON" or "OFF")
            })
        end
    }).Position = UDim2.new(0, 10, 0, 250)

    -- Reset Settings
    UI:CreateButton({
        parent = section,
        text = "Reset Settings",
        callback = function()
            if delfile and isfile and isfile(UI.SettingsFile) then
                delfile(UI.SettingsFile)
            end
            UI.Settings = { AutoLoad = true }
            UI:SaveSettings()
            UI:CreateNotify({title="Config Manager", description="Settings reset to default!"})
        end
    }).Position = UDim2.new(0, 10, 0, 290)

    -- Reset All Configs
    UI:CreateButton({
        parent = section,
        text = "Reset All Configs",
        callback = function()
            if listfiles and isfolder and isfolder(UI.ConfigsFolder) then
                local files = listfiles(UI.ConfigsFolder)
                for _, f in ipairs(files) do
                    if f:match("%.json$") and not f:match("settings%.json$") then
                        if delfile and isfile(f) then
                            delfile(f)
                        end
                    end
                end
                UI:CreateNotify({title="Config Manager", description="All configs deleted!"})
                selectedLabel.Text = "Selected: Default"
                refreshConfigs()
            end
        end
    }).Position = UDim2.new(0, 10, 0, 330)
end

-- 🖼️ Basic UI API (AshLibs-style)

function UI:CreateMain(options)
    local main = Instance.new("Frame", ScreenGui)
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 600, 0, 400)
    main.Position = UDim2.new(0.5, -300, 0.5, -200)
    main.BackgroundColor3 = options.Theme and options.Theme.Background or Color3.fromRGB(25,25,25)
    main.Active = true
    main.Draggable = true
    UI.MainFrame = main
    return UI
end

function UI:CreateTab(title, icon)
    local tab = Instance.new("Frame", UI.MainFrame)
    tab.Name = title
    tab.Size = UDim2.new(1, -10, 1, -50)
    tab.Position = UDim2.new(0, 5, 0, 45)
    tab.BackgroundTransparency = 1
    tab.Visible = true -- minimal: all tabs visible
    UI.Tabs[title] = tab
    return tab
end

function UI:CreateSection(opts)
    local section = Instance.new("Frame", opts.parent)
    section.Size = UDim2.new(1, -10, 0, 40)
    section.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", section)
    label.Size = UDim2.new(1,0,0,30)
    label.Text = opts.text or "Section"
    label.TextColor3 = Color3.new(1,1,1)
    label.BackgroundTransparency = 1
    return section
end

function UI:CreateToggle(opts)
    local btn = Instance.new("TextButton", opts.parent)
    btn.Size = UDim2.new(0, 200, 0, 30)
    local state = opts.default or false
    btn.Text = opts.text .. ": " .. (state and "ON" or "OFF")
    btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = opts.text .. ": " .. (state and "ON" or "OFF")
        if opts.callback then opts.callback(state) end
    end)
    return btn
end

function UI:CreateSlider(opts)
    local slider = Instance.new("TextButton", opts.parent)
    slider.Size = UDim2.new(0, 200, 0, 30)
    local value = opts.default or opts.min
    slider.Text = opts.text .. ": " .. tostring(value)
    slider.BackgroundColor3 = Color3.fromRGB(80,80,80)
    slider.TextColor3 = Color3.new(1,1,1)
    slider.MouseButton1Click:Connect(function()
        value = value + 1
        if value > opts.max then value = opts.min end
        slider.Text = opts.text .. ": " .. tostring(value)
        if opts.callback then opts.callback(value) end
    end)
    return slider
end

function UI:CreateButton(opts)
    local btn = Instance.new("TextButton", opts.parent)
    btn.Size = UDim2.new(0, 200, 0, 30)
    btn.Text = opts.text
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        if opts.callback then opts.callback() end
    end)
    return btn
end

function UI:CreateDropdown(opts)
    local dropdown = Instance.new("TextButton", opts.parent)
    dropdown.Size = UDim2.new(0, 200, 0, 30)
    local current = opts.default or (opts.options and opts.options[1]) or ""
    dropdown.Text = opts.text .. ": " .. tostring(current)
    dropdown.BackgroundColor3 = Color3.fromRGB(60,60,60)
    dropdown.TextColor3 = Color3.new(1,1,1)
    dropdown.MouseButton1Click:Connect(function()
        if opts.options then
            local idx = table.find(opts.options, current) or 0
            idx = idx + 1
            if idx > #opts.options then idx = 1 end
            current = opts.options[idx]
            dropdown.Text = opts.text .. ": " .. tostring(current)
            if opts.callback then opts.callback(current) end
        end
    end)
    return dropdown
end

function UI:CreateParagraph(opts)
    local frame = Instance.new("Frame", opts.parent)
    frame.Size = UDim2.new(0, 250, 0, 80)
    frame.BackgroundTransparency = 1
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,20)
    title.Text = opts.title or "Paragraph"
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    local text = Instance.new("TextLabel", frame)
    text.Size = UDim2.new(1,0,0,60)
    text.Position = UDim2.new(0,0,0,20)
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.Text = opts.text or ""
    text.TextColor3 = Color3.new(0.9,0.9,0.9)
    text.BackgroundTransparency = 1
    return frame
end

function UI:CreateColorPicker(opts)
    local btn = Instance.new("TextButton", opts.parent)
    btn.Size = UDim2.new(0, 200, 0, 30)
    btn.Text = opts.text
    btn.BackgroundColor3 = opts.default or Color3.fromRGB(255,0,0)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function()
        local newColor = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
        btn.BackgroundColor3 = newColor
        if opts.callback then opts.callback(newColor) end
    end)
    return btn
end

-- 🚀 INIT
UI:LoadSettings()
if UI.Settings.AutoLoad then
    local last = loadLastConfig()
    if last then
        UI:LoadConfig(last)
    else
        UI:LoadConfig("Default")
    end
end

return UI
