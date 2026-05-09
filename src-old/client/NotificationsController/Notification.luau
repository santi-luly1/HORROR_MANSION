--!strict
--https://devforum.roblox.com/t/reactive-and-modern-notification-system/4460923
-- Modified module from devforum to implement typechecking
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Fusion = require("@game/ReplicatedStorage/Packages/fusion")
local Signal = require("@game/ReplicatedStorage/Packages/signal")

local scoped = Fusion.scoped
local Children = Fusion.Children

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NOTIF_WIDTH = 320
local NOTIF_HEIGHT = 60
local OPTIONS_HEIGHT = 46
local TEXT_SIZE = 14
local OPTION_TEXT_SIZE = 12
local notifCount = 0

local BAR_COLOR_FULL = Color3.fromRGB(255, 255, 255)
local BAR_COLOR_EMPTY = Color3.fromRGB(255, 60, 60)

type opt = { Text: string }
type props = { -- string: type, -- defaultValue
	Type: "String"? | "Viewport"?, -- "Viewport"
	Content: string | Instance, -- Model
	Style: string?, -- "Modern"
	Duration: number?, -- 3
	ShowProgress: boolean?, -- true
	Persistent: boolean?, -- false
	Icon: string?, -- nil
	SeparatorColor: Color3?, -- white
	Option1: opt?, -- nil
	Option2: opt?, -- nil
	ViewportDistance: number?, -- 2.2
	ViewportHeight: number?, -- 1.4
	ViewportSpeed: number?, -- 0.8
}
type validPositionPresets = "BottomCenter" | "BottomRight" | "BottomLeft" | "TopCenter" | "TopRight" | "TopLeft"
type posPresets = { [validPositionPresets]: { anchor: Vector2, position: UDim2, listAlign: Enum.VerticalAlignment } }
type signals = {
	OnDismissed: Signal.Signal<()>,
	OnOption1: Signal.Signal<()>,
	OnOption2: Signal.Signal<()>,
}

local PositionPresets: posPresets = {
	BottomCenter = {
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, -50),
		listAlign = Enum.VerticalAlignment.Bottom,
	},
	BottomRight = {
		anchor = Vector2.new(1, 1),
		position = UDim2.new(1, -20, 1, -50),
		listAlign = Enum.VerticalAlignment.Bottom,
	},
	BottomLeft = {
		anchor = Vector2.new(0, 1),
		position = UDim2.new(0, 20, 1, -50),
		listAlign = Enum.VerticalAlignment.Bottom,
	},
	TopCenter = {
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 50),
		listAlign = Enum.VerticalAlignment.Top,
	},
	TopRight = {
		anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -20, 0, 50),
		listAlign = Enum.VerticalAlignment.Top,
	},
	TopLeft = {
		anchor = Vector2.new(0, 0),
		position = UDim2.fromOffset(20, 50),
		listAlign = Enum.VerticalAlignment.Top,
	},
}

