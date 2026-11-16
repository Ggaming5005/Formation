--!strict
local RunService = game:GetService("RunService")
local Settings = require(script.Settings)
local Layout = require(script.Layout)

export type Owner = BasePart | Model | (() -> CFrame?)
export type PetOptions = { Flying: boolean?, Scale: number? }
export type Config = { Settings: { [string]: any }?, Parent: Instance?, Exclude: { Instance }? }
local Formation = {}
Formation.__index = Formation

local function ownerFrame(owner: Owner): CFrame?
	if type(owner) == "function" then
		local value = owner()
		assert(value == nil or typeof(value) == "CFrame", "Owner function must return CFrame or nil")
		return value
	end
	if owner.Parent == nil then
		return nil
	end
	return owner:GetPivot()
end

local function bottomOffset(model: Model): (number, number)
	local pivot = model:GetPivot()
	local box, size = model:GetBoundingBox()
	local radius, lowest = 0, math.huge
	for _, x in { -0.5, 0.5 } do
		for _, y in { -0.5, 0.5 } do
			for _, z in { -0.5, 0.5 } do
				local corner = pivot:PointToObjectSpace(box:PointToWorldSpace(size * Vector3.new(x, y, z)))
				radius = math.max(radius, Vector2.new(corner.X, corner.Z).Magnitude)
				lowest = math.min(lowest, corner.Y)
			end
		end
	end
	return -lowest, radius * 2
end

function Formation.new(owner: Owner, config: Config?)
	assert(type(owner) == "function" or (typeof(owner) == "Instance" and (owner:IsA("BasePart") or owner:IsA("Model"))), "Owner must be a Model, BasePart, or function")
	local options = config or {}
	local settings = Settings.merge(Settings.defaults, options.Settings)
	local folder = Instance.new("Folder")
	folder.Name = "FormationCompanions"
	folder.Archivable = false
	folder.Parent = options.Parent or workspace
	local exclusions = table.clone(options.Exclude or {})
	table.insert(exclusions, folder)
	if typeof(owner) == "Instance" then
		table.insert(exclusions, owner)
	end
	local raycast = RaycastParams.new()
	raycast.FilterType = Enum.RaycastFilterType.Exclude
	raycast.FilterDescendantsInstances = exclusions
	local self = setmetatable({
		Owner = owner, Settings = table.freeze(settings), Folder = folder,
		_pets = {}, _byId = {}, _slots = {}, _raycast = raycast,
		_time = 0, _groundClock = 0, _stepClock = 0,
		_destroyed = false, _connection = nil, _lastOwner = nil,
		_stats = { Count = 0, Updates = 0, Raycasts = 0, LastStepMs = 0 },
	}, Formation)
	if typeof(owner) == "Instance" then
		self._ownerConnection = owner.Destroying:Connect(function() self:Destroy() end)
	end
	return self
end

