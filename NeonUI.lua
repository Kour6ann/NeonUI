-- NeonUI (Extended Minimal UI Library)
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
ScreenGui.ResetOnSpawn = false

---------------------------------------------------------------------
-- Notifications
---------------------------------------------------------------------
function UI:CreateNotify(opts)
    print("[NOTIFY]", opts.title, opts.description)
end

---------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------
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

-- Save last config
local function saveLastConfig(name)
    if writefile then
        writefile(UI.LastConfigFile, HttpService:JSONEncode({last = name}))
    end
end

-- Load last config
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

-- Save Config
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

-- Load Config
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

---------------------------------------------------------------------
-- CreateMain (Title bar, minimize/close, tab bar)
---------------------------------------------------------------------
function UI:CreateMain(options)
    local main = Instance.new("Frame", ScreenGui)
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 600, 0, 400)
    main.Position = UDim2.new(0.5, -300, 0.5, -200)
    main.BackgroundColor3 = options.Theme and options.Theme.Background or Color3.fromRGB(25,25,25)
    main.Active = true
    main.Draggable = true
    UI.MainFrame = main

    -- Title bar
    local titleBar = Instance.new("Frame", main)
    titleBar.Size = UDim2.new(1,0,0,30)
    titleBar.BackgroundColor3 = Color3.fromRGB(30,30,30)

    local title = Instance.new("TextLabel", titleBar)
    title.Size = UDim2.new(1,-60,1,0)
    title.Position = UDim2.new(0,5,0,0)
    title.Text = options.title or "NeonUI"
    title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Close button
    local closeBtn = Instance.new("TextButton", titleBar)
    closeBtn.Size = UDim2.new(0,30,1,0)
    closeBtn.Position = UDim2.new(1,-30,0,0)
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(100,30,30)
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    -- Minimize button
    local minBtn = Instance.new("TextButton", titleBar)
    minBtn.Size = UDim2.new(0,30,1,0)
    minBtn.Position = UDim2.new(1,-60,0,0)
    minBtn.Text = "-"
    minBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    minBtn.TextColor3 = Color3.new(1,1,1)
    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, child in ipairs(main:GetChildren()) do
            if child ~= titleBar and child ~= minBtn and child ~= closeBtn then
                child.Visible = not minimized
            end
        end
    end)

    -- Tab bar
    local tabBar = Instance.new("Frame", main)
    tabBar.Size = UDim2.new(1,0,0,30)
    tabBar.Position = UDim2.new(0,0,0,30)
    tabBar.BackgroundColor3 = Color3.fromRGB(20,20,20)
    local layout = Instance.new("UIListLayout", tabBar)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,5)
    UI.TabBar = tabBar
    UI.CurrentTab = nil

    return UI
end

---------------------------------------------------------------------
-- CreateTab (with vertical layout + scrolling)
---------------------------------------------------------------------
function UI:CreateTab(title, icon)
    -- Tab button
    local tabBtn = Instance.new("TextButton", UI.TabBar)
    tabBtn.Size = UDim2.new(0,100,1,0)
    tabBtn.Text = title
    tabBtn.BackgroundColor3 = Color3.fromRGB(40,40,40)
    tabBtn.TextColor3 = Color3.new(1,1,1)

    -- Tab content
    local tab = Instance.new("ScrollingFrame", UI.MainFrame)
    tab.Name = title
    tab.Size = UDim2.new(1,-10,1,-70)
    tab.Position = UDim2.new(0,5,0,65)
    tab.BackgroundTransparency = 1
    tab.Visible = false
    tab.ScrollBarThickness = 6

    -- Vertical layout
    local layout = Instance.new("UIListLayout", tab)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Padding = UDim.new(0,5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    UI.Tabs[title] = tab

    -- Click to switch
    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(UI.Tabs) do
            t.Visible = false
        end
        tab.Visible = true
        UI.CurrentTab = tab
    end)

    if not UI.CurrentTab then
        UI.CurrentTab = tab
        tab.Visible = true
    end

    return tab
end

---------------------------------------------------------------------
-- Controls
---------------------------------------------------------------------
function UI:CreateSection(opts)
    local section = Instance.new("TextLabel", opts.parent)
    section.Size = UDim2.new(1, -10, 0, 30)
    section.Text = opts.text or "Section"
    section.TextColor3 = Color3.new(1,1,1)
    section.BackgroundColor3 = Color3.fromRGB(40,40,40)
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
    local frame = Instance.new("TextLabel", opts.parent)
    frame.Size = UDim2.new(0, 250, 0, 60)
    frame.TextWrapped = true
    frame.TextXAlignment = Enum.TextXAlignment.Left
    frame.Text = (opts.title or "") .. "\n" .. (opts.text or "")
    frame.TextColor3 = Color3.new(1,1,1)
    frame.BackgroundTransparency = 1
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

---------------------------------------------------------------------
-- Config Manager
---------------------------------------------------------------------
function UI:CreateConfigManager(tab)
    local section = UI:CreateSection({parent = tab, text = "Config Manager"})

    -- Save
    UI:CreateButton({
        parent = tab,
        text = "Save Current Config",
        callback = function()
            UI:SaveConfig("Default")
        end
    })

    -- Load
    UI:CreateButton({
        parent = tab,
        text = "Load Default Config",
        callback = function()
            UI:LoadConfig("Default")
        end
    })

    -- Reset All
    UI:CreateButton({
        parent = tab,
        text = "Reset All Configs",
        callback = function()
            if listfiles and isfolder and isfolder(UI.ConfigsFolder) then
                for _, f in ipairs(listfiles(UI.ConfigsFolder)) do
                    if f:match("%.json$") then
                        if delfile and isfile(f) then delfile(f) end
                    end
                end
                UI:CreateNotify({title="Config", description="All configs deleted"})
            end
        end
    })
end

---------------------------------------------------------------------
-- INIT
---------------------------------------------------------------------
UI:LoadSettings()
if UI.Settings.AutoLoad then
    local last = loadLastConfig()
    if last then
        UI:LoadConfig(last)
    else
        UI:LoadConfig("Default")
    end
end

-- Ensure Default.json exists
local defaultPath = UI.ConfigsFolder .. "/Default.json"
if writefile and (not isfile or not isfile(defaultPath)) then
    writefile(defaultPath, HttpService:JSONEncode({}))
end

return UI
