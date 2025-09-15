-- NeonUI.lua (Full Patched Version)
-- Author: Kour6anHub

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local UI = {}
UI.Config = {}
UI.Tabs = {}
UI.ActiveTab = nil
UI.Minimized = false
UI.ConfigsFolder = "Kour6anHubConfigs"
UI.SettingsFile = UI.ConfigsFolder .. "/settings.json"
UI.LastConfigFile = UI.ConfigsFolder .. "/lastConfig.json"

-- ensure config folder if executor supports it
if makefolder and not isfolder(UI.ConfigsFolder) then
    pcall(makefolder, UI.ConfigsFolder)
end

-- create ScreenGui (replace any existing)
local function createScreenGui()
    local parent = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    if not parent then parent = game:GetService("CoreGui") end
    local existing = parent:FindFirstChild("Kour6anHubUI")
    if existing and existing:IsA("ScreenGui") then
        pcall(function() existing:Destroy() end)
    end
    local sg = Instance.new("ScreenGui")
    sg.Name = "Kour6anHubUI"
    sg.ResetOnSpawn = false
    sg.Parent = parent
    return sg
end

local ScreenGui = createScreenGui()

-- helper clamp
local function clamp(x, a, b)
    if x < a then return a elseif x > b then return b else return x end
end

-- lightweight notify
function UI:CreateNotify(opts)
    pcall(function()
        print("[NOTIFY]", opts.title or "Notify", opts.description or "")
        local f = Instance.new("Frame", ScreenGui)
        f.Size = UDim2.new(0, 320, 0, 56)
        f.Position = UDim2.new(0.5, -160, 0.08, 0)
        f.BackgroundColor3 = Color3.fromRGB(28,28,28)
        f.BorderSizePixel = 0
        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(1, -12, 0, 18)
        t.Position = UDim2.new(0, 6, 0, 4)
        t.BackgroundTransparency = 1
        t.Text = opts.title or ""
        t.TextColor3 = Color3.new(1,1,1)
        t.Font = Enum.Font.SourceSansBold
        t.TextSize = 16
        local d = Instance.new("TextLabel", f)
        d.Size = UDim2.new(1, -12, 0, 28)
        d.Position = UDim2.new(0, 6, 0, 22)
        d.BackgroundTransparency = 1
        d.Text = opts.description or ""
        d.TextColor3 = Color3.new(0.9,0.9,0.9)
        d.TextWrapped = true
        task.delay(3, function() pcall(function() f:Destroy() end) end)
    end)
end

-- Settings save/load
function UI:LoadSettings()
    UI.Settings = { AutoLoad = true }
    if readfile and isfile and isfile(UI.SettingsFile) then
        local ok, raw = pcall(function() return readfile(UI.SettingsFile) end)
        if ok and raw then
            local ok2, dec = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and type(dec) == "table" then
                UI.Settings = dec
            end
        end
    end
end

function UI:SaveSettings()
    if writefile then
        pcall(function()
            writefile(UI.SettingsFile, HttpService:JSONEncode(UI.Settings or {}))
        end)
    end
end

local function saveLastConfig(name)
    if writefile then
        pcall(function() writefile(UI.LastConfigFile, HttpService:JSONEncode({ last = name })) end)
    end
end

local function loadLastConfig()
    if readfile and isfile and isfile(UI.LastConfigFile) then
        local ok, raw = pcall(function() return readfile(UI.LastConfigFile) end)
        if ok and raw then
            local ok2, dec = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and dec and dec.last then return dec.last end
        end
    end
    return nil
end

function UI:SaveConfig(profileName)
    profileName = profileName or "Default"
    local path = UI.ConfigsFolder .. "/" .. profileName .. ".json"
    local ok, encoded = pcall(function() return HttpService:JSONEncode(UI.Config or {}) end)
    if ok and encoded and writefile then
        pcall(function() writefile(path, encoded) end)
        saveLastConfig(profileName)
        UI:CreateNotify({ title = "Config", description = "Saved as " .. profileName })
    end
end

