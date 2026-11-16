--!strict
local DemoScene = {}

function DemoScene.create(parent: Instance, origin: Vector3): Model
	local scene = Instance.new("Model")
	scene.Name = "FormationDemoCourse"
	local function part(name: string, size: Vector3, position: Vector3, color: string, class: string?): BasePart
		local p = Instance.new(class or "Part") :: BasePart
		p.Name = name
		p.Size = size
		p.Position = origin + position
		p.Anchored = true
		p.Material = Enum.Material.SmoothPlastic
		p.Color = Color3.fromHex(color)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = scene
		return p
	end
	part("Plinth", Vector3.new(82, 2, 66), Vector3.new(0, -1.2, 0), "35474A")
	part("Surface", Vector3.new(80, 0.4, 64), Vector3.new(0, 0, 0), "BFC9AD")
	part("Track", Vector3.new(56, 0.12, 25), Vector3.new(0, 0.25, 0), "D9D8C4")
	for i = 1, 5 do
		part("Step" .. i, Vector3.new(4, i * 0.45, 20), Vector3.new(-18 + i * 4, i * 0.225 + 0.3, 0), "C3C9BC")
	end
	local ramp = part("Slope", Vector3.new(20, 2.25, 12), Vector3.new(12, 1.425, 0), "B5BFAF", "WedgePart")
	ramp.CFrame *= CFrame.Angles(0, math.pi / 2, 0)
	for i, point in { Vector3.new(-32, 0, -22), Vector3.new(30, 0, -23), Vector3.new(30, 0, 23), Vector3.new(-31, 0, 23) } do
		part("Planter" .. i, Vector3.new(7, 1, 7), point + Vector3.yAxis * 0.8, "53665B")
		for j = 1, 4 do
			local blade = part("Leaf", Vector3.new(0.55, 3 + j * 0.4, 1.5), point + Vector3.new((j % 2) * 2 - 1, 2.5, math.floor(j / 2) - 1), if j % 2 == 0 then "879C70" else "657E60")
			blade.CFrame *= CFrame.Angles(0, j, (j - 2.5) * 0.17)
		end
	end
	local sign = part("TitleBoard", Vector3.new(26, 5, 0.5), Vector3.new(0, 3.2, -28), "35474A")
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = sign
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.65)
	title.BackgroundTransparency = 1
	title.Text = "FORMATION"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 56
	title.TextColor3 = Color3.fromHex("F3EEDC")
	title.Parent = gui
	local subtitle = title:Clone()
	subtitle.Size = UDim2.fromScale(1, 0.3)
	subtitle.Position = UDim2.fromScale(0, 0.65)
	subtitle.Text = "COMPANION MOTION / OPEN SOURCE"
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextSize = 20
	subtitle.Parent = gui
	scene.Parent = parent
	return scene
end

return DemoScene
