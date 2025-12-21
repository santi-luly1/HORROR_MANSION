local START_TICK = tick()
------------------------------------------------------------------

-- [[ Main ]]
local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local StarterGui = game.StarterGui

--local CoreUI = PlayerGui:WaitForChild('Core')
--local UI = PlayerGui:WaitForChild('UI')

------------------------------------------------------------------

-- [[ Services ]]
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local MarketPlaceService = game:GetService('MarketplaceService')
local TweenService = game:GetService('TweenService')
local SoundService = game:GetService('SoundService')
local ContentProvider = game:GetService('ContentProvider')
local CollectionService = game:GetService('CollectionService')
local UserInputService = game:GetService('UserInputService')

------------------------------------------------------------------

local DefaultFrameEvent = RunService.RenderStepped
local CurrentPlaceId = game.PlaceId
local CurrentPlaceVersion = game.PlaceVersion

------------------------------------------------------------------

--  [[ Folders ]]
local Utilities = ReplicatedStorage:WaitForChild('Utility')

local Events = ReplicatedStorage:WaitForChild('Events')
local Functions = Events:WaitForChild('Functions')
local RemoteEvents = Events:WaitForChild('Remotes')

------------------------------------------------------------------

-- [[ Modules ]]
local PRINT_UTILITY = require(Utilities:WaitForChild('PRINT_UTILITY')).new(RunService)
local GetObjectPropertyUtility = require(Utilities:WaitForChild('GetObjectProperty'))

local _TEMPLATE = require(script:WaitForChild('_TEMPLATE')).new(PRINT_UTILITY) --Template

local RobloxCoreGui = require(script:WaitForChild('CoreGui')).new(StarterGui, PRINT_UTILITY)

------------------------------------------------------------------

-- [[ Program ]]
PRINT_UTILITY:OnRootLoaded(START_TICK)