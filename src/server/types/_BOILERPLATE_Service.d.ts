/*
--------------------------------------------------------------------
--- Dependencies
--------------------------------------------------------------------
*/
import Promise from "@rbxts-js/roblox-lua-promise";

/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/
export type TYPE = "a" | "b";

export default interface BoilerplateMembers {
	doSomething(this: BoilerplateMembers, a: TYPE): Promise<void>;
}
