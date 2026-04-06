export type Scheduler<T...> = typeof((function()
	local module = require(script.Parent.Parent.cake)
	return (nil :: any) :: module.Scheduler<T...>
end)())

export type SystemContext = typeof((function()
	local module = require(script.Parent.Parent.cake)
	return (nil :: any) :: module.SystemContext
end)())

export type SystemTable<T> = typeof((function()
	local module = require(script.Parent.Parent.cake)
	return (nil :: any) :: module.SystemTable<T>
end)())

export type UnknownSystemTable = SystemTable<(...unknown) -> ...unknown>

return nil
