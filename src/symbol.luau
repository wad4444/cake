return function<T>(name: string & T): { __do_not_use_this_or_you_will_be_fired: T }
	local symbol = newproxy(true)
	local meta = getmetatable(symbol)
	meta.__tostring = function()
		return `Symbol({name})`
	end
	meta.metatable = meta
	return symbol
end
