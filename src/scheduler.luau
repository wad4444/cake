local types = require("./types")
local phase_std = require("./phase-std")
local util = require("./util")
local messages = require("./messages")
local logging = require("./logging")
local nodes = require("./error-nodes")
local phase = require("./phase")
local globals = require("./globals")
local system = require("./system")
local try = require("./try")
local hooks = require("./hooks")
local create_symbol = require("./symbol")

local default_phase_key = create_symbol("DefaultPhase")

local function init<T, K...>(self: types.SchedulerInternal<T, K...>, ...: K...): ()
	local top_index = logging.set_category(messages.categories.failed_to_init(self))

	if self.internal_values.init_arguments then
		logging.report_with_traceback(messages.errors.already_initialized, 2)
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	logging.end_after_inclusive(top_index)
	self.internal_values.init_arguments = { ... }
end

local function validate_initialized<T, K...>(self: types.SchedulerInternal<T, K...>)
	if not self.internal_values.init_arguments then
		logging.report_with_traceback(messages.errors.not_initialized, 3)
		logging.flush()
		return false
	end

	return true
end

local function validate_started<T, K...>(self: types.SchedulerInternal<T, K...>)
	if not validate_initialized(self) then
		return false
	end

	if not self.internal_values.is_started then
		logging.report_with_traceback(messages.errors.not_started, 3)
		logging.flush()
		return false
	end
	return true
end

local function validate_system<T, K...>(self: types.SchedulerInternal<T, K...>, to_add: types.SystemTable<T>)
	if globals.dev_mode and not system.is_system(to_add) then
		logging.report_with_traceback(messages.errors.invalid_system(to_add), 3)
		logging.flush(messages.errors.only_in_dev_mode)
		return false
	end

	return true
end

local function fire_hook<T, K...>(self: types.SchedulerInternal<T, K...>, hook: types.Hook, ...: any): ...any
	local hooks_list = self.internal_hooks[hook]
	if not hooks_list then
		return
	end

	local a, b, c, d = ...
	local r1, r2, r3, r4

	local top_index = logging.set_category(messages.categories.failed_to_run_hook(hook))
	local error_node = logging.collect(function()
		for _, callback in hooks_list do
			local e, f, g, h = a, b, c, d
			if not a then
				e = r1 or e
				f = r2 or f
				g = r3 or g
				h = r4 or h
			elseif not b then
				f = r1 or f
				g = r2 or g
				h = r3 or h
			elseif not c then
				g = r1 or g
				h = r2 or h
			elseif not d then
				h = r1 or h
			end

			r1, r2, r3, r4 = callback(e, f, g, h)
		end
	end)

	logging.end_after_inclusive(top_index)
	logging.propagate(error_node)
	logging.flush()

	return r1, r2, r3, r4
end

local function cache_system<T, K...>(self: types.SchedulerInternal<T, K...>, system_table: types.AnySystemTable)
	local key = system_table.phase or default_phase_key
	local systems: { any } = self.internal_phase_cache[key]
	if not systems then
		systems = {}
		self.internal_phase_cache[key] = systems
	end
	table.insert(systems, system_table)
end

local function uncache_system<T, K...>(self: types.SchedulerInternal<T, K...>, system_table: types.AnySystemTable)
	local key = system_table.phase or default_phase_key
	local systems: { any } = self.internal_phase_cache[key]
	if not systems then
		return
	end
	local index = table.find(systems, system_table)
	if index then
		table.remove(systems, index)
	end
end

local function start<T, K...>(self: types.SchedulerInternal<T, K...>): ()
	local top_index = logging.set_category(messages.categories.failed_to_start(self))

	if not validate_initialized(self) then
		logging.end_after_inclusive(top_index)
		return
	end

	if self.internal_values.is_started then
		logging.report_with_traceback(messages.errors.already_started, 2)
		logging.end_after_inclusive(top_index)
		return
	end

	self.internal_values.is_started = true
	local error_node = logging.collect(function()
		self:run_phase(phase_std.pre_start)
		self:run_phase(phase_std.on_start)
	end)

	logging.end_after_inclusive(top_index)
	logging.propagate(error_node)
	logging.flush()
