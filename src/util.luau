local types = require("./types")
local logging = require("./logging")
local errors = require("./messages")
local try = require("./try")

local function noop() end

local function cleanup_single(object: types.Cleanuppable)
	if typeof(object) == "Instance" then
		object:Destroy()
	elseif typeof(object) == "thread" then
		task.cancel(object)
	elseif typeof(object) == "RBXScriptConnection" then
		object:Disconnect()
	elseif typeof(object) == "function" then
		try.try_run(object)
	end

	logging.report_error(errors.errors.invalid_cleanup_object(typeof(object)))
	return
end

local function combine_into_tuple(array: { any }, value: any)
	local a, b, c, d, e, f, g, h, i, j = table.unpack(array)
	if not a then
		return value
	end
	if not b then
		return a, value
	end
	if not c then
		return a, b, value
	end
	if not d then
		return a, b, c, value
	end
	if not e then
		return a, b, c, d, value
	end
	if not f then
		return a, b, c, d, e, value
	end
	if not g then
		return a, b, c, d, e, f, value
	end
	if not h then
		return a, b, c, d, e, f, g, value
	end
	if not i then
		return a, b, c, d, e, f, g, h, value
	end
	if not j then
		return a, b, c, d, e, f, g, h, i, value
	end

	error(errors.errors.combine_failed(array)) -- hack: will get caught by xpcall error handler
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

return table.freeze({
	cleanup = cleanup,
	noop = noop,
	cleanup_single = cleanup_single,
	build_cleanup_function = build_cleanup_function,
	combine_into_tuple = combine_into_tuple,
})
