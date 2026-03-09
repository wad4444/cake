local types = require("./types")
local phase_std = require("./phase-std")
local util = require("./util")
local errors = require("./errors")
local logging = require("./logging")
local phase = require("./phase")
local globals = require("./globals")

local function init<T, K...>(self: types.SchedulerInternal<T, K...>, ...: K...): ()
	logging.set_category(errors.failed_to_init(self))

	if self.internal_init_arguments then
		logging.report_error(errors.already_initialized)
		logging.flush()
		return
	end

	logging.end_category()
	self.internal_init_arguments = { ... }

	self:run_phase(phase_std.on_init)
end

local function add_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.SystemTable<T>): () -> ()
	logging.set_category(errors.failed_to_add_system(system))
	if not self.internal_init_arguments then
		logging.report_error(errors.not_initialized)
		logging.flush()
		return util.noop
	end

	local to_cleanup: { types.Cleanuppable } = {}

	local context: types.SystemContext = {
		delta_time = 0,
		cleanup = util.build_cleanup_function(to_cleanup),
	}

	local cached_runner = function()
		return (system.system :: any)(table.unpack(self.internal_init_arguments), context)
	end

	logging.set_category(errors.failed_to_cache(system))
	local success, result = logging.try_run(cached_runner)

	if not success then
		logging.flush()
		util.cleanup(to_cleanup)

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
	logging.end_category()

	return function()
		self:remove_system(system)
	end
end

local function add_foreign_system<T, K..., V...>(
	self: types.SchedulerInternal<T, K...>,
	system: types.SystemTable<types.SystemFunction<V...>>,
	transformation: types.Transformation<K..., V...>
): () -> ()
	logging.set_category(errors.failed_to_add_system(system))
	if not self.internal_init_arguments then
		logging.report_error(errors.not_initialized)
		logging.flush()
		return util.noop
	end

	local to_cleanup: { types.Cleanuppable } = {}

	local context: types.SystemContext = {
		delta_time = 0,
		cleanup = util.build_cleanup_function(to_cleanup),
	}

	logging.set_category(errors.failed_to_transform(system))

	local trasform_success, arguments =
		logging.try_run_pack_args<<K...>>(transformation, table.unpack(self.internal_init_arguments), context)

	if not trasform_success then
		logging.flush()
		return util.noop
	end

	logging.end_category()

	local cached_runner = function()
		return (system.system :: any)(table.unpack(arguments))
	end

	logging.set_category(errors.failed_to_cache(system))
	local success, result = logging.try_run(cached_runner)

	if not success then
		logging.flush()
		util.cleanup(to_cleanup)

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
	logging.end_category()

	return function()
		self:remove_system(system)
	end
end

local function deinit<T, K...>(self: types.SchedulerInternal<T, K...>): ()
	self:run_phase(phase_std.on_deinit)

	logging.set_category(errors.failed_to_deinit(self))

	if not self.internal_init_arguments then
		logging.report_error(errors.not_initialized)
		logging.flush()
		return
	end

	self.internal_init_arguments = nil
	logging.collect(function()
		for system in self.internal_system_state do
			self:remove_system(system)
		end
	end)

	logging.flush()
	logging.end_category()
end

local function remove_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.SystemTable<any>)
	logging.set_category(errors.failed_to_remove_system(self, system))

	local system_state = self.internal_system_state[system]
	if not system_state then
		logging.report_error(errors.system_not_active(system))
		logging.flush()
		return
	end

	util.cleanup(system_state.to_cleanup)
	self.internal_system_state[system] = nil

	logging.end_category()
	logging.flush()
end

function run_system<T, K...>(self: types.SchedulerInternal<T, K...>, system: types.SystemTable<any>)
	logging.set_category(errors.failed_to_run_system(self, system))

	local system_state = self.internal_system_state[system]
	if not system_state then
		logging.report_error(errors.system_not_active(system))
		logging.flush()
		return
	end

	system_state.context.delta_time = os.clock() - system_state.last_run
	system_state.last_run = os.clock()

	local success = logging.try_run(system_state.cached_runner)
	if not success then
		logging.flush()
		return
	end

	logging.end_category()
end

function run_phase<T, K...>(self: types.SchedulerInternal<T, K...>, phase_to_run: types.Phase)
	local is_internal_default_phase = phase_to_run == self.internal_default_phase
	if globals.dev_mode and not phase.is_phase(phase_to_run) then
		logging.set_category(errors.failed_to_run_phase(self, phase_to_run))

		logging.report_error(errors.invalid_phase(phase_to_run))
		logging.flush()

		logging.end_category()
		return
	end

	local errors = logging.collect(function()
		for system in self.internal_system_state do
			if (is_internal_default_phase and system.phase == nil) or system.phase == phase then
				self:run_system(system)
			end
		end
	end)

	logging.flush(errors)
end

function set_default_phase<T, K...>(self: types.SchedulerInternal<T, K...>, new_phase: types.Phase)
	if globals.dev_mode and not phase.is_phase(new_phase) then
		logging.set_category(errors.failed_to_set_default_phase(self, new_phase))

		logging.report_error(errors.invalid_phase(new_phase))
		logging.flush()

		logging.end_category()
		return
	end

	self.internal_default_phase = new_phase
end

local template = {
	internal_default_phase = phase_std.on_init,
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
}

local meta = {
	__tostring = function(self)
		return `Scheduler({self.internal_default_phase})`
	end,
}

local function create_init<T...>(...: T...)
	local scheduler = table.clone(template)
	scheduler.internal_init_arguments = { ... }
	setmetatable(scheduler, meta)

	return scheduler :: types.Scheduler<T...>
end

local function create<T...>()
	local scheduler = table.clone(template)
	setmetatable(scheduler, meta)

	return template :: types.Scheduler<T...>
end

return {
	create = create,
	create_init = create_init,
}
