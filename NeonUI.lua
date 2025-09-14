-- NeonUI Library v1.1
-- Standalone Exploit UI Framework (LuaUIX Inspired)

local NeonUI = {}
NeonUI.__index = NeonUI

--// Services
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// Utils
local function Create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function Tween(obj, props, time)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

--// Colors
local colors = {
    background = Color3.fromRGB(33,34,44),
    titlebar   = Color3.fromRGB(46,46,66),
    sidebar    = Color3.fromRGB(27,28,37),
    content    = Color3.fromRGB(40,42,54),
    section    = Color3.fromRGB(23,25,34),
    accent     = Color3.fromRGB(56,172,212),
    toggleOff  = Color3.fromRGB(42,46,59),
    text       = Color3.fromRGB(255,255,255),
    textDim    = Color3.fromRGB(200,200,200),
}

--// Create Window
function NeonUI.new(name)
    local self = setmetatable({}, NeonUI)

    if CoreGui:FindFirstChild("NeonUI_"..name) then
        CoreGui["NeonUI_"..name]:Destroy()
    end

    self.gui = Create("ScreenGui", {
        Name = "NeonUI_"..name,
        ResetOnSpawn = false,
        Parent = CoreGui
    })

    self.window = Create("Frame", {
        Size = UDim2.new(0,650,0,500),
        Position = UDim2.new(0.5,-325,0.5,-250),
        BackgroundColor3 = colors.background,
        Parent = self.gui
    })
    Create("UICorner",{CornerRadius=UDim.new(0,12),Parent=self.window})

    -- Titlebar
    self.titlebar = Create("Frame", {
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = colors.titlebar,
        Parent = self.window
    })
    Create("UICorner",{CornerRadius=UDim.new(0,12),Parent=self.titlebar})

    self.title = Create("TextLabel", {
        Size = UDim2.new(1,-20,1,0),
        Position = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1,
        Text = name or "NeonUI Window",
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = colors.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.titlebar
    })

    -- Sidebar
    self.sidebar = Create("Frame", {
        Size = UDim2.new(0,150,1,-40),
        Position = UDim2.new(0,0,0,40),
        BackgroundColor3 = colors.sidebar,
        Parent = self.window
    })
    Create("UICorner",{CornerRadius=UDim.new(0,12),Parent=self.sidebar})

    -- Content
    self.content = Create("Frame", {
        Size = UDim2.new(1,-150,1,-40),
        Position = UDim2.new(0,150,0,40),
        BackgroundColor3 = colors.content,
        Parent = self.window
    })
    Create("UICorner",{CornerRadius=UDim.new(0,12),Parent=self.content})

    -- State
    self.pages = {}
    self.buttons = {}

    return self
end

--// Add Page
function NeonUI:AddPage(name)
    local page = Create("ScrollingFrame", {
        Name = name,
        Size = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 6,
        Visible = false,
        Parent = self.content
    })

    Create("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder,Parent=page})

    self.pages[name] = page

    local tab = Create("TextButton", {
        Text = name,
        Size = UDim2.new(1,-20,0,40),
        Position = UDim2.new(0,10,0,#self.buttons*50+10),
        BackgroundColor3 = colors.toggleOff,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = colors.text,
        Parent = self.sidebar
    })
    Create("UICorner",{CornerRadius=UDim.new(0,8),Parent=tab})

    tab.MouseButton1Click:Connect(function()
        for _,p in pairs(self.pages) do p.Visible = false end
        for _,b in pairs(self.buttons) do Tween(b,{BackgroundColor3=colors.toggleOff}) end
        page.Visible = true
        Tween(tab,{BackgroundColor3=colors.accent})
    end)

    table.insert(self.buttons, tab)
    if #self.buttons == 1 then tab:MouseButton1Click() end

    return page
end

--// Add Section
function NeonUI:AddSection(parent, title)
    local section = Create("Frame", {
        Size = UDim2.new(1,-20,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = colors.section,
        Parent = parent
    })
    Create("UICorner",{CornerRadius=UDim.new(0,10),Parent=section})
    Create("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=section})
    Create("UIPadding",{PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),Parent=section})

    Create("TextLabel",{
        Size=UDim2.new(1,0,0,20),
        BackgroundTransparency=1,
        Text=title or "Section",
        Font=Enum.Font.GothamBold,
        TextSize=14,
        TextColor3=colors.textDim,
        TextXAlignment=Enum.TextXAlignment.Left,
        Parent=section
    })

    return section
end

--// Elements
function NeonUI:AddButton(parent,text,callback)
    local btn = Create("TextButton",{
        Size=UDim2.new(1,0,0,35),
        BackgroundColor3=colors.toggleOff,
        Font=Enum.Font.GothamBold,
        Text=text,
        TextSize=14,
        TextColor3=colors.text,
        Parent=parent
    })
    Create("UICorner",{CornerRadius=UDim.new(0,8),Parent=btn})
    btn.MouseButton1Click:Connect(function() if callback then callback() end end)
    btn.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=colors.accent}) end)
    btn.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=colors.toggleOff}) end)
    return btn
