local cake = require("./dependencies/cake")
local cake_runservice = require("./dependencies/cake-runservice")
local types = require("./types")

local collect = require("./dependencies/jecs-utils").collect :: types.Collect

local function system_fn_client(client: types.ReplecsClient, remotes: types.ClientRemotes, ctx: types.SystemContext)
	local send_fulls, cleanup_send_fulls = collect(remotes.send_full.OnClientEvent)
	local send_unreliables, cleanup_send_unreliables = collect(remotes.send_unreliables.OnClientEvent)
	local send_updates, cleanup_send_updates = collect(remotes.send_updates.OnClientEvent)

	if game:IsLoaded() then
		remotes.request_full:FireServer()
	else
		local connection = game.Loaded:Once(function()
			remotes.request_full:FireServer()
		end)
		ctx.cleanup(connection)
	end

	ctx.cleanup(function()
		cleanup_send_fulls()
		cleanup_send_unreliables()
		cleanup_send_updates()
	end)

	return function()
		for _, buffer, variants in send_fulls do
			client:apply_full(buffer, variants)
		end

		for _, buffer, variants in send_unreliables do
			client:apply_unreliable(buffer, variants)
		end

		for _, buffer, variants in send_updates do
			client:apply_updates(buffer, variants)
		end
	end
end

return cake.system(system_fn_client, "Replication (Client)", cake_runservice.phases.heartbeat)
