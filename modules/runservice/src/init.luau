local run_service = game:GetService("RunService")
local cake = require(script.Parent.cake)

local phases = table.freeze({
	pre_render = cake.phase("PreRender"),
	pre_simulation = cake.phase("PreSimulation"),
	pre_animation = cake.phase("PreAnimation"),
	post_simulation = cake.phase("PostSimulation"),
	heartbeat = cake.phase("Heartbeat"),
})

local function system_function(scheduler: cake.Scheduler<...unknown>, context: cake.SystemContext)
	context.cleanup(run_service.PreRender:Connect(function()
		scheduler:run_phase(phases.pre_render)
	end))

	context.cleanup(run_service.PreSimulation:Connect(function()
		scheduler:run_phase(phases.pre_simulation)
	end))

	context.cleanup(run_service.PreAnimation:Connect(function()
		scheduler:run_phase(phases.pre_animation)
	end))

	context.cleanup(run_service.PostSimulation:Connect(function()
		scheduler:run_phase(phases.post_simulation)
	end))

	context.cleanup(run_service.Heartbeat:Connect(function()
		scheduler:run_phase(phases.heartbeat)
	end))
end

local system = cake.system(
    system_function,
    "Initialize RunService",
    cake.phase_std.on_start
)

return table.freeze({
    initialize_runservice = system,
    phases = phases,
})