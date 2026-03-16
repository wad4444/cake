local types = require("./types")

local node_stack = {
	stack = table.create(10) :: { types.ErrorNode },
	index = 1,
}

for i = 1, 10 do
	table.insert(
		node_stack.stack,
		{
			errors = {},
			category = nil,
			children = {},
		} :: types.ErrorNode
	)
end

local function append_node_stack(node: types.ErrorNode, category_stack: { string })
	local current_node = node
	local depth = 0

	while current_node do
		local category = category_stack[depth + 1]
		if not category then
			break
		end

		depth += 1

		local next_node
		for _, child in current_node.children do
			if child.category == category then
				next_node = child
				break
			end
		end

		if next_node then
			current_node = next_node
			continue
		end

		local new_node: types.ErrorNode = {
			category = category,
			errors = {},
			children = {},
		}

		table.insert(current_node.children, new_node)
		current_node = new_node
	end

	return current_node
end

local function is_empty(node: types.ErrorNode)
	return #node.children == 0 and #node.errors == 0
end

local function iterate(node: types.ErrorNode): () -> (types.ErrorNode, number)
	local stack = { node, 0 }

	return function(): (types.ErrorNode, number)
		local len = #stack
		if len == 0 then
			return nil :: any, nil :: any
		end

		local depth = stack[len] :: number
		local current = stack[len - 1] :: types.ErrorNode
		stack[len] = nil
		stack[len - 1] = nil

		local children = current.children
		for i = #children, 1, -1 do
			local new_len = #stack
			stack[new_len + 1] = children[i]
			stack[new_len + 2] = depth + 1
		end

		return current, depth
	end
end

local function collect(fn: () -> ())
	node_stack.index += 1

	local node = node_stack.stack[node_stack.index]
	if not node then
		node = {
			errors = {},
			category = nil,
			children = {},
		} :: types.ErrorNode
		table.insert(node_stack.stack, node)
	end

	fn()

	node_stack.index -= 1
	return node
end

local function has_errors(node: types.ErrorNode)
	if #node.errors == 0 and #node.children == 0 then
		return false
	end

	for node in iterate(node) do
		if #node.errors > 0 then
			return true
		end
	end

	return false
end

return table.freeze({
	collect = collect,
	append_node_stack = append_node_stack,
	iterate = iterate,
	is_empty = is_empty,
	has_errors = has_errors,
	node_stack = node_stack,
})
