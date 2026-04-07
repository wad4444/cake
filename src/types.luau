local hooks = require("./hooks")

export type Callback = (...any) -> ...any
export type UnknownCallback = (...unknown) -> ...unknown
export type Cleanuppable = Callback | Instance | thread | RBXScriptConnection
export type Symbol = { __do_not_use_this_or_you_will_be_fired: never }

export type ErrorNode = {
	read errors: { string },
	category: string?,
	children: { ErrorNode },
}

export type InternalSystemState = {
	read context: SystemContext,
	read to_cleanup: { Cleanuppable },
	read initial_runner: () -> ...any,
	processed_runner: (() -> ...any)?,
	last_run: number,
}

export type Transformation<T..., V...> = (T...) -> V...

export type Hook = index<typeof(hooks), keyof<typeof(hooks)>>

export type SchedulerInternal<T, K...> = {
	read internal_values: {
		default_phase: Phase,
		init_arguments: { unknown }?,
		is_started: boolean,
		name: string,
	},

	read internal_system_state: { [SystemTable<Callback>]: InternalSystemState },
	read internal_error_cache: { [string]: number },
	read internal_hooks: { [Hook]: { Callback } },

	read init: (SchedulerInternal<T, K...>, K...) -> (),
	read start: (SchedulerInternal<T, K...>) -> (),
	read deinit: (SchedulerInternal<T, K...>) -> (),
	read add_foreign_system: <V...>(
		SchedulerInternal<T, K...>,
		SystemTable<SystemFunction<V...>>,
		Transformation<K..., V...>
	) -> () -> (),
	read add_system: (SchedulerInternal<T, K...>, SystemTable<T>) -> () -> (),
	read add_systems: (SchedulerInternal<T, K...>, { SystemTable<T> }) -> (),
	read remove_system: (SchedulerInternal<T, K...>, SystemTable<Callback>) -> (),
	read run_system: (SchedulerInternal<T, K...>, SystemTable<Callback>) -> (),
	read run_phase: (SchedulerInternal<T, K...>, Phase) -> (),
	read set_default_phase: (SchedulerInternal<T, K...>, Phase) -> (),
	read get_default_phase: (SchedulerInternal<T, K...>) -> Phase,
	read get_name: (SchedulerInternal<T, K...>) -> string,
	read get_systems: (SchedulerInternal<T, K...>) -> { SystemTable<UnknownCallback> },
	read set_name: (SchedulerInternal<T, K...>, string) -> (),
	read hook: ((
		SchedulerInternal<T, K...>,
		typeof(hooks.system_ran),
		(SystemTable<UnknownCallback>, SystemContext) -> ()
	) -> () -> ()) & ((SchedulerInternal<T, K...>, typeof(hooks.phase_ran), (Phase) -> ()) -> () -> ()) & ((
		SchedulerInternal<T, K...>,
		typeof(hooks.system_added),
		(SystemTable<UnknownCallback>, SystemContext) -> ()
	) -> () -> ()) & ((
		SchedulerInternal<T, K...>,
		typeof(hooks.system_removed),
		(SystemTable<UnknownCallback>, SystemContext) -> ()
	) -> () -> ()) & ((
		SchedulerInternal<T, K...>,
		typeof(hooks.default_phase_changed),
		(Phase) -> ()
	) -> () -> ()) & ((
		SchedulerInternal<T, K...>,
		typeof(hooks.system_call),
		(SystemTable<UnknownCallback>, SystemContext, () -> ()) -> () -> ()
	) -> () -> ()),
}

export type Phase = { read name: string, read symbol: Symbol }

export type function ToInternal(type: type)
	assert(type:is("function"))
	local parameters = type:parameters()
	local head = parameters.head or {}

	local sys_fn_head = table.clone(head)
	table.insert(sys_fn_head, SystemContext)

	local sys_fn_type = types.newfunction({
		head = sys_fn_head,
		tail = parameters.tail,
	}, {
		head = { types.any },
	})

	return SchedulerInternal(sys_fn_type, table.unpack(head))
end

export type Scheduler<T...> = ToInternal<(T...) -> ()>

export type SystemContext = {
	delta_time: number,
	read cleanup: (Cleanuppable) -> () -> (),
}
export type SystemFunction<T...> = (T...) -> any

export type SystemTable<T> = {
	read system: T,
	read name: string?,
	read phase: Phase?,
	read symbol: Symbol,
}

return nil
