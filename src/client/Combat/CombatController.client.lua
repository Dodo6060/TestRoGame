--!strict

--[[
	Client combat controller:
	- Captures input (M1/M2)
	- Plays local animation quickly for responsive feel
	- Requests authoritative attack from server
	- Handles correction events to resync when attack denied
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Combat.Config)
local Remotes = require(ReplicatedStorage.Combat.Remotes)

local localPlayer = Players.LocalPlayer

local isAttackingPredicted = false
local localDebugHitbox = Config.DebugHitboxesDefault
local activeTracks: { [string]: AnimationTrack } = {}

local function debugLog(...: any)
	if Config.Debug then
		print("[CombatClient]", ...)
	end
end

local function getAnimator(): Animator?
	local character = localPlayer.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		return animator
	end
	animator = Instance.new("Animator")
	animator.Parent = humanoid
	return animator
end

local function playAnimation(moveId: string, animationId: string)
	local animator = getAnimator()
	if not animator then
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Action
	track:Play(0.05, 1, 1)
	activeTracks[moveId] = track
end

local function stopAllPredictedAnimations()
	for moveId, track in pairs(activeTracks) do
		if track.IsPlaying then
			track:Stop(0.08)
		end
		activeTracks[moveId] = nil
	end
end

local function requestAttack(attackKind: "Light" | "Heavy")
	isAttackingPredicted = true
	Remotes.Combat_AttackRequest:FireServer({
		attackKind = attackKind,
		clientTime = workspace:GetServerTimeNow(),
	})
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		requestAttack("Light")
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		requestAttack("Heavy")
	elseif input.KeyCode == Enum.KeyCode.H then
		localDebugHitbox = not localDebugHitbox
		debugLog("Local hitbox debug toggled:", localDebugHitbox)
	end
end)

Remotes.Combat_PlayEffect.OnClientEvent:Connect(function(effectType: string, payload)
	if effectType == "AttackStarted" then
		if payload.attackerUserId == localPlayer.UserId then
			playAnimation(payload.moveId, payload.animationId)
		end
		-- TODO: add world swing VFX/SFX for nearby players
	elseif effectType == "HitLanded" then
		-- TODO: add hit spark/hit reaction VFX/SFX
	end
end)

Remotes.Combat_ServerCorrection.OnClientEvent:Connect(function(payload)
	debugLog("Server correction:", payload.reason, "state:", payload.state)
	if isAttackingPredicted then
		isAttackingPredicted = false
		stopAllPredictedAnimations()
	end
	-- Graceful re-sync hook point for future client state machine.
end)

-- Minimal character hook so combat is active without extra UI/tool.
localPlayer.CharacterAdded:Connect(function()
	debugLog("Character spawned, combat input active")
end)

debugLog("CombatController started")
