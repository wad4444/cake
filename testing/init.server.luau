local cake = require(game.ReplicatedStorage.cake)

function system_fn(n: number, ctx: cake.SystemContext)
    print("init")
    return function()
        error(`{math.random(1, 3)}`)
    end
end


local phase = cake.phase("TSETT")

local system = cake.system(system_fn, "Test", phase)
local sys2 = cake.system(system_fn, "Test2", phase)

local scheduler = cake.scheduler<<(number)>>()
scheduler:init(1)

scheduler:add_system(system)
scheduler:add_system(sys2)

scheduler:run_phase(phase)
