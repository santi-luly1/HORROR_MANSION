/*
[=[
	@class runtime
    @author santi-luly1
    @description Server bootstrapper

    CHANGELOG: [
		25/12/26 --> New server bootstrapper.
        25/12/31 --> Added proper loader.
        26/03/01 --> Lighting setup and updated init loader.
        26/05/24 --> Migrated to flamework.
	]
]=]
*/
import { Flamework } from "@flamework/core";
import logger from "@rbxts/logger";
import { Lighting } from "@rbxts/services";

// initial set-up
Lighting.Ambient = Color3.fromRGB(128, 128, 128);

logger.configure().setMinimumLogLevel("DEBUG");

Flamework.addPaths("src/server/components");
Flamework.addPaths("src/server/services");
Flamework.addPaths("src/shared/components");

Flamework.ignite();
