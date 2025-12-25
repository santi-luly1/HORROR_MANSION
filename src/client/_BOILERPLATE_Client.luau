--[=[
    Boilerplate for client stuff
	@class _BOILERPLATE_Client
    @author: santi-luly1

    CHANGELOG: [
		MM/DD/YY --> change
	]
]=]

--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
local Packages = game:GetService("ReplicatedStorage").Packages

local Promise = require(Packages.promise)
local t = require(Packages.t)

local _BOILERPLATE_Client = {
	_init = false,
	_start = false,
}

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
export type TYPE = "a" | "b"
local TYPE = t.optional(t.string)

--------------------------------------------------------------------
--- ServiceBag (not currently using service bag)
--------------------------------------------------------------------
function _BOILERPLATE_Client:Init()
	assert(not self._init, `[{script.Name}] - Module already initialized.`)
    self._init = true
end

function _BOILERPLATE_Client:Start()
	assert(not self._start, `[{script.Name}] - Module already started.`)
    self._start = true
end

--------------------------------------------------------------------
--- Handlers
--------------------------------------------------------------------
function _BOILERPLATE_Client:doSomething(a: TYPE): any --> Promise.Promise<boolean>
    return Promise.new(function(resolve, reject, onCancel)
        do -- needed so the variables only live here.
            local _ok, log = TYPE(a)
            if not _ok then
                reject(log) -- when bad parameter type, reject the promise.
            end
        end

        if onCancel(function()
            -- cancel the promise
        end) then return end
        
        resolve("ok")
	end)
end

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------


return _BOILERPLATE_Client