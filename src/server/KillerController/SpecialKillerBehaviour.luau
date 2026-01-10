--!strict
-- TODO: maybe finish this?
-- local AI = require(script.Parent.AI)

-- local Util = {} -- shared helpers ------------------------------------------------
-- function Util.defaultLoop(model: Model, maid: any, computeMod: ((model: Model, maid: any) -> boolean)?)
-- 	computeMod = (computeMod or AI.Compute) :: (model: Model, maid: any) -> boolean
-- 	local running = true
-- 	maid:GiveTask(function()
-- 		running = false
-- 	end)

-- 	task.spawn(function()
-- 		while running and model.Parent do
-- 			local ok = computeMod(model, maid) -- LLS SHUT UPPPPPPPPPPPPP
-- 			task.wait(ok and 0.5 or 1)
-- 		end
-- 	end)
-- end

-- Util.killers = {
-- 	["MagnetKiller"] = function(model: Model, maid: any)
-- 		Util.defaultLoop(model, maid)

-- 		local root = model:FindFirstChild("HumanoidRootPart") :: Part
-- 		local pulse = game:GetService("RunService").Heartbeat:Connect(function()
-- 			for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
-- 				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
-- 				if hrp then
-- 					local dir = (root.Position - hrp.Position).Unit
-- 					hrp.AssemblyLinearVelocity += dir * 7.5
-- 				end
-- 			end
-- 		end)
-- 		maid:GiveTask(pulse)
-- 	end,
-- } :: { [string]: (model: Model, maid: any) -> () }

-- return Util
return nil