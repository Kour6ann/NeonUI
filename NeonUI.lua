-- Minimal UI Library with Config Manager
local Player = game:GetService("Players")
local LocalPlayer = Player.LocalPlayer
local HttpService = game:GetService("HttpService")

local UI = {}
UI.Config = {}
UI.ConfigsFolder = "Kour6anHubConfigs"
UI.SettingsFile = UI.ConfigsFolder .. "/settings.json"
UI.LastConfigFile = UI.ConfigsFolder .. "/lastConfig.json"

-- Ensure folder exists
if makefolder and not isfolder(UI.ConfigsFolder) then
    makefolder(UI.ConfigsFolder)
end

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
    local section = tab:CreateSection("Config Manager")

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
    local saveBtn = Instance.new("TextButton", section)
    saveBtn.Size = UDim2.new(0, 100, 0, 30)
    saveBtn.Position = UDim2.new(0, 220, 0, 10)
    saveBtn.Text = "Save"
    saveBtn.MouseButton1Click:Connect(function()
        local name = string.gsub(selectedLabel.Text,"Selected: ","")
        UI:SaveConfig(name)
        refreshConfigs()
    end)

    -- Load
    local loadBtn = Instance.new("TextButton", section)
    loadBtn.Size = UDim2.new(0, 100, 0, 30)
    loadBtn.Position = UDim2.new(0, 220, 0, 50)
    loadBtn.Text = "Load"
    loadBtn.MouseButton1Click:Connect(function()
        local name = string.gsub(selectedLabel.Text,"Selected: ","")
        UI:LoadConfig(name)
    end)

    -- Delete
    local deleteBtn = Instance.new("TextButton", section)
    deleteBtn.Size = UDim2.new(0, 100, 0, 30)
    deleteBtn.Position = UDim2.new(0, 220, 0, 90)
    deleteBtn.Text = "Delete"
    deleteBtn.MouseButton1Click:Connect(function()
        local name = string.gsub(selectedLabel.Text,"Selected: ","")
        local path = UI.ConfigsFolder .. "/" .. name .. ".json"
        if delfile and isfile(path) then
            delfile(path)
            UI:CreateNotify({title="Config", description="Deleted " .. name})
            selectedLabel.Text = "Selected: Default"
            refreshConfigs()
        end
    end)

    -- Save As
    local newConfigBox = Instance.new("TextBox", section)
    newConfigBox.Size = UDim2.new(0, 200, 0, 30)
    newConfigBox.Position = UDim2.new(0, 10, 0, 200)
    newConfigBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
    newConfigBox.TextColor3 = Color3.new(1,1,1)
    newConfigBox.PlaceholderText = "Enter new config name"

    local saveAsBtn = Instance.new("TextButton", section)
    saveAsBtn.Size = UDim2.new(0, 100, 0, 30)
    saveAsBtn.Position = UDim2.new(0, 220, 0, 200)
    saveAsBtn.Text = "Save As"
    saveAsBtn.MouseButton1Click:Connect(function()
        local name = newConfigBox.Text
        if name ~= "" then
            UI:SaveConfig(name)
            selectedLabel.Text = "Selected: " .. name
            newConfigBox.Text = ""
            refreshConfigs()
        else
            UI:CreateNotify({title="Config", description="Enter a name first!"})
        end
    end)

    -- Auto Load Toggle
    local autoLoadBtn = Instance.new("TextButton", section)
    autoLoadBtn.Size = UDim2.new(0, 200, 0, 30)
    autoLoadBtn.Position = UDim2.new(0, 10, 0, 250)

    local function updateAutoLoadBtn()
        autoLoadBtn.Text = "Auto Load Last Config: " .. (UI.Settings.AutoLoad and "ON" or "OFF")
    end

    autoLoadBtn.MouseButton1Click:Connect(function()
        UI.Settings.AutoLoad = not UI.Settings.AutoLoad
        UI:SaveSettings()
        updateAutoLoadBtn()
        UI:CreateNotify({
            title="Config Manager",
            description="Auto Load Last Config is now " .. (UI.Settings.AutoLoad and "ON" or "OFF")
        })
    end)
    updateAutoLoadBtn()

    -- Reset Settings
    local resetBtn = Instance.new("TextButton", section)
    resetBtn.Size = UDim2.new(0, 200, 0, 30)
    resetBtn.Position = UDim2.new(0, 10, 0, 290)
    resetBtn.Text = "Reset Settings"
    resetBtn.MouseButton1Click:Connect(function()
        if delfile and isfile and isfile(UI.SettingsFile) then
            delfile(UI.SettingsFile)
        end
        UI.Settings = { AutoLoad = true }
        UI:SaveSettings()
        updateAutoLoadBtn()
        UI:CreateNotify({title="Config Manager", description="Settings reset to default!"})
    end)

    -- Reset All Configs
    local resetAllBtn = Instance.new("TextButton", section)
    resetAllBtn.Size = UDim2.new(0, 200, 0, 30)
    resetAllBtn.Position = UDim2.new(0, 10, 0, 330)
    resetAllBtn.Text = "Reset All Configs"
    resetAllBtn.MouseButton1Click:Connect(function()
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
    end)
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
