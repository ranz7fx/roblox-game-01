-- SKYBOUND shared configuration.
-- Required by the server and the client so both agree on the numbers.

local Config = {}

Config.GAME_NAME = "SKYBOUND"
Config.STAGE_COUNT = 14
Config.TOTAL_COINS = 10

-- Stage numbers that hold a checkpoint pad. Touching one makes it your
-- respawn point for the rest of the run.
Config.CHECKPOINT_STAGES = { 4, 8, 12 }

-- How long a collected coin stays gone before it pops back.
Config.COIN_RESPAWN_SECONDS = 15

-- How long a disappearing platform stays gone before it comes back.
Config.FADER_HIDDEN_SECONDS = 2.5

-- Falling below this height kills you (backup for the lava floor).
Config.KILL_HEIGHT = -25

-- RemoteEvent name in ReplicatedStorage.
Config.REMOTE_NAME = "SkyboundRemotes"

return Config
