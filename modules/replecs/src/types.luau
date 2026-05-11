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

export type Collect = <T...>(event: RBXScriptSignal<T...>) -> (() -> (number, T...), () -> ())

return nil
