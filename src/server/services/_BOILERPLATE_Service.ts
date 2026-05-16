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
class _BOILERPLATE_ServiceClass implements Types._BOILERPLATE_Service {
	/*
		state
	*/
	private init = false;
	private start = false;

	/*
		runtime fields
	*/

	// dependencies
	public static Dependencies = [];

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
	--- Init / Start
	--------------------------------------------------------------------
	*/
	public Init() {
		assert(!this.init, `[${script.Name}] - Module already initialized.`);
		this.init = true;
	}

	public Start() {
		assert(this.init, `[${script.Name}] - Module not initialized.`);
		assert(!this.start, `[${script.Name}] - Module already started.`);
		this.start = true;
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

/*
--------------------------------------------------------------------
--- Export
--------------------------------------------------------------------
*/
const _BOILERPLATE_Service = new _BOILERPLATE_ServiceClass();
export = _BOILERPLATE_Service;
