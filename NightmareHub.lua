local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- ========== CONFIG SYSTEM ==========
local ConfigSystem = {}

ConfigSystem.ConfigFile = "NightmareV1_Config.json"

-- Default config
ConfigSystem.DefaultConfig = {
	InvisPanel = false,
	InfJump = false
}

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
			warn("Failed to load config, using defaults")
			return self.DefaultConfig
		end
	else
		return self.DefaultConfig
	end
end

-- Save config ke file
function ConfigSystem:Save(config)
	if not writefile then
		warn("writefile not available")
		return false
	end
	
	local success, error = pcall(function()
		local encoded = HttpService:JSONEncode(config)
		writefile(self.ConfigFile, encoded)
	end)
	
	if success then
		return true
	else
		warn("Failed to save config:", error)
		return false
	end
end

-- Update satu setting sahaja
function ConfigSystem:UpdateSetting(config, key, value)
	config[key] = value
	self:Save(config)
end

-- Load config masa startup
local currentConfig = ConfigSystem:Load()

-- ========== NOTIFICATION SYSTEM ==========
local activeNotifications = {} -- Track semua active notifs
local NOTIF_HEIGHT = 60
local NOTIF_SPACING = 10
local MAX_NOTIFS = 3

function updateNotificationPositions()
	-- Update position semua notifs
	for i, notifData in ipairs(activeNotifications) do
		local newYPos = 20 + ((i - 1) * (NOTIF_HEIGHT + NOTIF_SPACING))
		local moveTween = TweenService:Create(notifData.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -260, 0, newYPos)
		})
		moveTween:Play()
	end
end

function removeNotification(notifData)
	-- Remove dari active list
	for i, data in ipairs(activeNotifications) do
		if data == notifData then
			table.remove(activeNotifications, i)
			break
		end
	end
	updateNotificationPositions()
end

function showNotification(message)
	-- Kalau dah ada MAX_NOTIFS, remove yang paling lama (index 1)
	if #activeNotifications >= MAX_NOTIFS then
		local oldestNotif = activeNotifications[1]
		
		-- Remove dari list DULU
		table.remove(activeNotifications, 1)
		
		-- Update position notifs yang tinggal (naik ke atas)
		updateNotificationPositions()
		
		-- LEPAS TU baru tween keluar yang lama
		local tweenOut = TweenService:Create(oldestNotif.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 10, 0, oldestNotif.frame.Position.Y.Offset)
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			oldestNotif.frame:Destroy()
		end)
	end
	
	-- Buat notification GUI
	local screenGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("NotificationGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "NotificationGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	
	-- Calculate position untuk notif baru (di bawah semua notif yang ada)
	local startYPos = 20 + (#activeNotifications * (NOTIF_HEIGHT + NOTIF_SPACING))
	
	-- Buat notification frame
	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 250, 0, NOTIF_HEIGHT)
	notif.Position = UDim2.new(1, 10, 0, startYPos) -- Start dari luar screen
	notif.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	notif.BackgroundTransparency = 0.15
	notif.BorderSizePixel = 0
	notif.Parent = screenGui
	
	-- Rounded corners 8 pixel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = notif
	
	-- Close button X (hujung kanan atas)
	local closeButton = Instance.new("TextButton")
	closeButton.Size = UDim2.new(0, 20, 0, 20)
	closeButton.Position = UDim2.new(1, -25, 0, 5)
	closeButton.BackgroundTransparency = 1
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 14
	closeButton.Font = Enum.Font.Gotham
	closeButton.Parent = notif
	
	-- Text label untuk message
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -50, 1, -10)
	textLabel.Position = UDim2.new(0, 10, 0, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 14
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Center
	textLabel.TextWrapped = true
	textLabel.Parent = notif
	
	-- Container untuk progress bar
	local barContainer = Instance.new("Frame")
	barContainer.Size = UDim2.new(1, 0, 0, 3)
	barContainer.Position = UDim2.new(0, 0, 1, -3)
	barContainer.BackgroundTransparency = 1
	barContainer.ClipsDescendants = true
	barContainer.Parent = notif
	
	-- Progress bar dengan gradient
	local progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(1, 0, 1, 0)
	progressBar.Position = UDim2.new(0, 0, 0, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = barContainer
	
	-- Rounded corners untuk bar
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 2)
	barCorner.Parent = progressBar
	
	-- Gradient untuk bar
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 20, 60))
	}
	gradient.Parent = progressBar
	
	-- Play sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://102467889710186"
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	
	-- Store notif data
	local notifData = {
		frame = notif,
		progressBar = progressBar,
		barTween = nil
	}
	table.insert(activeNotifications, notifData)
	
	-- Tween masuk
	local tweenIn = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -260, 0, startYPos)
	})
	tweenIn:Play()
	
	-- Bar drain dari KANAN ke KIRI (3 saat)
	local barTween = TweenService:Create(progressBar, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 0, 1, 0)
	})
	notifData.barTween = barTween
	barTween:Play()
	
	-- Close button function
	closeButton.MouseButton1Click:Connect(function()
		-- Stop bar tween
		if notifData.barTween then
			notifData.barTween:Cancel()
		end
		
		-- Tween keluar
		local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 10, 0, notif.Position.Y.Offset)
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			notif:Destroy()
		end)
		
		removeNotification(notifData)
	end)
	
	-- Tunggu 3 saat, then tween keluar
	task.spawn(function()
		task.wait(3)
		
		-- Check kalau notif masih exist (mungkin user dah close manual)
		if notif.Parent then
			local tweenOut = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 10, 0, notif.Position.Y.Offset)
			})
			tweenOut:Play()
			tweenOut.Completed:Connect(function()
				notif:Destroy()
			end)
			
			removeNotification(notifData)
		end
	end)
end

-- Fungsi untuk melindungi GUI dari sync/detection
local function protectGui(gui)
    if gethui then
        gui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(gui)
        gui.Parent = CoreGui
    elseif CoreGui then
        gui.Parent = CoreGui
    end
end

-- ========== QUICK PANEL LIBRARY ==========
local QuickPanelLibrary = {}
QuickPanelLibrary.__index = QuickPanelLibrary

