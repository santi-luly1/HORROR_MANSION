--[=[
    Networking for the PlayerDataHandler module.
	@class PlayerDataNetwork
    @author: santi-luly1

    CHANGELOG: [
		12/31/25 --> Added SurvivalsChanged and PointsChanged items.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Net = require(Packages.net)

return {
	SurvivalsChanged = Net:RemoteEvent("SurvivalsChanged"),
	PointsChanged = Net:RemoteEvent("PointsChanged"),
}
