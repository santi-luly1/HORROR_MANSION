--!nocheck
--[=[
	Different types and interfaces used in modules.
    selene screams in warnings D:
    @class _Types
]=]
--------------------------------------------------------------------
--- Promise
--------------------------------------------------------------------
local Promise = {}
Promise.__index = Promise

export type Resolve<T...> = (T...) -> ()
export type Reject = (...any) -> ()
export type ResolveReject<T...> = (Resolve<T...>, Reject) -> ()

export type Promise<T...> = typeof(setmetatable(
	{} :: {
		_fulfilled: any?,
		_rejected: any?,
		_unconsumedException: boolean,
		_pendingExecuteList: { any }?,
		_source: string,
	},
	{} :: typeof({ __index = Promise })
))

function Promise.isPromise(_: any): boolean end
function Promise.new<T...>(func: ResolveReject<T...>?): Promise<T...> end
function Promise.spawn<T...>(func: ResolveReject<T...>): Promise<T...> end
function Promise.delay<T...>(seconds: number, func: ResolveReject<T...>): Promise<T...> end
function Promise.defer<T...>(func: ResolveReject<T...>): Promise<T...> end
function Promise.resolved<T...>(...: T...): Promise<T...> end
function Promise.rejected<T...>(...): Promise<()> end
function Promise.IsPending<T...>(self: Promise<T...>): boolean end
function Promise.IsFulfilled<T...>(self: Promise<T...>): boolean end
function Promise.IsRejected<T...>(self: Promise<T...>): boolean end
function Promise.Wait<T...>(self: Promise<T...>): T... end
function Promise.Yield<T...>(self: Promise<T...>): (boolean, T...) end
function Promise:Resolve<T...>(...: T...) end
function Promise._fulfill<T...>(self: Promise<T...>, values) end
function Promise.Reject<T...>(self: Promise<T...>, ...) end
function Promise._reject<T...>(self: Promise<T...>, values) end
function Promise._toHumanReadable<T...>(_self: Promise<T...>, data: any): string end
function Promise.Then<T...>(self: Promise<T...>, onFulfilled: ((T...) -> any...)?, onRejected: ((...any) -> any...)?) end
function Promise.Tap<T...>(self: Promise<T...>, onFulfilled, onRejected) end
function Promise.Finally<T...>(self: Promise<T...>, func) end
function Promise.Catch<T...>(self: Promise<T...>, onRejected) end
function Promise.Destroy<T...>(self: Promise<T...>) end
function Promise.GetResults<T...>(self: Promise<T...>): (boolean, T...) end
function Promise._getResolveReject<T...>(self: Promise<T...>): (Resolve<T...>, Reject) end
function Promise._executeThen<T...>(self: Promise<T...>, onFulfilled, onRejected, promise2) end




--------------------------------------------------------------------
--- Signal
--------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal

export type Signal<T...> = typeof(setmetatable(
	{} :: {
		_handlerListHead: Connection<T...> | false,
	},
	{} :: typeof({ __index = Signal })
))

function Signal.new<T...>(): Signal<T...> end
function Signal.isSignal(value: any): boolean end
function Signal.Connect<T...>(self: Signal<T...>, fn: SignalHandler<T...>): Connection<T...> end
function Signal:GetConnectionCount() end
function Signal.DisconnectAll<T...>(self: Signal<T...>): () end
function Signal.Fire<T...>(self: Signal<T...>, ...: T...): () end
function Signal.Wait<T...>(self: Signal<T...>): T... end
function Signal.Once<T...>(self: Signal<T...>, fn: SignalHandler<T...>): Connection<T...> end

Signal.Destroy = Signal.DisconnectAll




--------------------------------------------------------------------
--- Maid
--------------------------------------------------------------------
local Maid = {}

export type MaidTask = (() -> ()) | Instance | thread | any | RBXScriptConnection | nil