function QuickPanelLibrary:New()
	local self = setmetatable({}, QuickPanelLibrary)
	
	-- Buat ScreenGui untuk Quick Panel
	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "NightmareQuickPanel"
	self.ScreenGui.ResetOnSpawn = false
	
	-- Destroy existing Quick Panel if ada
	for _, gui in pairs(game.CoreGui:GetChildren()) do
		if gui.Name == "NightmareQuickPanel" and gui ~= self.ScreenGui then
			gui:Destroy()
		end
	end
	
	-- Buat Frame (Rounded Rectangle)
	self.Frame = Instance.new("Frame")
	self.Frame.Size = UDim2.new(0, 295, 0, 85) -- Start with title height only
	self.Frame.Position = UDim2.new(0.5000, 236, 0.5000, -203)
	self.Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	self.Frame.BackgroundTransparency = 0.15
	self.Frame.BorderSizePixel = 0
	self.Frame.Active = true
	self.Frame.Draggable = true
	self.Frame.Parent = self.ScreenGui
	
	-- Buat Rounded Corner (6 pixels)
	local quickFrameCorner = Instance.new("UICorner")
	quickFrameCorner.CornerRadius = UDim.new(0, 6)
	quickFrameCorner.Parent = self.Frame
	
	-- Buat Outline (Stroke) merah cerah dan hitam
	local quickFrameStroke = Instance.new("UIStroke")
	quickFrameStroke.Color = Color3.fromRGB(255, 0, 0)
	quickFrameStroke.Thickness = 1.0
	quickFrameStroke.Parent = self.Frame
	
	-- Buat UIGradient untuk stroke (MERAH CERAH DAN HITAM)
	local quickUiGradient = Instance.new("UIGradient")
	quickUiGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	}
	quickUiGradient.Parent = quickFrameStroke
	
	-- Gradient Animation untuk stroke (rotating)
	TweenService:Create(quickUiGradient, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0), {Rotation = 360}):Play()
	
	-- BUAT TITLE
	local quickTitle = Instance.new("TextLabel")
	quickTitle.Size = UDim2.new(1, -40, 0, 35)
	quickTitle.Position = UDim2.new(0, 10, 0, 0)
	quickTitle.BackgroundTransparency = 1
	quickTitle.Text = "Nightmare Quick Panel :3"
	quickTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	quickTitle.TextSize = 16
	quickTitle.Font = Enum.Font.GothamBold
	quickTitle.TextStrokeTransparency = 0.5
	quickTitle.TextXAlignment = Enum.TextXAlignment.Left
	quickTitle.Parent = self.Frame
	
	-- Buat UIGradient untuk Title (MERAH PEKAT KE MERAH CERAH)
	local quickTitleGradient = Instance.new("UIGradient")
	quickTitleGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
	}
	quickTitleGradient.Parent = quickTitle
	
	-- Gradient Animation untuk Title (rotating)
	TweenService:Create(quickTitleGradient, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0), {Rotation = 360}):Play()
	
	-- BUAT DIVIDER MERAH GELAP BAWAH TITLE
	self.Divider = Instance.new("Frame")
	self.Divider.Size = UDim2.new(0.92, 0, 0, 1)
	self.Divider.Position = UDim2.new(0.04, 0, 0, 35)
	self.Divider.BackgroundColor3 = Color3.fromRGB(139, 0, 0)
	self.Divider.BackgroundTransparency = 0.45
	self.Divider.BorderSizePixel = 0
	self.Divider.Parent = self.Frame
	
	-- BUAT BUTTON MINIMIZE
	self.MinimizeButton = Instance.new("TextButton")
	self.MinimizeButton.Size = UDim2.new(0, 35, 0, 35)
	self.MinimizeButton.Position = UDim2.new(1, -35, 0, 0)
	self.MinimizeButton.BackgroundTransparency = 1
	self.MinimizeButton.Text = "–"
	self.MinimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.MinimizeButton.TextSize = 26
	self.MinimizeButton.Font = Enum.Font.Gotham
	self.MinimizeButton.Parent = self.Frame
	
	-- CONTAINER UNTUK CONTENT
	self.ContentFrame = Instance.new("Frame")
	self.ContentFrame.Size = UDim2.new(1, 0, 1, -45)
	self.ContentFrame.Position = UDim2.new(0, 0, 0, 45)
	self.ContentFrame.BackgroundTransparency = 1
	self.ContentFrame.Parent = self.Frame
	
	-- UIListLayout untuk auto-arrange items
	self.Layout = Instance.new("UIListLayout")
	self.Layout.SortOrder = Enum.SortOrder.LayoutOrder
	self.Layout.Padding = UDim.new(0, 10)
	self.Layout.Parent = self.ContentFrame
	
	-- UIPadding
	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, 7)
	contentPadding.PaddingRight = UDim.new(0, 7)
	contentPadding.PaddingTop = UDim.new(0, 10)
	contentPadding.Parent = self.ContentFrame
	
	-- Track elements
	self.Elements = {}
	self.IsMinimized = false
	self.OriginalSize = self.Frame.Size
	
	-- Minimize functionality
	self.MinimizeButton.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end)
	
	-- Update size when items added
	self.Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if not self.IsMinimized then
			local newHeight = 45 + self.Layout.AbsoluteContentSize.Y + 20
			self.Frame.Size = UDim2.new(0, 295, 0, newHeight)
			self.OriginalSize = self.Frame.Size
		end
	end)
	
	-- Protect GUI
	protectGui(self.ScreenGui)
	
	return self
end

function QuickPanelLibrary:ToggleMinimize()
	if not self.IsMinimized then
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local tween = TweenService:Create(self.Frame, tweenInfo, {Size = UDim2.new(0, 295, 0, 35)})
		tween:Play()
		self.MinimizeButton.Text = "+"
		self.Divider.Visible = false
		self.ContentFrame.Visible = false
		self.IsMinimized = true
	else
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		local tween = TweenService:Create(self.Frame, tweenInfo, {Size = self.OriginalSize})
		tween:Play()
		self.MinimizeButton.Text = "–"
		self.Divider.Visible = true
		self.ContentFrame.Visible = true
		self.IsMinimized = false
	end
end

function QuickPanelLibrary:AddToggle(options)
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Size = UDim2.new(1, 0, 0, 30)
	toggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	toggleFrame.BackgroundTransparency = 0.45
	toggleFrame.BorderSizePixel = 0
	toggleFrame.ClipsDescendants = false
	toggleFrame.Parent = self.ContentFrame
	
	local toggleFrameCorner = Instance.new("UICorner")
	toggleFrameCorner.CornerRadius = UDim.new(0, 6)
	toggleFrameCorner.Parent = toggleFrame
	
	local toggleFrameStroke = Instance.new("UIStroke")
	toggleFrameStroke.Color = Color3.fromRGB(139, 0, 0)
	toggleFrameStroke.Thickness = 1.0
	toggleFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	toggleFrameStroke.Parent = toggleFrame
	
	local toggleGradient = Instance.new("UIGradient")
	toggleGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	}
	toggleGradient.Rotation = 0
	toggleGradient.Parent = toggleFrameStroke
	
	local toggleText = Instance.new("TextLabel")
	toggleText.Size = UDim2.new(0, 200, 1, 0)
	toggleText.Position = UDim2.new(0, 8, 0, 0)
	toggleText.BackgroundTransparency = 1
	toggleText.Text = options.Title or "Toggle"
	toggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleText.TextSize = 12
	toggleText.Font = Enum.Font.Gotham
	toggleText.TextXAlignment = Enum.TextXAlignment.Left
	toggleText.Parent = toggleFrame
	
	local toggleButton = Instance.new("TextButton")
	toggleButton.Size = UDim2.new(0, 34, 0, 16)
	toggleButton.Position = UDim2.new(1, -42, 0.5, -8)
	toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	toggleButton.BorderSizePixel = 0
	toggleButton.Text = ""
	toggleButton.Parent = toggleFrame
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Size = UDim2.new(0, 12, 0, 12)
	toggleCircle.Position = UDim2.new(0, 2, 0.5, -6)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleButton
	
	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = UDim.new(1, 0)
	circleCorner.Parent = toggleCircle
	
	local toggleEnabled = options.Default or false
	
	-- Update visual based on default
	if toggleEnabled then
		toggleButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		toggleCircle.Position = UDim2.new(0, 20, 0.5, -6)
	end
	
	toggleButton.MouseButton1Click:Connect(function()
		toggleEnabled = not toggleEnabled
		
		local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		
		if toggleEnabled then
			TweenService:Create(toggleButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(255, 0, 0)}):Play()
			TweenService:Create(toggleCircle, tweenInfo, {Position = UDim2.new(0, 20, 0.5, -6)}):Play()
		else
			TweenService:Create(toggleButton, tweenInfo, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}):Play()
			TweenService:Create(toggleCircle, tweenInfo, {Position = UDim2.new(0, 2, 0.5, -6)}):Play()
		end
		
		if options.Callback then
			options.Callback(toggleEnabled)
		end
	end)
	
	table.insert(self.Elements, toggleFrame)
	return toggleFrame
