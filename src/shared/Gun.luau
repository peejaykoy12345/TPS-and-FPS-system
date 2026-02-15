local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GunFolder = ReplicatedStorage.Guns
local ViewmodelsFolder = ReplicatedStorage.Viewmodels

local camera = workspace.CurrentCamera

local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local head = char.Head

local remotes = require(ReplicatedStorage.Packages.remotes)

local ViewModelRemote: RemoteEvent = remotes:getEventAsync("ViewModelRemote")
local ShootEvent: RemoteEvent = remotes:getEventAsync("Shoot")

local ViewModelTP
local ViewModel
local ViewModelTPS
local swayAmount = 0
local swayCF = CFrame.new()
local lastCameraCF = CFrame.new()

local GunName = ""
local equipped = false

local Gun = {}

function Gun:isFirstPerson()
	if head.LocalTransparencyModifier == 1 or (head.CFrame.Position - camera.CFrame.Position).Magnitude < 1 then
		return true
	else
		return false
	end
end
function Gun:MatchArmsToPlayer(plr, viewModel)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	
	local skinColor = hum:GetAppliedDescription().HeadColor
	local shirt = char:FindFirstChild("Shirt")
	local ViewModelShirt = viewModel:FindFirstChild("Shirt")
	
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

function Gun:SetArmsTransparency(plr, transparency)
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

function Gun:createFPVModel()
	local viewModel = ViewmodelsFolder[GunName].ViewModel:Clone()
	viewModel.Name = "ViewModel" .. GunName
	viewModel.Parent = camera
	self:MatchArmsToPlayer(plr, viewModel)
end

function Gun:createTPLocal()
	if not ViewModelTPS and equipped then
		ViewModelTPS = ViewModelTP:Clone()
		ViewModelTPS.Parent = plr.Character
		ViewModelTPS.Name = "ViewModelTPS(Local)" .. GunName
		
		local weld = Instance.new("Weld", ViewModelTPS.PrimaryPart)
		weld.Name = "WeaponWeld"
		weld.Part0 = plr.Character.Head
		weld.Part1 = ViewModelTPS.PrimaryPart
		
		self:MatchArmsToPlayer(plr, ViewModelTPS)
	end
end

function Gun:destroyViewModel()
	local viewModel_DESTROY = camera:FindFirstChild("ViewModel" .. GunName)
	if viewModel_DESTROY then
		viewModel_DESTROY:Destroy()
	end
end

function Gun:destroyFPViewModel_createTPSViewModel()
	if camera:FindFirstChild("ViewModel" .. GunName) then
		camera:FindFirstChild("ViewModel" .. GunName):Destroy()
	end
	
	self:createTPLocal()
	
	if plr.Character:FindFirstChild("ViewModelTPS" .. GunName) then
		plr.Character:FindFirstChild("ViewModelTPS" .. GunName):Destroy()
	end
end

local presentTools: {Tool} = {}

function Gun:Init()
    local lastCF = plr.Character.Head.CFrame
    local connection
    plr.Backpack.ChildAdded:Connect(function(child)
        if table.find(presentTools, child) then
            print("already added no need")
            return
        end
        if not child:IsA("Tool") then return end

        print("Adding this")

        local gun = child

        gun.Destroying:Connect(function()
            local index
            for i, presentTool in ipairs(presentTools) do
                if presentTool == gun then
                    index = i
                end
            end
            table.remove(presentTools, index)
        end)

        gun.Equipped:Connect(function(mouse)
            GunName = gun.Name
            ViewModelTP = ViewmodelsFolder[GunName].ViewTPModel
            equipped = true
            ViewModelRemote:FireServer(ViewModelTP, equipped, GunName)
            self:SetArmsTransparency(plr, 1)
        end)

        gun.Activated:Connect(function()
            ShootEvent:FireServer(camera.CFrame)
        end)

        gun.Unequipped:Connect(function()
            equipped = false
            ViewModelRemote:FireServer(ViewModelTP, equipped, GunName)
            self:destroyViewModel()
            if plr.Character:FindFirstChild("ViewModelTPS(Local)" .. GunName) then
                ViewModelTPS = nil
                plr.Character["ViewModelTPS(Local)" .. GunName]:Destroy()
            end
            
            self:SetArmsTransparency(plr, 0)

            --if connection then connection:Disconnect() end
        end)
        table.insert(presentTools, gun)
    end)

    connection = RunService.RenderStepped:Connect(function()
        if plr.Character.Humanoid.Health <= 0 then
            equipped = false
            return
        end
        
        if not equipped then return end
        
        if self:isFirstPerson() then
            local FPViewModel = camera:FindFirstChild("ViewModel" .. GunName)
            local TPSViewModel = plr.Character:FindFirstChild("ViewModelTPS(Local)" .. GunName)
            
            if not FPViewModel then
                self:createFPVModel()
            else
                if TPSViewModel then
                    ViewModelTPS = nil
                    TPSViewModel:Destroy()
                end
                
                local rotation = camera.CFrame:ToObjectSpace(lastCameraCF)
                local x, y = rotation:ToOrientation()
                local swayCF = swayCF:Lerp(CFrame.Angles(math.sin(x) * swayAmount, math.sin(y) * swayAmount, 0), 0.1)
                lastCameraCF = camera.CFrame
                
                local primaryPart = FPViewModel.PrimaryPart	
                
                FPViewModel:SetPrimaryPartCFrame(camera.CFrame * swayCF)
            end
        else
            self:destroyFPViewModel_createTPSViewModel()
            if plr.Character and ViewModelTPS then 
                ViewModelTPS:SetPrimaryPartCFrame(lastCF)
                lastCF = plr.Character.Head.CFrame
            end
        end	
    end)
end

return Gun