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

local function traverse(node: types.ErrorNode, fn: (node: types.ErrorNode, depth: number) -> (), depth: number?)
	depth = depth or 0

	fn(node, depth)
	for _, child in node.children do
		traverse(child, fn, depth + 1)
	end
end

local function strip_empty(node: types.ErrorNode)
	if is_empty(node) then
		return node
	end

	local children_to_strip = {}
	for i, child in node.children do
		local has_errors = false
		traverse(child, function(node)
			if #node.errors > 0 then
				has_errors = true
			end
		end)

		if not has_errors then
			table.insert(children_to_strip, child)
		end
	end

	for _, child in children_to_strip do
		table.remove(node.children, table.find(node.children, child))
	end

	return node
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

return {
	collect = collect,
	append_node_stack = append_node_stack,
	traverse = traverse,
	is_empty = is_empty,
	strip_empty = strip_empty,
	node_stack = node_stack,
}