end

function QuickPanelLibrary:AddButton(options)
	local actionButton = Instance.new("TextButton")
	actionButton.Size = UDim2.new(1, 0, 0, 30)
	actionButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	actionButton.BackgroundTransparency = 0.45
	actionButton.BorderSizePixel = 0
	actionButton.Text = options.Title or "Button"
	actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionButton.TextSize = 12
	actionButton.Font = Enum.Font.Gotham
	actionButton.Parent = self.ContentFrame
	
	local actionButtonCorner = Instance.new("UICorner")
	actionButtonCorner.CornerRadius = UDim.new(0, 6)
	actionButtonCorner.Parent = actionButton
	
	local actionButtonStroke = Instance.new("UIStroke")
	actionButtonStroke.Color = Color3.fromRGB(139, 0, 0)
	actionButtonStroke.Thickness = 1.0
	actionButtonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	actionButtonStroke.Parent = actionButton
	
	local actionButtonGradient = Instance.new("UIGradient")
	actionButtonGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	}
	actionButtonGradient.Rotation = 0
	actionButtonGradient.Parent = actionButtonStroke
	
	actionButton.MouseButton1Click:Connect(function()
		if options.Callback then
			options.Callback()
		end
	end)
	
	table.insert(self.Elements, actionButton)
	return actionButton
end

function QuickPanelLibrary:Notify(message)
	showNotification(message)
end

-- ========== MAIN HUB LIBRARY ==========
local MainHubLibrary = {}
MainHubLibrary.__index = MainHubLibrary

function MainHubLibrary:New()
	local self = setmetatable({}, MainHubLibrary)
	
	-- Buat ScreenGui
	self.ScreenGui = Instance.new("ScreenGui")
	self.ScreenGui.Name = "NightmareHubV1"
	self.ScreenGui.ResetOnSpawn = false
	
	-- Destroy existing GUI if ada
	for _, gui in pairs(game.CoreGui:GetChildren()) do
		if gui.Name == "NightmareHubV1" and gui ~= self.ScreenGui then
			gui:Destroy()
		end
	end
	
	-- Buat Toggle Button
	self.ToggleButton = Instance.new("ImageButton")
	self.ToggleButton.Size = UDim2.new(0, 60, 0, 60)
	self.ToggleButton.Position = UDim2.new(0, 20, 0.5, -30)
	self.ToggleButton.BackgroundTransparency = 1
	self.ToggleButton.Image = "rbxassetid://121996261654076"
	self.ToggleButton.Active = true
	self.ToggleButton.Draggable = true
	self.ToggleButton.Parent = self.ScreenGui
	
	-- Buat Frame
	self.Frame = Instance.new("Frame")
	self.Frame.Name = "Rectangle"
	self.Frame.Size = UDim2.new(0, 450, 0, 310)
	self.Frame.Position = UDim2.new(0.5, -225, 0.5, -155)
	self.Frame.BackgroundColor3 = Color3.new(0, 0, 0)
	self.Frame.BackgroundTransparency = 0.12
	self.Frame.BorderSizePixel = 0
	self.Frame.Active = true
	self.Frame.Draggable = true
	self.Frame.Visible = false
	self.Frame.Parent = self.ScreenGui
	
	self.OriginalPosition = self.Frame.Position
	
	-- UICorner
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 5)
	uiCorner.Parent = self.Frame
	
	-- UIStroke
	local frameStroke = Instance.new("UIStroke")
	frameStroke.Name = "Outline"
	frameStroke.Color = Color3.fromRGB(180, 0, 0)
	frameStroke.Thickness = 1.5
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Parent = self.Frame
	
	-- UIGradient untuk stroke
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	}
	uiGradient.Parent = frameStroke
	
	-- Gradient Animation
	TweenService:Create(uiGradient, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0), {Rotation = 360}):Play()
	
	-- Logo
	local logoImage = Instance.new("ImageLabel")
	logoImage.Name = "LogoImage"
	logoImage.Size = UDim2.new(0, 65, 0, 65)
	logoImage.Position = UDim2.new(0, 10, 0, -3)
	logoImage.BackgroundTransparency = 1
	logoImage.Image = "rbxassetid://107226954986307"
	logoImage.ScaleType = Enum.ScaleType.Fit
	logoImage.Parent = self.Frame
	
	-- Logo Divider
	local logoDivider = Instance.new("Frame")
	logoDivider.Name = "LogoDivider"
	logoDivider.Size = UDim2.new(0, 1, 0, 25)
	logoDivider.Position = UDim2.new(0, 95, 0, 8)
	logoDivider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	logoDivider.BackgroundTransparency = 0.5
	logoDivider.BorderSizePixel = 0
	logoDivider.Parent = self.Frame
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(0, 200, 0, 30)
	titleLabel.Position = UDim2.new(0, 115, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "Nightmare Hub"
	titleLabel.TextColor3 = Color3.fromRGB(180, 0, 0)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 20
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = self.Frame
	
	-- Subtitle
	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "SubtitleLabel"
	subtitleLabel.Size = UDim2.new(0, 300, 0, 15)
	subtitleLabel.Position = UDim2.new(0, 115, 0, 30)
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Text = "Version: 1.0 | https://discord.gg/Y7FEf44YH"
	subtitleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	subtitleLabel.Font = Enum.Font.Gotham
	subtitleLabel.TextSize = 10
	subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	subtitleLabel.Parent = self.Frame
	
	-- Subtitle Divider
	local subtitleDivider = Instance.new("Frame")
	subtitleDivider.Name = "SubtitleDivider"
	subtitleDivider.Size = UDim2.new(1, -20, 0, 1)
	subtitleDivider.Position = UDim2.new(0, 10, 0, 47)
	subtitleDivider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	subtitleDivider.BackgroundTransparency = 0.5
	subtitleDivider.BorderSizePixel = 0
	subtitleDivider.Parent = self.Frame
	
	-- Reset UI Button
	local resetButton = Instance.new("TextButton")
	resetButton.Name = "ResetButton"
	resetButton.Size = UDim2.new(0, 70, 0, 20)
	resetButton.Position = UDim2.new(1, -80, 0, 8)
	resetButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	resetButton.BackgroundTransparency = 0.75
	resetButton.BorderSizePixel = 0
	resetButton.Text = "Reset UI"
	resetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	resetButton.Font = Enum.Font.Gotham
	resetButton.TextSize = 10
	resetButton.Parent = self.Frame
	
	local resetCorner = Instance.new("UICorner")
	resetCorner.CornerRadius = UDim.new(0, 5)
	resetCorner.Parent = resetButton
	
	local resetStroke = Instance.new("UIStroke")
	resetStroke.Color = Color3.fromRGB(180, 0, 0)
	resetStroke.Thickness = 1.0
	resetStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	resetStroke.Parent = resetButton
	
	resetButton.MouseButton1Click:Connect(function()
		local resetTween = TweenService:Create(self.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = self.OriginalPosition
		})
		resetTween:Play()
	end)
	
	-- FPS & Ping Counter
	local fpsLabel = Instance.new("TextLabel")
	fpsLabel.Name = "FpsLabel"
	fpsLabel.Size = UDim2.new(0, 150, 0, 15)
	fpsLabel.Position = UDim2.new(1, -160, 0, 30)
	fpsLabel.BackgroundTransparency = 1
	fpsLabel.Text = "Fps: 0, Ping: 0"
	fpsLabel.TextColor3 = Color3.fromRGB(180, 0, 0)
	fpsLabel.Font = Enum.Font.GothamMedium
	fpsLabel.TextSize = 10
	fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
	fpsLabel.Parent = self.Frame
	
	-- FPS & Ping Logic
	local frames = 0
	local last = tick()
	
	RunService.RenderStepped:Connect(function()
		frames += 1
		local now = tick()
		if now - last >= 1 then
			local fps = frames
			frames = 0
			last = now
			
			local rawPing = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			local ping = math.floor(rawPing + 0.5)
			
			fpsLabel.Text = "Fps: " .. fps .. ", Ping: " .. ping
		end
	end)
	
	-- Side Tab Container
	local sideTabContainer = Instance.new("Frame")
	sideTabContainer.Name = "SideTabContainer"
	sideTabContainer.Size = UDim2.new(0, 80, 0, 200)
	sideTabContainer.Position = UDim2.new(0, 10, 0, 48)
	sideTabContainer.BackgroundTransparency = 1
	sideTabContainer.BorderSizePixel = 0
	sideTabContainer.Parent = self.Frame
	
	-- Divider
	local divider = Instance.new("Frame")
	divider.Name = "Divider"
	divider.Size = UDim2.new(0, 1, 0, 247)
	divider.Position = UDim2.new(0, 95, 0, 49)
	divider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	divider.BackgroundTransparency = 0.5
	divider.BorderSizePixel = 0
	divider.Parent = self.Frame
	
	-- Tab Names
	self.TabNames = {"Stealer", "Visual", "Misc", "Server", "Priority"}
	self.TabButtons = {}
	self.TabFrames = {}
	self.TabIndicators = {}
	self.CurrentTab = "Stealer"
	self.ActiveTweens = {}
	
	-- Create Tab Buttons
	for i, tabName in ipairs(self.TabNames) do
		-- Tab Indicator
		local tabIndicator = Instance.new("Frame")
		tabIndicator.Name = tabName .. "Indicator"
		tabIndicator.Size = UDim2.new(0, 78, 0, 30)
		tabIndicator.Position = UDim2.new(0, -1, 0, (i-1) * 45 + 5)
		tabIndicator.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		tabIndicator.BackgroundTransparency = 0.85
		tabIndicator.BorderSizePixel = 0
		tabIndicator.Visible = (tabName == "Stealer")
		tabIndicator.Parent = sideTabContainer
		
		local indicatorCorner = Instance.new("UICorner")
		indicatorCorner.CornerRadius = UDim.new(0, 5)
		indicatorCorner.Parent = tabIndicator
		
		table.insert(self.TabIndicators, tabIndicator)
		
		-- Tab Button
		local tabButton = Instance.new("TextButton")
		tabButton.Name = tabName .. "Tab"
		tabButton.Size = UDim2.new(1, 0, 0, 40)
		tabButton.Position = UDim2.new(0, 0, 0, (i-1) * 45)
		tabButton.BackgroundTransparency = 1
		tabButton.Text = "・" .. tabName
		tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
		tabButton.Font = Enum.Font.Gotham
		tabButton.TextSize = 14
		tabButton.TextXAlignment = Enum.TextXAlignment.Left
		tabButton.ZIndex = 2
		tabButton.Parent = sideTabContainer
		
		table.insert(self.TabButtons, {button = tabButton, name = tabName, indicator = tabIndicator})
		
		-- Create Content Frame
		local contentFrame = self:CreateContentFrame(tabName)
		self.TabFrames[tabName] = contentFrame
	end
	
	-- Connect Tab Buttons
	for _, tabData in ipairs(self.TabButtons) do
		tabData.button.MouseButton1Click:Connect(function()
			self:SwitchTab(tabData.name)
		end)
	end
	
	-- Animation Setup
	self.IsOpen = false
	self.IsAnimating = false
	self.CurrentTween = nil
	
	-- Toggle Button Functionality
	self.ToggleButton.MouseButton1Click:Connect(function()
		if self.IsAnimating then return end
		
		if self.IsOpen then
			self:CloseWindow()
		else
			self:OpenWindow()
		end
	end)
	
	-- Protect GUI
	protectGui(self.ScreenGui)
	
	-- ADD SERVER TAB CONTENT (KEKAL)
	self:CreateServerTabContent()
	
	return self
