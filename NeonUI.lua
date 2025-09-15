-- NeonUI.lua (Final Fixed Version)
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

-- ensure config folder
if makefolder and not isfolder(UI.ConfigsFolder) then
    pcall(makefolder, UI.ConfigsFolder)
end

-- create ScreenGui
local function createScreenGui()
    local parent = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    if not parent then parent = game:GetService("CoreGui") end
    local existing = parent:FindFirstChild("Kour6anHubUI")
    if existing then pcall(function() existing:Destroy() end) end

    local sg = Instance.new("ScreenGui")
    sg.Name = "Kour6anHubUI"
    sg.ResetOnSpawn = false
    sg.Parent = parent
    return sg
end

local ScreenGui = createScreenGui()

-- simple clamp
local function clamp(x, a, b)
    return (x < a and a) or (x > b and b) or x
end

-- notify
function UI:CreateNotify(opts)
    print("[NOTIFY]", opts.title or "Notify", opts.description or "")
end

-- settings load/save
function UI:LoadSettings()
    UI.Settings = { AutoLoad = true }
    if readfile and isfile and isfile(UI.SettingsFile) then
        local ok, raw = pcall(readfile, UI.SettingsFile)
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
        pcall(function()
            writefile(UI.LastConfigFile, HttpService:JSONEncode({ last = name }))
        end)
    end
end

local function loadLastConfig()
    if readfile and isfile and isfile(UI.LastConfigFile) then
        local ok, raw = pcall(readfile, UI.LastConfigFile)
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
        local ok, raw = pcall(readfile, path)
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
    main.BackgroundColor3 = Color3.fromRGB(25,25,25)
    main.Active = true
    main.Draggable = true
    UI.MainFrame = main

    local titleBar = Instance.new("Frame", main)
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 36)
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
    tabBar.BackgroundColor3 = Color3.fromRGB(30,30,30)
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
                tab.Visible = (UI.ActiveTab == name)
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

-- CreateTab
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
        tab.CanvasSize = UDim2.new(0,0,0,list.AbsoluteContentSize.Y+20)
    end)

    UI.Tabs[title] = tab

    local btn = Instance.new("TextButton", UI.TabBar)
    btn.Name = "TabBtn_" .. tostring(title)
    btn.Size = UDim2.new(0, 120, 1, -10)
    btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
    btn.Text = tostring(title)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 16

    btn.MouseButton1Click:Connect(function()
        for n, t in pairs(UI.Tabs) do
            t.Visible = false
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

-- CreateSlider (fixed draggable)
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

    local dragging = false

    local function setFill()
        local range = max - min
        local ratio = (value - min) / (range > 0 and range or 1)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        label.Text = tostring(opts.text or "Slider") .. " (" .. tostring(value) .. ")"
        if type(opts.callback) == "function" then
            pcall(opts.callback, value)
        end
    end

    local function updateFromMouse(mouseX)
        local barPos = bar.AbsolutePosition.X
        local barW = bar.AbsoluteSize.X
        local rel = clamp((mouseX - barPos) / barW, 0, 1)
        value = min + math.floor((max - min) * rel + 0.5)
        setFill()
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromMouse(input.Position.X)
        end
    end)

    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse(input.Position.X)
        end
    end)

    setFill()
    return container
end

-- Toggle
function UI:CreateToggle(opts)
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

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(0.28, -12, 0, 24)
    btn.Position = UDim2.new(0.72, 6, 0, 3)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 14
    btn.BorderSizePixel = 0

    local state = opts.default or false
    btn.Text = state and "ON" or "OFF"

    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        if opts.callback then pcall(opts.callback, state) end
    end)

    return container
end

function UI:CreateSlider(opts)
    local frame = Instance.new("Frame", opts.parent)
    frame.Size = UDim2.new(0, 200, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1, 0, 0.5, 0)
    bar.Position = UDim2.new(0, 0, 0.25, 0)
    bar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(138, 43, 226) -- accent

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.Text = opts.text .. ": " .. tostring(opts.default or opts.min)

    local dragging = false
    local value = opts.default or opts.min

    local function update(inputX)
        local relative = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = math.floor(opts.min + (opts.max - opts.min) * relative)
        fill.Size = UDim2.new(relative, 0, 1, 0)
        label.Text = opts.text .. ": " .. tostring(value)
        if opts.callback then opts.callback(value) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position.X)
        end
    end)

    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position.X)
        end
    end)

    return frame
end

-- Button
function UI:CreateButton(opts)
    local parent = opts.parent or error("CreateButton requires parent")
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1,0,0,30)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Text = opts.text or "Button"
    btn.MouseButton1Click:Connect(function()
        if opts.callback then pcall(opts.callback) end
    end)
    return btn
end

