local types = require("./types")
local create_symbol = require("./symbol")

local symbol = create_symbol("System")

function create_phase(name: string): types.Phase
	local phase_table = {
		name = name,
		symbol = symbol,
	}
	setmetatable(phase_table, {
		__tostring = function(self)
			return `Phase ({self.name})`
		end,
	})

	return table.freeze(phase_table)
end

return {
	create_phase = create_phase,
	symbol = symbol,
}
