-- NeonUI (Extended + Multi-Select Dropdowns)
local Player = game:GetService("Players")
local LocalPlayer = Player.LocalPlayer
local HttpService = game:GetService("HttpService")

local UI = {}
UI.Config, UI.Tabs = {}, {}
UI.ActiveTab, UI.Minimized = nil, false
UI.ConfigsFolder = "Kour6anHubConfigs"
UI.SettingsFile = UI.ConfigsFolder.."/settings.json"
UI.LastConfigFile = UI.ConfigsFolder.."/lastConfig.json"

if makefolder and not isfolder(UI.ConfigsFolder) then makefolder(UI.ConfigsFolder) end

local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "Kour6anHubUI"

-- Notify
function UI:CreateNotify(opts) print("[NOTIFY]", opts.title, opts.description) end

-- Settings
function UI:LoadSettings()
    if readfile and isfile and isfile(UI.SettingsFile) then
        local ok,decoded = pcall(function() return HttpService:JSONDecode(readfile(UI.SettingsFile)) end)
        if ok and decoded then UI.Settings=decoded return end
    end
    UI.Settings={AutoLoad=true}
end
function UI:SaveSettings() if writefile then writefile(UI.SettingsFile, HttpService:JSONEncode(UI.Settings)) end end
local function saveLastConfig(name) if writefile then writefile(UI.LastConfigFile, HttpService:JSONEncode({last=name})) end end
local function loadLastConfig()
    if readfile and isfile and isfile(UI.LastConfigFile) then
        local ok,decoded=pcall(function() return HttpService:JSONDecode(readfile(UI.LastConfigFile)) end)
        if ok and decoded and decoded.last then return decoded.last end
    end
end

function UI:SaveConfig(name) name=name or "Default"
    if writefile then writefile(UI.ConfigsFolder.."/"..name..".json", HttpService:JSONEncode(UI.Config)) end
    saveLastConfig(name)
    UI:CreateNotify({title="Config",description="Saved as "..name})
end
function UI:LoadConfig(name) name=name or "Default"
    local path=UI.ConfigsFolder.."/"..name..".json"
    if readfile and isfile and isfile(path) then
        local ok,decoded=pcall(function() return HttpService:JSONDecode(readfile(path)) end)
        if ok and decoded then UI.Config=decoded saveLastConfig(name) UI:CreateNotify({title="Config",description="Loaded "..name}) return end
    end
    UI:CreateNotify({title="Config",description="No config named "..name})
end

function UI:CreateConfigManager(tab)
    local sec=UI:CreateSection({parent=tab,text="Config Manager"})
    UI:CreateButton({parent=sec,text="Save Config",callback=function() UI:SaveConfig("Default") end})
    UI:CreateButton({parent=sec,text="Load Config",callback=function() UI:LoadConfig("Default") end})
end

-- Core UI
function UI:CreateMain(options)
    local main=Instance.new("Frame",ScreenGui)
    main.Size=UDim2.new(0,600,0,400)
    main.Position=UDim2.new(0.5,-300,0.5,-200)
    main.BackgroundColor3=options.Theme and options.Theme.Background or Color3.fromRGB(25,25,25)
    main.Active=true; main.Draggable=true
    UI.MainFrame=main

    local titleBar=Instance.new("Frame",main) titleBar.Size=UDim2.new(1,0,0,30) titleBar.BackgroundColor3=Color3.fromRGB(40,40,40)
    local title=Instance.new("TextLabel",titleBar) title.Size=UDim2.new(1,-60,1,0) title.Text=options.title or "NeonUI" title.TextColor3=Color3.new(1,1,1) title.BackgroundTransparency=1
    local minBtn=Instance.new("TextButton",titleBar) minBtn.Size=UDim2.new(0,30,1,0) minBtn.Position=UDim2.new(1,-60,0,0) minBtn.Text="-" minBtn.BackgroundColor3=Color3.fromRGB(80,80,80)
    local closeBtn=Instance.new("TextButton",titleBar) closeBtn.Size=UDim2.new(0,30,1,0) closeBtn.Position=UDim2.new(1,-30,0,0) closeBtn.Text="X" closeBtn.BackgroundColor3=Color3.fromRGB(150,50,50)
    closeBtn.MouseButton1Click:Connect(function() main.Visible=false end)

    minBtn.MouseButton1Click:Connect(function()
        if not UI.Minimized then for _,c in ipairs(main:GetChildren()) do if c~=titleBar then c.Visible=false end end UI.Minimized=true
        else for n,t in pairs(UI.Tabs) do t.Visible=(UI.ActiveTab==n) end if UI.TabBar then UI.TabBar.Visible=true end UI.Minimized=false end
    end)

    local tabBar=Instance.new("Frame",main) tabBar.Size=UDim2.new(1,0,0,30) tabBar.Position=UDim2.new(0,0,0,30) tabBar.BackgroundColor3=Color3.fromRGB(35,35,35) UI.TabBar=tabBar
    return UI
end

