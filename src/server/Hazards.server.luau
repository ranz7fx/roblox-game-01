-- SKYBOUND: lava, kill bricks and the fall safety net.
-- Anything inside Workspace/Hazards kills a humanoid on touch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local hazardsFolder = Workspace:WaitForChild("Hazards")

local function killHumanoid(humanoid)
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
end

for _, part in hazardsFolder:GetChildren() do
	part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then
			return
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			killHumanoid(humanoid)
		end
	end)
end

-- Safety net: anything that slips past the lava (or off the edge of the
-- world) still dies instead of falling forever.
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if character then
				local root = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if root and humanoid and root.Position.Y < Config.KILL_HEIGHT then
					killHumanoid(humanoid)
				end
			end
		end
	end
end)
