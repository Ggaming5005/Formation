--!strict
export type Slot = { x: number, z: number }
export type Options = { Formation: string, Columns: number, Spacing: number, Distance: number }
local Layout = {}

function Layout.compute(diameters: { number }, options: Options): { Slot }
	local slots: { Slot } = {}
	if #diameters == 0 then
		return slots
	end
	if options.Formation == "Rows" then
		local cursor = 1
		local z = options.Distance
		local previousDepth = 0
		while cursor <= #diameters do
			local last = math.min(cursor + options.Columns - 1, #diameters)
			local width, depth = 0, 0
			for i = cursor, last do
				width += diameters[i]
				depth = math.max(depth, diameters[i])
			end
			width += options.Spacing * (last - cursor)
			if cursor > 1 then
				z += previousDepth / 2 + depth / 2 + options.Spacing
			end
			local x = -width / 2
			for i = cursor, last do
				slots[i] = { x = x + diameters[i] / 2, z = z }
				x += diameters[i] + options.Spacing
			end
			previousDepth = depth
			cursor = last + 1
		end
		return slots
	end
	if #diameters == 1 then
		return { { x = 0, z = options.Distance } }
	end
	local maximum = 0
	for _, diameter in diameters do
		maximum = math.max(maximum, diameter)
	end
	local orbit = options.Formation == "Orbit"
	local span = if orbit then math.pi * 2 else math.rad(145)
	local gaps = {}
	for i = 1, if orbit then #diameters else #diameters - 1 do
		gaps[i] = (diameters[i] + diameters[i % #diameters + 1]) / 2 + options.Spacing
	end
	local function angularSpan(radius: number): number
		local total = 0
		for _, gap in gaps do
			total += 2 * math.asin(math.min(1, gap / (2 * radius)))
		end
		return total
	end
	local low = math.max(options.Distance, maximum + options.Spacing)
	local high = low
	while angularSpan(high) > span do high *= 2 end
	for _ = 1, 24 do
		local mid = (low + high) / 2
		if angularSpan(mid) > span then low = mid else high = mid end
	end
	local radius = high
	local used = angularSpan(radius)
	local slack = if orbit then (span - used) / #diameters else 0
	local angle = if orbit then 0 else -used / 2
	for i = 1, #diameters do
		slots[i] = { x = math.sin(angle) * radius, z = math.cos(angle) * radius }
		if gaps[i] then angle += 2 * math.asin(math.min(1, gaps[i] / (2 * radius))) + slack end
	end
	-- A small model between two large ones can make nonadjacent footprints touch.
	local expansion = 1
	for i = 1, #diameters - 1 do
		for j = i + 1, #diameters do
			local dx, dz = slots[i].x - slots[j].x, slots[i].z - slots[j].z
			local required = (diameters[i] + diameters[j]) / 2 + options.Spacing
			expansion = math.max(expansion, required / math.sqrt(dx * dx + dz * dz))
		end
	end
	if expansion > 1 then
		for _, slot in slots do
			slot.x *= expansion
			slot.z *= expansion
		end
	end
	return slots
end

return Layout