end

local function add_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.SystemTable<T>): () -> ()
	local top_index = logging.set_category(messages.categories.failed_to_add_system(system))
	if not validate_initialized(self) or not validate_system(self, system) then
		logging.end_after_inclusive(top_index)
		return util.noop
	end

	local to_cleanup: { types.Cleanuppable } = {}

	local context: types.SystemContext = {
		delta_time = 0,
		cleanup = util.build_cleanup_function(to_cleanup),
	}

	local initial_runner = function()
		return (system.system :: any)(util.combine_into_tuple(self.internal_values.init_arguments :: any, context))
	end

	local state: types.InternalSystemState = {
		context = context,
		to_cleanup = to_cleanup,
		initial_runner = initial_runner,
		last_run = os.clock(),
	}

	self.internal_system_state[system] = state
	cache_system(self, system)
	logging.end_after_inclusive(top_index)
	fire_hook(self, hooks.system_added, system, context)

	local is_default_phase = system.phase == nil
	local is_default_on_start = self.internal_values.default_phase == phase_std.on_start
	if
		self.internal_values.is_started
		and (system.phase == phase_std.on_start or (is_default_phase and is_default_on_start))
	then
		self:run_system(system)
	end

	return function()
		self:remove_system(system)
	end
end

local function add_systems<T, K...>(self: types.SchedulerInternal<T, K...>, systems: { types.SystemTable<T> })
	local top_index = logging.set_category(messages.categories.failed_to_add_systems)
	if not validate_initialized(self) then
		logging.end_after_inclusive(top_index)
		return
	end

	local error_node = logging.collect(function()
		for _, system in systems do
			if not validate_system(self, system) then
				continue
			end

			self:add_system(system)
		end
	end)

	logging.end_after_inclusive(top_index)
	logging.propagate(error_node)
	logging.flush()
end

local function add_foreign_system<T, K..., V...>(
	self: types.SchedulerInternal<T, K...>,
	system: types.SystemTable<types.SystemFunction<V...>>,
	transformation: types.Transformation<K..., V...>
): () -> ()
	local top_index = logging.set_category(messages.categories.failed_to_add_system(system))
	if not validate_initialized(self) or not validate_system(self, system) then
		logging.end_after_inclusive(top_index)
		return util.noop
	end

	local to_cleanup: { types.Cleanuppable } = {}

	local context: types.SystemContext = {
		delta_time = 0,
		cleanup = util.build_cleanup_function(to_cleanup),
	}

	logging.set_category(messages.categories.failed_to_transform(system))

	local trasform_success, arguments =
		try.try_run_pack_args<<K...>>(transformation, table.unpack(self.internal_values.init_arguments :: any), context)

	if not trasform_success then
		util.cleanup(to_cleanup)
		logging.end_after_inclusive(top_index)
		logging.flush()
		return util.noop
	end

	logging.end_category()

	local initial_runner = function()
		return (system.system :: any)(table.unpack(arguments))
	end

	local state: types.InternalSystemState = {
		context = context,
		to_cleanup = to_cleanup,
		initial_runner = initial_runner,
		last_run = os.clock(),
	}

	self.internal_system_state[system] = state
	cache_system(self, system)
	logging.end_after_inclusive(top_index)
	fire_hook(self, hooks.system_added, system, context)

	return function()
		self:remove_system(system)
	end
end

