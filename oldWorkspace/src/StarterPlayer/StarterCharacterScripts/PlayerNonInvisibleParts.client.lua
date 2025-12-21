local Player = game.Players.LocalPlayer
local NonTransparencyParts = {"Left Arm"; "Right Arm"; }

repeat wait() until Player.Character

while wait() do
	for _, CharacterParts in pairs(script.Parent:GetChildren()) do
		for _, a in pairs(NonTransparencyParts) do
			if CharacterParts.Name == a then
				CharacterParts.LocalTransparencyModifier = CharacterParts.Transparency
			end
		end
	end
end