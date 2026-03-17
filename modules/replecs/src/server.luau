local cake = require(script.Parent.Parent.cake)
local cake_runservice = require(script.Parent.Parent["cake-runservice"])
local interval = require(script.Parent.interval)
local types = require(script.Parent.types)

local function system_fn_server(server: types.ReplecsServer, remotes: types.Remotes)
	local updates_interval = interval(1 / 20)
	local unreliables_interval = interval(1 / 5)

	return function()
		for _, player in remotes.request_full.collect do
			if server:is_player_ready(player) then
				continue
			end

			server:mark_player_ready(player)
			local buffer, variants = server:get_full(player)

			remotes.send_full.fire(player, buffer, variants)
		end

		if updates_interval() then
			for player, buffer, variants in server:collect_updates() do
				remotes.send_updates.fire(player, buffer, variants)
			end
		end

		if unreliables_interval() then
			for player, buffer, variants in server:collect_unreliable() do
				remotes.send_unreliables.fire(player, buffer, variants)
			end
		end
	end
end

return cake.system(system_fn_server, "Replication (Server)", cake_runservice.phases.heartbeat)
