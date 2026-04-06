--!strict
-- NOTE: this file is currently for initial, rapid testing purposes and will be gone soon,
-- once the project makes it to initial release, i plan to add unit tests

local cake = require(game.ReplicatedStorage.cake)

local function sys_fn(context: cake.SystemContext)
    error("e"..math.random())
end

local scheduler = cake.scheduler<<()>>()
local f = scheduler:hook(cake.hooks.system_ran, function(system)
    
end)