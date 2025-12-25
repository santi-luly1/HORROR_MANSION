--!strict

export type envConstants = "LOGGING_ENABLED" | "LOGGING_PREFIX" | "USE_FULL_NAME"
export type predicate<T> = (T) -> boolean
export type lifecycleModule = {
	init: (() -> any)?,
	start: (() -> any)?,
	waitFor: ((moduleName: string) -> any)?,
	[string]: any,
}
export type core = {
	load_children: (container: Instance, predicate: predicate<Instance>?) -> any,
	load_descendants: (container: Instance, predicate: predicate<Instance>?) -> any,
}
export type internal = {
	safeRequire: (module: ModuleScript) -> any,
	waitFor: (name: string) -> any,
	load_modules: (container: Instance, useDescendants: boolean, predicate: predicate<Instance>?) -> any,
	get_priority: (module: ModuleScript) -> number,
}

return nil
