/*
--------------------------------------------------------------------
--- Types
--------------------------------------------------------------------
*/

declare namespace _SERVICE {
	export type Service<T> = {
		Init(this: T, registry: Record<string, unknown>): void; // would prefer that registry was Service.ServiceRegistry, but it makes cyclic deps.
		Start(this: T): void;

		_init: boolean;
		_start: boolean;
		Dependencies?: string[];
	};
}

export = _SERVICE;
