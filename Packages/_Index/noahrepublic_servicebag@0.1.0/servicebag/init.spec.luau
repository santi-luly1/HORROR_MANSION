return function()
	local ServiceBag = require(script.Parent)

	local serviceBag = ServiceBag.new()

	local data = {
		TestService = {
			Inited = false,
			Started = false,
		},

		TestService2 = {
			Inited = false,
			Started = false,
		},
	}

	local testService2 = {
		Init = function()
			data.TestService2.Inited = true
		end,

		Start = function()
			data.TestService2.Started = true
		end,
	}

	local testService = {
		Init = function(bag)
			data.TestService.Inited = true
			print(bag)
			local test = bag:GetService(testService2)

			print(test)
		end,

		Start = function()
			data.TestService.Started = true
		end,
	}

	serviceBag:GetService(testService)
	serviceBag:Init()
	serviceBag:Start()

	describe("Start up", function()
		it("should initialize TestService", function()
			expect(data.TestService.Inited).to.equal(true)
		end)

		it("should start TestService", function()
			expect(data.TestService.Started).to.equal(true)
		end)
	end)
end
