local types = require("./types")

local error_list = require("./errors")
local nodes = require("./error-nodes")
local globals = require("./globals")

local error_block_header = `[CAKE ERROR BLOCK]`
local error_block_footer = `[END OF BLOCK]`
local error_block_trivia = `[BLOCK TRIVIA]`

local category_stack: { string } = {}

local node_stack = nodes.node_stack
local append_node_stack = nodes.append_node_stack
local traverse = nodes.traverse
local collect = nodes.collect

local function report_error(error: string)
	local last_node = append_node_stack(node_stack.stack[node_stack.index], category_stack)
	table.insert(last_node.errors, error)
end

local function ast_to_string(node: types.ErrorNode, trivia_text: string?): string
	local error_str_buf = ""
	local longest_sym_count = 10

	traverse(node, function(node, depth)
		local tab_offset = string.rep("\t", depth - 1)
		local content_tab_offset = string.rep("\t", depth + if node.category then 0 else -1)

		local current_buf = ""
		if node.category then
			local category_header = `{tab_offset}* {node.category}:\n`
			local header_length = #string.gsub(category_header, "\t", "    ")

			longest_sym_count = math.max(longest_sym_count, header_length)
			current_buf = category_header
		end

		for _, error in node.errors do
			current_buf ..= `{content_tab_offset}{string.gsub(error, "\n", `\n{content_tab_offset}`)}\n`
		end

		error_str_buf ..= current_buf
	end)

	local base_count = math.round(longest_sym_count * 0.65) - 8 -- 8 is basically "/*  " symbols * 2 , 0.65 is to account for slashes not being as fat on avg
	local fsc_diff = math.round(math.abs(#error_block_header - #error_block_footer) / 2)
	local tsc_diff = math.round(math.abs(#error_block_header - #error_block_trivia) / 2)

	local hsc = base_count - #error_block_header -- header slash count
	local fsc = base_count - #error_block_footer - fsc_diff -- footer slash count
	local tsc = base_count - #error_block_trivia - tsc_diff -- trivia slash count

	local header = `\n/* {string.rep("-", hsc)} {error_block_header} {string.rep("-", hsc)} */\n`
	local footer = `/* {string.rep("-", fsc)} {error_block_footer} {string.rep("-", fsc)} */\n`
	local trivia = `/* {string.rep("-", tsc)} {error_block_trivia} {string.rep("-", tsc)} */\n`

	error_str_buf = header .. error_str_buf
	if trivia_text then
		error_str_buf ..= trivia .. trivia_text .. "\n"
	end
	error_str_buf ..= footer

	return error_str_buf
end

local function flush_node(node: types.ErrorNode, trivia_text: string?)
	if #node.children == 0 and #node.errors == 0 then
		return
	end

	warn(ast_to_string(node, trivia_text))

	table.clear(node.children)
	table.clear(node.errors)
	node.category = nil
end

local function flush(trivia_text: string?)
	if node_stack.index ~= 1 then
		return
	end

	flush_node(node_stack.stack[1], trivia_text)
	table.clear(category_stack)
end

local function format_err_std(err: unknown, source: string, line: number, name: string?)
	if name ~= "" then
		return `{err}.\nFunction {name} defined at: {source}:{line}`
	end

	return `{err}.\nAnonymous function defined at: {source}:{line}`
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
		local error = table.remove(result, 1)
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
	table.insert(category_stack, category)
end

local function end_category()
	table.remove(category_stack)
end

return {
	set_category = set_category,
	end_category = end_category,
	report_error = report_error,
	flush = flush,
	flush_node = flush_node,
	try_run = try_run,
	try_run_pack_args = try_run_pack_args,
	collect = collect,
	category_stack = category_stack,
}
