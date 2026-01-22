--[[
    NIGHTMARE PvP LIBRARY (With Config System)
    Based on Nightmare PvP UI with Purple/Blue Theme
]]

local Nightmarepvp = {}
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==================== ANTI-DETECTION PARENT (INFINITE YIELD METHOD) ====================
-- Fungsi untuk mendapatkan parent GUI yang paling selamat.
-- Keutamaan: gethui() > syn.protect_gui()
local function getSafeCoreGuiParent()
    -- 1. Cuba gunakan gethui() (kaedah paling selamat dan moden)
    if gethui then
        local success, result = pcall(function()
            return gethui()
        end)
        if success and result then
            return result
        end
    end

    -- 2. Jika gethui gagal, Cuba gunakan syn.protect_gui()
    if syn and syn.protect_gui then
        local protectedGui = Instance.new("ScreenGui")
        protectedGui.Name = "NightmarePvP_Protected"
        protectedGui.ResetOnSpawn = false
        protectedGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        syn.protect_gui(protectedGui)
        protectedGui.Parent = CoreGui
        return protectedGui
    end

    -- Jika kedua-duanya gagal, kembalikan CoreGui sebagai fallback
    return CoreGui
end

-- ==================== CONFIG SAVE SYSTEM ====================
local ConfigSystem = {}
ConfigSystem.ConfigFile = "NightmarePvP_Config.json"

-- Load config dari file
function ConfigSystem:Load()
    if isfile and isfile(self.ConfigFile) then
        local success, result = pcall(function()
            local fileContent = readfile(self.ConfigFile)
            local decoded = HttpService:JSONDecode(fileContent)
            return decoded
        end)
        
        if success and result then
            return result
        else
            warn("⚠️ Failed to load config, using defaults")
            return {}
        end
    else
        return {}
    end
end

-- Save config ke file
function ConfigSystem:Save(config)
    local success, error = pcall(function()
        local encoded = HttpService:JSONEncode(config)
        writefile(self.ConfigFile, encoded)
    end)
    
    if success then
        return true
    else
        warn("❌ Failed to save config:", error)
        return false
    end
end

-- Update satu setting sahaja
function ConfigSystem:UpdateSetting(config, key, value)
    config[key] = value
    self:Save(config)
end

-- ==================== UI VARIABLES ====================
local ScreenGui -- Pembolehubah untuk disimpan di luar fungsi
local MainFrame
local ToggleButton
local ScrollFrame
local ListLayout

-- ==================== CREATE UI ====================
function Nightmarepvp:CreateUI()
    -- Load config awal-awal
    self.Config = ConfigSystem:Load()

    -- Cleanup: Hapus UI lama jika wujud
    if ScreenGui then
        ScreenGui:Destroy()
        ScreenGui = nil
    end

    -- Buang GUI lama kalau ada
    for _, gui in pairs(CoreGui:GetChildren()) do
        if gui.Name == "NightmarePvP" then
            gui:Destroy()
        end
    end

    -- Dapatkan parent yang selamat
    local safeParent = getSafeCoreGuiParent()

    -- ScreenGui
    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NightmarePvP"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = safeParent

    -- Main Frame (Window) - Tambah tinggi untuk toggle baru
    MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainWindow"
    MainFrame.Size = UDim2.new(0, 280, 0, 440)  -- Tambah tinggi dari 395 ke 440
    MainFrame.Position = UDim2.new(0.5, -140, 0.5, -220)
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BackgroundTransparency = 0.10
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui

    -- UICorner untuk rounded corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = MainFrame

    -- Outline/Stroke - Purple dan Biru Gelap
    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(255, 255, 255)
    uiStroke.Thickness = 2
    uiStroke.Transparency = 0
    uiStroke.Parent = MainFrame

    -- UIGradient untuk outline (purple ke biru gelap)
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),  -- Purple
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))      -- Biru gelap
    }
    uiGradient.Parent = uiStroke

    -- Tween untuk rotate gradient outline
    local tweenService = game:GetService("TweenService")
    local gradientTweenInfo = TweenInfo.new(
        2,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        -1,
        false,
        0
    )

    tweenService:Create(uiGradient, gradientTweenInfo, {Rotation = 360}):Play()

    -- Title "Nightmare Hub"
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 30)
    titleLabel.Position = UDim2.new(0, 0, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Nightmare Hub"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextStrokeTransparency = 0.5
    titleLabel.Parent = MainFrame

    -- UIGradient untuk title text
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),  -- Purple
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))      -- Biru gelap
    }
    titleGradient.Parent = titleLabel

    -- Tween untuk rotate gradient title (lebih perlahan - 4 saat)
    local textGradientTweenInfo = TweenInfo.new(
        4,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        -1,
        false,
        0
    )

    tweenService:Create(titleGradient, textGradientTweenInfo, {Rotation = 360}):Play()

    -- Subtitle Discord Link
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0, 20)
    subtitleLabel.Position = UDim2.new(0, 0, 0, 38)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "https://discord.gg/XeBbhUnf"
    subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subtitleLabel.TextSize = 11
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextStrokeTransparency = 0.5
    subtitleLabel.Parent = MainFrame

    -- UIGradient untuk subtitle text
    local subtitleGradient = Instance.new("UIGradient")
    subtitleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),  -- Purple
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))      -- Biru gelap
    }
    subtitleGradient.Parent = subtitleLabel

    -- Tween untuk rotate gradient subtitle (lebih perlahan - 4 saat)
    tweenService:Create(subtitleGradient, textGradientTweenInfo, {Rotation = 360}):Play()

    -- Toggle Button (untuk show/hide UI)
    ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 60, 0, 60)
    ToggleButton.Position = UDim2.new(0, 20, 0.5, -30)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Text = "N"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 24
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.Active = true
    ToggleButton.Draggable = true
    ToggleButton.Parent = ScreenGui

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = ToggleButton

    ToggleButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    print("ok")
