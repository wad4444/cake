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

local function init<T, K...>(self: types.SchedulerInternal<T, K...>, ...: K...): ()
	local top_index = logging.set_category(messages.categories.failed_to_init(self))

	if self.internal_values.init_arguments then
		logging.report_with_traceback(messages.errors.already_initialized)
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	logging.end_after_inclusive(top_index)
	self.internal_values.init_arguments = { ... }

	self:run_phase(phase_std.on_init)
end

local function validate_scheduler_initialized<T, K...>(self: types.SchedulerInternal<T, K...>)
	if not self.internal_values.init_arguments then
		logging.report_with_traceback(messages.errors.not_initialized)
		logging.flush()
		return false
	end

	return true
end

local function validate_system<T, K...>(self: types.SchedulerInternal<T, K...>, to_add: types.SystemTable<T>)
	if globals.dev_mode and not system.is_system(to_add) then
		logging.report_with_traceback(messages.errors.invalid_system(to_add))
		logging.flush()
		return false
	end

	return true
end

local function add_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.SystemTable<T>): () -> ()
	local top_index = logging.set_category(messages.categories.failed_to_add_system(system))
	if not validate_scheduler_initialized(self) or not validate_system(self, system) then
		logging.end_after_inclusive(top_index)
		return util.noop
	end

	local to_cleanup: { types.Cleanuppable } = {}

	local context: types.SystemContext = {
		delta_time = 0,
		cleanup = util.build_cleanup_function(to_cleanup),
	}

	local cached_runner = function()
		return (system.system :: any)(util.combine_into_tuple(self.internal_values.init_arguments :: any, context))
	end

	logging.set_category(messages.categories.failed_to_cache(system))
	local success, result = try.try_run(cached_runner)

	if not success then
		util.cleanup(to_cleanup)
		logging.end_after_inclusive(top_index)
		logging.flush()

		return util.noop
	end

	logging.end_category()

	if result and typeof(result) == "function" then
		cached_runner = result
	end

	local state: types.InternalSystemState = {
		context = context,
		to_cleanup = to_cleanup,
		cached_runner = cached_runner,
		last_run = os.clock(),
	}

	self.internal_system_state[system] = state
	logging.end_after_inclusive(top_index)

	return function()
		self:remove_system(system)
	end
end

local function add_foreign_system<T, K..., V...>(
	self: types.SchedulerInternal<T, K...>,
	system: types.SystemTable<types.SystemFunction<V...>>,
	transformation: types.Transformation<K..., V...>
): () -> ()
	local top_index = logging.set_category(messages.categories.failed_to_add_system(system))
	if not validate_scheduler_initialized(self) or not validate_system(self, system) then
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

	local cached_runner = function()
		return (system.system :: any)(table.unpack(arguments))
	end

	logging.set_category(messages.categories.failed_to_cache(system))
	local success, result = try.try_run(cached_runner)

	if not success then
		util.cleanup(to_cleanup)
		logging.end_after_inclusive(top_index)
		logging.flush()

		return util.noop
	end

	logging.end_category()

	if result and typeof(result) == "function" then
		cached_runner = result
	end

	local state: types.InternalSystemState = {
		context = context,
		to_cleanup = to_cleanup,
		cached_runner = cached_runner,
		last_run = os.clock(),
	}

	self.internal_system_state[system] = state
	logging.end_after_inclusive(top_index)

	return function()
		self:remove_system(system)
	end
end

local function deinit<T, K...>(self: types.SchedulerInternal<T, K...>): ()
	self:run_phase(phase_std.on_deinit)

	local top_index = logging.set_category(messages.categories.failed_to_deinit(self))

	if not self.internal_values.init_arguments then
		logging.report_error(messages.errors.not_initialized)
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	self.internal_values.init_arguments = nil
	local error_node = logging.collect(function()
		for system in self.internal_system_state do
			self:remove_system(system)
		end
	end)

	logging.end_after_inclusive(top_index)
	logging.flush_node(error_node)
