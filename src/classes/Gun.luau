local Gun = {}
Gun.__index = Gun

function Gun.new(owner, tool)
    local self = setmetatable({}, Gun)
    self.owner = owner
    self.char = self.owner.Character
    self.tool = tool

    self.maxAmmo = 6
    self.ammo = self.maxAmmo

    return self
end

function Gun:ValidateDirection(clientCFrame: CFrame): boolean
	local head: BasePart? = self.char:FindFirstChild("Head")
	if not head then return nil end

	local serverLook: Vector3 = head.CFrame.LookVector
	local clientLook: Vector3 = clientCFrame.LookVector

	local dot: number = serverLook:Dot(clientLook)

	if dot < 0.8 then
		warn("Suspicious angle difference")
		return false
	end

	return true
end


function Gun:Shoot(cframe)
    if not self:CanShoot() then return end
    if not self:ValidateDirection(cframe) then return end

    local model = self.char:FindFirstChild("ViewModelTPS" .. self.tool.Name)
    if not model then 
        warn("Model not found")
        return 
    end

	local primaryPart: BasePart = model.PrimaryPart
	if not primaryPart then
        warn("No primary part set for instance: " .. model.Name)
		return
	end

	local origin: Vector3 = cframe.Position
	local direction: Vector3 = cframe.LookVector * 1000

	local rayParams: RaycastParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = {model, self.char}

	local result: RaycastResult? = workspace:Raycast(origin, direction, rayParams)

	if result then
		local hitPart = result.Instance
        local humanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:TakeDamage(20)
        end
	end
end

function Gun:CanShoot()
    return self.ammo > 0
end

return Gun