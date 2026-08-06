/*
[=[
	@class CmdrServer
    @author santi-luly1
	@description Cmdr server initializer

    CHANGELOG: [
		26/01/01 --> Added Cmdr for initialization only.
        26/07/16 --> Parsed into roblox-ts.
	]
]=]
*/

import { Service, OnInit, OnStart } from "@flamework/core";

import { Cmdr } from "@rbxts/cmdr";

@Service()
export default class CmdrServerClass implements OnInit, OnStart {
	public onInit() {}

	public onStart() {
		Cmdr.RegisterCommandsIn(<Folder>script.FindFirstChild("Commands"));
		Cmdr.RegisterHooksIn(<Folder>script.FindFirstChild("Hooks"));
		Cmdr.RegisterTypesIn(<Folder>script.FindFirstChild("Types"));
	}
}
