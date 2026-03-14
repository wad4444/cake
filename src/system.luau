local types = require("./types")
local create_symbol = require("./symbol")

local symbol = create_symbol("System")

function create_system<T...>(
	system: types.SystemFunction<T...>,
	name: string?,
	phase: types.Phase?
): types.SystemTable<types.SystemFunction<T...>>
	name = name or `System ({tostring(system)})`

	local system_table = {
		system = system,
		name = name,
		phase = phase,
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

function is_system(system: unknown): boolean
	return type(system) == "table" and (system :: any).symbol == symbol
end

return {
	create_system = create_system,
	is_system = is_system,
}
