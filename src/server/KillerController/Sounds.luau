export type SOUNDS = {
	[string]: {
		Kill: { number? },
	},
}

local SOUNDS = {
	["Killer"] = {
		Kill = { 139771888058836 },
	},
} :: SOUNDS

return setmetatable(SOUNDS, {
	__index = function()
		return { --dummy
			Kill = {},
		}
	end,
}) :: SOUNDS