end

function MainHubLibrary:CreateContentFrame(tabName)
	local contentFrame = Instance.new("ScrollingFrame")
	contentFrame.Name = tabName .. "Content"
	contentFrame.Size = UDim2.new(0, 310, 0, 245)
	contentFrame.Position = UDim2.new(0, 120, 0, 58)
	contentFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	contentFrame.BackgroundTransparency = 0.78
	contentFrame.BorderSizePixel = 0
	contentFrame.ScrollBarThickness = 4
	contentFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	contentFrame.ScrollBarImageTransparency = 0.5
	contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
	contentFrame.Visible = (tabName == "Stealer")
	contentFrame.ClipsDescendants = true
	contentFrame.Parent = self.Frame
	
	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 14)
	contentCorner.Parent = contentFrame
	
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	contentLayout.Padding = UDim.new(0, 10)
	contentLayout.Parent = contentFrame
	
	local contentPadding = Instance.new("UIPadding")
	contentPadding.PaddingLeft = UDim.new(0, 10)
	contentPadding.PaddingRight = UDim.new(0, 10)
	contentPadding.PaddingTop = UDim.new(0, 10)
	contentPadding.PaddingBottom = UDim.new(0, 10)
	contentPadding.Parent = contentFrame
	
	contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
	end)
	
	return contentFrame
end

