--!strict
local Companions = {}

local function block(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, rotation: CFrame?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function Companions.make(species: string): Model
	local palette = {
		Fox = { "D88E57", "F0D9B4", "503B35" },
		Cat = { "8FA79B", "DDE4CB", "304344" },
		Raccoon = { "89939A", "D7D6C9", "353F4B" },
		Owl = { "A998B2", "E7DFCA", "454053" },
	}
	local chosen = palette[species] or palette.Fox
	local main, light, dark = Color3.fromHex(chosen[1]), Color3.fromHex(chosen[2]), Color3.fromHex(chosen[3])
	local model = Instance.new("Model")
	model.Name = species
	block(model, "Body", Vector3.new(1.7, 1.4, 1.65), Vector3.new(0, 1.05, 0.25), main)
	block(model, "Chest", Vector3.new(1.2, 1.12, 0.12), Vector3.new(0, 0.99, -0.63), light)
	block(model, "Head", Vector3.new(1.84, 1.36, 1.22), Vector3.new(0, 1.86, -0.48), main)
	block(model, "CheekLeft", Vector3.new(0.65, 0.7, 0.14), Vector3.new(-0.56, 1.58, -1.14), light)
	block(model, "CheekRight", Vector3.new(0.65, 0.7, 0.14), Vector3.new(0.56, 1.58, -1.14), light)
	if species == "Raccoon" then
		block(model, "Mask", Vector3.new(1.86, 0.37, 0.14), Vector3.new(0, 1.98, -1.13), dark)
		for _, sign in { -1, 1 } do
			block(model, "MaskSide", Vector3.new(0.09, 0.37, 1.08), Vector3.new(sign * 0.94, 1.98, -0.52), dark)
		end
	end
	for _, sign in { -1, 1 } do
		local earHeight = if species == "Fox" then 0.85 elseif species == "Owl" then 0.25 else 0.55
		block(model, "Ear", Vector3.new(0.48, earHeight, 0.5), Vector3.new(sign * 0.63, 2.55 + earHeight / 2 - 0.1, -0.4), main, CFrame.Angles(0, 0, sign * math.rad(-12)))
		block(model, "EarInset", Vector3.new(0.24, earHeight * 0.64, 0.06), Vector3.new(sign * 0.63, 2.55 + earHeight / 2 - 0.1, -0.68), light, CFrame.Angles(0, 0, sign * math.rad(-12)))
		if species == "Owl" then
			block(model, "EyeDisk", Vector3.new(0.7, 0.68, 0.13), Vector3.new(sign * 0.46, 1.98, -1.18), light)
			block(model, "Wing", Vector3.new(0.48, 1.3, 1.4), Vector3.new(sign * 1.02, 1.1, 0.15), dark, CFrame.Angles(0, 0, sign * math.rad(-10)))
		end
		block(model, "Eye", Vector3.new(0.19, 0.27, 0.1), Vector3.new(sign * 0.47, 2.01, -1.26), dark)
		block(model, "EyeGlint", Vector3.new(0.055, 0.065, 0.025), Vector3.new(sign * 0.47 - 0.032, 2.09, -1.32), Color3.fromRGB(255, 248, 229))
		for _, z in { -0.25, 0.9 } do
			block(model, "Foot", Vector3.new(0.5, 0.42, 0.65), Vector3.new(sign * 0.58, 0.21, z), dark)
		end
	end
	block(model, "Muzzle", Vector3.new(0.7, 0.4, 0.38), Vector3.new(0, 1.59, -1.22), light)
	block(model, "Nose", Vector3.new(0.25, 0.17, 0.12), Vector3.new(0, 1.71, -1.47), if species == "Owl" then Color3.fromHex("D99E55") else dark)
	if species ~= "Owl" then
		local tail = if species == "Fox" then Vector3.new(0.8, 0.85, 1.65) else Vector3.new(0.5, 0.5, 1.8)
		block(model, "Tail", tail, Vector3.new(0, 1.25, 1.65), main, CFrame.Angles(math.rad(-24), 0, 0))
		block(model, "TailTip", Vector3.new(tail.X + 0.04, tail.Y + 0.04, 0.5), Vector3.new(0, 1.57, 2.28), if species == "Raccoon" then dark else light, CFrame.Angles(math.rad(-24), 0, 0))
		if species == "Raccoon" then
			block(model, "TailBand", Vector3.new(0.55, 0.55, 0.25), Vector3.new(0, 1.3, 1.8), dark, CFrame.Angles(math.rad(-24), 0, 0))
		end
	end
	model.WorldPivot = CFrame.new(0, 1.2, 0)
	return model
end

function Companions.all(): { Model }
	return { Companions.make("Fox"), Companions.make("Cat"), Companions.make("Raccoon"), Companions.make("Owl") }
end

return Companions
