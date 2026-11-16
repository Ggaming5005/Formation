local Layout = require("../src/Layout")
local Settings = require("../src/Settings")
local checks = 0
local function check(ok, message)
	assert(ok, message)
	checks += 1
end
local function rejects(callback)
	check(not pcall(callback), "invalid input was accepted")
end
check(#Layout.compute({}, Settings.defaults) == 0, "empty layout")
local slots = Layout.compute({ 2, 4, 2, 5, 1, 3 }, Settings.defaults)
check(math.abs(slots[1].x + 7.3) < 0.001, "row starts at centred footprint")
for i = 2, 5 do
	local sizes = { 2, 4, 2, 5, 1 }
	check(slots[i].x - slots[i - 1].x >= (sizes[i] + sizes[i - 1]) / 2 + 0.64, "row overlaps")
end
local function checkSeparation(sizes, kind, spacing)
	local result = Layout.compute(sizes, Settings.merge(Settings.defaults, { Formation = kind, Spacing = spacing }))
	for i = 1, #sizes do
		for j = i + 1, #sizes do
			local dx, dz = result[i].x - result[j].x, result[i].z - result[j].z
			local required = (sizes[i] + sizes[j]) / 2 + spacing
			check(math.sqrt(dx * dx + dz * dz) + 1e-5 >= required, kind .. " footprint gap is too small")
		end
	end
	return result
end
for _, sizes in {
	{ 8, 8 }, { 30, 30 }, { 12, 1, 12 }, { 2, 7, 3, 1, 6, 10 },
	{ 30, 0.2, 30 }, { 100, 0.1, 100 }, { 12, 0.01, 12 },
	{ 80, 0.5, 80, 0.5, 80, 0.5, 80, 0.5 },
} do
	for _, kind in { "Rows", "Arc", "Orbit" } do
		for _, spacing in { 0, Settings.defaults.Spacing, 12 } do
			checkSeparation(sizes, kind, spacing)
		end
	end
end
for _, sizes in { { 2, 4 }, { 30, 0.1 }, { 100, 100 } } do
	local pair = checkSeparation(sizes, "Arc", Settings.defaults.Spacing)
	local dx, dz = pair[1].x - pair[2].x, pair[1].z - pair[2].z
	check(math.abs(math.sqrt(dx * dx + dz * dz) - (sizes[1] + sizes[2]) / 2 - Settings.defaults.Spacing) < 1e-5, "small arc lost compact spacing")
end
local crowded = table.create(200)
for i = 1, 200 do crowded[i] = if i % 2 == 0 then 0.01 else 100 end
for _, kind in { "Rows", "Arc", "Orbit" } do
	checkSeparation(crowded, kind, Settings.defaults.Spacing)
end
check(slots[6].z > slots[1].z + 4, "rows respect depth")
check(slots[6].x == 0, "partial row centred")
for _, formation in { "Rows", "Arc", "Orbit" } do
	for count = 1, 100 do
		local sizes = table.create(count)
		for i = 1, count do sizes[i] = 0.5 + (i % 7) * 0.4 end
		local result = Layout.compute(sizes, Settings.merge(Settings.defaults, { Formation = formation }))
		check(#result == count, "count changed")
		for _, position in result do
			check(Settings.finite(position.x) and Settings.finite(position.z), "nonfinite position")
		end
	end
end
for _, value in { 0 / 0, math.huge, -math.huge, -1, "3" } do
	rejects(function() Settings.merge(Settings.defaults, { Spacing = value }) end)
end
rejects(function() Settings.merge(Settings.defaults, { Columns = 1.5 }) end)
rejects(function() Settings.merge(Settings.defaults, { Formation = "Square" }) end)
rejects(function() Settings.merge(Settings.defaults, { Unexpected = 1 }) end)
rejects(function() Settings.merge(Settings.defaults, { FarDistance = 2 }) end)
local amended = Settings.merge(Settings.defaults, { Spacing = 2 })
check(Settings.defaults.Spacing == 0.65 and amended.Spacing == 2, "settings mutated defaults")
print(string.format("Formation: %d assertions passed", checks))