function UI:LoadConfig(profileName)
    profileName = profileName or "Default"
    local path = UI.ConfigsFolder .. "/" .. profileName .. ".json"
    if readfile and isfile and isfile(path) then
        local ok, raw = pcall(function() return readfile(path) end)
        if ok and raw then
            local ok2, dec = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and dec then
                UI.Config = dec
                saveLastConfig(profileName)
                UI:CreateNotify({ title = "Config", description = "Loaded " .. profileName })
                return
            end
        end
    end
    UI:CreateNotify({ title = "Config", description = "No config named " .. profileName })
end

-- CreateMain
function UI:CreateMain(options)
    options = options or {}
    if UI.MainFrame and UI.MainFrame.Parent then
        pcall(function() UI.MainFrame:Destroy() end)
    end

    local main = Instance.new("Frame", ScreenGui)
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 640, 0, 420)
    main.Position = UDim2.new(0.5, -320, 0.5, -210)
    main.BackgroundColor3 = (options.Theme and options.Theme.Background) or Color3.fromRGB(25,25,25)
    main.Active = true
    UI.MainFrame = main

    local titleBar = Instance.new("Frame", main)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(20,20,20)

    local titleLabel = Instance.new("TextLabel", titleBar)
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 8, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = options.title or "NeonUI"
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 18

    -- drag only titlebar
    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function makeTitleBtn(txt, xOffset)
        local b = Instance.new("TextButton", titleBar)
        b.Size = UDim2.new(0, 28, 1, -8)
        b.Position = UDim2.new(1, xOffset, 0, 4)
        b.Text = txt
        b.Font = Enum.Font.SourceSansBold
        b.TextSize = 18
        b.TextColor3 = Color3.new(1,1,1)
        b.BackgroundColor3 = Color3.fromRGB(45,45,45)
        b.BorderSizePixel = 0
        return b
    end

    local minBtn = makeTitleBtn("-", -86)
    local closeBtn = makeTitleBtn("X", -50)

    local tabBar = Instance.new("Frame", main)
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 36)
    tabBar.Position = UDim2.new(0, 0, 0, 36)
    tabBar.BackgroundColor3 = (options.Theme and options.Theme.NavBackground) or Color3.fromRGB(30,30,30)
    local layout = Instance.new("UIListLayout", tabBar)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    UI.TabBar = tabBar
    UI.TitleBar = titleBar

    local originalSize = main.Size

    minBtn.MouseButton1Click:Connect(function()
        if not UI.Minimized then
            originalSize = main.Size
            main.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, titleBar.Size.Y.Offset)
            for _, child in ipairs(main:GetChildren()) do
                if child ~= titleBar then
                    child.Visible = false
                end
            end
            UI.Minimized = true
        else
            main.Size = originalSize
            for name, tab in pairs(UI.Tabs) do
                if tab and tab:IsA("ScrollingFrame") then
                    tab.Visible = (UI.ActiveTab == name)
                end
            end
            if UI.TabBar then UI.TabBar.Visible = true end
            UI.Minimized = false
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() main:Destroy() end)
    end)

    return UI
end

