/*
[=[
    @class _BOILERPLATE_Service
    @author author
    @description Service boilerplate

    CHANGELOG: [
        yy/mm/dd --> Initial version.
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
import { t } from "@rbxts/t";

// Types
import * as Types from "server/types/_BOILERPLATE_Service";

// Networking
import _BOILERPLATE_Network from "shared/networking/_BOILERPLATE_Network";

// Local utilities

// Services

/*
--------------------------------------------------------------------
--- Module
--------------------------------------------------------------------
*/

@Service()
export class _BOILERPLATE_ServiceClass implements Types.default, OnInit, OnStart {
	/*
		runtime fields
	*/

	/*
	--------------------------------------------------------------------
	--- Variables
	--------------------------------------------------------------------
	*/
	private _: undefined;

	private check = t.strictArray(t.string);

	/*
	--------------------------------------------------------------------
	--- Helpers
	--------------------------------------------------------------------
	*/
	private help() {
		return "helping";
	}

	/*
	--------------------------------------------------------------------
	--- Constructor
	--------------------------------------------------------------------
	*/
	//constructor(private readonly network: _BOILERPLATE_Network) {} // dependency injection
	constructor() {}

	/*
	--------------------------------------------------------------------
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public onInit() {
		/* initialization logic here */
	}

	public onStart() {
		/* start/runtime logic here */
	}

	/*
	--------------------------------------------------------------------
	--- Public API
	--------------------------------------------------------------------
	*/
	public doSomething() {
		return new Promise<void>((resolve) => {
			assert(this.check(""));
			print(this.help());
			return resolve();
		});
	}
}
