export type Callback = (...any) -> ...any
export type Cleanuppable = Callback | Instance | thread | RBXScriptConnection

export type ErrorNode = {
	read errors: { string },
	category: string?,
	children: { ErrorNode },
}

export type InternalSystemState = {
	read context: SystemContext,
	read to_cleanup: { Cleanuppable },
	read cached_runner: () -> ...any,
	last_run: number,
}

export type Transformation<T..., V...> = (T...) -> V...

export type SchedulerInternal<T, K...> = {
	read internal_values: {
		default_phase: Phase,
		init_arguments: { unknown }?,
	},

	read internal_system_state: { [SystemTable<Callback>]: InternalSystemState },
	read internal_error_cache: { [string]: number },

	read init: (SchedulerInternal<T, K...>, K...) -> (),
	read add_foreign_system: <V...>(
		SchedulerInternal<T, K...>,
		SystemTable<SystemFunction<V...>>,
		Transformation<K..., V...>
	) -> () -> (),
	read add_system: (SchedulerInternal<T, K...>, SystemTable<T>) -> () -> (),
	read remove_system: (SchedulerInternal<T, K...>, SystemTable<Callback>) -> (),
	read run_system: (SchedulerInternal<T, K...>, SystemTable<Callback>) -> (),
	read run_phase: (SchedulerInternal<T, K...>, Phase) -> (),
	read set_default_phase: (SchedulerInternal<T, K...>, Phase) -> (),
}

export type Phase = { read name: string, read symbol: { never } }

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
		head = { SystemReturns },
	})

	return SchedulerInternal(sys_fn_type, table.unpack(head))
end

export type Scheduler<T...> = ToInternal<(T...) -> ()>

export type SystemContext = {
	delta_time: number,
	read cleanup: (Cleanuppable) -> () -> (),
}
export type SystemReturns = nil | () -> ...any
export type SystemFunction<T...> = (T...) -> SystemReturns

export type SystemTable<T> = {
	read system: T,
	read name: string?,
	read phase: Phase?,
	read symbol: { never },
}

return nil
