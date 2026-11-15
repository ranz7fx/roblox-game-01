-- SKYBOUND client: HUD (stage, coins, timer), death toast, win screen
-- and the Play Again button. All game state lives on the server; this
-- script only shows it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild(Config.REMOTE_NAME)

local playerGui = player:WaitForChild("PlayerGui")

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local minutes = math.floor(seconds / 60)
	local rest = seconds % 60
	return string.format("%02d:%02d", minutes, rest)
end

-- ---------- GUI ----------
local gui = Instance.new("ScreenGui")
gui.Name = "SkyboundGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
	return c
end

local function pill(parent, name, anchor, position, width)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = anchor
	label.Position = position
	label.Size = UDim2.fromOffset(width, 46)
	label.BackgroundColor3 = Color3.fromRGB(20, 24, 40)
	label.BackgroundTransparency = 0.25
	label.Font = Enum.Font.GothamBold
	label.TextSize = 24
	label.Parent = parent
	addCorner(label, 10)
	return label
end

-- Stage: top centre. Coins and timer: top right, clear of the top-left
-- corner where Roblox puts its own menu buttons.
local stageLabel = pill(gui, "StageLabel", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 12), 280)
stageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
stageLabel.TextSize = 26
stageLabel.Text = "STAGE 0 / " .. tostring(Config.STAGE_COUNT)

local coinsLabel = pill(gui, "CoinsLabel", Vector2.new(1, 0), UDim2.new(1, 0, -16, 12), 180)
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.Text = "COINS 0 / " .. tostring(Config.TOTAL_COINS)

local timerLabel = pill(gui, "TimerLabel", Vector2.new(1, 0), UDim2.new(1, 0, -16, 66), 180)
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.Text = "TIME 00:00"

local hintLabel = Instance.new("TextLabel")
hintLabel.Name = "HintLabel"
hintLabel.AnchorPoint = Vector2.new(0.5, 1)
hintLabel.Position = UDim2.new(0.5, 0, 1, -16)
hintLabel.Size = UDim2.fromOffset(620, 36)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hintLabel.TextStrokeTransparency = 0.5
hintLabel.Font = Enum.Font.GothamBold
hintLabel.TextSize = 20
hintLabel.Text = "Climb the tower - reach the golden pad at the top!"
hintLabel.Parent = gui

local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "ToastLabel"
toastLabel.AnchorPoint = Vector2.new(0.5, 0.5)
toastLabel.Position = UDim2.new(0.5, 0, 0.35, 0)
toastLabel.Size = UDim2.fromOffset(460, 52)
toastLabel.BackgroundColor3 = Color3.fromRGB(120, 20, 20)
toastLabel.BackgroundTransparency = 0.2
toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 24
toastLabel.Text = "You fell! Back to your checkpoint."
toastLabel.Visible = false
toastLabel.Parent = gui
addCorner(toastLabel, 10)

-- Win screen.
local winFrame = Instance.new("Frame")
winFrame.Name = "WinFrame"
winFrame.Size = UDim2.fromScale(1, 1)
winFrame.BackgroundColor3 = Color3.fromRGB(10, 12, 24)
winFrame.BackgroundTransparency = 0.35
winFrame.Visible = false
winFrame.Parent = gui

local winTitle = Instance.new("TextLabel")
winTitle.AnchorPoint = Vector2.new(0.5, 0.5)
winTitle.Position = UDim2.new(0.5, 0, 0.5, -90)
winTitle.Size = UDim2.fromOffset(520, 80)
winTitle.BackgroundTransparency = 1
winTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
winTitle.Font = Enum.Font.GothamBold
winTitle.TextSize = 56
winTitle.Text = "YOU WIN!"
winTitle.Parent = winFrame

local winStats = Instance.new("TextLabel")
winStats.Name = "WinStats"
winStats.AnchorPoint = Vector2.new(0.5, 0.5)
winStats.Position = UDim2.new(0.5, 0, 0.5, -10)
winStats.Size = UDim2.fromOffset(560, 44)
winStats.BackgroundTransparency = 1
winStats.TextColor3 = Color3.fromRGB(255, 255, 255)
winStats.Font = Enum.Font.GothamBold
winStats.TextSize = 28
winStats.Text = ""
winStats.Parent = winFrame

local playAgainButton = Instance.new("TextButton")
playAgainButton.Name = "PlayAgainButton"
playAgainButton.AnchorPoint = Vector2.new(0.5, 0.5)
playAgainButton.Position = UDim2.new(0.5, 0, 0.5, 70)
playAgainButton.Size = UDim2.fromOffset(260, 60)
playAgainButton.BackgroundColor3 = Color3.fromRGB(46, 160, 67)
playAgainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playAgainButton.Font = Enum.Font.GothamBold
playAgainButton.TextSize = 28
playAgainButton.Text = "PLAY AGAIN"
playAgainButton.Parent = winFrame
addCorner(playAgainButton, 12)

gui.Parent = playerGui

-- ---------- Logic ----------
local runStart = os.clock()
local won = false
local toastUntil = 0

RunService.Heartbeat:Connect(function()
	if not won then
		timerLabel.Text = "TIME " .. formatTime(os.clock() - runStart)
	end
	if toastLabel.Visible and os.clock() > toastUntil then
		toastLabel.Visible = false
	end
end)

local function hookCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		toastLabel.Visible = true
		toastUntil = os.clock() + 2.5
	end)
end

if player.Character then
	hookCharacter(player.Character)
end
player.CharacterAdded:Connect(hookCharacter)

remotes.OnClientEvent:Connect(function(action, a, b)
	if action == "HUD" then
		local stage = a
		local coins = b
		stageLabel.Text = "STAGE " .. tostring(stage) .. " / " .. tostring(Config.STAGE_COUNT)
		coinsLabel.Text = "COINS " .. tostring(coins) .. " / " .. tostring(Config.TOTAL_COINS)
	elseif action == "Win" then
		local elapsed = a
		local coins = b
		won = true
		timerLabel.Text = "TIME " .. formatTime(elapsed)
		winStats.Text = "Time: " .. formatTime(elapsed) .. "   -   Coins: " .. tostring(coins) .. " / " .. tostring(Config.TOTAL_COINS)
		winFrame.Visible = true
	elseif action == "Reset" then
		won = false
		runStart = os.clock()
		winFrame.Visible = false
		toastLabel.Visible = false
		timerLabel.Text = "TIME 00:00"
	end
end)

playAgainButton.MouseButton1Click:Connect(function()
	remotes:FireServer("PlayAgain")
end)

remotes:FireServer("Ready")
