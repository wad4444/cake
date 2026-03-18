local cake = require(script.Parent.Parent.cake)
local cake_runservice = require(script.Parent.Parent["cake-runservice"])
local types = require(script.Parent.types)

local function system_fn_client(client: types.ReplecsClient, remotes: types.Remotes, ctx: cake.SystemContext)
	if game:IsLoaded() then
		remotes.request_full.fire()
	else
		local connection = game.Loaded:Once(remotes.request_full.fire)
		ctx.cleanup(connection)
	end

	return function()
		for _, buffer, variants in remotes.send_full.collect do
			client:apply_full(buffer, variants)
		end

		for _, buffer, variants in remotes.send_unreliables.collect do
			client:apply_unreliable(buffer, variants)
		end

		for _, buffer, variants in remotes.send_updates.collect do
			client:apply_updates(buffer, variants)
		end
	end
end

return cake.system(system_fn_client, "Replication (Client)", cake_runservice.phases.heartbeat)