local Styles = {
	Modern = {
		bgColor = Color3.fromRGB(14, 14, 18),
		bgAlpha = 0.08,
		cornerRadius = UDim.new(0, 10),
		hasSeparators = true,
		separatorAlpha = 0.18,
		hasTopShine = true,
		hasShadow = true,
		shadowAlpha = 0.52,
		hasGradientEdge = true,
		hasBottomLine = false,
		hasLeftBar = false,
		textColor = Color3.fromRGB(240, 240, 245),
		optionBgColor = Color3.fromRGB(255, 255, 255),
		optionBgAlpha = 0.06,
		optionTextColor = Color3.fromRGB(240, 240, 245),
	},
	Minimal = {
		bgColor = Color3.fromRGB(10, 10, 10),
		bgAlpha = 0.22,
		cornerRadius = UDim.new(0, 6),
		hasSeparators = false,
		separatorAlpha = 0,
		hasTopShine = false,
		hasShadow = false,
		shadowAlpha = 0,
		hasGradientEdge = false,
		hasBottomLine = true,
		hasLeftBar = false,
		textColor = Color3.fromRGB(195, 195, 195),
		optionBgColor = Color3.fromRGB(255, 255, 255),
		optionBgAlpha = 0.06,
		optionTextColor = Color3.fromRGB(195, 195, 195),
	},
	Bold = {
		bgColor = Color3.fromRGB(16, 16, 20),
		bgAlpha = 0.04,
		cornerRadius = UDim.new(0, 8),
		hasSeparators = false,
		separatorAlpha = 0,
		hasTopShine = false,
		hasShadow = true,
		shadowAlpha = 0.48,
		hasGradientEdge = true,
		hasBottomLine = false,
		hasLeftBar = true,
		textColor = Color3.fromRGB(255, 255, 255),
		optionBgColor = Color3.fromRGB(255, 255, 255),
		optionBgAlpha = 0.06,
		optionTextColor = Color3.fromRGB(255, 255, 255),
	},
	Classic = {
		bgColor = Color3.fromRGB(28, 20, 12),
		bgAlpha = 0.06,
		cornerRadius = UDim.new(0, 12),
		hasSeparators = true,
		separatorAlpha = 0.15,
		hasTopShine = true,
		hasShadow = true,
		shadowAlpha = 0.58,
		hasGradientEdge = true,
		hasBottomLine = false,
		hasLeftBar = false,
		textColor = Color3.fromRGB(255, 238, 195),
		optionBgColor = Color3.fromRGB(200, 160, 80),
		optionBgAlpha = 0.06,
		optionTextColor = Color3.fromRGB(255, 238, 195),
	},
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationsGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local container = Instance.new("Frame")
container.Name = "NotificationContainer"
container.AnchorPoint = Vector2.new(0.5, 1)
container.Position = UDim2.new(0.5, 0, 1, -50)
container.Size = UDim2.fromOffset(NOTIF_WIDTH + 20, 600)
container.BackgroundTransparency = 1
container.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Vertical
listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 5)
listLayout.Parent = container

local Notification = {}

function Notification.setPosition(presetName: validPositionPresets): ()
	local preset = PositionPresets[presetName]
	if not preset then
		warn("[Notification] Unknown position preset: " .. tostring(presetName))
		return
	end
	container.AnchorPoint = preset.anchor
	container.Position = preset.position
	listLayout.VerticalAlignment = preset.listAlign
end