end

local function remove_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.SystemTable<any>)
	local top_index = logging.set_category(messages.categories.failed_to_remove_system(self, system))

	local system_state = self.internal_system_state[system]
	if not system_state then
		logging.report_error(messages.errors.system_not_active(system))
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	util.cleanup(system_state.to_cleanup)
	self.internal_system_state[system] = nil

	logging.end_after_inclusive(top_index)
	logging.flush()
end

function run_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.SystemTable<any>)
	local top_index = logging.set_category(messages.categories.failed_to_run_system(self, system))

	local system_state = self.internal_system_state[system]
	if not system_state then
		logging.report_error(messages.errors.system_not_active(system))
		logging.end_after_inclusive(top_index)
		logging.flush()
		return
	end

	system_state.context.delta_time = os.clock() - system_state.last_run
	system_state.last_run = os.clock()

	local success
	local error_node = logging.collect(function()
		success = try.try_run(system_state.cached_runner)
	end)
	if not success then
		logging.end_after_inclusive(top_index)
		transform_system_error_node(self, error_node)
		logging.flush_node(error_node, messages.errors.ignore_error(globals.default_error_ignore_time))

		return
	end

	logging.end_after_inclusive(top_index)
end

function get_default_phase<T, K...>(self: types.SchedulerInternal<T, K...>): types.Phase
	return self.internal_values.default_phase
end

function transform_system_error_node<T, K...>(self: types.SchedulerInternal<T, K...>, error_node: types.ErrorNode)
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
	nodes.strip_empty(error_node)
end

function run_phase<T, K...>(self: types.SchedulerInternal<T, K...>, phase_to_run: types.Phase)
	local top_index = logging.set_category(messages.categories.failed_to_run_phase(self, phase_to_run))

	local is_default_phase = phase_to_run == self.internal_values.default_phase
	if globals.dev_mode and not phase.is_phase(phase_to_run) then
		logging.report_error(messages.errors.invalid_phase(phase_to_run))
		logging.end_after_inclusive(top_index)

		logging.flush()
		return
	end

	local error_node = logging.collect(function()
		for system in self.internal_system_state do
			if (is_default_phase and system.phase == nil) or system.phase == phase_to_run then
				self:run_system(system)
			end
		end
	end)

	if nodes.is_empty(error_node) then
		return
	end
	logging.flush_node(error_node, messages.errors.ignored_errors(globals.default_error_ignore_time))
	logging.end_after_inclusive(top_index)
end

function set_default_phase<T, K...>(self: types.SchedulerInternal<T, K...>, new_phase: types.Phase)
	if globals.dev_mode and not phase.is_phase(new_phase) then
		logging.set_category(messages.categories.failed_to_set_default_phase(self, new_phase))

		logging.report_error(messages.errors.invalid_phase(new_phase))
		logging.flush()

		logging.end_category()
		return
	end

	self.internal_values.default_phase = new_phase
end

local template = {
	internal_values = {
		default_phase = phase_std.on_init,
	},
	internal_system_state = {},
	internal_error_cache = {},
	add_system = add_system,
	remove_system = remove_system,
	add_foreign_system = add_foreign_system,
	set_default_phase = set_default_phase,
	init = init,
	deinit = deinit,
	run_system = run_system,
	run_phase = run_phase,
	get_default_phase = get_default_phase,
}

local meta = {
	__tostring = function(self)
		return `Scheduler({self.internal_values.default_phase})`
	end,
}

local function create_init<T...>(...: T...)
	local scheduler = table.clone(template)
	scheduler.internal_values.init_arguments = { ... }
	setmetatable(scheduler, meta)

	return table.freeze(scheduler) :: types.Scheduler<T...>
end

local function create<T...>()
	local scheduler = table.clone(template)
	setmetatable(scheduler, meta)

	return scheduler :: types.Scheduler<T...>
end

return {
	create = create,
	create_init = create_init,
}
