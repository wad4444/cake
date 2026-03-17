return function(time: number)
	local pin: number

	local function throttle()
		if not pin then
			pin = os.clock()
		end

		local elapsed = os.clock() - pin > time
		if elapsed then
			pin = os.clock()
		end

		return elapsed
	end
	return throttle
end
