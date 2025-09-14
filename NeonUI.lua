-- NeonUI.lua (Robust, full-featured, safe)
-- Replace your existing NeonUI.lua with this file.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local UI = {}
UI.Config = {}
UI.Tabs = {}
UI.ActiveTab = nil
UI.Minimized = false
UI.ConfigsFolder = "Kour6anHubConfigs"
UI.SettingsFile = UI.ConfigsFolder .. "/settings.json"
UI.LastConfigFile = UI.ConfigsFolder .. "/lastConfig.json"

-- Ensure configs folder exists (supported by many executors)
if makefolder and not isfolder(UI.ConfigsFolder) then
    pcall(function() makefolder(UI.ConfigsFolder) end)
end

-- Create or reuse ScreenGui
local function getScreenGui()
    local parent = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
    if not parent then
        -- fallback - safety
        parent = game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    end

    local existing = parent:FindFirstChild("Kour6anHubUI")
    if existing and existing:IsA("ScreenGui") then
        existing:Destroy()
    end

    local sg = Instance.new("ScreenGui")
    sg.Name = "Kour6anHubUI"
    sg.ResetOnSpawn = false
    sg.Parent = parent
    return sg
end

local ScreenGui = getScreenGui()

-- Simple notification: prints and transient GUI popup
function UI:CreateNotify(opts)
    pcall(function()
        print("[NOTIFY]", opts.title or "Notify", opts.description or "")
        -- lightweight visual toast (non-intrusive)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 50)
        frame.Position = UDim2.new(0.5, -150, 0.1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
        frame.BorderSizePixel = 0
        frame.Parent = ScreenGui

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, -10, 0, 20)
        title.Position = UDim2.new(0, 5, 0, 3)
        title.BackgroundTransparency = 1
        title.Text = opts.title or ""
        title.TextColor3 = Color3.new(1,1,1)
        title.TextScaled = false
        title.Font = Enum.Font.SourceSansBold

        local desc = Instance.new("TextLabel", frame)
        desc.Size = UDim2.new(1, -10, 0, 24)
        desc.Position = UDim2.new(0, 5, 0, 22)
        desc.BackgroundTransparency = 1
        desc.Text = opts.description or ""
        desc.TextColor3 = Color3.new(0.9,0.9,0.9)
        desc.TextWrapped = true
        desc.TextXAlignment = Enum.TextXAlignment.Left

        task.defer(function()
            task.wait(3.0)
            pcall(function() frame:Destroy() end)
        end)
    end)
end

-- Settings (save/load)
function UI:LoadSettings()
    UI.Settings = { AutoLoad = true }
    if readfile and isfile and isfile(UI.SettingsFile) then
        local ok, data = pcall(function() return readfile(UI.SettingsFile) end)
        if ok and data then
            local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
            if ok2 and type(decoded) == "table" then
                UI.Settings = decoded
            end
        end
    end
end

function UI:SaveSettings()
    if writefile then
        local ok, encoded = pcall(function() return HttpService:JSONEncode(UI.Settings) end)
        if ok and encoded then
            pcall(function() writefile(UI.SettingsFile, encoded) end)
        end
    end
end

local function saveLastConfig(name)
    if writefile then
        pcall(function() writefile(UI.LastConfigFile, HttpService:JSONEncode({ last = name })) end)
    end
end

local function loadLastConfig()
    if readfile and isfile and isfile(UI.LastConfigFile) then
        local ok, d = pcall(function() return readfile(UI.LastConfigFile) end)
        if ok and d then
            local ok2, dec = pcall(function() return HttpService:JSONDecode(d) end)
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
        local ok, data = pcall(function() return readfile(path) end)
        if ok and data then
            local ok2, decoded = pcall(function() return HttpService:JSONDecode(data) end)
            if ok2 and decoded then
                UI.Config = decoded
                saveLastConfig(profileName)
                UI:CreateNotify({ title = "Config", description = "Loaded " .. profileName })
                return
            end
        end
    end
    UI:CreateNotify({ title = "Config", description = "No config named " .. profileName })
end

