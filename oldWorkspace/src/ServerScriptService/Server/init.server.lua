local START_TICK = tick()
------------------------------------------------------------------

-- [[ Services ]]
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage') -- Not in use
local MarketPlaceService = game:GetService('MarketplaceService') -- Not in use
local TweenService = game:GetService('TweenService') -- Not in use
local SoundService = game:GetService('SoundService') -- Not in use
local CollectionService = game:GetService('CollectionService') -- Not in use
local BadgeService = game:GetService('BadgeService') -- Not in use
local MessagingService = game:GetService('MessagingService') -- Not in use
local TeleportService = game:GetService('TeleportService') -- Not in use
local Players = game:GetService('Players') -- Not in use
local TextService = game:GetService('TextService') -- Not in use
local Debris = game:GetService('Debris') -- Not in use
local ContentProvider = game:GetService('ContentProvider') -- Not in use

------------------------------------------------------------------

local DefaultFrameEvent = RunService.Heartbeat -- Not in use

local CurrentPlaceId = game.PlaceId -- Not in use
local CurrentPlaceVersion = game.PlaceVersion -- Not in use

------------------------------------------------------------------

--  [[ Folders ]]
local Utilities = ReplicatedStorage:WaitForChild('Utility')

local Events = ReplicatedStorage:WaitForChild('Events')
local Functions = Events:WaitForChild('Functions') -- Not in use
local RemoteEvents = Events:WaitForChild('Remotes') -- Not in use

------------------------------------------------------------------

-- [[ Modules ]]
local PRINT_UTILITY = require(Utilities:WaitForChild('PRINT_UTILITY')).new(RunService)
local GetObjectPropertyUtility = require(Utilities:WaitForChild('GetObjectProperty'))

local _TEMPLATE = require(script:WaitForChild('_TEMPLATE')).new(PRINT_UTILITY) -- Template

------------------------------------------------------------------

-- [[ Program ]]
PRINT_UTILITY:OnRootLoaded(START_TICK)