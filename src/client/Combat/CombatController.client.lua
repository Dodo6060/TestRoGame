--!strict

--[[
	Client combat controller:
	- Captures combat + sprint input
	- Plays local animation quickly for responsive feel
	- Requests authoritative attack/sprint from server
	- Handles correction events to resync when denied
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local combatFolder = ReplicatedStorage:WaitForChild("Combat")
local Config = require(combatFolder:WaitForChild("Config") :: ModuleScript)
local Remotes = require(combatFolder:WaitForChild("Remotes") :: ModuleScript)

local localPlayer = Players.LocalPlayer

local isAttackingPredicted = false
local isSprintingLocal = false
local localDebugHitbox = Config.DebugHitboxesDefault
local activeTracks: { [string]: AnimationTrack } = {}
local sprintTrack: AnimationTrack? = nil

local function debugLog(...: any)
	if Config.Debug then
		print("[CombatClient]", ...)
	end
end

local function getCharacterAndHumanoid(): (Model?, Humanoid?)
	local character = localPlayer.Character
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return character, nil
	end
	return character, humanoid
end

local function getAnimator(): Animator?
	local _, humanoid = getCharacterAndHumanoid()
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

local function stopSprintAnimation()
	if sprintTrack and sprintTrack.IsPlaying then
		sprintTrack:Stop(0.1)
	end
	sprintTrack = nil
end

local function playSprintAnimation()
	if Config.Movement.sprintAnimationId == "" then
		return
	end

	local animator = getAnimator()
	if not animator then
		return
	end

	stopSprintAnimation()
	local animation = Instance.new("Animation")
	animation.AnimationId = Config.Movement.sprintAnimationId
	local track = animator:LoadAnimation(animation)
	track.Priority = Enum.AnimationPriority.Movement
	track:Play(0.12, 1, 1)
	sprintTrack = track
end

local function setSprintLocal(nextSprint: boolean)
	if isSprintingLocal == nextSprint then
		return
	end

	isSprintingLocal = nextSprint
	if nextSprint then
		playSprintAnimation()
	else
		stopSprintAnimation()
	end
end

local function canStartSprintLocally(): boolean
	local _, humanoid = getCharacterAndHumanoid()
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if humanoid.Sit then
		return false
	end

	local movementState = humanoid:GetState()
	if movementState == Enum.HumanoidStateType.Dead
		or movementState == Enum.HumanoidStateType.Physics
		or movementState == Enum.HumanoidStateType.Ragdoll
		or movementState == Enum.HumanoidStateType.Seated then
		return false
	end

	return true
end

local function requestSprint(isSprinting: boolean)
	if isSprinting and not canStartSprintLocally() then
		return
	end

	setSprintLocal(isSprinting)
	Remotes.Combat_SprintRequest:FireServer({
		isSprinting = isSprinting,
		clientTime = workspace:GetServerTimeNow(),
	})
end

local function requestAttack(attackKind: "Light" | "Heavy")
	if isSprintingLocal then
		if Config.Movement.stopSprintOnAttackAttempt then
			requestSprint(false)
		else
			debugLog("Attack ignored during sprint", attackKind)
		end
		return
	end

	stopSprintAnimation()
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
	elseif input.KeyCode == Config.Movement.sprintKeyCode then
		requestSprint(true)
	elseif input.KeyCode == Enum.KeyCode.H then
		localDebugHitbox = not localDebugHitbox
		debugLog("Local hitbox debug toggled:", localDebugHitbox)
	end
end)

UserInputService.InputEnded:Connect(function(input, _gameProcessed)
	if input.KeyCode == Config.Movement.sprintKeyCode then
		requestSprint(false)
	end
end)

Remotes.Combat_PlayEffect.OnClientEvent:Connect(function(effectType: string, payload)
	if effectType == "AttackStarted" then
		if payload.attackerUserId == localPlayer.UserId then
			setSprintLocal(false)
			playAnimation(payload.moveId, payload.animationId)
		end
		-- TODO: add world swing VFX/SFX for nearby players
	elseif effectType == "HitLanded" then
		-- TODO: add hit spark/hit reaction VFX/SFX
	end
end)

Remotes.Combat_ServerCorrection.OnClientEvent:Connect(function(payload)
	debugLog("Server correction:", payload.reason, "state:", payload.state)
	setSprintLocal(payload.isSprinting == true)

	if isAttackingPredicted then
		isAttackingPredicted = false
		stopAllPredictedAnimations()
	end
end)

local function bindCharacterStateGuards(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.StateChanged:Connect(function(_, nextState)
		if not isSprintingLocal then
			return
		end

		if nextState == Enum.HumanoidStateType.Dead
			or nextState == Enum.HumanoidStateType.Physics
			or nextState == Enum.HumanoidStateType.Ragdoll
			or nextState == Enum.HumanoidStateType.Seated then
			requestSprint(false)
		end
	end)
end

-- Minimal character hook so combat is active without extra UI/tool.
localPlayer.CharacterAdded:Connect(function(character)
	setSprintLocal(false)
	bindCharacterStateGuards(character)
	debugLog("Character spawned, combat input active")
end)

if localPlayer.Character then
	bindCharacterStateGuards(localPlayer.Character)
end

debugLog("CombatController started")