export type Maid = typeof(setmetatable(
	{} :: {
		Add: <T>(self: Maid, task: T) -> T,
		GiveTask: (self: Maid, task: MaidTask) -> number,
		GivePromise: <T>(self: Maid, promise: T) -> T,
		DoCleaning: (self: Maid) -> (),
		Destroy: (self: Maid) -> (),
		_tasks: { [any]: MaidTask },
		[string | number | MaidTask]: any,
	},
	{} :: typeof({ __index = Maid })
))

function Maid.new(): Maid end
function Maid.isMaid(value: any): boolean end
function Maid.__index(self: Maid, index: any) end
function Maid.__newindex(self: Maid, index: any, newTask: MaidTask) end
function Maid.Add<T>(self: Maid, task: T): T end
function Maid.GiveTask(self: Maid, task: MaidTask): number end
function Maid.GivePromise(self: Maid, promise: any): any end
function Maid.DoCleaning(self: Maid) end
Maid.Destroy = Maid.DoCleaning




--------------------------------------------------------------------
--- ServiceBag & dependencies
--------------------------------------------------------------------

local BaseObject = {}
BaseObject.__index = BaseObject

export type BaseObject = typeof(setmetatable(
	{} :: {
		_obj: Instance?,
		_maid: Maid,
	},
	{} :: typeof({ __index = BaseObject })
))

function BaseObject.new(obj: Instance?): BaseObject end
function BaseObject.Destroy(self: BaseObject): () end


local ServiceInitLogger = {}
ServiceInitLogger.__index = ServiceInitLogger

type LogEntry = {
	name: string,
	children: { LogEntry },
	log: string?,
}

export type ServiceInitLogger = typeof(setmetatable(
	{} :: {
		_action: string,
		_rootNode: LogEntry,
		_stack: { LogEntry },
		_totalTimeUsed: number,
		_initIndent: number,
		_totalServices: number,
	},
	{} :: typeof({ __index = ServiceInitLogger })
))

function ServiceInitLogger.new(action: string): ServiceInitLogger end
function ServiceInitLogger.StartInitClock(self: ServiceInitLogger, serviceName: string) end
function ServiceInitLogger.Print(self: ServiceInitLogger) end


local ServiceBag = setmetatable({}, {} :: BaseObject)
ServiceBag.__index = ServiceBag

export type ServiceBag = typeof(setmetatable(
	{} :: {
		_services: { [any]: any },
		_parentProvider: ServiceBag?,
		_serviceTypesToInitializeSet: { [any]: true }?,
		_initializedServiceTypeSet: { [any]: true },
		_serviceTypesToStartSet: { [any]: true }?,

		_initRunAllowed: boolean,
		_destructing: boolean,
		_serviceInitLogger: ServiceInitLogger.ServiceInitLogger,
		_serviceStartLogger: ServiceInitLogger.ServiceInitLogger,

		_destroyingSignal: Signal.Signal<()>,
	},
	{} :: typeof({ __index = ServiceBag })
)) & BaseObject.BaseObject

function ServiceBag.new(parentProvider: ServiceBag?): ServiceBag end
function ServiceBag.isServiceBag(value: any): boolean end
function ServiceBag.PrintInitialization(self: ServiceBag) end
function ServiceBag.GetService<T>(self: ServiceBag, serviceType: T): T end
function ServiceBag.HasService<T>(self: ServiceBag, serviceType: T): boolean end
function ServiceBag.Init(self: ServiceBag) end
function ServiceBag.Start(self: ServiceBag) end
function ServiceBag._getServiceName(_self: ServiceBag, serviceType): string end
function ServiceBag.IsStarted(self: ServiceBag): boolean end
function ServiceBag.CreateScope(self: ServiceBag): ServiceBag end
function ServiceBag._addServiceType<T>(self: ServiceBag, serviceType: T) end
function ServiceBag._ensureInitialization<T>(self: ServiceBag, serviceType: T) end
function ServiceBag._initService(self: ServiceBag, serviceType) end
function ServiceBag.Destroy(self: ServiceBag) end
function ServiceBag._destructServices(self: ServiceBag) end


return nil