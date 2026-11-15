-- SKYBOUND: moving platforms, disappearing platforms and spinning coins.
-- Moving platforms are tweened back and forth; Roblox carries players
-- standing on a tweened anchored part, so no extra code is needed for that.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local movingFolder = Workspace:WaitForChild("MovingPlatforms")
local fadingFolder = Workspace:WaitForChild("DisappearingPlatforms")
local coinsFolder = Workspace:WaitForChild("Coins")

-- Travel of each moving platform, by part name. "from"/"to" are the
-- platform centre coordinates along the travel axis.
local MOVERS = {
	Stage_5 = { axis = "X", from = 8, to = 20 },
	Stage_11 = { axis = "Z", from = -28, to = -40 },
}

for _, part in movingFolder:GetChildren() do
	local spec = MOVERS[part.Name]
	if spec then
		local startPos = part.Position
		local goalPos = startPos
		if spec.axis == "X" then
			part.Position = Vector3.new(spec.from, startPos.Y, startPos.Z)
			goalPos = Vector3.new(spec.to, startPos.Y, startPos.Z)
		else
			part.Position = Vector3.new(startPos.X, startPos.Y, spec.from)
			goalPos = Vector3.new(startPos.X, startPos.Y, spec.to)
		end
		local info = TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		local tween = TweenService:Create(part, info, { CFrame = CFrame.new(goalPos) })
		tween:Play()
	end
end

-- Disappearing platforms: step on one and it fades out under you, then
-- comes back a few seconds later.
local faderBusy = {}

for _, part in fadingFolder:GetChildren() do
	part.Touched:Connect(function(hit)
		if faderBusy[part] then
			return
		end
		local character = hit.Parent
		if not character then
			return
		end
		if not Players:GetPlayerFromCharacter(character) then
			return
		end
		faderBusy[part] = true
		task.delay(0.8, function()
			part.CanCollide = false
			local tween = TweenService:Create(part, TweenInfo.new(0.4), { Transparency = 1 })
			tween:Play()
		end)
		task.delay(0.8 + Config.FADER_HIDDEN_SECONDS, function()
			part.CanCollide = true
			local tween = TweenService:Create(part, TweenInfo.new(0.4), { Transparency = 0 })
			tween:Play()
			faderBusy[part] = nil
		end)
	end)
end

-- Coins spin in place and bob gently, so they read as collectibles.
local coinData = {}
for _, coin in coinsFolder:GetChildren() do
	coinData[coin] = { base = coin.CFrame, angle = 0 }
end

task.spawn(function()
	while true do
		task.wait(0.05)
		local t = os.clock()
		for coin, data in coinData do
			if coin.Parent then
				data.angle = data.angle + math.rad(6)
				local bob = math.sin(t * 2) * 0.25
				coin.CFrame = data.base * CFrame.Angles(0, data.angle, 0) * CFrame.new(0, bob, 0)
			end
		end
	end
end)
