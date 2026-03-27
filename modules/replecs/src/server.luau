local cake = require("./dependencies/cake")
local cake_runservice = require("./dependencies/cake-runservice")
local types = require("./types")

local jecs_utils = require("./dependencies/jecs-utils")
local collect = jecs_utils.collect :: types.Collect
local interval = jecs_utils.interval

local function system_fn_server(server: types.ReplecsServer, remotes: types.ServerRemotes, ctx: types.SystemContext)
	local updates_interval = interval(1 / 20)
	local unreliables_interval = interval(1 / 5)

	local request_fulls, cleanup_request_fulls = collect(remotes.request_full.OnServerEvent)
	ctx.cleanup(cleanup_request_fulls)

	return function()
		for _, player in request_fulls do
			if server:is_player_ready(player) then
				continue
			end

			server:mark_player_ready(player)
			local buffer, variants = server:get_full(player)

			remotes.send_full:FireClient(player, buffer, variants)
		end

		if updates_interval() then
			for player, buffer, variants in server:collect_updates() do
				remotes.send_updates:FireClient(player, buffer, variants)
			end
		end

		if unreliables_interval() then
			for player, buffer, variants in server:collect_unreliable() do
				remotes.send_unreliables:FireClient(player, buffer, variants)
			end
		end
	end
end

return cake.system(system_fn_server, "Replication (Server)", cake_runservice.phases.heartbeat)
