--The only objetive for this is to reexport the types for LLS

local ProfileStore = require(script.Parent._Index["vyon_profilestore@1.0.3"]["profilestore"])

--------------------------------------------------------------------
--- Types reexport (LLS wasn't happy)
--------------------------------------------------------------------
export type ProfileStore<T> = ProfileStore.ProfileStore<T>
export type Profile<T> = ProfileStore.Profile<T>
export type JSONAcceptable = ProfileStore.JSONAcceptable
export type VersionQuery<T> = ProfileStore.VersionQuery<T>
export type ProfileStoreModule = ProfileStore.ProfileStoreModule

return ProfileStore