function Notification.create(props: props): signals
	assert(type(props) == "table", "[Notification] Expected a props table, got " .. type(props))

	local hasOptions = props.Option1 ~= nil or props.Option2 ~= nil
	local isPersistent = props.Persistent == true or hasOptions
	local duration = math.max(props.Duration or 3.0, 0.5)
	local showProgress = not isPersistent and props.ShowProgress ~= false
	local style = Styles[props.Style] or Styles.Modern
	local separatorColor = props.SeparatorColor or Color3.fromRGB(255, 255, 255)
	local contentType = props.Type or "String"
	local totalHeight = NOTIF_HEIGHT + (hasOptions and OPTIONS_HEIGHT or 0)

	local scope = scoped(Fusion)
	local transparency = scope:Value(1)
	local slideY = scope:Value(NOTIF_HEIGHT * 0.6)
	local progressWidth = scope:Value(1)

	local barColorTarget = scope:Value(BAR_COLOR_FULL)
	local barColorSpring = scope:Spring(barColorTarget, 6, 1)

	local sT = scope:Spring(transparency, 24, 0.86)
	local sY = scope:Spring(slideY, 24, 0.82)

	local signals: signals = {
		OnOption1 = Signal.new(),
		OnOption2 = Signal.new(),
		OnDismissed = Signal.new(),
	}

	local dismissed = false
	local hovered = false

	local function dismiss()
		if dismissed then
			return
		end
		dismissed = true
		progressWidth:set(0)
		transparency:set(1)
		task.wait(1.0)
		signals.OnDismissed:Fire()
		Fusion.doCleanup(scope)
	end

	task.spawn(function()
		transparency:set(0)
		slideY:set(0)
		if isPersistent then
			return
		end

		if showProgress then
			task.wait(0.12)
			local elapsed = 0
			local d = duration - 0.12

			while elapsed < d do
				if dismissed then
					return
				end

				if hovered then
					task.wait(0.05)
					continue
				end

				local dt = 0.05
				elapsed += dt
				local remaining = math.max(1 - (elapsed / d), 0)
				progressWidth:set(remaining)
				barColorTarget:set(BAR_COLOR_FULL:Lerp(BAR_COLOR_EMPTY, 1 - remaining))

				task.wait(dt)
			end

			progressWidth:set(0)
		else
			local elapsed = 0
			while elapsed < duration do
				if dismissed then
					return
				end
				if not hovered then
					elapsed += 0.05
				end
				task.wait(0.05)
			end
		end

		dismiss()
	end)

	local function fadeAlpha(base: number, range: number)
		return scope:Computed(function(use)
			return base + use(sT) * range
		end)
	end

	local fadeSeparator = style.hasSeparators and fadeAlpha(style.separatorAlpha, 1 - style.separatorAlpha)
	local fadeOptionBg = hasOptions and fadeAlpha(style.optionBgAlpha, 1 - style.optionBgAlpha)

	local contentChildren = {}

	if props.Icon then
		table.insert(
			contentChildren,
			scope:New "ImageLabel" {
				Name = "Icon",
				Size = UDim2.fromOffset(20, 20),
				BackgroundTransparency = 1,
				Image = props.Icon,
				ImageColor3 = style.textColor,
				ImageTransparency = sT,
				ZIndex = 3,
			}
		)
	end

	if contentType == "String" then
		table.insert(
			contentChildren,
			scope:New "TextLabel" {
				Name = "TextContent",
				Size = UDim2.new(1, props.Icon and -44 or -32, 1, 0),
				BackgroundTransparency = 1,
				Text = tostring(props.Content or ""),
				TextColor3 = style.textColor,
				FontFace = Font.fromEnum(Enum.Font.GothamMedium),
				TextSize = TEXT_SIZE,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true,
				RichText = true,
				TextTransparency = sT,
				ZIndex = 3,
			}
		)
	elseif contentType == "Viewport" then
		if not props.Content then
			warn("[Notification] Viewport type requires a Content model")
			return signals
		end

		local model = (props.Content :: Model):Clone()
		local pivot = model:GetPivot().Position
		local distance = props.ViewportDistance or 2.2
		local vHeight = props.ViewportHeight or 1.4
		local speed = props.ViewportSpeed or 0.8
		local angle = 0

		local camera: any = Instance.new("Camera")
		camera.CFrame = CFrame.new(pivot + Vector3.new(distance, vHeight, distance), pivot)

		local conn = RunService.RenderStepped:Connect(function(dt: number)
			angle += dt * speed
			camera.CFrame =
				CFrame.new(pivot + Vector3.new(math.cos(angle) * distance, vHeight, math.sin(angle) * distance), pivot)
		end)
		table.insert(scope, conn)

		table.insert(
			contentChildren,
			scope:New "ViewportFrame" {
				Name = "ViewportContent",
				Size = UDim2.fromOffset(46, 46),
				BackgroundTransparency = 1,
				ImageTransparency = sT,
				CurrentCamera = camera,
				ZIndex = 3,
				[Children] = { model, camera },
			}
		)
	else
		warn("[Notification] Unknown Type '" .. tostring(contentType) .. "'")
	end

	notifCount += 1

	local bgChildren = {
		scope:New "UICorner" { CornerRadius = style.cornerRadius },
	}

	if style.hasGradientEdge then
		table.insert(
			bgChildren,
			scope:New "UIGradient" {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.80),
					NumberSequenceKeypoint.new(0.07, 0),
					NumberSequenceKeypoint.new(0.93, 0),
					NumberSequenceKeypoint.new(1, 0.80),
				}),
			}
		)
	end

	if style.hasTopShine then
		table.insert(
			bgChildren,
			scope:New "Frame" {
				Name = "TopShine",
				Size = UDim2.new(0.5, 0, 0, 1),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = fadeAlpha(0.62, 0.38),
				ZIndex = 3,
				[Children] = {
					scope:New "UIGradient" {
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.5, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					},
				},
			}
		)
	end

	if style.hasSeparators then
		local sepSeq = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.28, 0),
			NumberSequenceKeypoint.new(0.72, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		table.insert(
			bgChildren,
			scope:New "Frame" {
				Name = "SeparatorTop",
				Size = UDim2.new(0.62, 0, 0, 1),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				BackgroundColor3 = separatorColor,
				BackgroundTransparency = fadeSeparator,
				ZIndex = 2,
				[Children] = { scope:New "UIGradient" { Transparency = sepSeq } },
			}
		)
		table.insert(
			bgChildren,
			scope:New "Frame" {
				Name = "SeparatorBottom",
				Size = UDim2.new(0.62, 0, 0, 1),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundColor3 = separatorColor,
				BackgroundTransparency = fadeSeparator,
				ZIndex = 2,
				[Children] = { scope:New "UIGradient" { Transparency = sepSeq } },
			}
		)
	end

	if style.hasBottomLine then
		table.insert(
			bgChildren,
			scope:New "Frame" {
				Name = "BottomLine",
				Size = UDim2.new(0.55, 0, 0, 1),
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				BackgroundColor3 = separatorColor,
				BackgroundTransparency = fadeAlpha(0.28, 0.72),
				ZIndex = 3,
				[Children] = {
					scope:New "UIGradient" {
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.4, 0),
							NumberSequenceKeypoint.new(0.6, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					},
				},
			}
		)
	end

	if style.hasLeftBar then
		table.insert(
			bgChildren,
			scope:New "Frame" {
				Name = "LeftBar",
				Size = UDim2.new(0, 3, 0.62, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				BackgroundColor3 = separatorColor,
				BackgroundTransparency = fadeAlpha(0, 1),
				ZIndex = 3,
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 2) },
					scope:New "UIGradient" {
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 0.5),
							NumberSequenceKeypoint.new(0.5, 0),
							NumberSequenceKeypoint.new(1, 0.5),
						}),
						Rotation = 90,
					},
				},
			}
		)
	end

	if showProgress then
		table.insert(
			bgChildren,
			scope:New "Frame" {
				Name = "ProgressBar",
				Size = scope:Computed(function(use)
					return UDim2.new(use(progressWidth), -6, 0, 2)
				end),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 3, 1, -1),
				BackgroundColor3 = barColorSpring,
				BackgroundTransparency = fadeAlpha(0.1, 0.9),
				BorderSizePixel = 0,
				ZIndex = 4,
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 1) },
				},
			}
		)
	end

	local decorChildren = {}

	if style.hasShadow then
		table.insert(
			decorChildren,
			scope:New "Frame" {
				Name = "Shadow",
				Size = UDim2.new(1, 18, 1, 14),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = fadeAlpha(style.shadowAlpha, 1 - style.shadowAlpha),
				ZIndex = 0,
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 14) },
					scope:New "UIGradient" {
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.14, 0.5),
							NumberSequenceKeypoint.new(0.5, 0.22),
							NumberSequenceKeypoint.new(0.86, 0.5),
							NumberSequenceKeypoint.new(1, 1),
						}),
					},
				},
			}
		)
	end

	table.insert(
		decorChildren,
		scope:New "Frame" {
			Name = "Background",
			Size = UDim2.new(1, -2, 0, NOTIF_HEIGHT),
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			BackgroundColor3 = style.bgColor,
			BackgroundTransparency = fadeAlpha(style.bgAlpha, 1 - style.bgAlpha),
			ZIndex = 1,
			[Children] = bgChildren,
		}
	)

	table.insert(
		decorChildren,
		scope:New "Frame" {
			Name = "ContentLayer",
			Size = UDim2.new(1, 0, 0, NOTIF_HEIGHT),
			Position = UDim2.fromScale(0, 0),
			BackgroundTransparency = 1,
			ZIndex = 3,
			[Children] = {
				scope:New "UIListLayout" {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 8),
				},
				table.unpack(contentChildren),
			},
		}
	)

	if hasOptions then
		local hasBoth = props.Option1 ~= nil and props.Option2 ~= nil
		local optionButtons = {}

		local function makeOptionButton(optData: opt?, optSignal)
			if not optData then
				return
			end
			local btn = scope:New "TextButton" {
				Name = "OptionButton",
				Size = UDim2.new(hasBoth and 0.44 or 0.65, 0, 0, 28),
				BackgroundColor3 = style.optionBgColor,
				BackgroundTransparency = fadeOptionBg,
				Text = optData.Text or "OK",
				TextColor3 = style.optionTextColor,
				TextTransparency = sT,
				FontFace = Font.fromEnum(Enum.Font.GothamBold),
				TextSize = OPTION_TEXT_SIZE,
				ZIndex = 4,
				[Children] = {
					scope:New "UICorner" { CornerRadius = UDim.new(0, 6) },
				},
			} :: TextButton
			btn.MouseButton1Click:Connect(function()
				optSignal:Fire(optData)
				task.spawn(dismiss)
			end)
			table.insert(optionButtons, btn)
		end

		makeOptionButton(props.Option1, signals.OnOption1)
		makeOptionButton(props.Option2, signals.OnOption2)

		table.insert(
			decorChildren,
			scope:New "Frame" {
				Name = "OptionsDivider",
				Size = UDim2.new(0.7, 0, 0, 1),
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromOffset(NOTIF_WIDTH / 2, NOTIF_HEIGHT),
				BackgroundColor3 = separatorColor,
				BackgroundTransparency = fadeAlpha(0.55, 0.45),
				ZIndex = 2,
				[Children] = {
					scope:New "UIGradient" {
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 1),
							NumberSequenceKeypoint.new(0.3, 0),
							NumberSequenceKeypoint.new(0.7, 0),
							NumberSequenceKeypoint.new(1, 1),
						}),
					},
				},
			}
		)

		table.insert(
			decorChildren,
			scope:New "Frame" {
				Name = "OptionsLayer",
				Size = UDim2.new(1, 0, 0, OPTIONS_HEIGHT),
				Position = UDim2.fromOffset(0, NOTIF_HEIGHT),
				BackgroundTransparency = 1,
				ZIndex = 3,
				[Children] = {
					scope:New "UIListLayout" {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						Padding = UDim.new(0, 8),
					},
					table.unpack(optionButtons),
				},
			}
		)
	end

	local notifFrame = scope:New "Frame" {
		Name = "NotificationItem",
		Size = UDim2.fromOffset(NOTIF_WIDTH, totalHeight),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		LayoutOrder = notifCount,
		ZIndex = 1,
		[Children] = {
			scope:New "Frame" {
				Name = "AnimatedContent",
				Size = UDim2.fromOffset(NOTIF_WIDTH, totalHeight),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = scope:Computed(function(use)
					return UDim2.new(0.5, 0, 0.5, use(sY))
				end),
				BackgroundTransparency = 1,
				ZIndex = 1,
				[Children] = decorChildren,
			},
		},
	} :: Frame

	if not isPersistent then
		notifFrame.MouseEnter:Connect(function()
			hovered = true
		end)
		notifFrame.MouseLeave:Connect(function()
			hovered = false
		end)
	end

	notifFrame.Parent = container
	return signals
end

return Notification
