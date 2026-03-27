export type ReplecsClient = typeof((function()
	local module = require(script.Parent.Parent.replecs)
	return (nil :: any) :: module.Client
end)())

export type ReplecsServer = typeof((function()
	local module = require(script.Parent.Parent.replecs)
	return (nil :: any) :: module.Server
end)())

export type SystemContext = typeof((function()
	local module = require(script.Parent.Parent.cake)
	return (nil :: any) :: module.SystemContext
end)())

export type ServerEventLike<T... = ()> = {
	OnServerEvent: RBXScriptSignal<(Player, T...)>,
	FireClient: (self: ServerEventLike<T...>, player: Player, T...) -> (),
}

export type ClientEventLike<T... = ()> = {
	OnClientEvent: RBXScriptSignal<T...>,
	FireServer: (self: ClientEventLike<T...>, T...) -> (),
}

export type ServerRemotes = {
	read request_full: ServerEventLike,
	read send_full: ServerEventLike<buffer, { { any } }?>,
	read send_unreliables: ServerEventLike<buffer, { { any } }?>,
	read send_updates: ServerEventLike<buffer, { { any } }?>,
}

export type ClientRemotes = {
	read request_full: ClientEventLike,
	read send_full: ClientEventLike<buffer, { { any } }?>,
	read send_unreliables: ClientEventLike<buffer, { { any } }?>,
	read send_updates: ClientEventLike<buffer, { { any } }?>,
}

export type Collect = <T...>(event: RBXScriptSignal<T...>) -> (() -> (number, T...), () -> ())

return nil
