local errors = {
	failed_to_add_system = function(system: unknown)
		return `Failed to add {system}`
	end,
	failed_to_remove_system = function(scheduler: unknown, system: unknown)
		return `Failed to remove {system} from {scheduler}`
	end,
	failed_to_run_system = function(scheduler: unknown, system: unknown)
		return `Failed to run {system} in {scheduler}`
	end,
	failed_to_run_phase = function(scheduler: unknown, phase: unknown)
		return `Failed to run phase {phase} in {scheduler}`
	end,
	invalid_phase = function(phase: unknown)
		return `{phase} is not a valid phase object. Traceback:{debug.traceback("", 3)}`
	end,
	failed_to_transform = function(system: unknown)
		return `Failed to run transformation for {system}`
	end,
	failed_to_cache = function(system: unknown)
		return `Failed to cache {system}`
	end,
	failed_to_init = function(scheduler: unknown)
		return `Failed to initialize {scheduler}`
	end,
	failed_to_deinit = function(scheduler: unknown)
		return `Failed to deinitialize {scheduler}`
	end,
	invalid_cleanup_object = function(got: string)
		return `Expected Instance, thread, RBXScriptConnection, or function, got {got}`
	end,
	system_not_active = function(system: unknown)
		return `{system} isn't active in the scheduler`
	end,
	no_yielding_allowed = `No yielding allowed in the current environment`,
	already_initialized = `Tried to initialize scheduler twice`,
	not_initialized = `Scheduler isn't initialized`,
	default_error = function(err: unknown)
		return `An error has occured. Error: {err}`
	end,
}

return errors