-- CreateTab (with scroll auto-resize)
function UI:CreateTab(title)
    if not UI.MainFrame then error("Call CreateMain() first", 2) end

    local tab = Instance.new("ScrollingFrame", UI.MainFrame)
    tab.Name = tostring(title)
    tab.Size = UDim2.new(1, -16, 1, -84)
    tab.Position = UDim2.new(0, 8, 0, 76)
    tab.BackgroundTransparency = 1
    tab.ScrollBarThickness = 6
    tab.Visible = false
    tab.CanvasSize = UDim2.new(0,0,0,0)

    local list = Instance.new("UIListLayout", tab)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 12)
    end)

    UI.Tabs[title] = tab

    local btn = Instance.new("TextButton", UI.TabBar)
    btn.Name = "TabBtn_" .. tostring(title)
    btn.Size = UDim2.new(0, 120, 1, -10)
    btn.Position = UDim2.new(0, 6, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.BorderSizePixel = 0
    btn.Text = tostring(title)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16

    btn.MouseButton1Click:Connect(function()
        -- close dropdown when switching tab
        if UI.CloseDropdownPopup then UI.CloseDropdownPopup() end
        for n, t in pairs(UI.Tabs) do
            if t and t:IsA("ScrollingFrame") then t.Visible = false end
        end
        tab.Visible = true
        UI.ActiveTab = title
    end)

    if not UI.ActiveTab then
        tab.Visible = true
        UI.ActiveTab = title
    end

    return tab
end

-- CreateSection
function UI:CreateSection(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateSection requires parent")
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -8, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(opts.text or "Section")
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 15
    label.TextXAlignment = Enum.TextXAlignment.Left
    return frame
end

-- CreateToggle
function UI:CreateToggle(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateToggle requires parent")
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.7, -8, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(opts.text or "Toggle")
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 15

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0.28, -12, 0, 24)
    btn.Position = UDim2.new(0.72, 6, 0, 3)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14

    local state = opts.default and true or false
    btn.Text = (state and "ON" or "OFF")
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = (state and "ON" or "OFF")
        if type(opts.callback) == "function" then pcall(opts.callback, state) end
    end)

    return container
end

-- CreateSlider
function UI:CreateSlider(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateSlider requires parent")
    local min = tonumber(opts.min) or 0
    local max = tonumber(opts.max) or min
    local value = tonumber(opts.default) or min

    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 40)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -8, 0, 16)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(opts.text or "Slider") .. " (" .. tostring(value) .. ")"
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 14

    local bar = Instance.new("Frame", container)
    bar.Size = UDim2.new(1, -16, 0, 10)
    bar.Position = UDim2.new(0, 8, 0, 24)
    bar.BackgroundColor3 = Color3.fromRGB(80,80,80)
    bar.BorderSizePixel = 0

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    fill.BorderSizePixel = 0

    local function setFillFromValue()
        local range = max - min
        local ratio = 0
        if range > 0 then ratio = (value - min) / range end
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        label.Text = tostring(opts.text or "Slider") .. " (" .. tostring(value) .. ")"
        if type(opts.callback) == "function" then pcall(opts.callback, value) end
    end

    task.defer(function() setFillFromValue() end)

    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local mouse = UIS:GetMouseLocation()
            local barPos = bar.AbsolutePosition.X
            local barW = math.max(1, bar.AbsoluteSize.X)
            local rel = clamp((mouse.X - barPos) / barW, 0, 1)
            value = min + math.floor((max - min) * rel + 0.5)
            setFillFromValue()
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = UIS:GetMouseLocation()
            local barPos = bar.AbsolutePosition.X
            local barW = math.max(1, bar.AbsoluteSize.X)
            local rel = clamp((mouse.X - barPos) / barW, 0, 1)
            value = min + math.floor((max - min) * rel + 0.5)
            setFillFromValue()
        end
    end)

    return container
end

