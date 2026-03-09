return function(name: string): { never }
	local symbol = newproxy(true)
	local meta = getmetatable(symbol)
	meta.__tostring = function()
		return `Symbol({name})`
	end
	meta.metatable = meta
	return symbol
end
