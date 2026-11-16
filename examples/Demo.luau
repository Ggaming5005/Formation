--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Formation = require(ReplicatedStorage.Formation)
local Companions = require(script.Parent.Companions)
local DemoScene = require(script.Parent.DemoScene)
local Demo = {}

function Demo.start(player: Player)
	local playerGui = player:WaitForChild("PlayerGui")
	local course = DemoScene.create(workspace, Vector3.new(0, 0, 0))
	local templates = Companions.all()
	local controller = Formation.new(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return if root and root:IsA("BasePart") then root.CFrame else nil
	end)
	for i = 1, 12 do
		controller:Add(tostring(i), templates[(i - 1) % #templates + 1], { Scale = if i % 5 == 0 then 1.1 else 0.7 })
	end
	controller:Start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FormationDemo"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -20)
	bar.Size = UDim2.new(0.8, 0, 0, 48)
	bar.BackgroundColor3 = Color3.fromHex("293C3E")
	bar.Parent = gui
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(600, 48)
	constraint.Parent = bar
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bar
	local flying = false
	for i, name in { "Rows", "Arc", "Orbit", "Flight" } do
		local button = Instance.new("TextButton")
		button.LayoutOrder = i
		button.Size = UDim2.fromScale(0.25, 1)
		button.BackgroundTransparency = 1
		button.Text = name
		button.TextSize = 17
		button.TextColor3 = Color3.fromHex("F3EEDC")
		button.Font = Enum.Font.GothamMedium
		button.Parent = bar
		button.Activated:Connect(function()
			if name == "Flight" then flying = not flying; controller:SetFlying(flying); button.Text = if flying then "Ground" else "Flight"
			else controller:Configure({ Formation = name }) end
		end)
	end
	gui.Parent = playerGui
	local alive = true
	local handle = { Controller = controller, Gui = gui, Course = course }
	function handle:Destroy()
		if not alive then return end
		alive = false
		controller:Destroy()
		gui:Destroy()
		course:Destroy()
		for _, template in templates do template:Destroy() end
		table.clear(templates)
	end
	return handle
end

return Demo
