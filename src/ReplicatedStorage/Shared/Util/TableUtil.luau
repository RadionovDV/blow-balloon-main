local TableUtil = {}

function TableUtil.DeepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = TableUtil.DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

function TableUtil.Contains(t, value)
	for _, v in ipairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

function TableUtil.Find(t, predicate)
	for _, v in ipairs(t) do
		if predicate(v) then
			return v
		end
	end
	return nil
end

function TableUtil.Filter(t, predicate)
	local result = {}
	for _, v in ipairs(t) do
		if predicate(v) then
			table.insert(result, v)
		end
	end
	return result
end

function TableUtil.Sum(t)
	local total = 0
	for _, v in ipairs(t) do
		total = total + v
	end
	return total
end

return TableUtil