function MainHubLibrary:CreateServerTabContent()
	local serverFrame = self.TabFrames["Server"]
	
	-- INPUT JOB ID
	local inputButton = Instance.new("Frame")
	inputButton.Name = "InputJobID"
	inputButton.Size = UDim2.new(1, -20, 0, 35)
	inputButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	inputButton.BackgroundTransparency = 0.25
	inputButton.BorderSizePixel = 0
	inputButton.ClipsDescendants = true
	inputButton.Parent = serverFrame
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 5)
	inputCorner.Parent = inputButton
	
	local inputStroke = Instance.new("UIStroke")
	inputStroke.Color = Color3.fromRGB(180, 0, 0)
	inputStroke.Thickness = 1.5
	inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	inputStroke.Parent = inputButton
	
	local inputGradient = Instance.new("UIGradient")
	inputGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	inputGradient.Rotation = 0
	inputGradient.Parent = inputStroke
	
	local inputLabel = Instance.new("TextLabel")
	inputLabel.Name = "InputLabel"
	inputLabel.Size = UDim2.new(0, 100, 1, 0)
	inputLabel.Position = UDim2.new(0, 10, 0, 0)
	inputLabel.BackgroundTransparency = 1
	inputLabel.Text = "Input Job ID"
	inputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	inputLabel.Font = Enum.Font.GothamMedium
	inputLabel.TextSize = 12
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left
	inputLabel.TextTruncate = Enum.TextTruncate.AtEnd
	inputLabel.Parent = inputButton
	
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "InputBox"
	inputBox.Size = UDim2.new(0, 150, 1, -10)
	inputBox.Position = UDim2.new(1, -160, 0, 5)
	inputBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	inputBox.BackgroundTransparency = 0.65
	inputBox.BorderSizePixel = 0
	inputBox.Text = ""
	inputBox.PlaceholderText = "Enter Job ID..."
	inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	inputBox.Font = Enum.Font.Gotham
	inputBox.TextSize = 11
	inputBox.TextXAlignment = Enum.TextXAlignment.Center
	inputBox.ClearTextOnFocus = false
	inputBox.TextTruncate = Enum.TextTruncate.AtEnd
	inputBox.Parent = inputButton
	
	local inputBoxCorner = Instance.new("UICorner")
	inputBoxCorner.CornerRadius = UDim.new(0, 4)
	inputBoxCorner.Parent = inputBox
	
	-- JOIN SERVER BUTTON
	local joinButton = Instance.new("TextButton")
	joinButton.Name = "JoinServerButton"
	joinButton.Size = UDim2.new(1, -20, 0, 35)
	joinButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	joinButton.BackgroundTransparency = 0.25
	joinButton.BorderSizePixel = 0
	joinButton.Text = ""
	joinButton.ClipsDescendants = true
	joinButton.Parent = serverFrame
	
	local joinCorner = Instance.new("UICorner")
	joinCorner.CornerRadius = UDim.new(0, 5)
	joinCorner.Parent = joinButton
	
	local joinStroke = Instance.new("UIStroke")
	joinStroke.Color = Color3.fromRGB(180, 0, 0)
	joinStroke.Thickness = 1.5
	joinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	joinStroke.Parent = joinButton
	
	local joinGradient = Instance.new("UIGradient")
	joinGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	joinGradient.Rotation = 0
	joinGradient.Parent = joinStroke
	
	local joinLabel = Instance.new("TextLabel")
	joinLabel.Name = "JoinLabel"
	joinLabel.Size = UDim2.new(0, 100, 1, 0)
	joinLabel.Position = UDim2.new(0, 10, 0, 0)
	joinLabel.BackgroundTransparency = 1
	joinLabel.Text = "Join Server"
	joinLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	joinLabel.Font = Enum.Font.GothamMedium
	joinLabel.TextSize = 12
	joinLabel.TextXAlignment = Enum.TextXAlignment.Left
	joinLabel.TextTruncate = Enum.TextTruncate.AtEnd
	joinLabel.Parent = joinButton
	
	local joinIcon = Instance.new("ImageLabel")
	joinIcon.Name = "JoinIcon"
	joinIcon.Size = UDim2.new(0, 20, 0, 20)
	joinIcon.Position = UDim2.new(1, -30, 0.5, -10)
	joinIcon.BackgroundTransparency = 1
	joinIcon.Image = "rbxassetid://97462463002118"
	joinIcon.ScaleType = Enum.ScaleType.Fit
	joinIcon.Parent = joinButton
	
	joinButton.MouseButton1Click:Connect(function()
		local jobId = inputBox.Text
		
		if jobId == "" then
			showNotification("Please enter a Job ID first!")
			return
		end
		
		showNotification("Joining server: " .. jobId)
		
		local TeleportService = game:GetService("TeleportService")
		local success, errorMessage = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
		end)
		
		if not success then
			warn("Failed to join server:", errorMessage)
			showNotification("Failed to join! Invalid Job ID.")
		end
	end)
	
	-- COPY JOB ID BUTTON
	local copyJobButton = Instance.new("TextButton")
	copyJobButton.Name = "CopyJobIDButton"
	copyJobButton.Size = UDim2.new(1, -20, 0, 35)
	copyJobButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	copyJobButton.BackgroundTransparency = 0.25
	copyJobButton.BorderSizePixel = 0
	copyJobButton.Text = ""
	copyJobButton.ClipsDescendants = true
	copyJobButton.Parent = serverFrame
	
	local copyJobCorner = Instance.new("UICorner")
	copyJobCorner.CornerRadius = UDim.new(0, 5)
	copyJobCorner.Parent = copyJobButton
	
	local copyJobStroke = Instance.new("UIStroke")
	copyJobStroke.Color = Color3.fromRGB(180, 0, 0)
	copyJobStroke.Thickness = 1.5
	copyJobStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	copyJobStroke.Parent = copyJobButton
	
	local copyJobGradient = Instance.new("UIGradient")
	copyJobGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	copyJobGradient.Rotation = 0
	copyJobGradient.Parent = copyJobStroke
	
	local copyJobLabel = Instance.new("TextLabel")
	copyJobLabel.Name = "CopyJobLabel"
	copyJobLabel.Size = UDim2.new(0, 100, 1, 0)
	copyJobLabel.Position = UDim2.new(0, 10, 0, 0)
	copyJobLabel.BackgroundTransparency = 1
	copyJobLabel.Text = "Copy Job ID"
	copyJobLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	copyJobLabel.Font = Enum.Font.GothamMedium
	copyJobLabel.TextSize = 12
	copyJobLabel.TextXAlignment = Enum.TextXAlignment.Left
	copyJobLabel.TextTruncate = Enum.TextTruncate.AtEnd
	copyJobLabel.Parent = copyJobButton
	
	local copyJobIcon = Instance.new("ImageLabel")
	copyJobIcon.Name = "CopyJobIcon"
	copyJobIcon.Size = UDim2.new(0, 20, 0, 20)
	copyJobIcon.Position = UDim2.new(1, -30, 0.5, -10)
	copyJobIcon.BackgroundTransparency = 1
	copyJobIcon.Image = "rbxassetid://97462463002118"
	copyJobIcon.ScaleType = Enum.ScaleType.Fit
	copyJobIcon.Parent = copyJobButton
	
	copyJobButton.MouseButton1Click:Connect(function()
		local currentJobId = game.JobId
		
		if setclipboard then
			setclipboard(currentJobId)
			showNotification("Job ID copied: " .. currentJobId)
		else
			showNotification("Clipboard not supported!")
		end
	end)
	
	-- HOP SERVER BUTTON
	local hopButton = Instance.new("TextButton")
	hopButton.Name = "HopServerButton"
	hopButton.Size = UDim2.new(1, -20, 0, 35)
	hopButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	hopButton.BackgroundTransparency = 0.25
	hopButton.BorderSizePixel = 0
	hopButton.Text = ""
	hopButton.ClipsDescendants = true
	hopButton.Parent = serverFrame
	
	local hopCorner = Instance.new("UICorner")
	hopCorner.CornerRadius = UDim.new(0, 5)
	hopCorner.Parent = hopButton
	
	local hopStroke = Instance.new("UIStroke")
	hopStroke.Color = Color3.fromRGB(180, 0, 0)
	hopStroke.Thickness = 1.5
	hopStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	hopStroke.Parent = hopButton
	
	local hopGradient = Instance.new("UIGradient")
	hopGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	hopGradient.Rotation = 0
	hopGradient.Parent = hopStroke
	
	local hopLabel = Instance.new("TextLabel")
	hopLabel.Name = "HopLabel"
	hopLabel.Size = UDim2.new(0, 100, 1, 0)
	hopLabel.Position = UDim2.new(0, 10, 0, 0)
	hopLabel.BackgroundTransparency = 1
	hopLabel.Text = "Hop Server"
	hopLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	hopLabel.Font = Enum.Font.GothamMedium
	hopLabel.TextSize = 12
	hopLabel.TextXAlignment = Enum.TextXAlignment.Left
	hopLabel.TextTruncate = Enum.TextTruncate.AtEnd
	hopLabel.Parent = hopButton
	
	local hopIcon = Instance.new("ImageLabel")
	hopIcon.Name = "HopIcon"
	hopIcon.Size = UDim2.new(0, 20, 0, 20)
	hopIcon.Position = UDim2.new(1, -30, 0.5, -10)
	hopIcon.BackgroundTransparency = 1
	hopIcon.Image = "rbxassetid://97462463002118"
	hopIcon.ScaleType = Enum.ScaleType.Fit
	hopIcon.Parent = hopButton
	
	-- AUTO RETRY TOGGLE
	local autoRetryEnabled = false
	local isHopping = false
	
	local autoRetryFrame = Instance.new("Frame")
	autoRetryFrame.Name = "AutoRetryToggle"
	autoRetryFrame.Size = UDim2.new(1, -20, 0, 35)
	autoRetryFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	autoRetryFrame.BackgroundTransparency = 0.25
	autoRetryFrame.BorderSizePixel = 0
	autoRetryFrame.ClipsDescendants = false
	autoRetryFrame.Parent = serverFrame
	
	local autoRetryCorner = Instance.new("UICorner")
	autoRetryCorner.CornerRadius = UDim.new(0, 5)
	autoRetryCorner.Parent = autoRetryFrame
	
	local autoRetryStroke = Instance.new("UIStroke")
	autoRetryStroke.Color = Color3.fromRGB(180, 0, 0)
	autoRetryStroke.Thickness = 1.5
	autoRetryStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	autoRetryStroke.Parent = autoRetryFrame
	
	local autoRetryGradient = Instance.new("UIGradient")
	autoRetryGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	autoRetryGradient.Rotation = 0
	autoRetryGradient.Parent = autoRetryStroke
	
	local autoRetryLabel = Instance.new("TextLabel")
	autoRetryLabel.Name = "AutoRetryLabel"
	autoRetryLabel.Size = UDim2.new(0, 100, 1, 0)
	autoRetryLabel.Position = UDim2.new(0, 10, 0, 0)
	autoRetryLabel.BackgroundTransparency = 1
	autoRetryLabel.Text = "Auto Retry"
	autoRetryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	autoRetryLabel.Font = Enum.Font.GothamMedium
	autoRetryLabel.TextSize = 12
	autoRetryLabel.TextXAlignment = Enum.TextXAlignment.Left
	autoRetryLabel.TextTruncate = Enum.TextTruncate.AtEnd
	autoRetryLabel.Parent = autoRetryFrame
	
	local autoRetryToggleBg = Instance.new("Frame")
	autoRetryToggleBg.Name = "ToggleBg"
	autoRetryToggleBg.Size = UDim2.new(0, 35, 0, 18)
	autoRetryToggleBg.Position = UDim2.new(1, -45, 0.5, -9)
	autoRetryToggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	autoRetryToggleBg.BorderSizePixel = 0
	autoRetryToggleBg.Parent = autoRetryFrame
	
	local autoRetryToggleBgCorner = Instance.new("UICorner")
	autoRetryToggleBgCorner.CornerRadius = UDim.new(1, 0)
	autoRetryToggleBgCorner.Parent = autoRetryToggleBg
	
	local autoRetryToggleBgGradient = Instance.new("UIGradient")
	autoRetryToggleBgGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	autoRetryToggleBgGradient.Rotation = 0
	autoRetryToggleBgGradient.Parent = autoRetryToggleBg
	
	local autoRetryToggleCircle = Instance.new("Frame")
	autoRetryToggleCircle.Name = "ToggleCircle"
	autoRetryToggleCircle.Size = UDim2.new(0, 14, 0, 14)
	autoRetryToggleCircle.Position = UDim2.new(0, 2, 0.5, -7)
	autoRetryToggleCircle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	autoRetryToggleCircle.BorderSizePixel = 0
	autoRetryToggleCircle.Parent = autoRetryToggleBg
	
	local autoRetryToggleCircleCorner = Instance.new("UICorner")
	autoRetryToggleCircleCorner.CornerRadius = UDim.new(1, 0)
	autoRetryToggleCircleCorner.Parent = autoRetryToggleCircle
	
	local autoRetryToggleButton = Instance.new("TextButton")
	autoRetryToggleButton.Name = "ToggleButton"
	autoRetryToggleButton.Size = UDim2.new(1, 0, 1, 0)
	autoRetryToggleButton.Position = UDim2.new(0, 0, 0, 0)
	autoRetryToggleButton.BackgroundTransparency = 1
	autoRetryToggleButton.Text = ""
	autoRetryToggleButton.Parent = autoRetryFrame
	
	autoRetryToggleButton.MouseButton1Click:Connect(function()
		autoRetryEnabled = not autoRetryEnabled
		
		local targetPos
		if autoRetryEnabled then
			targetPos = UDim2.new(1, -16, 0.5, -7)
			showNotification("Auto Retry: Enabled")
		else
			targetPos = UDim2.new(0, 2, 0.5, -7)
			showNotification("Auto Retry: Disabled")
			isHopping = false
		end
		
		local circleTween = TweenService:Create(autoRetryToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = targetPos
		})
		circleTween:Play()
	end)
	
	-- HOP SERVER FUNCTIONALITY
	hopButton.MouseButton1Click:Connect(function()
		if isHopping then
			showNotification("Already hopping, please wait...")
			return
		end
		
		isHopping = true
		showNotification("Server hopping...")
		
		local TeleportService = game:GetService("TeleportService")
		local attempt = 0
		
		local function tryHop()
			attempt = attempt + 1
			
			local success, result = pcall(function()
				local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
				
				for _, server in pairs(servers.data) do
					if server.id ~= game.JobId and server.playing < server.maxPlayers then
						showNotification("Found server! Joining...")
						TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, player)
						isHopping = false
						return true
					end
				end
				
				return false
			end)
			
			if not success then
				warn("Hop attempt failed:", result)
				
				if autoRetryEnabled and isHopping then
					showNotification("Retry " .. attempt .. ": Searching...")
					task.wait(2)
					return tryHop()
				else
					showNotification("Failed to hop server!")
					isHopping = false
					return false
				end
			end
			
			if not result then
				if autoRetryEnabled and isHopping then
					showNotification("Retry " .. attempt .. ": No servers found...")
					task.wait(2)
					return tryHop()
				else
					showNotification("No available servers found!")
					isHopping = false
					return false
				end
			end
		end
		
		tryHop()
	end)
	
	-- REJOIN SERVER BUTTON
	local rejoinButton = Instance.new("TextButton")
	rejoinButton.Name = "RejoinServerButton"
	rejoinButton.Size = UDim2.new(1, -20, 0, 35)
	rejoinButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	rejoinButton.BackgroundTransparency = 0.25
	rejoinButton.BorderSizePixel = 0
	rejoinButton.Text = ""
	rejoinButton.ClipsDescendants = true
	rejoinButton.Parent = serverFrame
	
	local rejoinCorner = Instance.new("UICorner")
	rejoinCorner.CornerRadius = UDim.new(0, 5)
	rejoinCorner.Parent = rejoinButton
	
	local rejoinStroke = Instance.new("UIStroke")
	rejoinStroke.Color = Color3.fromRGB(180, 0, 0)
	rejoinStroke.Thickness = 1.5
	rejoinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rejoinStroke.Parent = rejoinButton
	
	local rejoinGradient = Instance.new("UIGradient")
	rejoinGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	rejoinGradient.Rotation = 0
	rejoinGradient.Parent = rejoinStroke
	
	local rejoinLabel = Instance.new("TextLabel")
	rejoinLabel.Name = "RejoinLabel"
	rejoinLabel.Size = UDim2.new(0, 100, 1, 0)
	rejoinLabel.Position = UDim2.new(0, 10, 0, 0)
	rejoinLabel.BackgroundTransparency = 1
	rejoinLabel.Text = "Rejoin Server"
	rejoinLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	rejoinLabel.Font = Enum.Font.GothamMedium
	rejoinLabel.TextSize = 12
	rejoinLabel.TextXAlignment = Enum.TextXAlignment.Left
	rejoinLabel.TextTruncate = Enum.TextTruncate.AtEnd
	rejoinLabel.Parent = rejoinButton
	
	local rejoinIcon = Instance.new("ImageLabel")
	rejoinIcon.Name = "RejoinIcon"
	rejoinIcon.Size = UDim2.new(0, 20, 0, 20)
	rejoinIcon.Position = UDim2.new(1, -30, 0.5, -10)
	rejoinIcon.BackgroundTransparency = 1
	rejoinIcon.Image = "rbxassetid://97462463002118"
	rejoinIcon.ScaleType = Enum.ScaleType.Fit
	rejoinIcon.Parent = rejoinButton
	
	rejoinButton.MouseButton1Click:Connect(function()
		showNotification("Rejoining server...")
		
		local TeleportService = game:GetService("TeleportService")
		TeleportService:Teleport(game.PlaceId, player)
	end)