-- Dropdown (popup, multi-select supported, closes properly)
local openPopup=nil
function UI:CreateDropdown(opts)
    local parent = opts.parent or error("CreateDropdown requires parent")
    local options = opts.options or {}
    local multi = opts.multi or false

    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1,0,0,30)
    container.BackgroundTransparency=1

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(0.5,-8,1,0)
    label.Position=UDim2.new(0,8,0,0)
    label.BackgroundTransparency=1
    label.Text = opts.text or "Dropdown"
    label.TextColor3=Color3.new(1,1,1)

    local btn=Instance.new("TextButton",container)
    btn.Size=UDim2.new(0.45,-8,0,24)
    btn.Position=UDim2.new(0.55,8,0,3)
    btn.BackgroundColor3=Color3.fromRGB(70,70,70)
    btn.TextColor3=Color3.new(1,1,1)

    local selectedMulti = {}
    local selectedSingle = options[1] or "None"

    btn.Text = multi and "None" or selectedSingle

    local function closePopup()
        if openPopup then openPopup:Destroy() openPopup=nil end
    end

    btn.MouseButton1Click:Connect(function()
        if openPopup then closePopup() return end
        local popup=Instance.new("Frame",ScreenGui)
        popup.Size=UDim2.new(0,200,0,math.min(200,#options*26))
        local abs=btn.AbsolutePosition
        local sz=btn.AbsoluteSize
        popup.Position=UDim2.new(0,abs.X,0,abs.Y+sz.Y+4)
        popup.BackgroundColor3=Color3.fromRGB(35,35,35)
        popup.ZIndex=1000

        local layout=Instance.new("UIListLayout",popup)
        layout.SortOrder=Enum.SortOrder.LayoutOrder

        for _,opt in ipairs(options) do
            local optBtn=Instance.new("TextButton",popup)
            optBtn.Size=UDim2.new(1,0,0,26)
            optBtn.BackgroundColor3=Color3.fromRGB(55,55,55)
            optBtn.TextColor3=Color3.new(1,1,1)
            optBtn.Text=opt
            optBtn.ZIndex=1001
            optBtn.MouseButton1Click:Connect(function()
                if multi then
                    if table.find(selectedMulti,opt) then
                        table.remove(selectedMulti,table.find(selectedMulti,opt))
                    else
                        table.insert(selectedMulti,opt)
                    end
                    btn.Text = #selectedMulti>0 and table.concat(selectedMulti,",") or "None"
                    if opts.callback then pcall(opts.callback,selectedMulti) end
                else
                    selectedSingle=opt
                    btn.Text=opt
                    if opts.callback then pcall(opts.callback,opt) end
                    closePopup()
                end
            end)
        end

        openPopup=popup
        UIS.InputBegan:Connect(function(input,proc)
            if proc then return end
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                local m=UIS:GetMouseLocation()
                local pos=popup.AbsolutePosition
                local size=popup.AbsoluteSize
                if not (m.X>=pos.X and m.X<=pos.X+size.X and m.Y>=pos.Y and m.Y<=pos.Y+size.Y) then
                    closePopup()
                end
            end
        end)
    end)

    return container
end

-- Paragraph
function UI:CreateParagraph(opts)
    local parent = opts.parent or error("CreateParagraph requires parent")
    local frame = Instance.new("Frame", parent)
    frame.Size=UDim2.new(1,0,0,60)
    frame.BackgroundTransparency=1
    local title=Instance.new("TextLabel",frame)
    title.Size=UDim2.new(1,0,0,20)
    title.Text=opts.title or "Paragraph"
    title.TextColor3=Color3.new(1,1,1)
    title.BackgroundTransparency=1
    local text=Instance.new("TextLabel",frame)
    text.Size=UDim2.new(1,0,1,-20)
    text.Position=UDim2.new(0,0,0,20)
    text.Text=opts.text or ""
    text.TextWrapped=true
    text.TextColor3=Color3.new(0.9,0.9,0.9)
    text.BackgroundTransparency=1
    return frame
end

-- ColorPicker
function UI:CreateColorPicker(opts)
    local parent = opts.parent or error("CreateColorPicker requires parent")
    local frame=Instance.new("Frame",parent)
    frame.Size=UDim2.new(1,0,0,30)
    frame.BackgroundTransparency=1
    local label=Instance.new("TextLabel",frame)
    label.Size=UDim2.new(0.6,0,1,0)
    label.Text=opts.text or "Color"
    label.TextColor3=Color3.new(1,1,1)
    label.BackgroundTransparency=1
    local btn=Instance.new("TextButton",frame)
    btn.Size=UDim2.new(0.3,0,1,0)
    btn.Position=UDim2.new(0.65,0,0,0)
    btn.BackgroundColor3=opts.default or Color3.fromRGB(255,0,0)
    btn.MouseButton1Click:Connect(function()
        local c=Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
        btn.BackgroundColor3=c
        if opts.callback then pcall(opts.callback,c) end
    end)
    return frame
end

-- ConfigManager
function UI:CreateConfigManager(tab)
    UI:CreateSection({parent=tab,text="Config Manager"})
    UI:CreateButton({parent=tab,text="Save Default",callback=function() UI:SaveConfig("Default") end})
    UI:CreateButton({parent=tab,text="Load Default",callback=function() UI:LoadConfig("Default") end})
end

-- Init
UI:LoadSettings()
if UI.Settings.AutoLoad then
    local last=loadLastConfig()
    if last then UI:LoadConfig(last) else UI:LoadConfig("Default") end
end

return UI
