--!strict

--[[
	Creates/fetches combat remotes from ReplicatedStorage.
	Required remotes:
	- Combat_AttackRequest (client -> server)
	- Combat_PlayEffect (server -> all clients)
	- Combat_ServerCorrection (server -> client)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOLDER_NAME = "CombatRemotes"

local function getOrCreateRemote(parent: Instance, remoteName: string): RemoteEvent
	local existing = parent:FindFirstChild(remoteName)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = parent
	return remote
end

local remotesFolder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = FOLDER_NAME
	remotesFolder.Parent = ReplicatedStorage
end

local Remotes = {
	Combat_AttackRequest = getOrCreateRemote(remotesFolder, "Combat_AttackRequest"),
	Combat_PlayEffect = getOrCreateRemote(remotesFolder, "Combat_PlayEffect"),
	Combat_ServerCorrection = getOrCreateRemote(remotesFolder, "Combat_ServerCorrection"),
}

return Remotes