end

function MainHubLibrary:SwitchTab(tabName)
	if self.CurrentTab == tabName then return end
	
	if self.ActiveTweens[self.CurrentTab] then
		self.ActiveTweens[self.CurrentTab]:Cancel()
	end
	if self.ActiveTweens[tabName] then
		self.ActiveTweens[tabName]:Cancel()
	end
	
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	
	for _, tabData in ipairs(self.TabButtons) do
		if tabData.name ~= tabName then
			tabData.indicator.Visible = false
			tabData.indicator.BackgroundTransparency = 1
		end
		if self.TabFrames[tabData.name] then
			self.TabFrames[tabData.name].Visible = false
		end
	end
	
	for _, tabData in ipairs(self.TabButtons) do
		if tabData.name == tabName then
			tabData.indicator.Visible = true
			tabData.indicator.BackgroundTransparency = 1
			
			local tween = TweenService:Create(tabData.indicator, tweenInfo, {
				BackgroundTransparency = 0.85
			})
			self.ActiveTweens[tabName] = tween
			tween:Play()
			
			if self.TabFrames[tabName] then
				self.TabFrames[tabName].Visible = true
			end
			break
		end
	end
	
	self.CurrentTab = tabName
end

function MainHubLibrary:OpenWindow()
	if self.IsOpen or self.IsAnimating then return end
	self.IsAnimating = true
	self.IsOpen = true
	
	if self.CurrentTween then
		self.CurrentTween:Cancel()
	end
	
	self.Frame.Visible = true
	
	local currentPos = self.Frame.Position
	
	self.Frame.Size = UDim2.new(0, 315, 0, 217)
	self.Frame.Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset - 67.5, currentPos.Y.Scale, currentPos.Y.Offset - 46.5)
	self.Frame.BackgroundTransparency = 1
	
	self.CurrentTween = TweenService:Create(self.Frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 450, 0, 310),
		Position = currentPos,
		BackgroundTransparency = 0.12
	})
	
	self.CurrentTween:Play()
	self.CurrentTween.Completed:Connect(function()
		self.IsAnimating = false
		self.CurrentTween = nil
	end)
