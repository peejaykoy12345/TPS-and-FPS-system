local Animation = {}
local cachedAnims = {}
local activeTracks = {} 

local function cleanupCharacter(char)
	if activeTracks[char] then
		for _, track in pairs(activeTracks[char]) do
			track:Stop()
			track:Destroy()
		end
		activeTracks[char] = nil
	end
end

game:GetService("Players").PlayerRemoving:Connect(function(player)
	if player.Character then
		cleanupCharacter(player.Character)
	end
end)


function Animation.PlayAnimation(char: Model, animationId: number, dontAutoCleanUp: boolean?): (AnimationTrack, () -> ())
	if not char then return end

	local human = char:FindFirstChild("Humanoid")
	if not human then
		warn("Humanoid not found in character!")
		return
	end

	if not activeTracks[char] then
		activeTracks[char] = {}
		char.AncestryChanged:Connect(function(_, parent)
			if not parent then
				cleanupCharacter(char)
			end
		end)
	end

	if not cachedAnims[animationId] then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(animationId)
		cachedAnims[animationId] = anim
	end

	local animator = human:FindFirstChildOfClass("Animator") or human:WaitForChild("Animator")

	local track = animator:LoadAnimation(cachedAnims[animationId])
	table.insert(activeTracks[char], track)
	
	local function cleanUp()
		task.wait()
		if activeTracks[char] then
			for i, t in ipairs(activeTracks[char]) do
				if t == track then
					table.remove(activeTracks[char], i)
					track:Destroy()
					break
				end
			end
		end
	end
	
	if not dontAutoCleanUp then
		track.Stopped:Connect(function()
			cleanUp()
		end)
	end

	track:Play()
	return track, cleanUp
end

function Animation.PlayAnimationThatHasAnAnimationEvent(char, animationId)
	return Animation.PlayAnimation(char, animationId)
end

function Animation.CreateAnimation(char, animationId)
	return Animation.PlayAnimation(char, animationId)
end

function Animation.PlayAndHoldAnimation(char, animationId)
	if not char then return end
	local human = char:FindFirstChild("Humanoid")
	if not human then
		warn("Humanoid not found in character!")    
		return
	end

	if not activeTracks[char] then
		activeTracks[char] = {}
		char.AncestryChanged:Connect(function(_, parent)
			if not parent then
				cleanupCharacter(char)
			end
		end)
	end

	if not cachedAnims[animationId] then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(animationId)
		cachedAnims[animationId] = anim
	end

	local animator = human:FindFirstChildOfClass("Animator") or human:WaitForChild("Animator")
	local track = animator:LoadAnimation(cachedAnims[animationId])
	table.insert(activeTracks[char], track)

	local isHolding = false
	local holdConnection
	local stoppedConnection

	stoppedConnection = track.Stopped:Connect(function()
		if not isHolding then
			task.wait()
			if activeTracks[char] then
				for i, t in ipairs(activeTracks[char]) do
					if t == track then
						table.remove(activeTracks[char], i)
						track:Destroy()
						break
					end
				end
			end
		end
	end)

	track:Play()
	repeat task.wait() until track.IsPlaying 
	task.spawn(function()
		task.wait(track.Length - 0.05)
		if track.IsPlaying then
			isHolding = true
			track:AdjustSpeed(0)
		end
	end)

	return track, function()
		isHolding = false
		if holdConnection then
			holdConnection:Disconnect()
			holdConnection = nil
		end
		if stoppedConnection then
			stoppedConnection:Disconnect()
			stoppedConnection = nil
		end

		if activeTracks[char] then
			for i, t in ipairs(activeTracks[char]) do
				if t == track then
					table.remove(activeTracks[char], i)
					break
				end
			end
		end

		track:Stop()
		track:Destroy()
	end
end

function Animation.LoadAnimationTrack(char: Model, animationId: number, waitBeforeClearing: number?): AnimationTrack
	if not char then return end

	local human = char:FindFirstChild("Humanoid")
	if not human then
		warn("Humanoid not found in character!")
		return
	end

	if not activeTracks[char] then
		activeTracks[char] = {}
		char.AncestryChanged:Connect(function(_, parent)
			if not parent then
				cleanupCharacter(char)
			end
		end)
	end

	if not cachedAnims[animationId] then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(animationId)
		cachedAnims[animationId] = anim
	end

	local animator = human:FindFirstChildOfClass("Animator") or human:WaitForChild("Animator")
	local track = animator:LoadAnimation(cachedAnims[animationId])
	table.insert(activeTracks[char], track)

	track.Stopped:Connect(function()
		if waitBeforeClearing then
			task.wait(waitBeforeClearing)
		end
		if activeTracks[char] then
			for i, t in ipairs(activeTracks[char]) do
				if t == track then
					table.remove(activeTracks[char], i)
					track:Destroy()
					break
				end
			end
		end
	end)

	return track
end



function Animation.StopAndCleanup(char, track)
	if not char or not track then return end

	if activeTracks[char] then
		for i, t in ipairs(activeTracks[char]) do
			if t == track then
				table.remove(activeTracks[char], i)
				break
			end
		end
	end

	track:Stop()
	track:Destroy()
end

function Animation.StopAllAnimations(char: Model)
	if char and activeTracks[char] then
		cleanupCharacter(char)
	end
end

function Animation.GetAllAnimations()
	return cachedAnims
end

local PreloadingDoneEvent = Instance.new("BindableEvent")
local PreloadingDone = false

function Animation.PreloadAnimations(animationIDs: {number})
	for _, animationId in ipairs(animationIDs) do
		if cachedAnims[animationId] then continue end
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(animationId)
		cachedAnims[animationId] = anim
	end
	PreloadingDone = true
	PreloadingDoneEvent:Fire()
end

function Animation.GetAllAnims()
	if not PreloadingDone then
		PreloadingDoneEvent.Event:Wait()
	end
	local animationIds = {}
	for id, _ in pairs(cachedAnims) do
		table.insert(animationIds, id)
	end
	return animationIds
end

function Animation.DeleteCachedAnim(animationID: number)
	if cachedAnims[animationID] then
		cachedAnims[animationID]:Destroy()
		cachedAnims[animationID] = nil
	end
end

return Animation