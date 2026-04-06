local symbol = require("./symbol")

return table.freeze({
	system_ran = symbol<<"Hook (system_ran)">>("Hook (system_ran)"),
	phase_ran = symbol<<"Hook (phase_ran)">>("Hook (phase_ran)"),
	system_added = symbol<<"Hook (system_added)">>("Hook (system_added)"),
	system_removed = symbol<<"Hook (system_removed)">>("Hook (system_removed)"),
	default_phase_changed = symbol<<"Hook (default_phase_changed)">>("Hook (default_phase_changed)"),
})