end

function MainHubLibrary:CloseWindow()
	if not self.IsOpen or self.IsAnimating then return end
	self.IsAnimating = true
	self.IsOpen = false
	
	if self.CurrentTween then
		self.CurrentTween:Cancel()
	end
	
	local currentPos = self.Frame.Position
	
	self.CurrentTween = TweenService:Create(self.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 315, 0, 217),
		Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset - 67.5, currentPos.Y.Scale, currentPos.Y.Offset - 46.5),
		BackgroundTransparency = 1
	})
	
	self.CurrentTween:Play()
	
	self.CurrentTween.Completed:Connect(function()
		self.Frame.Visible = false
		self.Frame.Position = currentPos
		self.IsAnimating = false
		self.CurrentTween = nil
	end)
end

function MainHubLibrary:AddToggle(options)
	local tab = options.Tab or "Misc"
	local contentFrame = self.TabFrames[tab]
	
	if not contentFrame then
		warn("Tab not found:", tab)
		return
	end
	
	local toggleFrame = Instance.new("Frame")
	toggleFrame.Size = UDim2.new(1, -20, 0, 35)
	toggleFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	toggleFrame.BackgroundTransparency = 0.25
	toggleFrame.BorderSizePixel = 0
	toggleFrame.ClipsDescendants = false
	toggleFrame.Parent = contentFrame
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 5)
	toggleCorner.Parent = toggleFrame
	
	local toggleStroke = Instance.new("UIStroke")
	toggleStroke.Color = Color3.fromRGB(180, 0, 0)
	toggleStroke.Thickness = 1.5
	toggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	toggleStroke.Parent = toggleFrame
	
	local toggleGradient = Instance.new("UIGradient")
	toggleGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	toggleGradient.Rotation = 0
	toggleGradient.Parent = toggleStroke
	
	local toggleLabel = Instance.new("TextLabel")
	toggleLabel.Name = "ToggleLabel"
	toggleLabel.Size = UDim2.new(0, 200, 1, 0)
	toggleLabel.Position = UDim2.new(0, 10, 0, 0)
	toggleLabel.BackgroundTransparency = 1
	toggleLabel.Text = options.Title or "Toggle"
	toggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	toggleLabel.Font = Enum.Font.GothamMedium
	toggleLabel.TextSize = 12
	toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
	toggleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	toggleLabel.Parent = toggleFrame
	
	local toggleBg = Instance.new("Frame")
	toggleBg.Name = "ToggleBg"
	toggleBg.Size = UDim2.new(0, 35, 0, 18)
	toggleBg.Position = UDim2.new(1, -45, 0.5, -9)
	toggleBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = toggleFrame
	
	local toggleBgCorner = Instance.new("UICorner")
	toggleBgCorner.CornerRadius = UDim.new(1, 0)
	toggleBgCorner.Parent = toggleBg
	
	local toggleBgGradient = Instance.new("UIGradient")
	toggleBgGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	toggleBgGradient.Rotation = 0
	toggleBgGradient.Parent = toggleBg
	
	local toggleCircle = Instance.new("Frame")
	toggleCircle.Name = "ToggleCircle"
	toggleCircle.Size = UDim2.new(0, 14, 0, 14)
	toggleCircle.Position = UDim2.new(0, 2, 0.5, -7)
	toggleCircle.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	toggleCircle.BorderSizePixel = 0
	toggleCircle.Parent = toggleBg
	
	local toggleCircleCorner = Instance.new("UICorner")
	toggleCircleCorner.CornerRadius = UDim.new(1, 0)
	toggleCircleCorner.Parent = toggleCircle
	
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(1, 0, 1, 0)
	toggleButton.Position = UDim2.new(0, 0, 0, 0)
	toggleButton.BackgroundTransparency = 1
	toggleButton.Text = ""
	toggleButton.Parent = toggleFrame
	
	local toggleEnabled = options.Default or false
	
	-- Update visual based on default
	if toggleEnabled then
		toggleCircle.Position = UDim2.new(1, -16, 0.5, -7)
	end
	
	toggleButton.MouseButton1Click:Connect(function()
		toggleEnabled = not toggleEnabled
		
		local targetPos
		if toggleEnabled then
			targetPos = UDim2.new(1, -16, 0.5, -7)
		else
			targetPos = UDim2.new(0, 2, 0.5, -7)
		end
		
		local circleTween = TweenService:Create(toggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = targetPos
		})
		circleTween:Play()
		
		if options.Callback then
			options.Callback(toggleEnabled)
		end
	end)
	
	return toggleFrame
