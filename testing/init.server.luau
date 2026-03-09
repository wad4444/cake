local cake = require(game.ReplicatedStorage.cake)

function system_fn(n: number, ctx: cake.SystemContext)
    error("waduhn")
    return function()
        print(ctx.delta_time)
    end
end

local system = cake.system(system_fn, "Test")
local scheduler = cake.scheduler<<(number)>>()
scheduler:init(1)
scheduler:add_system(system)