end

-- ==================== TOGGLE CREATION FUNCTION ====================
function Nightmarepvp:AddToggleRow(text1, callback1, text2, callback2)
    if not MainFrame then
        warn("UI not created yet! Call CreateUI() first.")
        return
    end

    local rowFrame = Instance.new("Frame")
    rowFrame.Size = UDim2.new(0, 260, 0, 35)
    rowFrame.Position = UDim2.new(0, 10, 0, 75 + (#MainFrame:GetChildren() - 10) * 45)
    rowFrame.BackgroundTransparency = 1
    rowFrame.Parent = MainFrame

    local function createSingleToggle(text, callback, xPos)
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Name = "ToggleFrame_" .. text
        toggleFrame.Size = UDim2.new(0, 125, 0, 35)
        toggleFrame.Position = xPos
        toggleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleFrame.BackgroundTransparency = 0.45
        toggleFrame.BorderSizePixel = 0
        toggleFrame.Parent = rowFrame

        local toggleBgGradient = Instance.new("UIGradient")
        toggleBgGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))
        }
        toggleBgGradient.Parent = toggleFrame

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 6)
        toggleCorner.Parent = toggleFrame

        local toggleStroke = Instance.new("UIStroke")
        toggleStroke.Color = Color3.fromRGB(255, 255, 255)
        toggleStroke.Thickness = 1
        toggleStroke.Transparency = 0
        toggleStroke.Parent = toggleFrame

        local toggleOutlineGradient = Instance.new("UIGradient")
        toggleOutlineGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 139)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
        }
        toggleOutlineGradient.Parent = toggleStroke

        local tweenService = game:GetService("TweenService")
        local toggleOutlineGradientTweenInfo = TweenInfo.new(
            2,
            Enum.EasingStyle.Linear,
            Enum.EasingDirection.InOut,
            -1,
            false,
            0
        )

        tweenService:Create(toggleOutlineGradient, toggleOutlineGradientTweenInfo, {Rotation = -360}):Play()

        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Name = "Label"
        toggleLabel.Size = UDim2.new(0, 70, 1, 0)
        toggleLabel.Position = UDim2.new(0, 8, 0, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.Text = text
        toggleLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
        toggleLabel.TextSize = 13
        toggleLabel.Font = Enum.Font.Arcade
        toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        toggleLabel.Parent = toggleFrame

        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "ToggleButton"
        toggleButton.Size = UDim2.new(0, 35, 0, 16)
        toggleButton.Position = UDim2.new(1, -40, 0.5, -8)
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.BorderSizePixel = 0
        toggleButton.Text = ""
        toggleButton.Parent = toggleFrame

        local toggleButtonGradient = Instance.new("UIGradient")
        toggleButtonGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))
        }
        toggleButtonGradient.Parent = toggleButton

        local toggleButtonCorner = Instance.new("UICorner")
        toggleButtonCorner.CornerRadius = UDim.new(1, 0)
        toggleButtonCorner.Parent = toggleButton

        local toggleCircle = Instance.new("Frame")
        toggleCircle.Name = "Circle"
        toggleCircle.Size = UDim2.new(0, 12, 0, 12)
        toggleCircle.Position = UDim2.new(0, 2, 0.5, -6)
        toggleCircle.BackgroundColor3 = Color3.fromRGB(138, 43, 226)
        toggleCircle.BorderSizePixel = 0
        toggleCircle.Parent = toggleButton

        local circleCorner = Instance.new("UICorner")
        circleCorner.CornerRadius = UDim.new(1, 0)
        circleCorner.Parent = toggleCircle

        local configKey = "NightmarePvP_" .. text
        local isToggled = self.Config[configKey] or false
        
        -- Set initial state
        if isToggled then
            toggleButtonGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 0, 130))
            }
            toggleCircle.Position = UDim2.new(1, -14, 0.5, -6)
        end

        -- Call callback on initial load
        if callback then callback(isToggled) end

        toggleButton.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            
            if isToggled then
                toggleButtonGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(75, 0, 130))
                }
                tweenService:Create(toggleCircle, TweenInfo.new(0.2), {
                    Position = UDim2.new(1, -14, 0.5, -6),
                    BackgroundColor3 = Color3.fromRGB(138, 43, 226)
                }):Play()
            else
                toggleButtonGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))
                }
                tweenService:Create(toggleCircle, TweenInfo.new(0.2), {
                    Position = UDim2.new(0, 2, 0.5, -6),
                    BackgroundColor3 = Color3.fromRGB(138, 43, 226)
                }):Play()
            end

            -- Save state to config
            ConfigSystem:UpdateSetting(self.Config, configKey, isToggled)

            -- Execute callback
            if callback then callback(isToggled) end
        end)
    end

    createSingleToggle(text1, callback1, UDim2.new(0, 0, 0, 0))

    if text2 and callback2 then
        createSingleToggle(text2, callback2, UDim2.new(0, 135, 0, 0))
    end
