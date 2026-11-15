-- SKYBOUND: game state, checkpoints, coins, the win pad and HUD updates.
-- One state table per player, kept in memory for this session only
-- (no DataStore: nothing here needs to survive the session).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local remotes = ReplicatedStorage:WaitForChild(Config.REMOTE_NAME)
local stagesFolder = Workspace:WaitForChild("Stages")
local movingFolder = Workspace:WaitForChild("MovingPlatforms")
local fadingFolder = Workspace:WaitForChild("DisappearingPlatforms")
local coinsFolder = Workspace:WaitForChild("Coins")
local checkpointsFolder = Workspace:WaitForChild("Checkpoints")
local winPad = Workspace:WaitForChild("WinPad")
local spawnLocation = Workspace:WaitForChild("Spawn")

-- state[player] = { stage, coins, startTime, finished }
local state = {}

local function newState()
	return {
		stage = 0,
		coins = 0,
		startTime = os.clock(),
		finished = false,
	}
end

local function sendHud(player)
	local s = state[player]
	if not s then
		return
	end
	remotes:FireClient(player, "HUD", s.stage, s.coins)
end

local function resetPlayer(player, teleport)
	local s = state[player]
	if not s then
		return
	end
	s.stage = 0
	s.coins = 0
	s.startTime = os.clock()
	s.finished = false
	player.RespawnLocation = spawnLocation
	if teleport then
		local character = player.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = CFrame.new(0, 3, 6)
			end
		end
	end
	remotes:FireClient(player, "Reset")
	sendHud(player)
end

-- "Stage_7" -> 7, "Checkpoint_12" -> 12, anything else -> nil.
local function stageFromName(name)
	return tonumber(string.match(name, "_(%d+)$"))
end

local function onStageTouched(stageNumber)
	return function(hit)
		local character = hit.Parent
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local s = state[player]
		if not s or s.finished then
			return
		end
		if stageNumber > s.stage then
			s.stage = stageNumber
			sendHud(player)
		end
	end
end

local function hookStagePart(part)
	local n = stageFromName(part.Name)
	if n then
		part.Touched:Connect(onStageTouched(n))
	end
end

for _, part in stagesFolder:GetChildren() do
	hookStagePart(part)
end
for _, part in movingFolder:GetChildren() do
	hookStagePart(part)
end
for _, part in fadingFolder:GetChildren() do
	hookStagePart(part)
end

-- Checkpoints: touching one moves your respawn point there.
for _, pad in checkpointsFolder:GetChildren() do
	local n = stageFromName(pad.Name)
	if n then
		pad.Touched:Connect(function(hit)
			local character = hit.Parent
			if not character then
				return
			end
			local player = Players:GetPlayerFromCharacter(character)
			if not player then
				return
			end
			local s = state[player]
			if not s or s.finished then
				return
			end
			player.RespawnLocation = pad
			if n > s.stage then
				s.stage = n
				sendHud(player)
			end
		end)
	end
end

-- Coins: touch one to collect it. It vanishes for everyone, then pops
-- back after COIN_RESPAWN_SECONDS so a second climb can collect it again.
local coinBusy = {}

local function hookCoin(coin)
	coin.Touched:Connect(function(hit)
		if coinBusy[coin] then
			return
		end
		local character = hit.Parent
		if not character then
			return
		end
		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end
		local s = state[player]
		if not s or s.finished then
			return
		end
		coinBusy[coin] = true
		s.coins = s.coins + 1
		sendHud(player)

		coin.CanTouch = false
		coin.Transparency = 1
		task.delay(Config.COIN_RESPAWN_SECONDS, function()
			coin.Transparency = 0
			coin.CanTouch = true
			coinBusy[coin] = nil
		end)
	end)
end

for _, coin in coinsFolder:GetChildren() do
	hookCoin(coin)
end

-- Win pad: first touch ends the run and shows the win screen.
winPad.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end
	local s = state[player]
	if not s or s.finished then
		return
	end
	s.finished = true
	s.stage = Config.STAGE_COUNT
	local elapsed = os.clock() - s.startTime
	sendHud(player)
	remotes:FireClient(player, "Win", elapsed, s.coins)
end)

-- Client requests.
remotes.OnServerEvent:Connect(function(player, action)
	if action == "Ready" then
		sendHud(player)
	elseif action == "PlayAgain" then
		resetPlayer(player, true)
	end
end)

-- Player lifecycle.
Players.PlayerAdded:Connect(function(player)
	state[player] = newState()
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		sendHud(player)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	state[player] = nil
end)

for _, player in Players:GetPlayers() do
	state[player] = newState()
end
