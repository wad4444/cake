local cake = require("./dependencies/cake")
local cake_runservice = require("./dependencies/cake-runservice")
local wcs_actions = require("./dependencies/wcs-actions")

return cake.system(wcs_actions.server_system, "WCS Actions (Server)", cake_runservice.phases.heartbeat)
