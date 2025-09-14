-- NeonUI (Extended with Config Manager + True Minimize)
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

-- 📝 Notifications
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

-- Save/load last config
local function saveLastConfig(name)
    if writefile then
        writefile(UI.LastConfigFile, HttpService:JSONEncode({last = name}))
    end
end

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

-- Save/Load Config
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

    -- Example Save button
    UI:CreateButton({
        parent = section,
        text = "Save Config",
        callback = function() UI:SaveConfig("Default") end
    })
    UI:CreateButton({
        parent = section,
        text = "Load Config",
        callback = function() UI:LoadConfig("Default") end
    })
end

-- 🖼️ Main Window
function UI:CreateMain(options)
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 600, 0, 400)
    main.Position = UDim2.new(0.5, -300, 0.5, -200)
    main.BackgroundColor3 = options.Theme and options.Theme.Background or Color3.fromRGB(25,25,25)
    main.Active = true
    main.Draggable = true
    main.Parent = ScreenGui
    UI.MainFrame = main

    -- Title Bar
    local titleBar = Instance.new("Frame", main)
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(20,20,20)

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.new(0, 5, 0, 0)
    titleLabel.Text = options.title or "NeonUI"
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Minimize Button
    local minBtn = Instance.new("TextButton", titleBar)
    minBtn.Size = UDim2.new(0, 30, 1, 0)
    minBtn.Position = UDim2.new(1, -60, 0, 0)
    minBtn.Text = "-"
    minBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    minBtn.TextColor3 = Color3.new(1,1,1)

    -- Close Button
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0, 30, 1, 0)
    closeBtn.Position = UDim2.new(1, -30, 0, 0)
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(60,40,40)
    closeBtn.TextColor3 = Color3.new(1,1,1)

    -- Tab Bar
    UI.TabBar = Instance.new("Frame", main)
    UI.TabBar.Size = UDim2.new(1, 0, 0, 30)
    UI.TabBar.Position = UDim2.new(0, 0, 0, 30)
    UI.TabBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
    local layout = Instance.new("UIListLayout", UI.TabBar)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)

    -- Minimize Logic (true minimize)
    local originalSize = main.Size
    minBtn.MouseButton1Click:Connect(function()
        if not UI.Minimized then
            originalSize = main.Size
            main.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 30)
            for _, child in ipairs(main:GetChildren()) do
                if child ~= titleBar then
                    child.Visible = false
                end
            end
            UI.Minimized = true
        else
            main.Size = originalSize
            for name, tab in pairs(UI.Tabs) do
                tab.Visible = (UI.ActiveTab == name)
            end
            if UI.TabBar then
                UI.TabBar.Visible = true
            end
            UI.Minimized = false
        end
    end)

    -- Close logic
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    return UI
end

-- 🖱️ Tabs
function UI:CreateTab(title)
    local tab = Instance.new("ScrollingFrame", UI.MainFrame)
    tab.Name = title
    tab.Size = UDim2.new(1, -10, 1, -70)
    tab.Position = UDim2.new(0, 5, 0, 65)
    tab.BackgroundTransparency = 1
    tab.Visible = false
    tab.CanvasSize = UDim2.new(0,0,0,0)
    tab.ScrollBarThickness = 6
    UI.Tabs[title] = tab

    -- Layout for stacking
    local layout = Instance.new("UIListLayout", tab)
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Tab button
    local btn = Instance.new("TextButton", UI.TabBar)
    btn.Size = UDim2.new(0, 100, 1, 0)
    btn.Text = title
    btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    btn.TextColor3 = Color3.new(1,1,1)

    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(UI.Tabs) do
            t.Visible = false
        end
        tab.Visible = true
        UI.ActiveTab = title
    end)

    -- Show first tab
    if not UI.ActiveTab then
        tab.Visible = true
        UI.ActiveTab = title
    end

    return tab
end

-- 🧩 Sections
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

-- 🔘 Controls
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