local function deinit<T, K...>(self: types.SchedulerInternal<T, K...>): ()
	local top_index = logging.set_category(messages.categories.failed_to_deinit(self))

	if not self.internal_values.init_arguments then
		logging.report_error(messages.errors.not_initialized, 2)
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	local error_node = logging.collect(function()
		self:run_phase(phase_std.on_stop)

		for system in self.internal_system_state do
			self:remove_system(system)
		end
	end)

	self.internal_values.init_arguments = nil
	self.internal_values.default_phase = phase_std.on_start
	self.internal_values.is_started = false
	table.clear(self.internal_error_cache)
	table.clear(self.internal_system_state)
	table.clear(self.internal_phase_cache)
	table.clear(self.internal_hooks)

	logging.end_after_inclusive(top_index)
	logging.propagate(error_node)
	logging.flush()
end

local function remove_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.AnySystemTable)
	local top_index = logging.set_category(messages.categories.failed_to_remove_system(self, system))

	local system_state = self.internal_system_state[system]
	if not system_state then
		logging.report_with_traceback(messages.errors.system_not_active(system), 2)
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	util.cleanup(system_state.to_cleanup)
	uncache_system(self, system)
	self.internal_system_state[system] = nil

	logging.end_after_inclusive(top_index)
	logging.flush()
	fire_hook(self, hooks.system_removed, system, system_state.context)
end

local function transform_system_error_node<T, K...>(self: types.SchedulerInternal<T, K...>, error_node: types.ErrorNode)
	for node in nodes.iterate(error_node) do
		if #node.errors == 0 then
			continue
		end

		local errors_to_remove = {}
		for _, error in node.errors do
			local last_seen = self.internal_error_cache[error]
			if last_seen and os.clock() - last_seen < globals.default_error_ignore_time then
				table.insert(errors_to_remove, error)
				continue
			end

			self.internal_error_cache[error] = os.clock()
		end

		for _, error in errors_to_remove do
			table.remove(node.errors, table.find(node.errors, error))
		end
	end
end

local function run_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.AnySystemTable)
	local top_index = logging.set_category(messages.categories.failed_to_run_system(self, system))
	if not validate_started(self) then
		logging.end_after_inclusive(top_index)
		return
	end

	local system_state = self.internal_system_state[system]
	if not system_state then
		logging.report_error(messages.errors.system_not_active(system))
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	system_state.context.delta_time = os.clock() - system_state.last_run
	system_state.last_run = os.clock()

	local runner = system_state.processed_runner or system_state.initial_runner
	local success, result
	local error_node

	local function perform_system_call()
		error_node = logging.collect(function()
			success, result = try.try_run(runner)
		end)
	end

	local perform: types.Callback =
		fire_hook(self, hooks.system_call, system, system_state.context, perform_system_call)

	perform = perform or perform_system_call
	perform()

	if not success and error_node then
		logging.end_after_inclusive(top_index)
		transform_system_error_node(self, error_node)
		logging.propagate(error_node)
		logging.flush(messages.errors.ignore_error(globals.default_error_ignore_time))

		return
	end

	if not system_state.processed_runner and typeof(result) == "function" then
		system_state.processed_runner = result
	end

	logging.end_after_inclusive(top_index)
	fire_hook(self, hooks.system_ran, system, system_state.context)
end

local function get_systems<T, K...>(self: types.SchedulerInternal<T, K...>): { types.UnknownSystemTable }
	local systems: { any } = {}
	for system in self.internal_system_state do
		table.insert(systems, system)
	end
	return systems
end

local function get_name<T, K...>(self: types.SchedulerInternal<T, K...>): string
	return self.internal_values.name
end

local function get_default_phase<T, K...>(self: types.SchedulerInternal<T, K...>): types.Phase
	return self.internal_values.default_phase
end

