-- scripts/transform_to_build.lua
local TIMEOUT = 30

local function read(p)
	local f = io.open(p, "r")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end
local function mkdirp(d)
	if package.config:sub(1, 1) == "\\" then
		os.execute('mkdir "' .. d .. '" >NUL 2>&1')
	else
		os.execute('mkdir -p "' .. d .. '"')
	end
end
local function write(p, s)
	local dir = p:match("^(.*)[/\\]")
	if dir then
		mkdirp(dir)
	end
	local f, err = io.open(p, "w")
	if not f then
		error(err)
	end
	f:write(s)
	f:close()
end

-- load .luaurc aliases (fallback to provided mapping if missing)
local cfg = read(".luaurc") or ""
local aliases = {}
for k, v in cfg:gmatch('"([%w_%-]+)"%s*:%s*"(.-)"') do
	aliases["@" .. k] = v:gsub("^%./", "")
end
-- merge explicit helpful aliases (won't overwrite existing)
local explicit = {
	["@src"] = "./src",
	["@client"] = "@src/client",
	["@server"] = "@src/server",
	["@shared"] = "@src/shared",
	["@network"] = "@src/network",
	["@packages"] = "./Packages",
	["@serverPackages"] = "./ServerPackages",
	["@serverTypes"] = "@server/Types",
	["@clientTypes"] = "@client/Types",
}
for k, v in pairs(explicit) do
	if not aliases[k] then
		aliases[k] = v
	end
end
if next(aliases) == nil then
	error("no aliases available (check .luaurc)")
end

local function service_for_alias(a)
	-- default mapping for simple aliases (kept for backward compatibility)
	if a == "@serverPackages" then
		return "ServerStorage"
	end
	if a:lower():find("server") then
		return "ServerScriptService"
	end
	return "ReplicatedStorage"
end

local function expand_alias_target(target)
	local t = target:gsub("^@", ""):gsub("^%./", "")
	local lead = t:match("^([%w_%-]+)[/\\]?")
	if lead and aliases["@" .. lead] then
		local resolved = aliases["@" .. lead]:gsub("^@", ""):gsub("^%./", "")
		local rest = t:sub(#lead + 2)
		if rest and #rest > 0 then
			return resolved .. "/" .. rest
		end
		return resolved
	end
	return t
end

local function split_parts(path)
	local parts = {}
	for p in path:gmatch("[^/\\]+") do
		parts[#parts + 1] = p
	end
	return parts
end

local function to_waitfor_chain(svc, parts)
	-- convert leading "src" to "build_src" for local-only build copies
	if parts[1] == "src" then
		parts[1] = "build_src"
	end

	-- special-case StarterPlayer: use GetService("StarterPlayer") then WaitForChild("StarterPlayerScripts")...
	local cur
	if svc == "StarterPlayer" then
		cur = 'game:GetService("StarterPlayer")'
	else
		cur = 'game:GetService("' .. svc .. '")'
	end

	for _, p in ipairs(parts) do
		cur = cur .. ':WaitForChild("' .. p .. '", ' .. tostring(TIMEOUT) .. ")"
	end
	return cur
end

local function resolve_require_path(p)
	for alias, target in pairs(aliases) do
		if p:sub(1, #alias) == alias then
			local tail = p:sub(#alias + 1):gsub("^/", ""):gsub("%.luau$", ""):gsub("%.lua$", "")
			local target_clean = expand_alias_target(target) -- e.g. "src/client" or "Packages"
			local combined = target_clean
			if tail ~= "" then
				combined = combined .. "/" .. tail
			end
			local parts = split_parts(combined)

			-- Normalize and map filesystem parts to Rojo/Roblox tree
			local svc = "ReplicatedStorage"

			-- ServerPackages -> ServerStorage/ServerPackages (must come first)
			if parts[1] and parts[1]:lower() == "serverpackages" then
				svc = "ServerStorage"
			-- Packages -> ReplicatedStorage/Packages
			elseif parts[1] and parts[1]:lower() == "packages" then
				svc = "ReplicatedStorage"
			-- src/server -> ServerScriptService/Server/...
			elseif parts[1] and parts[1]:lower() == "src" and parts[2] and parts[2]:lower() == "server" then
				svc = "ServerScriptService"
				table.remove(parts, 1)
				if parts[1]:lower() ~= "server" then
					table.insert(parts, 1, "Server")
				end
			-- src/client -> StarterPlayer/StarterPlayerScripts/Client/...
			elseif parts[1] and parts[1]:lower() == "src" and parts[2] and parts[2]:lower() == "client" then
				svc = "StarterPlayer"
				table.remove(parts, 1)
				if parts[1]:lower() == "client" then
					parts = { "StarterPlayerScripts", "Client", table.unpack(parts, 2) }
				else
					parts = { "StarterPlayerScripts", "Client", table.unpack(parts) }
				end
			-- src/shared or src/network -> ReplicatedStorage/Shared or ReplicatedStorage/Network
			elseif parts[1] and parts[1]:lower() == "src" and parts[2] then
				table.remove(parts, 1)
				svc = "ReplicatedStorage"
			else
				-- fallback: try heuristic from alias name
				svc = service_for_alias(alias)
			end

			-- Remove any stray leading "src"
			if parts[1] and parts[1]:lower() == "src" then
				table.remove(parts, 1)
			end

			-- Normalize known names' casing
			for i, v in ipairs(parts) do
				local lv = v:lower()
				if lv == "packages" then
					parts[i] = "Packages"
				elseif lv == "serverpackages" then
					parts[i] = "ServerPackages"
				elseif lv == "server" then
					parts[i] = "Server"
				elseif lv == "client" then
					parts[i] = "Client"
				elseif lv == "shared" then
					parts[i] = "Shared"
				elseif lv == "network" then
					parts[i] = "Network"
				elseif lv == "starterplayerscripts" then
					parts[i] = "StarterPlayerScripts"
				end
			end

			-- If parts now start with "starterplayerscripts" and svc isn't StarterPlayer, move to StarterPlayer service
			if parts[1] and parts[1] == "StarterPlayerScripts" then
				svc = "StarterPlayer"
			end

			return to_waitfor_chain(svc, parts)
		end
	end
	return nil
end

local function transform_source(src)
	return src:gsub("require%(%s*(['\"])(@[^'\"]-)%1%s*%)", function(_, p)
		local expr = resolve_require_path(p)
		if expr then
			return "require(" .. expr .. ")"
		end
		return 'require("' .. p .. '")'
	end)
end

-- walk src files and write build_src equivalents
local p = io.popen('find "src" -type f \\( -name "*.luau" -o -name "*.lua" \\) -print')
if not p then
	error("find failed")
end
local any = false
for file in p:lines() do
	any = true
	local rel = file:sub(#"src" + 2)
	local out = "build_src/" .. rel
	local s = read(file)
	if not s then
		io.stderr:write("failed reading " .. file .. "\n")
	else
		local ok, err = pcall(function()
			write(out, transform_source(s))
		end)
		if not ok then
			io.stderr:write("failed writing " .. out .. ": " .. tostring(err) .. "\n")
		end
	end
end
p:close()
if not any then
	error("no files under src")
end
print("build_src generated. TIMEOUT=" .. tostring(TIMEOUT))
