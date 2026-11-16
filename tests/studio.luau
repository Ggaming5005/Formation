--!strict
return function(Formation)
	local owner = Instance.new("Part")
	owner.Anchored = true
	owner.Transparency = 1
	owner.CFrame = CFrame.new(0, 20, 0)
	owner.Parent = workspace
	local template = Instance.new("Model")
	local cube = Instance.new("Part")
	cube.Size = Vector3.new(4, 4, 4)
	cube.CFrame = CFrame.new(3, 2, 0)
	cube.Parent = template
	template.WorldPivot = CFrame.new()
	local controller = Formation.new(owner, { Settings = { Formation = "Arc", BobHeight = 0 } })
	local ok, err = pcall(function()
		for i = 1, 4 do controller:Add(tostring(i), template, { Flying = true }) end
		controller:Step(1 / 60)
		for i = 1, 4 do
			for j = i + 1, 4 do
				local a = controller.Folder:FindFirstChild(tostring(i)):GetPivot().Position
				local b = controller.Folder:FindFirstChild(tostring(j)):GetPivot().Position
				assert((a - b).Magnitude >= 2 * Vector2.new(5, 2).Magnitude + 0.65 - 0.001, "Off-center footprint overlap")
			end
		end
		assert(template:GetPivot() == CFrame.new(), "Template pivot changed")
		assert(not cube.Anchored, "Source part changed")
		assert(not pcall(function() controller.Settings.Spacing = 9 end), "Settings must be read-only")
		controller:Configure({ Formation = "Rows" })
		assert(controller.Settings.Formation == "Rows")
		assert(controller:Remove("1") and not controller:Remove("1"))
		cube.Archivable = false
		assert(not pcall(function() controller:Add("invalid", template) end), "Empty clone was accepted")
		assert(#controller.Folder:GetChildren() == 3, "Failed Add retained a clone")
		controller:Start()
		controller:Start()
		controller:Stop()
		controller:Stop()
		assert(controller._connection == nil)
		owner:Destroy()
		task.wait()
		assert(controller.Folder.Parent == nil, "Destroyed owner retained companions")
		assert(controller._connection == nil)
		controller:Destroy()
	end)
	controller:Destroy()
	owner:Destroy()
	template:Destroy()
	assert(ok, err)
	return "Off-center footprints, template isolation, immutable settings, failed Add, removal, loop lifecycle and owner destruction passed"
end
