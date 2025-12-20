--[=[
	@class HORROR_MANSIONService
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local HORROR_MANSIONService = {}
HORROR_MANSIONService.ServiceName = "HORROR_MANSIONService"
---@diagnostic disable-next-line: undefined-type
function HORROR_MANSIONService:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrService"))

	-- Internal
	self._serviceBag:GetService(require("HORROR_MANSIONTranslator"))
end

return HORROR_MANSIONService