local function run_phase<T, K...>(self: types.SchedulerInternal<T, K...>, phase_to_run: types.Phase)
	local top_index = logging.set_category(messages.categories.failed_to_run_phase(self, phase_to_run))
	if not validate_started(self) then
		logging.end_after_inclusive(top_index)
		return
	end

	if globals.dev_mode and not phase.is_phase(phase_to_run) then
		logging.report_with_traceback(messages.errors.invalid_phase(phase_to_run), 2)
		logging.end_after_inclusive(top_index)

		logging.flush(messages.errors.only_in_dev_mode)
		return
	end

	if phase_to_run == phase_std.never then
		logging.report_error(messages.errors.tried_ran_never)
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	local is_default_phase = phase_to_run == self.internal_values.default_phase

	local error_node = logging.collect(function()
		local systems = self.internal_phase_cache[phase_to_run]
		if systems then
			for _, system in systems do
				self:run_system(system)
			end
		end

		if not is_default_phase then
			return
		end

		local default_systems = self.internal_phase_cache[default_phase_key]
		if default_systems then
			for _, system in default_systems do
				self:run_system(system)
			end
		end
	end)

	logging.end_after_inclusive(top_index)
	fire_hook(self, hooks.phase_ran, phase_to_run)

	if nodes.is_empty(error_node) then
		return
	end
	logging.propagate(error_node)
	logging.flush(messages.errors.ignore_errors(globals.default_error_ignore_time))
end

local function set_name<T, K...>(self: types.SchedulerInternal<T, K...>, new_name: string)
	self.internal_values.name = new_name
end

local function set_default_phase<T, K...>(self: types.SchedulerInternal<T, K...>, new_phase: types.Phase)
	if globals.dev_mode and not phase.is_phase(new_phase) then
		logging.set_category(messages.categories.failed_to_set_default_phase(self, new_phase))

		logging.report_with_traceback(messages.errors.invalid_phase(new_phase), 2)
		logging.flush(messages.errors.only_in_dev_mode)

		logging.end_category()
		return
	end

	self.internal_values.default_phase = new_phase
	fire_hook(self, hooks.default_phase_changed, new_phase)
end

local function hook<T, K...>(self: types.SchedulerInternal<T, K...>, hook: types.Hook, callback: (...any) -> ()): () -> ()
	local hooks_list = self.internal_hooks[hook]
	if not hooks_list then
		hooks_list = {}
		self.internal_hooks[hook] = hooks_list
	end
	table.insert(hooks_list, callback)

	return function()
		local index = table.find(hooks_list, callback)
		if index then
			table.remove(hooks_list, index)
		end
	end
end

local template = {
	internal_values = {
		default_phase = phase_std.on_start,
		init_arguments = nil,
		name = "",
		is_started = false,
	},
	internal_system_state = {},
	internal_phase_cache = {},
	internal_error_cache = {},
	internal_hooks = {},
	add_system = add_system,
	add_systems = add_systems,
	remove_system = remove_system,
	add_foreign_system = add_foreign_system,
	set_default_phase = set_default_phase,
	set_name = set_name,
	init = init,
	deinit = deinit,
	start = start,
	run_system = run_system,
	run_phase = run_phase,
	get_default_phase = get_default_phase,
	get_name = get_name,
	get_systems = get_systems,
	hook = hook,
}

local meta = {
	__tostring = function(self: types.Scheduler<...any>)
		return `Scheduler({self.internal_values.name})`
	end,
}

local new_id = util.ids()

local function create<T...>()
	local scheduler = table.clone(template)
	scheduler.internal_system_state = {}
	scheduler.internal_phase_cache = {}
	scheduler.internal_error_cache = {}
	scheduler.internal_hooks = {}
	scheduler.internal_values = table.clone(template.internal_values)
	scheduler.internal_values.name = `#{new_id()}`
	setmetatable(scheduler, meta)

	return scheduler :: types.Scheduler<T...>
end

local function create_init<T...>(...: T...)
	local scheduler = table.clone(template)
	scheduler.internal_system_state = {}
	scheduler.internal_phase_cache = {}
	scheduler.internal_error_cache = {}
	scheduler.internal_hooks = {}
	scheduler.internal_values = table.clone(template.internal_values)
	scheduler.internal_values.name = `#{new_id()}`
	setmetatable(scheduler, meta)

	return scheduler :: types.Scheduler<T...>
end

return table.freeze({
	create = create,
	create_init = create_init,
})
