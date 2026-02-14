local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationModule = require(script.Parent)
local store = DataStoreService:GetDataStore("PreloadedAnimations")

-- === CONSTANTS / FLAGS ===
local SAVE = true          -- actually save to DataStore
local DELETE_MODE = false  -- overwrite even if fewer anims than before
local SAVE_INTERVAL = 300  -- seconds between autosaves

-- Helper: safely save table to DataStore
local function safeSetAsync(key, data)
	local success, err = pcall(function()
		store:SetAsync(key, data)
	end)
	if not success then
		warn("Failed to save preloaded animations: " .. err)
	end
end

-- Save all animations globally
local function saveAllAnimations()
	if not SAVE then return end

	local allAnims = AnimationModule.GetAllAnimations()
	local animIds = {}

	for animId, _ in pairs(allAnims) do
		table.insert(animIds, animId)
	end

	if #animIds == 0 then return end

	-- Fetch existing data
	local success, storedData = pcall(function()
		return store:GetAsync("GlobalAnimations")
	end)
	storedData = storedData or {}

	-- Merge existing IDs with current IDs, removing duplicates
	local merged = {}
	local seen = {}
	for _, id in ipairs(storedData) do
		seen[id] = true
		table.insert(merged, id)
	end
	for _, id in ipairs(animIds) do
		if not seen[id] then
			table.insert(merged, id)
			seen[id] = true
		end
	end

	-- Save merged list
	safeSetAsync("GlobalAnimations", merged)
	print("Saved preloaded animations to DataStore ✅ (" .. #merged .. " IDs)")
end

-- Load animations from DataStore and preload into Animation.cachedAnims
local function loadAllAnimations()
	local success, storedData = pcall(function()
		return store:GetAsync("GlobalAnimations")
	end)
	if success and storedData then
		AnimationModule.PreloadAnimations(storedData)
		print("Loaded " .. #storedData .. " preloaded animations ✅")
	else
		warn("Failed to load preloaded animations from DataStore")
	end
end

-- Initial load
loadAllAnimations()

-- Optional: autosave loop
spawn(function()
	while true do
		task.wait(SAVE_INTERVAL)
		saveAllAnimations()
	end
end)

-- Save once on server shutdown
game:BindToClose(function()
	saveAllAnimations()
end)

--[[local RemoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local SaveAnimEvent = RemoteFolder:WaitForChild("SavePreloadedAnimations") -- create this RemoteEvent

SaveAnimEvent.OnServerEvent:Connect(function(player)
	saveAllAnimations()
end)]]

print("Preloaded Animation DataStore Server Script loaded ✅")
