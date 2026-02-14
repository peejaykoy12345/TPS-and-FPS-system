local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local camera = Workspace.CurrentCamera

local recoil = Vector2.new()
local zoom = 0

local function onRenderStepped(deltaTime: number)
	camera.CFrame *= CFrame.Angles(recoil.Y * deltaTime, recoil.X * deltaTime, 0)
	camera.FieldOfView = 70+ zoom
	recoil = recoil:Lerp(Vector2.zero, math.min(deltaTime * 10, 1))
	zoom = math.lerp(zoom, 0, math.min(deltaTime * 20, 1))
end

local CameraRecoiler = {}

function CameraRecoiler.recoilClient(recoilAmount: Vector2)
	zoom = 1
	recoil += recoilAmount
end

RunService:BindToRenderStep("Recoiler", Enum.RenderPriority.Camera.Value + 2, onRenderStepped)

return CameraRecoiler
