--!nonstrict
local cake = require("@self/dependencies/cake")
local jabby = require("@self/dependencies/jabby")
local types = require("@self/types")

local function system_function(scheduler: types.Scheduler<...unknown>, context: types.SystemContext)
	local display_name = scheduler:get_name()

	local jabby_scheduler = jabby.scheduler.create()
	local system_to_id = {}

	local function is_single_pass_system(system)
		local default_phase = scheduler:get_default_phase()
		local is_start_phase = system.phase == cake.phase_std.on_start or system.phase == cake.phase_std.pre_start
		local is_default_phase = system.phase == nil
		local is_default_on_start = default_phase == cake.phase_std.on_start or default_phase == cake.phase_std.pre_start

		return is_start_phase or (is_default_phase and is_default_on_start)
	end
	
	local function register_system(system)
		local default_phase = scheduler:get_default_phase()
		local id = jabby_scheduler:register_system({
			name = system.name,
			phase = if system.phase then system.phase.name else default_phase.name,
		})
		system_to_id[system] = id

		if is_single_pass_system(system) then
			jabby_scheduler:set_system_data(id, {
				paused = true,
			})
		end
	end

	for _, system in scheduler:get_systems() do
		register_system(system)
	end

	context.cleanup(scheduler:hook(cake.hooks.system_added, register_system))

	context.cleanup(scheduler:hook(cake.hooks.default_phase_changed, function()
		for system, id in system_to_id do
			jabby_scheduler:remove_system(id)
		end
		table.clear(system_to_id)

		for _, system in scheduler:get_systems() do
			register_system(system)
		end
	end))

	context.cleanup(scheduler:hook(cake.hooks.system_removed, function(system)
		local id = system_to_id[system]
		if id then
			jabby_scheduler:remove_system(id)
			system_to_id[system] = nil
		end
	end))

	context.cleanup(scheduler:hook(cake.hooks.system_call, function(system, _, call)
		local id = system_to_id[system]
		if not id then
			return
		end
		if is_single_pass_system(system) then
			return function()
				jabby_scheduler:set_system_data(id, {
					paused = false,
				})
				jabby_scheduler:run(id, call)
				jabby_scheduler:set_system_data(id, {
					paused = true,
				})
			end
		end

		return function()
			jabby_scheduler:run(id, call)
		end
	end))

	jabby.register({
		applet = jabby.applets.scheduler,
		name = display_name,
		configuration = {
			scheduler = jabby_scheduler,
		},
	})
end

return cake.system(system_function, "Initialize Jabby", cake.phase_std.pre_start)
