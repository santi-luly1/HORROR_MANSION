--The only objetive for this is to reexport the types for LLS

local Maid = require(script.Parent._Index["devsparkle_maid@2.1.0"]["maid"])

--------------------------------------------------------------------
--- Types reexport (LLS wasn't happy)
--------------------------------------------------------------------
export type Maid = Maid.Maid
export type MaidTask = Maid.MaidTask

return Maid