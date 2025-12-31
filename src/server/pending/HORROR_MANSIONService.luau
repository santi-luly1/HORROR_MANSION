--[=[
	@class HORROR_MANSIONService
]=]

local Types = require(script.Parent._Types)
local require = (require :: any)(script.Parent.loader).load(script)

local HORROR_MANSIONService = {}
HORROR_MANSIONService.ServiceName = "HORROR_MANSIONService"
function HORROR_MANSIONService:Init(serviceBag: Types.ServiceBag)
	assert(not self._serviceBag, "Already initialized")
	self._serviceBag = assert(serviceBag, "No serviceBag")

	-- External
	self._serviceBag:GetService(require("CmdrService"))

	-- Internal
	self._serviceBag:GetService(require("HORROR_MANSIONTranslator"))
end

return HORROR_MANSIONService
