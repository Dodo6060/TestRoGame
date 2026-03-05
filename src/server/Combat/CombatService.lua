--!strict

--[[
	Authoritative melee combat service.
	Security model:
	- Client sends only attack intent (light/heavy + local timestamp)
	- Server validates character state, cooldowns, combo windows, and performs hit detection
	- Server applies all damage, knockback, and stun
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Combat.Config)
local Remotes = require(ReplicatedStorage.Combat.Remotes)
local SharedUtil = require(ReplicatedStorage.Combat.SharedUtil)
local HitboxService = require(script.Parent.HitboxService)

type AttackKind = "Light" | "Heavy"
type PlayerState = "Idle" | "Attacking" | "Stunned" | "Blocking" | "Sprinting"

type MoveDef = {
	id: string,
	attackKind: AttackKind,
	animationId: string,
	damage: number,
	knockback: number,
	stunTime: number,
	windup: number,
	activeTime: number,
	endlag: number,
	cooldown: number,
	hitbox: {
		size: Vector3,
		forwardOffset: number,
		heightOffset: number,
	},
}

type PlayerCombatState = {
	state: PlayerState,
	weaponId: string,
	comboIndex: number,
	lastLightTime: number,
	nextAttackTime: number,
	stunUntil: number,
	activeAttackToken: number,
}

local CombatService = {}

local playerStates: { [Player]: PlayerCombatState } = {}
local attackTokenCounter = 0

local function now(): number
	return workspace:GetServerTimeNow()
end

local function getDefaultState(): PlayerCombatState
	return {
		state = "Idle",
		weaponId = Config.DefaultWeapon,
		comboIndex = 0,
		lastLightTime = 0,
		nextAttackTime = 0,
		stunUntil = 0,
		activeAttackToken = 0,
	}
end

local function getWeaponConfig(state: PlayerCombatState)
	return Config.Weapons[state.weaponId]
end

local function sendCorrection(player: Player, reason: string)
	local state = playerStates[player]
	if not state then
		return
	end
	Remotes.Combat_ServerCorrection:FireClient(player, {
		reason = reason,
		state = state.state,
		comboIndex = state.comboIndex,
		nextAttackTime = state.nextAttackTime,
		serverTime = now(),
	})
end

local function applyStun(character: Model, stunDuration: number)
	local humanoid, _ = SharedUtil.getHumanoidAndRoot(character)
	if not humanoid then
		return
	end
	humanoid.WalkSpeed = 5
	task.delay(stunDuration, function()
		if humanoid.Parent and humanoid.Health > 0 then
			humanoid.WalkSpeed = 16
		end
	end)
end

local function applyKnockback(targetCharacter: Model, sourceRoot: BasePart, forceAmount: number)
	local _, targetRoot = SharedUtil.getHumanoidAndRoot(targetCharacter)
	if not targetRoot then
		return
	end
	local direction = (targetRoot.Position - sourceRoot.Position)
	if direction.Magnitude < 0.001 then
		direction = sourceRoot.CFrame.LookVector
	end
	direction = direction.Unit
	local knockVector = (direction * forceAmount) + Vector3.new(0, forceAmount * 0.2, 0)
	targetRoot.AssemblyLinearVelocity = knockVector
end

local function selectMove(state: PlayerCombatState, attackKind: AttackKind): MoveDef?
	local weapon = getWeaponConfig(state)
	if not weapon then
		return nil
	end

	if attackKind == "Heavy" then
		state.comboIndex = 0
		return weapon.heavyMove
	end

	local current = now()
	if current - state.lastLightTime > weapon.comboResetTime then
		state.comboIndex = 0
	end

	local nextIndex = math.clamp(state.comboIndex + 1, 1, #weapon.lightMoves)
	local move = weapon.lightMoves[nextIndex]
	if not move then
		return nil
	end

	state.comboIndex = nextIndex
	state.lastLightTime = current

	if state.comboIndex >= #weapon.lightMoves then
		state.comboIndex = 0
	end

	return move
end

local function resolveCharacterFromTarget(target: Player | Model): Model?
	if typeof(target) == "Instance" and target:IsA("Player") then
		return target.Character
	elseif typeof(target) == "Instance" and target:IsA("Model") then
		return target
	end
	return nil
end

local function executeAttack(player: Player, state: PlayerCombatState, move: MoveDef)
	local character = player.Character
	if not SharedUtil.isCharacterAlive(character) then
		return
	end

	local _, root = SharedUtil.getHumanoidAndRoot(character)
	if not root then
		return
	end

	attackTokenCounter += 1
	local token = attackTokenCounter
	state.activeAttackToken = token
	state.state = "Attacking"

	Remotes.Combat_PlayEffect:FireAllClients("AttackStarted", {
		attackerUserId = player.UserId,
		moveId = move.id,
		attackKind = move.attackKind,
		animationId = move.animationId,
		windup = move.windup,
	})

	task.delay(move.windup, function()
		if playerStates[player] ~= state or state.activeAttackToken ~= token then
			return
		end

		local attackerCharacter = player.Character
		if not SharedUtil.isCharacterAlive(attackerCharacter) then
			return
		end

		local hitCharacters = HitboxService.performHitboxQuery({
			attacker = player,
			attackerCharacter = attackerCharacter :: Model,
			hitboxSize = move.hitbox.size,
			forwardOffset = move.hitbox.forwardOffset,
			heightOffset = move.hitbox.heightOffset,
			debugEnabled = Config.Debug and Config.DebugHitboxesDefault,
		})

		local targets = HitboxService.resolveTargets(player, hitCharacters, Config.AllowFriendlyFire)
		local alreadyHit: { [Model]: boolean } = {}

		for _, target in ipairs(targets) do
			local targetCharacter = resolveCharacterFromTarget(target)
			if targetCharacter and not alreadyHit[targetCharacter] then
				alreadyHit[targetCharacter] = true

				local targetHumanoid, _ = SharedUtil.getHumanoidAndRoot(targetCharacter)
				if targetHumanoid and targetHumanoid.Health > 0 then
					targetHumanoid:TakeDamage(move.damage)
					applyStun(targetCharacter, move.stunTime)
					applyKnockback(targetCharacter, root, move.knockback)

					Remotes.Combat_PlayEffect:FireAllClients("HitLanded", {
						attackerUserId = player.UserId,
						targetModel = targetCharacter,
						moveId = move.id,
						damage = move.damage,
					})
				end
			end
		end
	end)

	task.delay(move.windup + move.activeTime + move.endlag, function()
		if playerStates[player] ~= state or state.activeAttackToken ~= token then
			return
		end
		if state.stunUntil > now() then
			state.state = "Stunned"
		else
			state.state = "Idle"
		end
	end)
end

local function canAttack(player: Player, state: PlayerCombatState, attackKind: AttackKind): (boolean, string)
	local character = player.Character
	if not SharedUtil.isCharacterAlive(character) then
		return false, "CharacterInvalid"
	end

	local currentTime = now()
	if state.stunUntil > currentTime then
		state.state = "Stunned"
		return false, "Stunned"
	end

	if state.nextAttackTime > currentTime then
		return false, "Cooldown"
	end

	if state.state == "Attacking" then
		return false, "AlreadyAttacking"
	end

	if attackKind == "Light" then
		local weapon = getWeaponConfig(state)
		if weapon and currentTime - state.lastLightTime > weapon.lightComboWindow and state.comboIndex > 0 then
			state.comboIndex = 0
		end
	end

	return true, "OK"
end

function CombatService.onAttackRequest(player: Player, payload)
	local state = playerStates[player]
	if not state then
		return
	end

	if typeof(payload) ~= "table" then
		sendCorrection(player, "MalformedPayload")
		return
	end

	local attackKind = payload.attackKind
	if attackKind ~= "Light" and attackKind ~= "Heavy" then
		sendCorrection(player, "InvalidAttackKind")
		return
	end

	if type(payload.clientTime) ~= "number" then
		sendCorrection(player, "MissingClientTime")
		return
	end

	local delta = math.abs(now() - payload.clientTime)
	if delta > Config.MaxServerValidationLatency then
		sendCorrection(player, "LatencyOutOfBounds")
		return
	end

	local allowed, reason = canAttack(player, state, attackKind)
	if not allowed then
		sendCorrection(player, reason)
		SharedUtil.debugLog(Config.Debug, player.Name, "attack denied:", reason)
		return
	end

	local move = selectMove(state, attackKind)
	if not move then
		sendCorrection(player, "MoveNotFound")
		return
	end

	local totalRecovery = move.windup + move.activeTime + move.endlag + Config.GlobalAttackBuffer
	state.nextAttackTime = now() + math.max(move.cooldown, totalRecovery)
	state.state = "Attacking"

	SharedUtil.debugLog(Config.Debug, player.Name, "attack accepted:", move.id)
	executeAttack(player, state, move)
end

function CombatService.setStunned(player: Player, duration: number)
	local state = playerStates[player]
	if not state then
		return
	end
	state.stunUntil = math.max(state.stunUntil, now() + duration)
	state.state = "Stunned"
end

function CombatService.init()
	Players.PlayerAdded:Connect(function(player)
		playerStates[player] = getDefaultState()
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerStates[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		playerStates[player] = getDefaultState()
	end

	Remotes.Combat_AttackRequest.OnServerEvent:Connect(function(player, payload)
		CombatService.onAttackRequest(player, payload)
	end)

	SharedUtil.debugLog(Config.Debug, "CombatService initialized")
end

return CombatService