end

function NeonUI:AddToggle(parent,text,default,callback)
    local state = default or false
    local holder = Create("Frame",{Size=UDim2.new(1,0,0,35),BackgroundTransparency=1,Parent=parent})
    local box = Create("TextButton",{
        Size=UDim2.new(0,35,0,35),
        BackgroundColor3=state and colors.accent or colors.toggleOff,
        Text="",
        Parent=holder
    })
    Create("UICorner",{CornerRadius=UDim.new(0,8),Parent=box})
    local label = Create("TextLabel",{
        Position=UDim2.new(0,45,0,0),Size=UDim2.new(1,-45,1,0),
        BackgroundTransparency=1,Text=text,Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,
        TextColor3=colors.text,Parent=holder
    })
    box.MouseButton1Click:Connect(function()
        state = not state
        Tween(box,{BackgroundColor3=state and colors.accent or colors.toggleOff})
        if callback then callback(state) end
    end)
    return box
end

function NeonUI:AddSlider(parent,text,min,max,default,callback)
    local val = default or min
    local holder = Create("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,Parent=parent})
    local label = Create("TextLabel",{Size=UDim2.new(1,0,0,20),BackgroundTransparency=1,Text=text.." ("..val..")",Font=Enum.Font.GothamBold,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,TextColor3=colors.text,Parent=holder})
    local bar = Create("Frame",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,0,30),BackgroundColor3=colors.toggleOff,Parent=holder})
    Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=bar})
    local fill = Create("Frame",{Size=UDim2.new((val-min)/(max-min),0,1,0),BackgroundColor3=colors.accent,Parent=bar})
    Create("UICorner",{CornerRadius=UDim.new(0,4),Parent=fill})

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local move; local release
            move = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement then
                    local percent = math.clamp((inp.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,0,1)
                    val = math.floor(min + (max-min)*percent)
                    fill.Size = UDim2.new(percent,0,1,0)
                    label.Text = text.." ("..val..")"
                    if callback then callback(val) end
                end
            end)
            release = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    move:Disconnect()
                    release:Disconnect()
                end
            end)
        end
    end)
    return holder
end

function NeonUI:AddDropdown(parent,text,options,default,callback)
    local current = default or options[1]
    local holder = Create("Frame",{Size=UDim2.new(1,0,0,35),BackgroundTransparency=1,Parent=parent})
    local btn = Create("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=colors.toggleOff,Text=current,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=colors.text,Parent=holder})
    Create("UICorner",{CornerRadius=UDim.new(0,8),Parent=btn})

    local list = Create("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,1,0),BackgroundColor3=colors.section,Parent=holder,ClipsDescendants=true})
    Create("UICorner",{CornerRadius=UDim.new(0,8),Parent=list})
    Create("UIListLayout",{Parent=list})

    for _,opt in ipairs(options) do
        local o = Create("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,Text=opt,Font=Enum.Font.Gotham,TextSize=14,TextColor3=colors.text,Parent=list})
        o.MouseButton1Click:Connect(function()
            current = opt
            btn.Text = current
            Tween(list,{Size=UDim2.new(1,0,0,0)})
            if callback then callback(opt) end
        end)
    end

    local open=false
    btn.MouseButton1Click:Connect(function()
        open = not open
        Tween(list,{Size=open and UDim2.new(1,0,0,#options*30) or UDim2.new(1,0,0,0)})
    end)

    return btn
end

--// Notifications
function NeonUI:Notify(text,duration)
    local note = Create("TextLabel",{Size=UDim2.new(0,200,0,40),Position=UDim2.new(1,-220,1,-60),BackgroundColor3=colors.accent,Text=text,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=colors.text,Parent=self.gui})
    Create("UICorner",{CornerRadius=UDim.new(0,8),Parent=note})
    Tween(note,{Position=UDim2.new(1,-220,1,-110)},0.3)
    task.delay(duration or 2,function()
        Tween(note,{Position=UDim2.new(1,-220,1,0)},0.3)
        task.wait(0.3) note:Destroy()
    end)
end

return NeonUI
