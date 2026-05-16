/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/

declare namespace _SERVICE {
	export type Service<T> = T & {
		Init(this: T, registry: Map<string, unknown>): void; // would prefer that registry was Service.ServiceRegistry, but it makes cyclic deps.
		Start(this: T): void;

		//_init: boolean; // these are private, should not be inside the interface.
		//_start: boolean;
		Dependencies?: string[];
	};
}

export = _SERVICE;