function Formation:_layout()
	local diameters = table.create(#self._pets)
	for i, pet in self._pets do
		diameters[i] = pet.diameter
	end
	self._slots = Layout.compute(diameters, self.Settings)
	self._stats.Count = #self._pets
end

function Formation:Add(id: string, template: Model, options: PetOptions?): Model
	assert(not self._destroyed, "Formation has been destroyed")
	assert(type(id) == "string" and #id > 0 and #id <= 128, "Pet id must be a nonempty string, up to 128 bytes")
	assert(not self._byId[id], "Pet id already exists: " .. id)
	assert(#self._pets < 200, "A Formation controller supports at most 200 companions")
	assert(typeof(template) == "Instance" and template:IsA("Model"), "Template must be a Model")
	assert(template:FindFirstChildWhichIsA("BasePart", true), "Template must contain a BasePart")
	local opts = options or {}
	local scale = opts.Scale or 1
	assert(Settings.finite(scale) and scale >= 0.1 and scale <= 10, "Scale must be between 0.1 and 10")
	assert(opts.Flying == nil or type(opts.Flying) == "boolean", "Flying must be boolean")
	local clone = template:Clone()
	assert(clone, "Template must be Archivable")
	local ok, result = pcall(function()
		assert(clone:FindFirstChildWhichIsA("BasePart", true), "Template parts must be Archivable")
		clone.Name = id
		for _, child in clone:GetDescendants() do
			if child:IsA("BasePart") then
				child.Anchored = true
				child.CanCollide = false
				child.CanTouch = false
				child.CanQuery = false
			elseif child:IsA("BaseScript") then
				child.Enabled = false
			end
		end
		if scale ~= 1 then clone:ScaleTo(clone:GetScale() * scale) end
	end)
	if not ok then clone:Destroy(); error(result, 2) end
	local bottom, diameter = bottomOffset(clone)
	local pet = {
		id = id, model = clone, flying = opts.Flying == true,
		bottom = bottom, diameter = diameter, phase = #self._pets * 2.39996,
		frame = nil, groundY = nil, normal = Vector3.yAxis,
	}
	clone.Parent = self.Folder
	table.insert(self._pets, pet)
	self._byId[id] = pet
	self:_layout()
	return clone
end

function Formation:Remove(id: string): boolean
	local pet = self._byId[id]
	if not pet then
		return false
	end
	self._byId[id] = nil
	local index = table.find(self._pets, pet)
	if index then
		table.remove(self._pets, index)
	end
	pet.model:Destroy()
	self:_layout()
	return true
end

function Formation:Configure(changes: { [string]: any })
	assert(not self._destroyed, "Formation has been destroyed")
	self.Settings = table.freeze(Settings.merge(self.Settings, changes))
	self:_layout()
end

function Formation:SetFlying(flying: boolean)
	assert(not self._destroyed, "Formation has been destroyed")
	assert(type(flying) == "boolean", "Flying must be boolean")
	for _, pet in self._pets do
		pet.flying = flying
		pet.groundY = nil
	end
end

function Formation:GetStats()
	return table.clone(self._stats)
end

function Formation:Step(dt: number)
	if self._destroyed then
		return
	end
	assert(Settings.finite(dt) and dt >= 0, "dt must be finite and nonnegative")
	if dt == 0 then
		return
	end
	local frame = ownerFrame(self.Owner)
	if not frame then
		return
	end
	local settings = self.Settings
	self._time += dt
	self._stepClock += dt
	self._groundClock += dt
	local camera = workspace.CurrentCamera
	local distance = if camera then (camera.CFrame.Position - frame.Position).Magnitude else 0
	local interval = if distance > settings.FarDistance then settings.DistantInterval elseif distance > settings.NearDistance then settings.FarInterval else 0
	if self._stepClock < interval then
		return
	end
	local started = os.clock()
	local step = self._stepClock
	self._stepClock = 0
	local snap = self._lastOwner == nil or (frame.Position - self._lastOwner).Magnitude > settings.TeleportDistance
	self._lastOwner = frame.Position
	local updateGround = snap or self._groundClock >= settings.GroundInterval
	if updateGround then
		self._groundClock = 0
	end
	local alpha = 1 - math.exp(-settings.Responsiveness * step)
	local orbitAngle = if settings.Formation == "Orbit" then self._time * settings.OrbitSpeed else 0
	local cosine, sine = math.cos(orbitAngle), math.sin(orbitAngle)
	local stale = {}
	for i, pet in self._pets do
		if pet.model.Parent == nil then
			table.insert(stale, pet.id)
			continue
		end
		local slot = self._slots[i]
		local offset = Vector3.new(slot.x * cosine - slot.z * sine, 0, slot.x * sine + slot.z * cosine)
		local target = frame:PointToWorldSpace(offset)
		if pet.flying then
			target += Vector3.new(0, settings.FlightHeight + math.sin(self._time * settings.BobSpeed + pet.phase) * settings.BobHeight, 0)
		else
			if updateGround or pet.groundY == nil then
				local hit = workspace:Raycast(target + Vector3.yAxis * settings.RayHeight, -Vector3.yAxis * settings.RayDepth, self._raycast)
				self._stats.Raycasts += 1
				if hit then
					pet.groundY = hit.Position.Y + pet.bottom + settings.GroundHeight
					pet.normal = (Vector3.yAxis + hit.Normal).Unit
				elseif pet.groundY == nil or snap then
					pet.groundY = frame.Position.Y - 3 + pet.bottom + settings.GroundHeight
					pet.normal = Vector3.yAxis
				end
			end
			target = Vector3.new(target.X, pet.groundY, target.Z)
		end
		local previous = pet.frame
		local position = if snap or previous == nil then target else previous.Position:Lerp(target, alpha)
		local direction = frame.LookVector
		if previous and not snap then
			local delta = target - previous.Position
			if Vector3.new(delta.X, 0, delta.Z).Magnitude > 0.3 then
				direction = Vector3.new(delta.X, 0, delta.Z).Unit
			end
		end
		local up = if pet.flying then Vector3.yAxis else pet.normal
		local forward = direction - up * direction:Dot(up)
		if forward.Magnitude < 0.001 then
			forward = Vector3.new(0, 0, -1)
		end
		local rotation = CFrame.lookAt(Vector3.zero, forward.Unit, up)
		if previous and not snap then
			rotation = previous.Rotation:Lerp(rotation, alpha)
		end
		pet.frame = CFrame.new(position) * rotation
		pet.model:PivotTo(pet.frame)
	end
	for _, id in stale do
		self:Remove(id)
	end
	self._stats.Updates += 1
	self._stats.LastStepMs = (os.clock() - started) * 1000
end

function Formation:Start()
	assert(not self._destroyed, "Formation has been destroyed")
	assert(RunService:IsClient() or not RunService:IsRunning(), "Formation is a client cosmetic renderer; call Start from a LocalScript")
	if self._connection then
		return
	end
	local event = if RunService:IsClient() then RunService.PreRender else RunService.Heartbeat
	self._connection = event:Connect(function(dt)
		self:Step(dt)
	end)
end

function Formation:Stop()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
end

function Formation:Destroy()
	if self._destroyed then
		return
	end
	self:Stop()
	if self._ownerConnection then self._ownerConnection:Disconnect(); self._ownerConnection = nil end
	self._destroyed = true
	self.Folder:Destroy()
	table.clear(self._pets)
	table.clear(self._byId)
	table.clear(self._slots)
	self._stats.Count = 0
end

Formation.defaults = Settings.defaults
return Formation
