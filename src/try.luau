local globals = require("./globals")
local messages = require("./messages")
local logging = require("./logging")

local function run_error_handling_no_yield<T..., V...>(fn: (T...) -> V..., ...: T...): (boolean, V...)
	if not globals.dev_mode then
		return xpcall(fn, function(error)
			local source, name = debug.info(1, "sn")
			logging.report_error(messages.wrappers.sln(messages.errors.default_error(error), source, name))
		end, ...)
	end

	local thread = coroutine.create(fn)
	local result = { coroutine.resume(thread, ...) } :: { unknown }

	local success = table.remove(result, 1)
	if not success then
		local error = table.remove(result, 1)
		local source, name = debug.info(thread, 1, "sn")
		logging.report_error(messages.wrappers.sln(messages.errors.default_error(error), source, name))
		return false, nil :: any
	end

	if coroutine.status(thread) == "suspended" then
		local source, name = debug.info(thread, 1, "sn")
		logging.report_error(messages.wrappers.sln(messages.errors.no_yielding_allowed, source, name))
		return false, nil :: any
	end

	return true, table.unpack(result :: any)
end

local function try_run<T..., V...>(fn: (T...) -> V..., ...: T...)
	return run_error_handling_no_yield(fn, ...)
end

local function try_run_pack_args<T...>(fn: (T...) -> ...any, ...: T...): (boolean, { unknown })
	local result = { run_error_handling_no_yield(fn, ...) }

	local success = table.remove(result, 1) :: boolean
	return success, result :: { unknown }
end

return table.freeze({
	try_run = try_run,
	try_run_pack_args = try_run_pack_args,
})
