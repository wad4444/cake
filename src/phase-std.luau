local phase = require("./phase").create_phase

local on_start = phase("OnStart")
local on_stop = phase("OnStop")
local never = phase("Never")

return table.freeze({
	on_start = on_start,
	on_stop = on_stop,
	never = never,
})
