--!strict
-- A repeatable capture scene using the real Formation controller.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Demo = require(script.Parent.Demo)

local Showcase = {}
local CREAM = Color3.fromHex("F3EEDC")
local SAGE = Color3.fromHex("74876D")
local INK = Color3.fromHex("293C3E")
local MODES = {
	{ Name = "Rows", Caption = "Room for every companion.", Formation = "Rows", Flying = false },
	{ Name = "Arc", Caption = "A wider view. The same little crew.", Formation = "Arc", Flying = false },
	{ Name = "Orbit", Caption = "Keep your companions in the loop.", Formation = "Orbit", Flying = false },
	{ Name = "Flying", Caption = "A little lift. A softer landing.", Formation = "Rows", Flying = true },
}

local function text(parent: Instance, name: string, value: string, height: number, font: Enum.Font, max: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromScale(1, height)
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextColor3 = INK
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	label.TextWrapped = true
	label.Font = font
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = 10
	limit.MaxTextSize = max
	limit.Parent = label
	label.Parent = parent
	return label
end

function Showcase.start(player: Player)
	assert(RunService:IsClient(), "Showcase.start runs on the client")
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "Showcase needs the player's original Humanoid")
	local camera = workspace.CurrentCamera
	assert(camera, "Showcase needs CurrentCamera")
	local saved = {
		MouseIconEnabled = UserInputService.MouseIconEnabled,
		RootCFrame = root.CFrame, Anchored = root.Anchored,
		LinearVelocity = root.AssemblyLinearVelocity, AngularVelocity = root.AssemblyAngularVelocity,
		AutoRotate = humanoid.AutoRotate, DisplayDistanceType = humanoid.DisplayDistanceType,
		CameraType = camera.CameraType, CameraSubject = camera.CameraSubject,
		CameraCFrame = camera.CFrame, CameraFocus = camera.Focus, FieldOfView = camera.FieldOfView,
	}
	local demo = Demo.start(player)
	local originalDemoGuiEnabled = demo.Gui.Enabled
	demo.Gui.Enabled = false
	demo.Controller:Configure({ Columns = 4, Distance = 5.2, Spacing = 0.4, Responsiveness = 7, FlightHeight = 2.2, BobHeight = 0.22, BobSpeed = 2, OrbitSpeed = 0.3 })
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	humanoid.AutoRotate = false
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 43
	UserInputService.MouseIconEnabled = false

	local gui = Instance.new("ScreenGui")
	gui.Name = "FormationShowcase"
	gui.ResetOnSpawn = false
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.DisplayOrder = 100
	local panel = Instance.new("Frame")
	panel.Name = "Title"
	panel.Position = UDim2.fromScale(0.035, 0.045)
	panel.Size = UDim2.fromScale(0.29, 0.195)
	panel.BackgroundColor3 = CREAM
	panel.BackgroundTransparency = 0.06
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local size = Instance.new("UISizeConstraint")
	size.MinSize = Vector2.new(230, 115)
	size.MaxSize = Vector2.new(430, 180)
	size.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.06, 0)
	corner.Parent = panel
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0.065, 0)
	padding.PaddingRight = UDim.new(0.065, 0)
	padding.PaddingTop = UDim.new(0.10, 0)
	padding.PaddingBottom = UDim.new(0.10, 0)
	padding.Parent = panel
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0.035, 0)
	list.Parent = panel
	local eyebrow = text(panel, "Eyebrow", "FORMATION  /  COMPANION MOTION", 0.16, Enum.Font.GothamBold, 10)
	eyebrow.LayoutOrder = 1
	eyebrow.TextColor3 = SAGE
	local title = text(panel, "Mode", "Rows", 0.40, Enum.Font.GothamBold, 36)
	title.LayoutOrder = 2
	local caption = text(panel, "Benefit", MODES[1].Caption, 0.23, Enum.Font.Gotham, 14)
	caption.LayoutOrder = 3
	local progressBack = Instance.new("Frame")
	progressBack.Name = "ChapterProgress"
	progressBack.Size = UDim2.fromScale(1, 0.025)
	progressBack.BackgroundColor3 = Color3.fromHex("D9DECB")
	progressBack.BorderSizePixel = 0
	progressBack.LayoutOrder = 4
	progressBack.Parent = panel
	local progress = progressBack:Clone()
	progress.Name = "Progress"
	progress.Size = UDim2.fromScale(0, 1)
	progress.BackgroundColor3 = SAGE
	progress.Parent = progressBack
	local footer = text(gui, "Edition", "OPEN SOURCE  /  ORIGINAL COMPANIONS", 0.03, Enum.Font.GothamMedium, 11)
	footer.Size = UDim2.fromScale(0.55, 0.03)
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.fromScale(0.035, 0.965)
	gui.Parent = player:WaitForChild("PlayerGui")

	local ground = RaycastParams.new()
	ground.FilterType = Enum.RaycastFilterType.Include
	ground.FilterDescendantsInstances = { demo.Course }
	local lift = root.Size.Y / 2 + humanoid.HipHeight + (if humanoid.RigType == Enum.HumanoidRigType.R6 then 2 else 0)
	local walkTrack: AnimationTrack? = nil
	local animate = character:FindFirstChild("Animate")
	local walk = animate and animate:FindFirstChild("walk")
	local animation = walk and walk:FindFirstChildWhichIsA("Animation")
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animation and animator then
		local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
		if ok then
			walkTrack = track
			track.Priority = Enum.AnimationPriority.Movement
			track.Looped = true
			track:Play(0.2, 1, 0.5)
		end
	end

	local alive = true
	local clock = -2
	local chapter = 0
	local center: Vector3? = nil
	local height: number? = nil
	local connection: RBXScriptConnection? = nil
	local characterConnection: RBXScriptConnection? = nil
	local handle = { Demo = demo, Controller = demo.Controller, Gui = gui }

	function handle:Destroy()
		if not alive then return end
		alive = false
		if connection then connection:Disconnect(); connection = nil end
		if characterConnection then characterConnection:Disconnect(); characterConnection = nil end
		UserInputService.MouseIconEnabled = saved.MouseIconEnabled
		if walkTrack then walkTrack:Stop(0.15); walkTrack:Destroy(); walkTrack = nil end
		if root.Parent then
			root.CFrame = saved.RootCFrame
			root.Anchored = saved.Anchored
			root.AssemblyLinearVelocity = saved.LinearVelocity
			root.AssemblyAngularVelocity = saved.AngularVelocity
		end
		if humanoid.Parent then
			humanoid.AutoRotate = saved.AutoRotate
			humanoid.DisplayDistanceType = saved.DisplayDistanceType
		end
		if camera.Parent then
			camera.CameraType = saved.CameraType
			camera.CameraSubject = saved.CameraSubject
			camera.CFrame = saved.CameraCFrame
			camera.Focus = saved.CameraFocus
			camera.FieldOfView = saved.FieldOfView
		end
		if demo.Gui.Parent then demo.Gui.Enabled = originalDemoGuiEnabled end
		gui:Destroy()
		demo:Destroy()
	end

	characterConnection = player.CharacterRemoving:Connect(function(removing)
		if removing == character then handle:Destroy() end
	end)
	connection = RunService.PreRender:Connect(function(dt: number)
		if not root.Parent then handle:Destroy(); return end
		clock += math.min(dt, 0.1)
		local time = math.max(clock, 0) % 32
		local index = math.floor(time / 8) + 1
		if index ~= chapter then
			chapter = index
			local mode = MODES[index]
			demo.Controller:Configure({ Formation = mode.Formation })
			demo.Controller:SetFlying(mode.Flying)
			title.Text = mode.Name
			caption.Text = mode.Caption
			eyebrow.Text = string.format("FORMATION  /  %02d — 04", index)
			gui:SetAttribute("Mode", mode.Name)
		end
		progress.Size = UDim2.fromScale((time % 8) / 8, 1)
		local theta = time / 32 * math.pi * 2
		local x, z = 12 * math.sin(theta), 5 * math.cos(theta)
		local hit = workspace:Raycast(Vector3.new(x, 24, z), Vector3.new(0, -50, 0), ground)
		local wantedHeight = (if hit then hit.Position.Y else 0.2) + lift
		height = if height then height + (wantedHeight - height) * (1 - math.exp(-10 * dt)) else wantedHeight
		local position = Vector3.new(x, height :: number, z)
		local tangent = Vector3.new(12 * math.cos(theta), 0, -5 * math.sin(theta)).Unit
		root.CFrame = CFrame.lookAt(position, position + tangent)
		if walkTrack then walkTrack:AdjustSpeed(if clock < 0 then 0 else 0.52) end

		local low, high = position, position
		for _, model in demo.Controller.Folder:GetChildren() do
			if model:IsA("Model") then
				local p = model:GetPivot().Position
				low = Vector3.new(math.min(low.X, p.X), math.min(low.Y, p.Y), math.min(low.Z, p.Z))
				high = Vector3.new(math.max(high.X, p.X), math.max(high.Y, p.Y), math.max(high.Z, p.Z))
			end
		end
		local desired = (low + high) / 2 + Vector3.new(0, 1.0, -0.8)
		center = if center then center:Lerp(desired, 1 - math.exp(-1.8 * dt)) else desired
		local angle = 0.32 + math.sin(time / 32 * math.pi * 2) * 0.055
		local offset = Vector3.new(math.sin(angle) * 48, 33, math.cos(angle) * 48)
		local focus = center :: Vector3
		camera.CFrame = CFrame.lookAt(focus + offset, focus)
		camera.Focus = CFrame.new(focus)
	end)
	return handle
end

return Showcase
