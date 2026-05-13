/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import Promise from "@rbxts-js/roblox-lua-promise";
import _SERVICE from "./_SERVICE";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/
export type TYPE = "a" | "b";

export interface BoilerplateMembers {
	doSomething(this: BoilerplateMembers, a: TYPE): Promise<void>;
}

export type _BOILERPLATE_Server = _SERVICE.Service<BoilerplateMembers>;

declare const _default: _BOILERPLATE_Server;
export default _default;
