local cake = require(game.ReplicatedStorage.cake)

local function sys_fn(context: cake.SystemContext)
    print("yay")
end

local scheduler = cake.scheduler()
scheduler:init()

local sys = cake.system(sys_fn, "test")
scheduler:start()
scheduler:add_system(sys)

scheduler:run_system(sys)
scheduler:run_system(sys)
