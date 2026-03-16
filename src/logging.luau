local types = require("./types")

local messages = require("./messages")
local nodes = require("./error-nodes")

local error_block_header = `[CAKE ERROR BLOCK]`
local error_block_footer = `[END OF BLOCK]`
local error_block_trivia = `[BLOCK TRIVIA]`

local category_stack: { string } = {}

local node_stack = nodes.node_stack
local append_node_stack = nodes.append_node_stack
local iterate = nodes.iterate
local collect = nodes.collect

local function report_error(error: string)
	local last_node = append_node_stack(node_stack.stack[node_stack.index], category_stack)
	table.insert(last_node.errors, error)
end

local function report_with_traceback(error: string, up: number?)
	up = up or 1
	local traceback = debug.traceback("", up + 1)
	report_error(messages.wrappers.traceback(error, traceback))
end

local function ast_to_string(node: types.ErrorNode, trivia_text: string?): string
	local error_str_buf = ""
	local longest_sym_count = 10

	for node, depth in iterate(node) do
		if not nodes.has_errors(node) then
			continue
		end

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
			local formatted_error = `{content_tab_offset}{string.gsub(error, "\n", `\n{content_tab_offset}`)}\n`
			local tabs_to_spaces = string.gsub(formatted_error, "\t", "    ")
			for _, part in string.split(tabs_to_spaces, "\n") do
				longest_sym_count = math.max(longest_sym_count, #part)
			end

			current_buf ..= formatted_error
		end

		error_str_buf ..= current_buf
	end

	-- 8 is basically "/*  " symbols * 2 , 0.7 is to account for slashes not being as fat on avg
	local base_count = math.round(longest_sym_count * 0.7) - 8
	local fsc_diff = math.round(math.abs(#error_block_header - #error_block_footer) / 2)
	local tsc_diff = math.round(math.abs(#error_block_header - #error_block_trivia) / 2)

	local hsc = base_count - #error_block_header -- header slash count
	local fsc = base_count - #error_block_footer - fsc_diff -- footer slash count
	local tsc = base_count - #error_block_trivia - tsc_diff -- trivia slash count

	local header = `\n/* {string.rep("-", hsc)} {error_block_header} {string.rep("-", hsc)} *\\\n`
	local footer = `/* {string.rep("-", fsc)} {error_block_footer} {string.rep("-", fsc)} *\\\n`
	local trivia = `/* {string.rep("-", tsc)} {error_block_trivia} {string.rep("-", tsc)} *\\\n`

	error_str_buf = header .. error_str_buf
	if trivia_text then
		error_str_buf ..= trivia .. trivia_text .. "\n"
	end
	error_str_buf ..= footer

	return error_str_buf
end

local function flush(trivia_text: string?)
	if node_stack.index ~= 1 then
		return
	end

	local node = node_stack.stack[1]
	if not nodes.has_errors(node) then
		return
	end

	warn(ast_to_string(node, trivia_text))
	nodes.clear_node(node)
end

local function set_category(category: string)
	table.insert(category_stack, category)
	return #category_stack
end

local function end_category()
	table.remove(category_stack)
end

local function propagate(node: types.ErrorNode)
	if node == node_stack.stack[node_stack.index] or nodes.is_empty(node) then
		return
	end

	nodes.merge_nodes(node_stack.stack[node_stack.index], node)
end

local function end_after_inclusive(index: number)
	if #category_stack < index then
		return
	end

	while category_stack[index] do
		table.remove(category_stack, index) -- array gets shifted atp
	end
end

return table.freeze({
	set_category = set_category,
	end_category = end_category,
	report_error = report_error,
	flush = flush,
	category_stack = category_stack,
	end_after_inclusive = end_after_inclusive,
	collect = collect,
	report_with_traceback = report_with_traceback,
	propagate = propagate,
})
