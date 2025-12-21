--Made By:Palle1--
local head = script.Parent
local sound = head:findFirstChild("Luagh") --The name of the sound in the brick. Be aware of any changes.

function onTouched(part)
	local h = part.Parent:findFirstChild("Humanoid")
	if h~=nil then
		sound:play()
	end
end

script.Parent.Touched:connect(onTouched)

--This works great for scary places, adding scream sounds when a humanoi passes trough a zone--