-- UI core: CreateMain with titlebar, tabbar, minimize/close
function UI:CreateMain(options)
    options = options or {}
    -- clear if exists
    if UI.MainFrame and UI.MainFrame.Parent then
        pcall(function() UI.MainFrame:Destroy() end)
    end

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 640, 0, 420)
    main.Position = UDim2.new(0.5, -320, 0.5, -210)
    main.BackgroundColor3 = (options.Theme and options.Theme.Background) or Color3.fromRGB(25,25,25)
    main.Active = true
    main.Draggable = true
    main.Parent = ScreenGui
    UI.MainFrame = main

    -- Titlebar
    local titleBar = Instance.new("Frame", main)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 32)
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

    local function makeTitleButton(text, xOffset)
        local btn = Instance.new("TextButton", titleBar)
        btn.Size = UDim2.new(0, 28, 1, -6)
        btn.Position = UDim2.new(1, xOffset, 0, 3)
        btn.Text = text
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 18
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
        btn.BorderSizePixel = 0
        return btn
    end

    local minBtn = makeTitleButton("-", -80)
    local closeBtn = makeTitleButton("X", -46)

    -- TabBar (buttons)
    local tabBar = Instance.new("Frame", main)
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 34)
    tabBar.Position = UDim2.new(0, 0, 0, 32)
    tabBar.BackgroundColor3 = (options.Theme and options.Theme.NavBackground) or Color3.fromRGB(30,30,30)

    local listLayout = Instance.new("UIListLayout", tabBar)
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 6)

    UI.TabBar = tabBar
    UI.TitleBar = titleBar

    -- store original size for restore
    local originalSize = main.Size

    -- Minimize: shrink to titlebar only and hide all other children (including TabBar)
    minBtn.MouseButton1Click:Connect(function()
        if not UI.Minimized then
            originalSize = main.Size
            -- shrink
            main.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, titleBar.Size.Y.Offset)
            -- hide everything except titlebar
            for _, child in ipairs(main:GetChildren()) do
                if child ~= titleBar then
                    child.Visible = false
                end
            end
            UI.Minimized = true
        else
            -- restore
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

    -- Close
    closeBtn.MouseButton1Click:Connect(function()
        pcall(function() main:Destroy() end)
    end)

    return UI
end

-- CreateTab: scrolling frame + UIListLayout + tab button
function UI:CreateTab(title)
    if not UI.MainFrame then
        error("CreateMain must be called before CreateTab()", 2)
    end

    -- create the scrolling content area
    local tab = Instance.new("ScrollingFrame", UI.MainFrame)
    tab.Name = tostring(title)
    tab.Size = UDim2.new(1, -16, 1, -72) -- leaves space for titlebar and tabbar
    tab.Position = UDim2.new(0, 8, 0, 68)
    tab.BackgroundTransparency = 1
    tab.ScrollBarThickness = 6
    tab.Visible = false
    tab.CanvasSize = UDim2.new(0, 0, 0, 0) -- will auto expand with UIListLayout

    local layout = Instance.new("UIListLayout", tab)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)

    UI.Tabs[title] = tab

    -- create tab button in tabBar
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
        for n, t in pairs(UI.Tabs) do
            if t and t:IsA("ScrollingFrame") then
                t.Visible = false
            end
        end
        tab.Visible = true
        UI.ActiveTab = title
    end)

    -- auto-show first tab created
    if not UI.ActiveTab then
        tab.Visible = true
        UI.ActiveTab = title
    end

    return tab
end

-- CreateSection: simple label container (full width)
function UI:CreateSection(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateSection requires parent")
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -6, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(opts.text or "Section")
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.SourceSansBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left

    return frame
end

-- CreateToggle: full-width toggle that calls callback(state)
function UI:CreateToggle(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateToggle requires parent")
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.7, -8, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(opts.text or "Toggle")
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0.28, -8, 0, 24)
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
        if type(opts.callback) == "function" then
            pcall(opts.callback, state)
        end
    end)

    return container
end

-- CreateSlider: clicking cycles value by +1, wraps at max. calls callback(value)
-- (keeps implementation simple and robust)
function UI:CreateSlider(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateSlider requires parent")
    local min = tonumber(opts.min) or 0
    local max = tonumber(opts.max) or min
    local value = tonumber(opts.default) or min

    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, -8, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(opts.text or "Slider") .. ": " .. tostring(value)
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0.38, -8, 0, 24)
    btn.Position = UDim2.new(0.62, 6, 0, 3)
    btn.BackgroundColor3 = Color3.fromRGB(80,80,80)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.Text = tostring(value)

    btn.MouseButton1Click:Connect(function()
        value = value + 1
        if value > max then value = min end
        label.Text = tostring(opts.text or "Slider") .. ": " .. tostring(value)
        btn.Text = tostring(value)
        if type(opts.callback) == "function" then
            pcall(opts.callback, value)
        end
    end)

    return container
