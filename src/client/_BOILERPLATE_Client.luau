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

local Promise = require(Packages:WaitForChild("promise"))
local t = require(Packages:WaitForChild("t"))

local _BOILERPLATE_Client = {
	_init = false,
	_start = false,
}

--------------------------------------------------------------------
--- Variables
--------------------------------------------------------------------
local _

--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
type Promise<T> = typeof(Promise)
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
function _BOILERPLATE_Client:doSomething(a: TYPE): Promise<nil>
    return Promise.new(function(resolve, reject, onCancel)
        if not TYPE(a) then
			return reject(`[{script.Name}] bad argument #1 (string expected)`)
		end

        if onCancel(function()
            -- cancel the promise
        end) then return end
        
        return resolve()
	end)
end

--------------------------------------------------------------------
--- API
--------------------------------------------------------------------


return _BOILERPLATE_Client