/*
[=[
    @class Centurion
    @author santi-luly1
    @description Centurion server bootstrapper

    CHANGELOG: [
        26/08/06 --> Initial version.
    ]
]=]
*/

/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
// Roblox services

// Packages
import { Service, OnInit, OnStart } from "@flamework/core";
import { Centurion } from "@rbxts/centurion";

// Types

// Networking

// Local utilities

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export default class Centurion_ServiceClass implements OnInit, OnStart {
	/*
        runtime fields
    */

	/*
    --------------------------------------------------------------------
    --- Variables
    --------------------------------------------------------------------
    */

	/*
    --------------------------------------------------------------------
    --- Helpers
    --------------------------------------------------------------------
    */

	/*
    --------------------------------------------------------------------
    --- Constructor
    --------------------------------------------------------------------
    */
	constructor() {}

	/*
    --------------------------------------------------------------------
    --- Init / Start
    --------------------------------------------------------------------
    */
	public onInit() {}

	public onStart() {
		const server = Centurion.server();

		server.registry.load(<Folder>script.FindFirstChild("Commands"));
		// server.registry.load(<Folder>script.FindFirstChild("Types"));

		server.start();
	}

	/*
    --------------------------------------------------------------------
    --- Public API
    --------------------------------------------------------------------
    */
}