end

-- CreateButton: full-width-ish button
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
        btn.MouseButton1Click:Connect(function()
            pcall(opts.callback)
        end)
    end

    return btn
end

-- CreateDropdown: supports single-select (default) and multi-select (popup list)
function UI:CreateDropdown(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateDropdown requires parent")
    local options = opts.options or {}
    local isMulti = opts.multi and true or false

    -- container full width
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundTransparency = 1

    local titleLabel = Instance.new("TextLabel", container)
    titleLabel.Size = UDim2.new(0.55, -8, 1, 0)
    titleLabel.Position = UDim2.new(0, 6, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = tostring(opts.text or "Select")
    titleLabel.TextColor3 = Color3.new(1,1,1)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Font = Enum.Font.SourceSans
    titleLabel.TextSize = 16

    local mainBtn = Instance.new("TextButton", container)
    mainBtn.Size = UDim2.new(0.45, -8, 0, 24)
    mainBtn.Position = UDim2.new(0.55, 6, 0, 3)
    mainBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    mainBtn.BorderSizePixel = 0
    mainBtn.TextColor3 = Color3.new(1,1,1)
    mainBtn.Font = Enum.Font.SourceSans
    mainBtn.TextSize = 14

    -- selected state
    local selectedSingle = nil
    local selectedMulti = {}

    -- initialize defaults
    if isMulti then
        if type(opts.default) == "table" then
            for _, v in ipairs(opts.default) do
                if table.find(options, v) then
                    table.insert(selectedMulti, v)
                end
            end
        end
        mainBtn.Text = (#selectedMulti > 0) and table.concat(selectedMulti, ", ") or "None"
    else
        if opts.default then
            if type(opts.default) == "string" and table.find(options, opts.default) then
                selectedSingle = opts.default
            elseif #options > 0 then
                selectedSingle = options[1]
            end
        else
            selectedSingle = options[1]
        end
        mainBtn.Text = tostring(selectedSingle or "")
    end

    -- popup frame (created on demand)
    local popup
    local function createPopup()
        if popup and popup.Parent then popup:Destroy() end
        popup = Instance.new("Frame")
        popup.Size = UDim2.new(0, 220, 0, math.clamp(#options * 28, 28, 300))
        popup.Position = mainBtn.AbsolutePosition + Vector2.new(0, mainBtn.AbsoluteSize.Y + 6)
        popup.BackgroundColor3 = Color3.fromRGB(40,40,40)
        popup.BorderSizePixel = 0
        popup.Parent = ScreenGui
        popup.ClipsDescendants = true

        local ui = Instance.new("UIListLayout", popup)
        ui.SortOrder = Enum.SortOrder.LayoutOrder
        ui.Padding = UDim.new(0, 2)

        -- create option buttons
        for _, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton", popup)
            optBtn.Size = UDim2.new(1, -8, 0, 26)
            optBtn.Position = UDim2.new(0, 4, 0, 0)
            optBtn.Text = tostring(opt)
            optBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
            optBtn.TextColor3 = Color3.new(1,1,1)
            optBtn.AutoButtonColor = true
            optBtn.Font = Enum.Font.SourceSans
            optBtn.TextSize = 14

            optBtn.MouseButton1Click:Connect(function()
                if isMulti then
                    local idx = table.find(selectedMulti, opt)
                    if idx then
                        table.remove(selectedMulti, idx)
                    else
                        table.insert(selectedMulti, opt)
                    end
                    mainBtn.Text = (#selectedMulti > 0) and table.concat(selectedMulti, ", ") or "None"
                    if type(opts.callback) == "function" then
                        pcall(opts.callback, selectedMulti)
                    end
                else
                    selectedSingle = opt
                    mainBtn.Text = tostring(selectedSingle)
                    if type(opts.callback) == "function" then
                        pcall(opts.callback, selectedSingle)
                    end
                    -- close popup after single select
                    if popup and popup.Parent then
                        popup:Destroy()
                        popup = nil
                    end
                end
            end)
        end

        -- clicking outside closes popup
        local conn
        conn = UserInputService.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if popup and popup.Parent then
                local mousePos = inp.Position
                local abs = popup.AbsolutePosition
                local size = popup.AbsoluteSize
                if not (mousePos.X >= abs.X and mousePos.X <= abs.X + size.X and mousePos.Y >= abs.Y and mousePos.Y <= abs.Y + size.Y) then
                    pcall(function() popup:Destroy() end)
                    popup = nil
                    conn:Disconnect()
                end
            else
                conn:Disconnect()
            end
        end)
    end

    mainBtn.MouseButton1Click:Connect(function()
        -- toggle popup
        if popup and popup.Parent then
            pcall(function() popup:Destroy() end)
            popup = nil
        else
            createPopup()
        end
    end)

    -- return a small helper object so callers can programmatically set/get values if needed
    local api = {
        get = function()
            if isMulti then
                return selectedMulti
            else
                return selectedSingle
            end
        end,
        set = function(val)
            if isMulti and type(val) == "table" then
                selectedMulti = {}
                for _, v in ipairs(val) do if table.find(options, v) then table.insert(selectedMulti, v) end end
                mainBtn.Text = (#selectedMulti>0) and table.concat(selectedMulti, ", ") or "None"
                if type(opts.callback) == "function" then pcall(opts.callback, selectedMulti) end
            elseif (not isMulti) and type(val) == "string" then
                if table.find(options, val) then
                    selectedSingle = val
                    mainBtn.Text = selectedSingle
                    if type(opts.callback) == "function" then pcall(opts.callback, selectedSingle) end
                end
            end
        end
    }

    return api
end

-- CreateParagraph
function UI:CreateParagraph(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateParagraph requires parent")
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -6, 0, 18)
    title.Position = UDim2.new(0, 6, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = tostring(opts.title or "")
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left

    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1, -6, 1, -20)
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

-- CreateColorPicker (simple random color for convenience)
function UI:CreateColorPicker(opts)
    opts = opts or {}
    local parent = opts.parent or error("CreateColorPicker requires parent")
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, 0, 0, 30)
    container.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.6, -8, 1, 0)
    label.Position = UDim2.new(0, 6, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(opts.text or "Color")
    label.TextColor3 = Color3.new(1,1,1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0.38, -8, 0, 24)
    btn.Position = UDim2.new(0.62, 6, 0, 3)
    btn.BackgroundColor3 = opts.default or Color3.fromRGB(255,0,0)
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.MouseButton1Click:Connect(function()
        local c = Color3.fromRGB(math.random(0,255), math.random(0,255), math.random(0,255))
        btn.BackgroundColor3 = c
        if type(opts.callback) == "function" then
            pcall(opts.callback, c)
        end
    end)

    return container
end

-- CreateConfigManager (basic full-feature)
function UI:CreateConfigManager(tab)
    if not tab then return end
    local section = UI:CreateSection({ parent = tab, text = "Config Manager" })

    local container = Instance.new("Frame", tab)
    container.Size = UDim2.new(1, 0, 0, 140)
    container.BackgroundTransparency = 1

    local selectedLabel = Instance.new("TextLabel", container)
    selectedLabel.Size = UDim2.new(0.6, -8, 0, 28)
    selectedLabel.Position = UDim2.new(0, 6, 0, 6)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = "Selected: Default"
    selectedLabel.TextColor3 = Color3.new(1,1,1)
    selectedLabel.Font = Enum.Font.SourceSans
    selectedLabel.TextSize = 15
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left

    local function refreshConfigs()
        -- build list of config files
        local files = {}
        if listfiles and isfolder and isfolder(UI.ConfigsFolder) then
            local ok, fl = pcall(function() return listfiles(UI.ConfigsFolder) end)
            if ok and type(fl) == "table" then
                for _, f in ipairs(fl) do
                    local name = f:match("([^/\\]+)%.json$")
                    if name and name ~= "settings" and name ~= "lastConfig" then
                        table.insert(files, name)
                    end
                end
            end
        end
        return files
    end

    -- Save button
    local saveBtn = UI:CreateButton({
        parent = container,
        text = "Save",
        callback = function()
            local name = tostring(selectedLabel.Text):gsub("^Selected:%s*", ""):gsub("^Selected: ", ""):gsub("Selected: ","")
            if name == "" then name = "Default" end
            UI:SaveConfig(name)
        end
    })
    saveBtn.Position = UDim2.new(0.62, 6, 0, 6)

    -- Load button
    local loadBtn = UI:CreateButton({
        parent = container,
        text = "Load",
        callback = function()
            local name = tostring(selectedLabel.Text):gsub("^Selected:%s*", ""):gsub("^Selected: ", ""):gsub("Selected: ","")
            if name == "" then name = "Default" end
            UI:LoadConfig(name)
        end
    })
    loadBtn.Position = UDim2.new(0.62, 6, 0, 40)

    -- Delete button
    local deleteBtn = UI:CreateButton({
        parent = container,
        text = "Delete",
        callback = function()
            local name = tostring(selectedLabel.Text):gsub("^Selected:%s*", ""):gsub("^Selected: ", ""):gsub("Selected: ","")
            local path = UI.ConfigsFolder .. "/" .. name .. ".json"
            if delfile and isfile and isfile(path) then
                pcall(function() delfile(path) end)
                UI:CreateNotify({ title = "Config", description = "Deleted " .. name })
                selectedLabel.Text = "Selected: Default"
            else
                UI:CreateNotify({ title = "Config", description = "Nothing to delete" })
            end
        end
    })
    deleteBtn.Position = UDim2.new(0.62, 6, 0, 74)

    -- Save As input
    local saveAsBox = Instance.new("TextBox", container)
    saveAsBox.Size = UDim2.new(0.6, -8, 0, 28)
    saveAsBox.Position = UDim2.new(0, 6, 0, 40)
    saveAsBox.Text = ""
    saveAsBox.PlaceholderText = "Enter config name"
    saveAsBox.BackgroundColor3 = Color3.fromRGB(30,30,30)
    saveAsBox.TextColor3 = Color3.new(1,1,1)

    local saveAsBtn = UI:CreateButton({
        parent = container,
        text = "Save As",
        callback = function()
            local name = tostring(saveAsBox.Text or "")
            if name == "" then
                UI:CreateNotify({ title = "Config", description = "Enter a name first" })
                return
            end
            UI:SaveConfig(name)
            selectedLabel.Text = "Selected: " .. name
            saveAsBox.Text = ""
        end
    })
    saveAsBtn.Position = UDim2.new(0.62, 6, 0, 108)

    -- Auto Load toggle
    local autoLoadToggle = UI:CreateToggle({
        parent = container,
        text = "Auto Load Last Config",
        default = UI.Settings and UI.Settings.AutoLoad,
        callback = function(state)
            UI.Settings.AutoLoad = state
            UI:SaveSettings()
            UI:CreateNotify({ title = "Config Manager", description = "Auto Load is " .. (state and "ON" or "OFF") })
        end
    })
    autoLoadToggle.Position = UDim2.new(0, 6, 0, 74)

    -- list existing configs as clickable labels under the container
    local files = refreshConfigs()
    local yoff = 6
    -- small scroll area for configs
    local listFrame = Instance.new("Frame", container)
    listFrame.Size = UDim2.new(0.6, -8, 0, 28)
    listFrame.Position = UDim2.new(0, 6, 0, 108)
    listFrame.BackgroundTransparency = 1

    if #files == 0 then
        local lbl = Instance.new("TextLabel", listFrame)
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = "No configs"
        lbl.TextColor3 = Color3.new(1,1,1)
    else
        for i, name in ipairs(files) do
            local btn = Instance.new("TextButton", listFrame)
            btn.Size = UDim2.new(1, 0, 0, 20)
            btn.Position = UDim2.new(0, 0, 0, (i-1)*22)
            btn.BackgroundColor3 = Color3.fromRGB(40,40,40)
            btn.Text = name
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.SourceSans
            btn.TextSize = 14
            btn.MouseButton1Click:Connect(function()
                selectedLabel.Text = "Selected: " .. name
            end)
        end
        listFrame.Size = UDim2.new(0.6, -8, 0, math.min(#files * 22, 200))
    end

    return section
end

-- INIT: load settings and last config if set
UI:LoadSettings()
if UI.Settings and UI.Settings.AutoLoad then
    local last = loadLastConfig()
    if last then UI:LoadConfig(last) else UI:LoadConfig("Default") end
end

-- ensure Default exists
pcall(function()
    local defaultPath = UI.ConfigsFolder .. "/Default.json"
    if writefile and (not isfile or not isfile(defaultPath)) then
        pcall(function() writefile(defaultPath, HttpService:JSONEncode({})) end)
    end
end)

return UI
