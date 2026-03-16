local messages = {
	categories = {
		failed_to_add_system = function(system: unknown)
			return `Failed to add {system}`
		end,
		failed_to_add_systems = `Failed to add systems`,
		failed_to_remove_system = function(scheduler: unknown, system: unknown)
			return `Failed to remove {system} from {scheduler}`
		end,
		failed_to_run_system = function(scheduler: unknown, system: unknown)
			return `Failed to run {system} in {scheduler}`
		end,
		failed_to_run_phase = function(scheduler: unknown, phase: unknown)
			return `Failed to run phase {phase} in {scheduler}`
		end,
		failed_to_set_default_phase = function(scheduler: unknown, phase: unknown)
			return `Failed to set default phase {phase} in {scheduler}`
		end,
		failed_to_start = function(scheduler: unknown)
			return `Failed to start {scheduler}`
		end,
		failed_to_transform = function(system: unknown)
			return `Failed to run transformation for {system}`
		end,
		failed_to_init = function(scheduler: unknown)
			return `Failed to initialize {scheduler}`
		end,
		failed_to_deinit = function(scheduler: unknown)
			return `Failed to deinitialize {scheduler}`
		end,
	},
	errors = {
		invalid_phase = function(phase: unknown)
			return `{phase} is not a valid phase object`
		end,
		invalid_system = function(system: unknown)
			return `{system} is not a valid system object`
		end,
		invalid_cleanup_object = function(got: string)
			return `Expected Instance, thread, RBXScriptConnection, or function, got {got}`
		end,
		system_not_active = function(system: unknown)
			return `{system} isn't active in the scheduler`
		end,
		no_yielding_allowed = `Yielding is disallowed in the current environment`,
		already_initialized = `Tried to initialize scheduler twice`,
		not_initialized = `Scheduler isn't initialized`,
		not_started = `Scheduler isn't started`,
		already_started = `Scheduler is already started`,
		ignore_error = function(seconds: number)
			return `Following error will be ignored for the next {seconds} second{if seconds ~= 1 then "s" else ""}....`
		end,
		ignore_errors = function(seconds: number)
			return `Following errors will be ignored for the next {seconds} second{if seconds ~= 1 then "s" else ""}...`
		end,
		tried_ran_never = `Cannot run Phase(Never), it's purpose is to never be ran.`,
		only_in_dev_mode = `This error will only be shown in development mode, that is on in studio by default.\nYou can change this behavior by setting 'dev_mode' in scheduler globals.`,
		default_error = function(err: unknown)
			return `An error has occured. Error:\n{err}`
		end,
		combine_failed = function(array: { any })
			return `Failed to combine {array} into a tuple, the table is too big! Must be <9 elements`
		end,
	},
	wrappers = {
		sln = function(err: unknown, source: string, name: string?)
			if name ~= "" and source ~= nil then
				return `{err}.\nFunction {name} defined at: {source}`
			elseif source ~= nil then
				return `{err}.\nAnonymous function defined at: {source}`
			end

			return `{err}.`
		end,
		traceback = function(err: unknown, traceback: string)
			traceback = string.sub(traceback, 2, -2) -- for some reason traceback includes a newline at the start and the end
			return `{err}. Traceback:\n{traceback}`
		end,
	},
}

table.freeze(messages.categories)
table.freeze(messages.errors)
table.freeze(messages.wrappers)

return table.freeze(messages)
