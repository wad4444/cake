local cake = require(game.ReplicatedStorage.cake)

local function sys_fn(context: cake.SystemContext)
    return function()
        error("test")
    end
end

local scheduler = cake.scheduler()
scheduler:init()

local sys = cake.system(sys_fn, "test")
scheduler:add_system(sys)

scheduler:run_system(sys)
scheduler:run_system(sys)

task.wait(11)

scheduler:run_system(sys)
scheduler:run_system(sys)