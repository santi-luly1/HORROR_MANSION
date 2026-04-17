--!strict

export type BehaviorModule = {
	OnMapLoaded: (self: BehaviorModule, mapModel: Model, maid: any) -> (),
}

local Default = {} :: BehaviorModule

function Default:OnMapLoaded(_mapModel: Model, _maid)
	-- default no-op
end

return Default
