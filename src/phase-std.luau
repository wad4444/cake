local phase = require("./phase").create_phase

local on_start = phase("OnStart")
local on_stop = phase("OnStop")

return table.freeze({
	on_start = on_start,
	on_stop = on_stop,
})
