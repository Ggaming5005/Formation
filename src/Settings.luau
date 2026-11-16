--!strict
local Settings = {}

Settings.defaults = table.freeze({
	Formation = "Rows",
	Columns = 5,
	Spacing = 0.65,
	Distance = 5,
	Responsiveness = 10,
	GroundHeight = 0,
	FlightHeight = 2.4,
	BobHeight = 0.16,
	BobSpeed = 2.2,
	OrbitSpeed = 0.22,
	TeleportDistance = 70,
	RayHeight = 18,
	RayDepth = 90,
	GroundInterval = 0.08,
	NearDistance = 90,
	FarDistance = 220,
	FarInterval = 0.1,
	DistantInterval = 0.3,
})

local bounds = {
	Columns = { 1, 20 }, Spacing = { 0, 12 }, Distance = { 1, 100 },
	Responsiveness = { 0.1, 60 }, GroundHeight = { -10, 20 },
	FlightHeight = { 0, 50 }, BobHeight = { 0, 4 }, BobSpeed = { 0, 20 },
	OrbitSpeed = { -5, 5 }, TeleportDistance = { 5, 5000 },
	RayHeight = { 1, 200 }, RayDepth = { 2, 1000 },
	GroundInterval = { 0.01, 2 }, NearDistance = { 1, 10000 },
	FarDistance = { 1, 20000 }, FarInterval = { 0.01, 2 }, DistantInterval = { 0.01, 5 },
}

function Settings.finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Settings.merge(base: { [string]: any }, changes: { [string]: any }?): { [string]: any }
	local result = table.clone(base)
	for key, value in changes or {} do
		if key == "Formation" then
			assert(value == "Rows" or value == "Arc" or value == "Orbit", "Formation must be Rows, Arc, or Orbit")
		else
			local limit = bounds[key]
			assert(limit, "Unknown setting: " .. tostring(key))
			assert(Settings.finite(value) and value >= limit[1] and value <= limit[2], "Invalid setting: " .. key)
			if key == "Columns" then
				assert(value % 1 == 0, "Columns must be an integer")
			end
		end
		result[key] = value
	end
	assert(result.FarDistance >= result.NearDistance, "FarDistance must be at least NearDistance")
	return result
end

return Settings
