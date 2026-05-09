--!strict

return function(value: number): string
	local rounded = math.floor(math.abs(value))
	local digits = tostring(rounded)
	local grouped = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()

	if string.sub(grouped, 1, 1) == "," then
		grouped = string.sub(grouped, 2)
	end

	if value < 0 then
		return `-{grouped}`
	end

	return grouped
end
