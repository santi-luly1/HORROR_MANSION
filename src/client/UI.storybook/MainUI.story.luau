-- UI.story.luau finalmente, mira lo que logr'e luego de modificar 213 archivos, y como 5 horas de estar aqu'i
return function(Target)
	local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")

	local Fusion = require(Packages:WaitForChild("fusion"))
	local OnyxUI = require(Packages:WaitForChild("onyx-ui"))
	local Themer = OnyxUI.Themer

	local scope = Fusion.scoped(Fusion)

	-- optional theme toggle
	local useLight = scope:Value(false)
	local activeTheme = scope:Computed(function(use)
		return use(useLight) and Themer.NewTheme(scope, {}) -- empty = default light
			or Themer.Theme:now() -- default dark
	end)

	-- mount the real module under the chosen theme
	Themer.Theme:is(activeTheme):during(function()
		local UI = require(script.Parent.Parent.UI)
		UI:Init()
		local ui = UI:Start()
		for _, child in ipairs(ui:GetChildren()) do
			child.Parent = Target
		end
		ui:Destroy() -- we do not need the ScreenGui any more
		return function()
			ui:Destroy()
		end
	end)

	-- quick toggle button (optional)
	scope:New "TextButton" {
		Parent = Target,
		Size = UDim2.fromOffset(80, 24),
		Text = "Toggle theme",
		[Fusion.OnEvent "Activated"] = function()
			useLight:set(not Fusion.peek(useLight))
		end,
	}

	return function()
		Target:Destroy()
	end
end
