local phase = require("./phase").create_phase

local on_init = phase("OnInit")
local on_deinit = phase("OnDeinit")

return table.freeze({
	on_init = on_init,
	on_deinit = on_deinit,
})
