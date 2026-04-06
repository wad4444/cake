local types = require("@self/types")
local system = require("@self/system")
local scheduler = require("@self/scheduler")
local phase_std = require("@self/phase-std")
local phase = require("@self/phase")
local globals = require("@self/globals")
local hooks = require("@self/hooks")

export type SystemContext = types.SystemContext
export type SystemTable<T> = types.SystemTable<T>
export type Phase = types.Phase
export type SystemFunction<T...> = types.SystemFunction<T...>
export type Scheduler<T...> = types.Scheduler<T...>
export type Hook = types.Hook

local cake = {
	system = system.create_system,
	scheduler = scheduler.create,
	scheduler_init = scheduler.create_init,
	phase = phase.create_phase,

	phase_std = phase_std,
	globals = globals,
	hooks = hooks,
}
cake.default = cake

return table.freeze(cake)
