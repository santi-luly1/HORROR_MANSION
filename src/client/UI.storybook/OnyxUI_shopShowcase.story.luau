-- UI.story.luau
return function(Target)
	local Packages = game:GetService("ReplicatedStorage"):WaitForChild("Packages")

	local Fusion = require(Packages:WaitForChild("fusion"))
	local OnyxUI = require(Packages:WaitForChild("onyx-ui"))

	-- Get components
	local Components = OnyxUI.Components
	local Util = OnyxUI.Util
	local Children = Fusion.Children
	local Scope = Fusion.scoped(Fusion, Components)

	-- Shop state - using proper reactive values
	local coinBalance = Scope:Value(1000)
	local selectedItem = Scope:Value("None")
	local notificationText = Scope:Value("")
	local mainFrameVisibility = Scope:Value(true)
	-- Item data
	local shopItems = {
		{
			name = "Steel Sword",
			description = "A basic but reliable weapon",
			cost = 250,
			icon = "rbxassetid://10709683343",
			category = "Weapons",
		},
		{
			name = "Health Potion",
			description = "Restores 50 HP instantly",
			cost = 100,
			icon = "rbxassetid://10709683344",
			category = "Consumables",
		},
		{
			name = "Iron Shield",
			description = "Blocks 25% damage",
			cost = 400,
			icon = "rbxassetid://10709683345",
			category = "Armor",
		},
	}

	-- Main shop frame
	local mainFrame = Scope:Frame {
		Parent = Target,
		Size = UDim2.fromOffset(400, 500),
		Position = UDim2.new(0.5, -200, 0.5, -250),
		BackgroundColor3 = Color3.fromRGB(35, 35, 35),
		Visible = mainFrameVisibility,
		BackgroundTransparency = 0,
		[Children] = {
			Scope:TitleBar { -- Title bar
				Content = { "🏪 Item Shop" },
				Size = UDim2.new(1, 0, 0, 40),
			},
			Scope:Text { -- Simple balance display - FIXED: Combined into single text
				Position = UDim2.new(0.5, 0, 0, 50),
				AnchorPoint = Vector2.new(0.5, 0),
				Text = Scope:Computed(function(Use)
					local balance = Use(coinBalance)
					return "💰 Balance: " .. tostring(balance) .. " coins"
				end),
				Font = Enum.Font.SourceSansBold,
				TextSize = 16,
				Color = Util.Colors.Green["500"],
			},
			Scope:Text { -- Selected item - FIXED: Simple and visible
				Position = UDim2.new(0.5, 0, 1, -40),
				AnchorPoint = Vector2.new(0.5, 0),
				Text = Scope:Computed(function(Use)
					local item = Use(selectedItem)
					local notification = Use(notificationText)
					if notification ~= "" then
						return notification
					elseif item ~= "None" then
						return "Selected: " .. item
					else
						return "Select an item to purchase"
					end
				end),
				Font = Enum.Font.SourceSans,
				TextSize = 14,
				Color = Scope:Computed(function(Use)
					local notification = Use(notificationText)
					return notification ~= "" and Util.Colors.Yellow["500"] or Util.Colors.White
				end),
			},
			Scope:IconButton { -- Close button - FIXED: Simple and reliable
				Position = UDim2.new(1, -35, 0, 5),
				Size = UDim2.fromOffset(30, 30),
				Image = "rbxassetid://10709683348", -- Close icon
				Color = Util.Colors.Red["500"],
				OnActivated = function()
					mainFrameVisibility:set(false)
					print("Shop closed!")
				end,
			},
		},
	}

	-- Items container - FIXED: Simple positioning
	local itemsContainer = Scope:Frame {
		Parent = mainFrame,
		Size = UDim2.new(1, -20, 1, -140),
		Position = UDim2.fromOffset(10, 100),
		BackgroundTransparency = 0.1,
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
	}

	-- Create shop items - FIXED: Simple and reliable
	for i, item in ipairs(shopItems) do
		local yPos = 10 + (i - 1) * 90

		Scope:Frame { -- Item background
			Parent = itemsContainer,
			Size = UDim2.new(1, 0, 0, 80),
			Position = UDim2.fromOffset(0, yPos),
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			BackgroundTransparency = 0.2,
			[Children] = {
				Scope:Avatar { -- Item icon
					Position = UDim2.new(0, 10, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.fromOffset(60, 60),
					Image = item.icon,
					CornerRadius = UDim.new(0, 8),
				},
				Scope:Text { -- Item name
					Position = UDim2.fromOffset(80, 10),
					Text = item.name,
					Font = Enum.Font.SourceSansBold,
					TextSize = 16,
					Color = Util.Colors.Blue["400"],
				},
				Scope:Text { -- Item description
					Position = UDim2.fromOffset(80, 35),
					Text = item.description,
					Font = Enum.Font.SourceSans,
					TextSize = 12,
					TextColor3 = Color3.fromRGB(170, 170, 170),
				},
				Scope:Button { -- Buy button - FIXED: Simple and direct
					Position = UDim2.new(1, -90, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.fromOffset(80, 30),
					Content = { tostring(item.cost) .. " coins" },
					Color = Util.Colors.Green["500"],
					OnActivated = function()
						local currentBalance = Fusion.peek(coinBalance)

						if currentBalance >= item.cost then
							coinBalance:set(currentBalance - item.cost)
							selectedItem:set(item.name)
							notificationText:set("Purchased " .. item.name .. "!")
							print("Purchased " .. item.name)
						else
							notificationText:set("Not enough coins!")
							print("Not enough coins!")
						end
					end,
				},
			},
		}
	end

	local CountThread = task.spawn(function()
		--while true do
		task.wait(5)
		coinBalance:set(Fusion.peek(coinBalance) + 50)
		print("Added 50 coins! New balance:", Fusion.peek(coinBalance))
		--end
	end)

	Scope:innerScope({
		function()
			task.cancel(CountThread)
		end,
	})

	return function()
		Target:Destroy()
	end
end
