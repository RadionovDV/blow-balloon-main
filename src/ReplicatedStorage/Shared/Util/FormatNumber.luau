local FormatNumber = {}

local SUFFIXES = { "B", "M", "K" }
local THRESHOLDS = { 1e9, 1e6, 1e3 }

function FormatNumber.Format(value: number): string
	local absVal = math.abs(value)
	for i, threshold in ipairs(THRESHOLDS) do
		if absVal >= threshold then
			local formatted = string.format("%.1f", value / threshold)
			return formatted .. SUFFIXES[i]
		end
	end
	return tostring(math.floor(value))
end

function FormatNumber.FormatTime(totalSeconds: number): string
	totalSeconds = math.max(0, math.floor(totalSeconds))
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local secs = totalSeconds % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	else
		return string.format("%02d:%02d", minutes, secs)
	end
end

return FormatNumber