--[=[
    Networking for the PlayerDataService module.
	@class PlayerDataNetwork
    @author: santi-luly1

    CHANGELOG: [
		12/31/25 --> Added SurvivalsChanged and PointsChanged items.
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Net = require("@packages/net")

return {
	SurvivalsChanged = Net:RemoteEvent("SurvivalsChanged"),
	PointsChanged = Net:RemoteEvent("PointsChanged"),
}