end

-- ==================== INPUT FIELD CREATION FUNCTION ====================
function Nightmarepvp:AddInputField(text, callback, defaultValue)
    if not MainFrame then
        warn("UI not created yet! Call CreateUI() first.")
        return
    end

    local inputFrame = Instance.new("Frame")
    inputFrame.Name = "InputFrame_" .. text
    inputFrame.Size = UDim2.new(0, 125, 0, 35)
    inputFrame.Position = UDim2.new(0, 10, 0, 75 + (#MainFrame:GetChildren() - 10) * 45)
    inputFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inputFrame.BackgroundTransparency = 0.45
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = MainFrame

    local inputBgGradient = Instance.new("UIGradient")
    inputBgGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))
    }
    inputBgGradient.Parent = inputFrame

    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputFrame

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(255, 255, 255)
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0
    inputStroke.Parent = inputFrame

    local inputOutlineGradient = Instance.new("UIGradient")
    inputOutlineGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 139)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
    }
    inputOutlineGradient.Parent = inputStroke

    local tweenService = game:GetService("TweenService")
    local toggleOutlineGradientTweenInfo = TweenInfo.new(
        2,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        -1,
        false,
        0
    )

    tweenService:Create(inputOutlineGradient, toggleOutlineGradientTweenInfo, {Rotation = -360}):Play()

    local inputLabel = Instance.new("TextLabel")
    inputLabel.Name = "InputLabel"
    inputLabel.Size = UDim2.new(0, 65, 1, 0)
    inputLabel.Position = UDim2.new(0, 8, 0, 0)
    inputLabel.BackgroundTransparency = 1
    inputLabel.Text = text
    inputLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
    inputLabel.TextSize = 10
    inputLabel.Font = Enum.Font.Arcade
    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
    inputLabel.Parent = inputFrame

    local configKey = "NightmarePvP_" .. text
    local savedValue = self.Config[configKey] or defaultValue or "16"

    local inputBox = Instance.new("TextBox")
    inputBox.Name = "InputBox"
    inputBox.Size = UDim2.new(0, 40, 0, 20)
    inputBox.Position = UDim2.new(1, -45, 0.5, -10)
    inputBox.BackgroundColor3 = Color3.fromRGB(0, 0, 80)
    inputBox.BackgroundTransparency = 0.2
    inputBox.BorderSizePixel = 0
    inputBox.Text = tostring(savedValue)
    inputBox.TextColor3 = Color3.fromRGB(0, 255, 255)
    inputBox.TextSize = 12
    inputBox.Font = Enum.Font.Arcade
    inputBox.TextXAlignment = Enum.TextXAlignment.Center
    inputBox.PlaceholderText = "Max 100"
    inputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    inputBox.Parent = inputFrame

    local inputBoxCorner = Instance.new("UICorner")
    inputBoxCorner.CornerRadius = UDim.new(0, 4)
    inputBoxCorner.Parent = inputBox

    local inputBoxStroke = Instance.new("UIStroke")
    inputBoxStroke.Color = Color3.fromRGB(75, 0, 130)
    inputBoxStroke.Thickness = 1
    inputBoxStroke.Transparency = 0
    inputBoxStroke.Parent = inputBox

    -- Call callback with initial value
    if callback then callback(tonumber(savedValue)) end

    inputBox.FocusLost:Connect(function()
        local value = tonumber(inputBox.Text)
        if value then
            if value > 100 then
                inputBox.Text = "100"
                value = 100
            elseif value < 0 then
                inputBox.Text = "0"
                value = 0
            end
            
            -- Save to config
            ConfigSystem:UpdateSetting(self.Config, configKey, value)
            
            -- Execute callback
            if callback then callback(value) end
        else
            inputBox.Text = tostring(savedValue)
        end
    end)
