export type ReplecsClient = typeof((function()
	local module = require(script.Parent.Parent.replecs)
	return (nil :: any) :: module.Client
end)())

export type ReplecsServer = typeof((function()
	local module = require(script.Parent.Parent.replecs)
	return (nil :: any) :: module.Server
end)())

type ServerEventLike<T... = ()> = {
	read fire: (T...) -> (),
	read collect: () -> (number, Player, T...),
}

type ClientEventLike<T... = ()> = {
	read fire: (Player, T...) -> (),
	read collect: () -> (number, T...),
}

export type Remotes = {
	read request_full: ServerEventLike,
	read send_full: ClientEventLike<buffer, { { any } }?>,
	read send_unreliables: ClientEventLike<buffer, { { any } }?>,
	read send_updates: ClientEventLike<buffer, { { any } }?>,
}

return nil
