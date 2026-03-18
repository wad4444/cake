local system_client = require(script.client)
local system_server = require(script.server)

return table.freeze({
	initialize_client = system_client,
	initialize_server = system_server,
})
