local types = require("./types")
local logging = require("./logging")
local errors = require("./errors")

local function noop() end

local function cleanup_single(object: types.Cleanuppable)
	if typeof(object) == "Instance" then
		object:Destroy()
	elseif typeof(object) == "thread" then
		task.cancel(object)
	elseif typeof(object) == "RBXScriptConnection" then
		object:Disconnect()
	elseif typeof(object) == "function" then
		object()
	end

	logging.report_error(errors.invalid_cleanup_object(typeof(object)))
	return
end

local function build_cleanup_function(to_cleanup: { types.Cleanuppable })
	return function(cleanuppable: types.Cleanuppable)
		table.insert(to_cleanup, cleanuppable)
		return function()
			local found_index = table.find(to_cleanup, cleanuppable)
			if found_index then
				table.remove(to_cleanup, found_index)
			end
		end
	end
end

local function cleanup(to_cleanup: { types.Cleanuppable })
	for _, cleanuppable in to_cleanup do
		cleanup_single(cleanuppable)
	end
	table.clear(to_cleanup)
end

return {
	cleanup = cleanup,
	noop = noop,
	cleanup_single = cleanup_single,
	build_cleanup_function = build_cleanup_function,
}
