local cake = require(game.ReplicatedStorage.cake)

function sys_fn(context: cake.SystemContext)
    print(context.delta_time)
end

local scheduler = cake.scheduler()
scheduler:init()

local sys = cake.system(sys_fn, "test")
scheduler:add_system(sys)