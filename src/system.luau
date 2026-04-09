local types = require("./types")
local create_symbol = require("./symbol")

local symbol = create_symbol("System")

local function create_system<T...>(
	system: types.SystemFunction<T...>,
	name: string?,
	phase: types.Phase?,
	priority: number?
): types.SystemTable<types.SystemFunction<T...>>
	name = name or `System ({tostring(system)})`

	local system_table = {
		system = system,
		name = name,
		phase = phase,
		priority = priority or 0,
		symbol = symbol,
	}
	setmetatable(system_table, {
		__tostring = function(self)
			if phase then
				return `System({self.name}, {self.phase})`
			end
			return `System({self.name})`
		end,
	})

	return table.freeze(system_table)
end

local function is_system(system: unknown): boolean
	return type(system) == "table" and (system :: any).symbol == symbol
end

return table.freeze({
	create_system = create_system,
	is_system = is_system,
})