end

-- ==================== BUTTON CREATION FUNCTION ====================
function Nightmarepvp:AddButton(text, callback)
    if not MainFrame then
        warn("UI not created yet! Call CreateUI() first.")
        return
    end

    local buttonFrame = Instance.new("TextButton")
    buttonFrame.Name = "ButtonFrame_" .. text
    buttonFrame.Size = UDim2.new(0, 125, 0, 35)
    buttonFrame.Position = UDim2.new(0, 10, 0, 75 + (#MainFrame:GetChildren() - 10) * 45)
    buttonFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    buttonFrame.BackgroundTransparency = 0.45
    buttonFrame.BorderSizePixel = 0
    buttonFrame.Text = ""
    buttonFrame.Parent = MainFrame

    local buttonBgGradient = Instance.new("UIGradient")
    buttonBgGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(138, 43, 226)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))
    }
    buttonBgGradient.Parent = buttonFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = buttonFrame

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = Color3.fromRGB(255, 255, 255)
    buttonStroke.Thickness = 1
    buttonStroke.Transparency = 0
    buttonStroke.Parent = buttonFrame

    local buttonOutlineGradient = Instance.new("UIGradient")
    buttonOutlineGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 139)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(138, 43, 226))
    }
    buttonOutlineGradient.Parent = buttonStroke

    local tweenService = game:GetService("TweenService")
    local toggleOutlineGradientTweenInfo = TweenInfo.new(
        2,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut,
        -1,
        false,
        0
    )

    tweenService:Create(buttonOutlineGradient, toggleOutlineGradientTweenInfo, {Rotation = -360}):Play()

    local buttonLabel = Instance.new("TextLabel")
    buttonLabel.Name = "ButtonLabel"
    buttonLabel.Size = UDim2.new(1, 0, 1, 0)
    buttonLabel.Position = UDim2.new(0, 0, 0, 0)
    buttonLabel.BackgroundTransparency = 1
    buttonLabel.Text = text
    buttonLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
    buttonLabel.TextSize = 12
    buttonLabel.Font = Enum.Font.Arcade
    buttonLabel.TextXAlignment = Enum.TextXAlignment.Center
    buttonLabel.Parent = buttonFrame

    buttonFrame.MouseButton1Click:Connect(function()
        -- Flash effect
        buttonLabel.TextColor3 = Color3.fromRGB(0, 0, 139)
        
        task.wait(0.2)
        
        -- Balik ke color asal
        buttonLabel.TextColor3 = Color3.fromRGB(200, 100, 255)
        
        -- Execute callback
        if callback then callback() end
    end)
end

return Nightmarepvp
