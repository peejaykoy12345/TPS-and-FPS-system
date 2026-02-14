local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remotes = require(ReplicatedStorage.Packages.remotes)

local ViewModelRemote: RemoteEvent = remotes:getEventAsync("ViewModelRemote")

local function MatchArmsToPlayer(plr, viewModel)
	local char = plr.Character
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	local skinColor = hum:GetAppliedDescription().HeadColor
	local shirt = char:FindFirstChild("Shirt")
	local ViewModelShirt = viewModel:FindFirstChild("Shirt")
	
	print(shirt, ViewModelShirt)
	
	if viewModel:FindFirstChild("Right Arm") then
		viewModel["Right Arm"].Color = skinColor
	end
	
	if viewModel:FindFirstChild("Left Arm") then
		viewModel["Left Arm"].Color = skinColor
	end
	
	if shirt and ViewModelShirt then
		ViewModelShirt.ShirtTemplate = shirt.ShirtTemplate
	end
end

local function SetArmsTransparency(plr, transparency)
	local char = plr.Character
	if not char then return end
	
	local rightArm = char:FindFirstChild("Right Arm")
	local leftArm = char:FindFirstChild("Left Arm")
	
	if rightArm.Transparency then
		rightArm.Transparency = transparency
	end
	
	if leftArm.Transparency then
		leftArm.Transparency = transparency
	end
end

ViewModelRemote.OnServerEvent:Connect(function(plr, ViewModelTP, equipped, GunName)
	--print(plr, ViewModelTP, equipped, GunName)
	if equipped then
		if not ViewModelTP then return end
		local ViewModelTP =ViewModelTP:Clone()
		ViewModelTP.Parent = plr.Character
		ViewModelTP.Name = "ViewModelTPS" .. GunName
		MatchArmsToPlayer(plr, ViewModelTP)
		SetArmsTransparency(plr, 1)
		
		local lastCF = plr.Character.Head.CFrame
		local connection: RBXScriptConnection?
		
		connection = RunService.Heartbeat:Connect(function()
			local char = plr.Character
			if char and char:FindFirstChild("Head").CFrame then
				local targetCF = char.Head.CFrame
				lastCF = lastCF:Lerp(targetCF, 0.15)
				if ViewModelTP.PrimaryPart then
					ViewModelTP:SetPrimaryPartCFrame(lastCF)
				end
			else
				connection:Disconnect()
			end
		end)
	else
		local viewModelTPS = plr.Character:FindFirstChild("ViewModelTPS" .. GunName)
		if viewModelTPS then
			viewModelTPS:Destroy()
			SetArmsTransparency(plr, 0)
		end
	end
end)