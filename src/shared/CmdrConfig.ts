export = {
	Permissions: {
		Admin: [
			// all ids inside this table will be admin.
			game.CreatorId,
		],
	},
	Colors: {
		Error: new Color3(1, 0, 0), // 255, 0, 0
		Warn: new Color3(1, 0.7843137255, 0), // 255, 200, 0
		Success: new Color3(0, 1, 0), // 0, 255, 0
		Info: new Color3(0.3921568627, 0.7843137255, 0.9019607843), // 100, 200, 230
	},
};