-- CreateButton
function UI:CreateButton(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateButton requires parent")
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16
    btn.Text = tostring(opts.text or "Button")
    if type(opts.callback) == "function" then
        btn.MouseButton1Click:Connect(function() pcall(opts.callback) end)
    end
    return btn
end

-- 🔽 Fully patched CreateDropdown
do
    local openPopup, openConn

    function UI:CreateDropdown(opts)
        opts = opts or {}
        local parent = opts.parent or error("CreateDropdown requires parent")
        local options = opts.options or {}
        local multi = opts.multi and true or false

        local container = Instance.new("Frame", parent)
        container.Size = UDim2.new(1, 0, 0, 30)
        container.BackgroundTransparency = 1

        local title = Instance.new("TextLabel", container)
        title.Size = UDim2.new(0.55, -8, 1, 0)
        title.Position = UDim2.new(0, 8, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = tostring(opts.text or "Select")
        title.TextColor3 = Color3.new(1,1,1)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Font = Enum.Font.SourceSans
        title.TextSize = 15

        local mainBtn = Instance.new("TextButton", container)
        mainBtn.Size = UDim2.new(0.45, -8, 0, 24)
        mainBtn.Position = UDim2.new(0.55, 8, 0, 3)
        mainBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
        mainBtn.BorderSizePixel = 0
        mainBtn.TextColor3 = Color3.new(1,1,1)
        mainBtn.Font = Enum.Font.SourceSans
        mainBtn.TextSize = 14

        local selectedSingle, selectedMulti = nil, {}

        -- Initialize defaults
        if multi then
            if type(opts.default) == "table" then
                for _, v in ipairs(opts.default) do
                    if table.find(options, v) then table.insert(selectedMulti, v) end
                end
            end
            mainBtn.Text = (#selectedMulti > 0) and table.concat(selectedMulti, ", ") or "None"
        else
            if type(opts.default) == "string" and table.find(options, opts.default) then
                selectedSingle = opts.default
            else
                selectedSingle = options[1] or "None"
            end
            mainBtn.Text = tostring(selectedSingle)
        end

        local function closePopup()
            if openPopup and openPopup.Parent then openPopup:Destroy() end
            openPopup = nil
            if openConn then openConn:Disconnect() end
            openConn = nil
        end

        local function createPopup()
            closePopup()

            local popup = Instance.new("Frame", ScreenGui)
            popup.Size = UDim2.new(0, 220, 0, math.min(#options * 28, 200))
            local absPos = mainBtn.AbsolutePosition
            popup.Position = UDim2.new(0, absPos.X, 0, absPos.Y + mainBtn.AbsoluteSize.Y + 4)
            popup.BackgroundColor3 = Color3.fromRGB(35,35,35)
            popup.BorderSizePixel = 0
            popup.ZIndex = 2000
            popup.ClipsDescendants = false

            local layout = Instance.new("UIListLayout", popup)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 2)

            for _, optVal in ipairs(options) do
                local optBtn = Instance.new("TextButton", popup)
                optBtn.Size = UDim2.new(1, -8, 0, 26)
                optBtn.Position = UDim2.new(0, 4, 0, 0)
                optBtn.BackgroundColor3 = Color3.fromRGB(55,55,55)
                optBtn.TextColor3 = Color3.new(1,1,1)
                optBtn.Font = Enum.Font.SourceSans
                optBtn.TextSize = 14
                optBtn.Text = tostring(optVal)
                optBtn.ZIndex = 2001
                optBtn.AutoButtonColor = true

                optBtn.MouseButton1Click:Connect(function()
                    if multi then
                        local idx = table.find(selectedMulti, optVal)
                        if idx then table.remove(selectedMulti, idx) else table.insert(selectedMulti, optVal) end
                        mainBtn.Text = (#selectedMulti > 0) and table.concat(selectedMulti, ", ") or "None"
                        if type(opts.callback) == "function" then pcall(opts.callback, selectedMulti) end
                    else
                        selectedSingle = optVal
                        mainBtn.Text = tostring(selectedSingle)
                        if type(opts.callback) == "function" then pcall(opts.callback, selectedSingle) end
                        closePopup()
                    end
                end)
            end

            openPopup = popup
            openConn = UIS.InputBegan:Connect(function(inp, processed)
                if processed then return end
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mouse = UIS:GetMouseLocation()
                    local pPos, pSize = popup.AbsolutePosition, popup.AbsoluteSize
                    local bPos, bSize = mainBtn.AbsolutePosition, mainBtn.AbsoluteSize
                    local insidePopup = mouse.X >= pPos.X and mouse.X <= (pPos.X + pSize.X) and mouse.Y >= pPos.Y and mouse.Y <= (pPos.Y + pSize.Y)
                    local insideBtn = mouse.X >= bPos.X and mouse.X <= (bPos.X + bSize.X) and mouse.Y >= bPos.Y and mouse.Y <= (bPos.Y + bSize.Y)
                    if not (insidePopup or insideBtn) then closePopup() end
                end
            end)
        end

        mainBtn.MouseButton1Click:Connect(function()
            if openPopup then closePopup() else createPopup() end
        end)

        return {
            get = function() return multi and selectedMulti or selectedSingle end,
            set = function(val)
                if multi and type(val) == "table" then
                    selectedMulti = {}
                    for _, v in ipairs(val) do if table.find(options, v) then table.insert(selectedMulti, v) end end
                    mainBtn.Text = (#selectedMulti > 0) and table.concat(selectedMulti, ", ") or "None"
                    if type(opts.callback) == "function" then pcall(opts.callback, selectedMulti) end
                elseif not multi and type(val) == "string" and table.find(options, val) then
                    selectedSingle = val
                    mainBtn.Text = tostring(selectedSingle)
                    if type(opts.callback) == "function" then pcall(opts.callback, selectedSingle) end
                end
            end
        }
    end
end

-- CreateParagraph
function UI:CreateParagraph(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateParagraph requires parent")
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundTransparency = 1
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -12, 0, 18)
    title.Position = UDim2.new(0, 6, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = tostring(opts.title or "")
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1, -12, 1, -20)
    txt.Position = UDim2.new(0, 6, 0, 20)
    txt.BackgroundTransparency = 1
    txt.Text = tostring(opts.text or "")
    txt.TextColor3 = Color3.new(0.9,0.9,0.9)
    txt.TextWrapped = true
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.Font = Enum.Font.SourceSans
    txt.TextSize = 14
    return frame
end

-- CreateColorPicker
function UI:CreateColorPicker(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateColorPicker requires parent")
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, -8, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(opts.text or "Color")
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 15
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0.36, -8, 0, 24)
    btn.Position = UDim2.new(0.62, 8, 0, 3)
    btn.BackgroundColor3 = opts.default or Color3.fromRGB(255,0,0)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        local c = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
        btn.BackgroundColor3 = c
        if type(opts.callback) == "function" then pcall(opts.callback, c) end
    end)
    return container
end

-- Config manager
function UI:CreateConfigManager(tab)
    if not tab then return end
    local s = UI:CreateSection({ parent = tab, text = "Config Manager" })
    local cont = Instance.new("Frame", tab)
    cont.Size = UDim2.new(1, 0, 0, 140)
    cont.BackgroundTransparency = 1

    local selectedLabel = Instance.new("TextLabel", cont)
    selectedLabel.Size = UDim2.new(0.6, -8, 0, 28)
    selectedLabel.Position = UDim2.new(0, 8, 0, 6)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = "Selected: Default"
    selectedLabel.TextColor3 = Color3.new(1,1,1)

    local saveBtn = UI:CreateButton({ parent = cont, text = "Save", callback = function()
        local name = tostring(selectedLabel.Text):gsub("Selected:%s*", "")
        if name == "" then name = "Default" end
        UI:SaveConfig(name)
    end })
    saveBtn.Position = UDim2.new(0.62, 8, 0, 6)

    local loadBtn = UI:CreateButton({ parent = cont, text = "Load", callback = function()
        local name = tostring(selectedLabel.Text):gsub("Selected:%s*", "")
        if name == "" then name = "Default" end
        UI:LoadConfig(name)
    end })
    loadBtn.Position = UDim2.new(0.62, 8, 0, 42)

    local saveAsBox = Instance.new("TextBox", cont)
    saveAsBox.Size = UDim2.new(0.6, -8, 0, 28)
    saveAsBox.Position = UDim2.new(0, 8, 0, 42)
    saveAsBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    saveAsBox.TextColor3 = Color3.new(1,1,1)
    saveAsBox.PlaceholderText = "Enter config name"

    local saveAsBtn = UI:CreateButton({ parent = cont, text = "Save As", callback = function()
        local name = tostring(saveAsBox.Text or "")
        if name == "" then UI:CreateNotify({ title = "Config", description = "Enter a name first" }); return end
        UI:SaveConfig(name)
        selectedLabel.Text = "Selected: " .. name
        saveAsBox.Text = ""
    end })
    saveAsBtn.Position = UDim2.new(0.62, 8, 0, 78)

    local autoLoadToggle = UI:CreateToggle({
        parent = cont,
        text = "Auto Load Last Config",
        default = UI.Settings and UI.Settings.AutoLoad,
        callback = function(state)
            UI.Settings.AutoLoad = state
            UI:SaveSettings()
            UI:CreateNotify({ title = "Config Manager", description = "Auto Load is " .. (state and "ON" or "OFF") })
        end
    })
    autoLoadToggle.Position = UDim2.new(0, 8, 0, 78)

    return s
end

-- Init
UI:LoadSettings()
if UI.Settings and UI.Settings.AutoLoad then
    local last = loadLastConfig()
    if last then UI:LoadConfig(last) else UI:LoadConfig("Default") end
end

pcall(function()
    local defaultPath = UI.ConfigsFolder .. "/Default.json"
    if writefile and (not isfile or not isfile(defaultPath)) then
        pcall(function() writefile(defaultPath, HttpService:JSONEncode({})) end)
    end
end)

-- 🔑 Hotkey Toggle (RightShift)
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if ScreenGui then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end
end)

return UI
