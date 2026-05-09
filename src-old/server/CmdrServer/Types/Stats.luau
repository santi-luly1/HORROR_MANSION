return function(registry)
	registry:RegisterType(
		"stats",
		registry.Cmdr.Util.MakeEnumType(script.Name, {
			"Survivals",
			"Points",
		})
	)
end