end

function MainHubLibrary:AddButton(options)
	local tab = options.Tab or "Misc"
	local contentFrame = self.TabFrames[tab]
	
	if not contentFrame then
		warn("Tab not found:", tab)
		return
	end
	
	local buttonFrame = Instance.new("TextButton")
	buttonFrame.Size = UDim2.new(1, -20, 0, 35)
	buttonFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	buttonFrame.BackgroundTransparency = 0.25
	buttonFrame.BorderSizePixel = 0
	buttonFrame.Text = ""
	buttonFrame.ClipsDescendants = true
	buttonFrame.Parent = contentFrame
	
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 5)
	buttonCorner.Parent = buttonFrame
	
	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = Color3.fromRGB(180, 0, 0)
	buttonStroke.Thickness = 1.5
	buttonStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	buttonStroke.Parent = buttonFrame
	
	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	buttonGradient.Rotation = 0
	buttonGradient.Parent = buttonStroke
	
	local buttonLabel = Instance.new("TextLabel")
	buttonLabel.Name = "ButtonLabel"
	buttonLabel.Size = UDim2.new(1, -50, 1, 0)
	buttonLabel.Position = UDim2.new(0, 10, 0, 0)
	buttonLabel.BackgroundTransparency = 1
	buttonLabel.Text = options.Title or "Button"
	buttonLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	buttonLabel.Font = Enum.Font.GothamMedium
	buttonLabel.TextSize = 12
	buttonLabel.TextXAlignment = Enum.TextXAlignment.Left
	buttonLabel.TextTruncate = Enum.TextTruncate.AtEnd
	buttonLabel.Parent = buttonFrame
	
	local buttonIcon = Instance.new("ImageLabel")
	buttonIcon.Name = "ButtonIcon"
	buttonIcon.Size = UDim2.new(0, 20, 0, 20)
	buttonIcon.Position = UDim2.new(1, -30, 0.5, -10)
	buttonIcon.BackgroundTransparency = 1
	buttonIcon.Image = "rbxassetid://97462463002118"
	buttonIcon.ScaleType = Enum.ScaleType.Fit
	buttonIcon.Parent = buttonFrame
	
	buttonFrame.MouseButton1Click:Connect(function()
		if options.Callback then
			options.Callback()
		end
	end)
	
	return buttonFrame
end

function MainHubLibrary:AddInput(options)
	local tab = options.Tab or "Misc"
	local contentFrame = self.TabFrames[tab]
	
	if not contentFrame then
		warn("Tab not found:", tab)
		return
	end
	
	local inputFrame = Instance.new("Frame")
	inputFrame.Name = "InputFrame"
	inputFrame.Size = UDim2.new(1, -20, 0, 35)
	inputFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	inputFrame.BackgroundTransparency = 0.25
	inputFrame.BorderSizePixel = 0
	inputFrame.ClipsDescendants = true
	inputFrame.Parent = contentFrame
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 5)
	inputCorner.Parent = inputFrame
	
	local inputStroke = Instance.new("UIStroke")
	inputStroke.Color = Color3.fromRGB(180, 0, 0)
	inputStroke.Thickness = 1.5
	inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	inputStroke.Parent = inputFrame
	
	local inputGradient = Instance.new("UIGradient")
	inputGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 0, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 0, 0))
	}
	inputGradient.Rotation = 0
	inputGradient.Parent = inputStroke
	
	local inputLabel = Instance.new("TextLabel")
	inputLabel.Name = "InputLabel"
	inputLabel.Size = UDim2.new(0, 100, 1, 0)
	inputLabel.Position = UDim2.new(0, 10, 0, 0)
	inputLabel.BackgroundTransparency = 1
	inputLabel.Text = options.Title or "Input"
	inputLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	inputLabel.Font = Enum.Font.GothamMedium
	inputLabel.TextSize = 12
	inputLabel.TextXAlignment = Enum.TextXAlignment.Left
	inputLabel.TextTruncate = Enum.TextTruncate.AtEnd
	inputLabel.Parent = inputFrame
	
	local inputBox = Instance.new("TextBox")
	inputBox.Name = "InputBox"
	inputBox.Size = UDim2.new(0, 140, 1, -10)
	inputBox.Position = UDim2.new(1, -150, 0, 5)
	inputBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	inputBox.BackgroundTransparency = 0.65
	inputBox.BorderSizePixel = 0
	inputBox.Text = ""
	inputBox.PlaceholderText = options.Placeholder or "Enter text..."
	inputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	inputBox.Font = Enum.Font.Gotham
	inputBox.TextSize = 11
	inputBox.TextXAlignment = Enum.TextXAlignment.Center
	inputBox.ClearTextOnFocus = false
	inputBox.TextTruncate = Enum.TextTruncate.AtEnd
	inputBox.Parent = inputFrame
	
	local inputBoxCorner = Instance.new("UICorner")
	inputBoxCorner.CornerRadius = UDim.new(0, 4)
	inputBoxCorner.Parent = inputBox
	
	inputBox.FocusLost:Connect(function(enterPressed)
		if options.Callback then
			options.Callback(inputBox.Text)
		end
	end)
	
	return inputFrame
end

function MainHubLibrary:Notify(message)
	showNotification(message)
end

-- ========== RETURN LIBRARIES ==========
return {
	QuickPanel = QuickPanelLibrary,
	MainHub = MainHubLibrary
}
