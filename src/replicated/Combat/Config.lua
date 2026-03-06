--!strict

--[[
	Central combat tuning values.
	Per project guideline, all tunables for damage/hit rules/cooldowns live in this file.
]]

local Config = {}

Config.Debug = true
Config.DefaultWeapon = "Sword"
Config.AllowFriendlyFire = false
Config.MaxServerValidationLatency = 0.6
Config.GlobalAttackBuffer = 0.04
Config.DebugHitboxesDefault = false

Config.Movement = {
	normalWalkSpeed = 16,
	sprintWalkSpeed = 24,
	stunWalkSpeed = 5,
	sprintKeyCode = Enum.KeyCode.LeftShift,
	stopSprintOnAttackAttempt = true,
	sprintAnimationId = "", -- TODO: add sprint animation asset id if desired
}

Config.Weapons = {
	Sword = {
		lightComboWindow = 0.9,
		comboResetTime = 1.2,
		lightMoves = {
			{
				id = "Sword_L1",
				attackKind = "Light",
				animationId = "rbxassetid://000000001", -- TODO: replace with real animation
				damage = 8,
				knockback = 35,
				stunTime = 0.22,
				windup = 0.08,
				activeTime = 0.12,
				endlag = 0.14,
				cooldown = 0.28,
				hitbox = {
					size = Vector3.new(4, 5, 5),
					forwardOffset = 3,
					heightOffset = 0,
				},
			},
			{
				id = "Sword_L2",
				attackKind = "Light",
				animationId = "rbxassetid://000000002", -- TODO: replace with real animation
				damage = 9,
				knockback = 37,
				stunTime = 0.24,
				windup = 0.09,
				activeTime = 0.12,
				endlag = 0.16,
				cooldown = 0.3,
				hitbox = {
					size = Vector3.new(4.5, 5, 5.5),
					forwardOffset = 3.4,
					heightOffset = 0,
				},
			},
			{
				id = "Sword_L3",
				attackKind = "Light",
				animationId = "rbxassetid://000000003", -- TODO: replace with real animation
				damage = 10,
				knockback = 40,
				stunTime = 0.26,
				windup = 0.1,
				activeTime = 0.13,
				endlag = 0.18,
				cooldown = 0.34,
				hitbox = {
					size = Vector3.new(5, 5, 5.5),
					forwardOffset = 3.8,
					heightOffset = 0,
				},
			},
			{
				id = "Sword_L4",
				attackKind = "Light",
				animationId = "rbxassetid://000000004", -- TODO: replace with real animation
				damage = 13,
				knockback = 48,
				stunTime = 0.3,
				windup = 0.12,
				activeTime = 0.14,
				endlag = 0.24,
				cooldown = 0.45,
				hitbox = {
					size = Vector3.new(5.5, 5.2, 6),
					forwardOffset = 4,
					heightOffset = 0,
				},
			},
		},
		heavyMove = {
			id = "Sword_H1",
			attackKind = "Heavy",
			animationId = "rbxassetid://000000010", -- TODO: replace with real animation
			damage = 22,
			knockback = 75,
			stunTime = 0.42,
			windup = 0.3,
			activeTime = 0.18,
			endlag = 0.35,
			cooldown = 1.2,
			hitbox = {
				size = Vector3.new(6, 5.5, 7),
				forwardOffset = 4.6,
				heightOffset = 0,
			},
		},
	},
}

return Config
