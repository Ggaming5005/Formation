--!strict
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Runtime = require(script.Parent.Runtime)
local Companions = require(script.Parent.Companions)
local Theme = require(script.Parent.Theme)
local App = {}

local function create(class: string, props: { [string]: any }, parent: Instance): any
	local object = Instance.new(class)
	for key, value in props do
		object[key] = value
	end
	object.Parent = parent
	return object
end

function App.start(plugin: Plugin)
	local widget = plugin:CreateDockWidgetPluginGuiAsync("FormationStudio.v1.0", DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 350, 690, 300, 420))
	widget.Title = "Formation"
	local toolbar = plugin:CreateToolbar("Formation")
	local toggle = toolbar:CreateButton("FormationPanel", "Companion movement and formations", "", "Formation")
	toggle.ClickableWhenViewportHidden = true
	local colors = Theme.colors()
	local root = create("ScrollingFrame", { Name = "Inspector", Size = UDim2.fromScale(1, 1), BackgroundColor3 = colors.background, BorderSizePixel = 0, ScrollBarThickness = 3, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, widget)
	create("UIPadding", { PaddingTop = UDim.new(0, 16), PaddingBottom = UDim.new(0, 16), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, root)
	create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, root)
	local order = 0
	local function label(text: string, size: number, muted: boolean?): TextLabel
		order += 1
		return create("TextLabel", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, size + 8), BackgroundTransparency = 1, Text = text, TextSize = size, Font = Enum.Font.SourceSans, TextColor3 = if muted then colors.muted else colors.text, TextXAlignment = Enum.TextXAlignment.Left }, root)
	end
	local function button(text: string, action: () -> (), accent: boolean?): TextButton
		order += 1
		local b = create("TextButton", { Name = text:gsub("%s", ""), LayoutOrder = order, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = if accent then colors.accent else colors.button, BorderSizePixel = 0, Text = text, TextSize = 15, Font = Enum.Font.SourceSansSemibold, TextColor3 = if accent then Color3.fromRGB(18, 32, 27) else colors.text, AutoButtonColor = true }, root)
		create("UICorner", { CornerRadius = UDim.new(0, 4) }, b)
		b.Activated:Connect(action)
		return b
	end
	local state = { formation = "Rows", flying = false, count = 12, settings = table.clone(Runtime.defaults), controller = nil, templates = nil, preview = nil, connection = nil, alive = true, elapsed = 0 }
	local app: any = { Widget = widget }
	label("FORMATION", 12, true)
	label("Companion motion", 24)
	label("A small renderer. Your models, your game.", 14, true)
	local status = label("Select pet Models, or use the included set.", 14, true)
	status.TextWrapped = true
	status.Size = UDim2.new(1, 0, 0, 42)
	local function stop()
		if state.connection then state.connection:Disconnect(); state.connection = nil end
		if state.controller then state.controller:Destroy(); state.controller = nil end
		if state.preview then state.preview:Destroy(); state.preview = nil end
		if state.templates then
			for _, model in state.templates do model:Destroy() end
			state.templates = nil
		end
		status.Text = "Preview stopped. No scene objects retained."
	end
	local stats: TextLabel
	local function startPreview(useSelection: boolean)
		stop()
		if RunService:IsRunning() then status.Text = "Stop Play mode to preview in the editor."; return end
		local templates = {}
		if useSelection then
			for _, item in Selection:Get() do
				if item:IsA("Model") and item:FindFirstChildWhichIsA("BasePart", true) then
					local clone = item:Clone()
					if clone then table.insert(templates, clone) end
				end
			end
			if #templates == 0 then status.Text = "Select one or more Models containing parts."; return end
		else templates = Companions.all() end
		state.templates = templates
		local preview = Instance.new("Folder")
		preview.Name = "FormationPreview"
		preview.Archivable = false
		preview.Parent = workspace
		state.preview = preview
		local camera = workspace.CurrentCamera
		local origin = if camera then camera.CFrame.Position + camera.CFrame.LookVector * 25 else Vector3.new(0, 4, 0)
		local hit = workspace:Raycast(origin + Vector3.yAxis * 30, -Vector3.yAxis * 150)
		if hit then origin = Vector3.new(origin.X, hit.Position.Y + 3, origin.Z) end
		state.elapsed = 0
		state.settings.Formation = state.formation
		state.controller = Runtime.new(function()
			local t = state.elapsed * 0.28
			local point = origin + Vector3.new(math.sin(t) * 12, 0, math.sin(t * 2) * 6)
			local nextPoint = origin + Vector3.new(math.sin(t + 0.02) * 12, 0, math.sin((t + 0.02) * 2) * 6)
			return CFrame.lookAt(point, nextPoint)
		end, { Settings = state.settings, Parent = preview })
		for i = 1, state.count do
			state.controller:Add(tostring(i), templates[(i - 1) % #templates + 1], { Flying = state.flying, Scale = if i % 5 == 0 then 1.25 else 0.7 })
		end
		local refresh = 0
		state.connection = RunService.Heartbeat:Connect(function(dt)
			state.elapsed += dt
			state.controller:Step(dt)
			refresh += dt
			if refresh >= 0.3 then
				refresh = 0
				local measured = state.controller:GetStats()
				stats.Text = string.format("%d companions  ·  %.2f ms / update", measured.Count, measured.LastStepMs)
			end
		end)
		status.Text = "Preview running near your camera. Close this panel to clean up."
	end
	local function start(useSelection: boolean)
		local ok, err = pcall(startPreview, useSelection)
		if not ok then
			stop()
			status.Text = tostring(err):gsub("^.-:%d+: ", "")
		end
	end
	button("Preview included companions", function() start(false) end, true)
	button("Preview selected models", function() start(true) end)
	label("LAYOUT", 12, true)
	local layoutButton: TextButton
	layoutButton = button("Formation    Rows", function()
		local list = { "Rows", "Arc", "Orbit" }
		state.formation = list[(table.find(list, state.formation) or 1) % #list + 1]
		layoutButton.Text = "Formation    " .. state.formation
		state.settings.Formation = state.formation
		if state.controller then state.controller:Configure({ Formation = state.formation }) end
	end)
	local flightButton: TextButton
	flightButton = button("Movement    Ground", function()
		state.flying = not state.flying
		flightButton.Text = "Movement    " .. (if state.flying then "Flying" else "Ground")
		if state.controller then state.controller:SetFlying(state.flying) end
	end)
	local function numberField(name: string, initial: number, apply: (number) -> ())
		order += 1
		local row = create("Frame", { LayoutOrder = order, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 }, root)
		create("TextLabel", { Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = name, TextSize = 15, Font = Enum.Font.SourceSans, TextColor3 = colors.text, TextXAlignment = Enum.TextXAlignment.Left }, row)
		local input = create("TextBox", { Name = name, Position = UDim2.fromScale(0.65, 0), Size = UDim2.fromScale(0.35, 1), Text = tostring(initial), ClearTextOnFocus = false, BackgroundColor3 = colors.panel, BorderSizePixel = 0, TextColor3 = colors.text, TextSize = 15, Font = Enum.Font.SourceSans }, row)
		create("UICorner", { CornerRadius = UDim.new(0, 3) }, input)
		input.FocusLost:Connect(function()
			local value = tonumber(input.Text)
			local ok, err = pcall(function() assert(value, "Enter a number"); apply(value) end)
			if ok then initial = value; status.Text = if name == "Preview count" then "Count changed. Start a preview to apply." else "Settings updated." else input.Text = tostring(initial); status.Text = tostring(err):gsub("^.-:%d+: ", "") end
		end)
	end
	numberField("Preview count", 12, function(n)
		assert(n == n and n % 1 == 0 and n >= 1 and n <= 100, "Preview count must be 1–100")
		state.count = n
		status.Text = "Count changed. Start a preview to apply."
	end)
	for _, spec in { { "Spacing", "Spacing" }, { "Follow distance", "Distance" }, { "Responsiveness", "Responsiveness" }, { "Flight height", "FlightHeight" }, { "Bob height", "BobHeight" } } do
		numberField(spec[1], state.settings[spec[2]], function(value)
			local new = require(script.Parent.Runtime.Settings).merge(state.settings, { [spec[2]] = value })
			state.settings = new
			if state.controller then state.controller:Configure({ [spec[2]] = value }) end
		end)
	end
	label("OUTPUT", 12, true)
	button("Export configuration", function()
		local recording = ChangeHistoryService:TryBeginRecording("FormationExport", "Export Formation configuration")
		if not recording then status.Text = "Finish the current Studio operation first."; return end
		local ok, err = pcall(function()
			local module = Instance.new("ModuleScript")
			module.Name = "FormationConfig"
			local lines = { "return {", "\tSettings = {" }
			local keys = {}
			for key in state.settings do table.insert(keys, key) end
			table.sort(keys)
			for _, key in keys do
				local value = state.settings[key]
				table.insert(lines, string.format("\t\t%s = %s,", key, if type(value) == "string" then string.format("%q", value) else tostring(value)))
			end
			table.insert(lines, "\t},")
			table.insert(lines, string.format("\tPetOptions = { Flying = %s },", tostring(state.flying)))
			table.insert(lines, "}")
			module.Source = table.concat(lines, "\n")
			module.Parent = game:GetService("ReplicatedStorage")
			Selection:Set({ module })
		end)
		ChangeHistoryService:FinishRecording(recording, if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel)
		status.Text = if ok then "FormationConfig added to ReplicatedStorage." else tostring(err)
	end)
	button("Stop preview", stop)
	stats = label("Update time measures this renderer only.", 13, true)
	stats.TextWrapped = true
	stats.Size = UDim2.new(1, 0, 0, 36)
	local connections = {}
	table.insert(connections, toggle.Click:Connect(function() widget.Enabled = not widget.Enabled end))
	table.insert(connections, widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		toggle:SetActive(widget.Enabled)
		if not widget.Enabled then stop() end
	end))
	function app:Destroy()
		if not state.alive then return end
		state.alive = false
		stop()
		for _, connection in connections do connection:Disconnect() end
		widget:Destroy()
		toolbar:Destroy()
	end
	table.insert(connections, plugin.Unloading:Connect(function() app:Destroy() end))
	app.Preview = start
	app.Stop = stop
	app.State = state
	return app
end

return App
