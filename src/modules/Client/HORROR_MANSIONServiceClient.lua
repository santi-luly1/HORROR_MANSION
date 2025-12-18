--[=[
	@class HORROR_MANSIONServiceClient
]=]

local require = require(script.Parent.loader).load(script)

local ServiceBag = require("ServiceBag")

local HORROR_MANSIONServiceClient = {}
HORROR_MANSIONServiceClient.ServiceName = "HORROR_MANSIONServiceClient"

function HORROR_MANSIONServiceClient:Init(serviceBag: ServiceBag.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrServiceClient"))

	-- Internal
	self._serviceBag:GetService(require("HORROR_MANSIONTranslator"))
end

return HORROR_MANSIONServiceClient