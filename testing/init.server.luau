-- NOTE: this file is currently for initial, rapid testing purposes and will be gone soon,
-- once the project makes it to initial release, i plan to add unit tests

local cake = require(game.ReplicatedStorage.cake)

local function sys_fn(context: cake.SystemContext)
    error("e"..math.random())
end

local scheduler = cake.scheduler()
scheduler:init()

local phase = cake.phase("hey")

local sys = cake.system(sys_fn, "test", phase)
local sys2 = cake.system(sys_fn, "test2", phase)
scheduler:start()
scheduler:set_default_phase(phase)

scheduler:add_system(sys)
scheduler:add_system(sys2)

scheduler:run_phase(phase)