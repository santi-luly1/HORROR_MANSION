/*
[=[
    @class Centurion
    @author santi-luly1
    @description Centurion bootstrapper

    CHANGELOG: [
        26/08/05 --> Initial version.
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
import { Controller, OnInit, OnStart } from "@flamework/core";
import { Centurion } from "@rbxts/centurion";
import { CenturionUI } from "@rbxts/centurion-ui";
import { warn } from "@rbxts/logger";
import { UserInputService } from "@rbxts/services";

// Types

// Networking

// Local utilities

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Controller()
export default class CenturionClass implements OnInit, OnStart {
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
		Centurion.client()
			.start()
			.then(() => CenturionUI.start(Centurion.client(), {}))
			.catch((err) => warn("Failed to start Centurion:", err));

		UserInputService.InputBegan.Connect((input, gpe) => {
			if (gpe) return;

			if (input.KeyCode === Enum.KeyCode.P) CenturionUI.setVisible(!CenturionUI.isVisible());
		});
	}

	/*
    --------------------------------------------------------------------
    --- Public API
    --------------------------------------------------------------------
    */
}
