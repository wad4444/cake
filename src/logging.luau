local types = require("./types")
local error_list = require("./errors")
local globals = require("./globals")

local error_block_prefix = "\n/* Cake has caught the following errors in your code: */\n"
local error_block_trivia = "\n/* End of cake error block */\n"

local categories: { string } = {}
local errors: { types.ErrorObject } = {}
local collect_stack: { { types.ErrorObject } } = {}

local function create_error(error: string): types.ErrorObject
	return {
		error = error,
		context = categories[#categories],
	}
end

local function report_error(error: string)
	local error_object = create_error(error)

	if #collect_stack > 0 then
		table.insert(collect_stack[#collect_stack], error_object)
	else
		table.insert(errors, error_object)
	end
end

local function flush(errors_to_flush: { types.ErrorObject }?)
	errors_to_flush = errors_to_flush or errors
	if #errors_to_flush == 0 then
		return
	end

	local error_str = error_block_prefix
	for index, error in errors_to_flush do
		local current_error_str = if error.context then ` {index}. {error.context}:\n` else ``
		current_error_str ..= `\t{string.gsub(error.error, "\n", `\n\t`)}`

		error_str ..= current_error_str
		if index ~= #errors_to_flush then
			error_str ..= "\n"
		end
	end

	table.clear(errors_to_flush)
	error_str ..= error_block_trivia

	warn(error_str)
end

local function format_err_std(err: unknown, source: string, line: number, name: string?)
	return `{err}.\nFunction defined at: {source}:{line}{if name then `\n function {name}` else ""}`
end

local function run_error_handling_no_yield<T..., V...>(fn: (T...) -> V..., ...: T...): (boolean, V...)
	if not globals.dev_mode then
		return xpcall(fn, function(error)
			local source, line, name = debug.info(1, "sln")
			report_error(format_err_std(error_list.default_error(error), source, line, name))
		end, ...)
	end

	local thread = coroutine.create(fn)
	local result = { coroutine.resume(thread, ...) } :: { unknown }

	local success = table.remove(result, 1)
	if not success then
		local error = table.remove(result, 2)
		local source, line, name = debug.info(thread, 1, "sln")
		report_error(format_err_std(error_list.default_error(error), source, line, name))
		return false, nil :: any
	end

	if coroutine.status(thread) == "suspended" then
		local source, line, name = debug.info(thread, 1, "sln")
		report_error(format_err_std(error_list.no_yielding_allowed, source, line, name))
		return false, nil :: any
	end

	return true, table.unpack(result) :: any
end

local function try_run<T..., V...>(fn: (T...) -> V..., ...: T...)
	return run_error_handling_no_yield(fn, ...)
end

local function try_run_pack_args<T...>(fn: (T...) -> ...any, ...: T...): (boolean, { unknown })
	local result = { run_error_handling_no_yield(fn, ...) }

	local success = table.remove(result, 1) :: boolean
	return success, result :: { unknown }
end

local function set_category(category: string)
	table.insert(categories, category)
end

local function end_category()
	table.remove(categories)
end

local function collect(fn: () -> ()): { types.ErrorObject }
	local errors: { types.ErrorObject } = {}
	table.insert(collect_stack, errors)

	try_run(fn)

	table.remove(collect_stack)
	return errors
end

return {
	set_category = set_category,
	end_category = end_category,
	report_error = report_error,
	flush = flush,
	try_run = try_run,
	create_error = create_error,
	try_run_pack_args = try_run_pack_args,
	collect = collect,
}
