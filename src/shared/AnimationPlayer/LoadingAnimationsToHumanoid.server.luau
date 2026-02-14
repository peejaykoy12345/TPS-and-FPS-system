local Players = game:GetService("Players")
local AnimationPlayer = require(script.Parent)

Players.PlayerAdded:Connect(function(plr: Player)
	local conn: RBXScriptConnection?
	conn = plr.CharacterAdded:Once(function(char: Model)
		local anims = AnimationPlayer.GetAllAnims()
		local loadedTracks = {}

		for _, animId in pairs(anims) do
			if typeof(animId) == "string" then
				animId = animId:gsub("rbxassetid://", "")
			end

			-- Load animation track but DON'T play it yet
			local animTrack = AnimationPlayer.LoadAnimationTrack(char, animId)
			loadedTracks[animId] = animTrack
		end

		-- Optional: if you want, you can play briefly then stop to force Roblox to cache it
		for _, track in pairs(loadedTracks) do
			track:Play()  -- plays the animation
			track.Stopped:Wait()  -- immediately stops it
		end
		
		print("Done preplaying animations")
		conn:Disconnect()
	end)
end)