function UI:CreateTab(title)
    local tab=Instance.new("ScrollingFrame",UI.MainFrame)
    tab.Name=title tab.Size=UDim2.new(1,-10,1,-65) tab.Position=UDim2.new(0,5,0,65)
    tab.BackgroundTransparency=1 tab.Visible=false tab.ScrollBarThickness=6
    local list=Instance.new("UIListLayout",tab) list.Padding=UDim.new(0,5) list.SortOrder=Enum.SortOrder.LayoutOrder
    UI.Tabs[title]=tab
    local btn=Instance.new("TextButton",UI.TabBar) btn.Size=UDim2.new(0,100,1,0) btn.Text=title btn.BackgroundColor3=Color3.fromRGB(60,60,60) btn.TextColor3=Color3.new(1,1,1)
    btn.MouseButton1Click:Connect(function() for _,t in pairs(UI.Tabs) do t.Visible=false end tab.Visible=true UI.ActiveTab=title end)
    return tab
end

-- Elements
function UI:CreateSection(o) local s=Instance.new("Frame",o.parent) s.Size=UDim2.new(1,-10,0,40) s.BackgroundTransparency=1 local l=Instance.new("TextLabel",s) l.Size=UDim2.new(1,0,0,30) l.Text=o.text or "Section" l.TextColor3=Color3.new(1,1,1) l.BackgroundTransparency=1 return s end
function UI:CreateToggle(o) local b=Instance.new("TextButton",o.parent) b.Size=UDim2.new(0,200,0,30) local st=o.default or false b.Text=o.text..": "..(st and "ON" or "OFF") b.BackgroundColor3=Color3.fromRGB(50,50,50) b.TextColor3=Color3.new(1,1,1) b.MouseButton1Click:Connect(function() st=not st b.Text=o.text..": "..(st and "ON" or "OFF") if o.callback then o.callback(st) end end) return b end
function UI:CreateSlider(o) local s=Instance.new("TextButton",o.parent) s.Size=UDim2.new(0,200,0,30) local v=o.default or o.min s.Text=o.text..": "..tostring(v) s.BackgroundColor3=Color3.fromRGB(80,80,80) s.TextColor3=Color3.new(1,1,1) s.MouseButton1Click:Connect(function() v=v+1 if v>o.max then v=o.min end s.Text=o.text..": "..tostring(v) if o.callback then o.callback(v) end end) return s end
function UI:CreateButton(o) local b=Instance.new("TextButton",o.parent) b.Size=UDim2.new(0,200,0,30) b.Text=o.text b.BackgroundColor3=Color3.fromRGB(70,70,70) b.TextColor3=Color3.new(1,1,1) b.MouseButton1Click:Connect(function() if o.callback then o.callback() end end) return b end

-- 🔥 Multi-Select Dropdown
function UI:CreateDropdown(o)
    local b=Instance.new("TextButton",o.parent) b.Size=UDim2.new(0,200,0,30)
    local current,selected=o.default or (o.multi and {} or (o.options and o.options[1])) or {}
    local function updateText()
        if o.multi then b.Text=o.text..": "..(next(selected) and table.concat(selected,", ") or "None")
        else b.Text=o.text..": "..tostring(current) end
    end
    updateText()
    b.BackgroundColor3=Color3.fromRGB(60,60,60) b.TextColor3=Color3.new(1,1,1)
    b.MouseButton1Click:Connect(function()
        if not o.options then return end
        if o.multi then
            -- Toggle one option per click
            local cycle=o.options
            local idx=(table.find(cycle,selected[#selected]) or 0)+1
            if idx>#cycle then idx=1 end
            local opt=cycle[idx]
            if table.find(selected,opt) then
                table.remove(selected,table.find(selected,opt))
            else
                table.insert(selected,opt)
            end
            updateText()
            if o.callback then o.callback(selected) end
        else
            local idx=(table.find(o.options,current) or 0)+1
            if idx>#o.options then idx=1 end
            current=o.options[idx] updateText()
            if o.callback then o.callback(current) end
        end
    end)
    return b
end

function UI:CreateParagraph(o) local f=Instance.new("Frame",o.parent) f.Size=UDim2.new(0,250,0,80) f.BackgroundTransparency=1 local t=Instance.new("TextLabel",f) t.Size=UDim2.new(1,0,0,20) t.Text=o.title or "Paragraph" t.TextColor3=Color3.new(1,1,1) t.BackgroundTransparency=1 local tx=Instance.new("TextLabel",f) tx.Size=UDim2.new(1,0,0,60) tx.Position=UDim2.new(0,0,0,20) tx.TextWrapped=true tx.TextXAlignment=Enum.TextXAlignment.Left tx.Text=o.text or "" tx.TextColor3=Color3.new(0.9,0.9,0.9) tx.BackgroundTransparency=1 return f end
function UI:CreateColorPicker(o) local b=Instance.new("TextButton",o.parent) b.Size=UDim2.new(0,200,0,30) b.Text=o.text b.BackgroundColor3=o.default or Color3.fromRGB(255,0,0) b.TextColor3=Color3.new(1,1,1) b.MouseButton1Click:Connect(function() local c=Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255)) b.BackgroundColor3=c if o.callback then o.callback(c) end end) return b end

-- Init
UI:LoadSettings() if UI.Settings.AutoLoad then local last=loadLastConfig() if last then UI:LoadConfig(last) else UI:LoadConfig("Default") end end
return UI
