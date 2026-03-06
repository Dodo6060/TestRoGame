--!strict

--[[
	Shared combat type aliases and constants used by both client and server.
	Keeping these centralized makes remotes and state handling easier to maintain.
]]

local CombatTypes = {}

export type AttackKind = "Light" | "Heavy"
export type PlayerState = "Idle" | "Attacking" | "Stunned" | "Blocking" | "Sprinting"

export type HitboxDef = {
	size: Vector3,
	forwardOffset: number,
	heightOffset: number,
}

export type MoveDef = {
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
	hitbox: HitboxDef,
}

export type WeaponConfig = {
	lightComboWindow: number,
	comboResetTime: number,
	lightMoves: { MoveDef },
	heavyMove: MoveDef,
}

export type AttackRequest = {
	attackKind: AttackKind,
	clientTime: number,
}

export type SprintRequest = {
	isSprinting: boolean,
	clientTime: number,
}

export type ServerCorrectionPayload = {
	reason: string,
	state: PlayerState,
	comboIndex: number,
	nextAttackTime: number,
	serverTime: number,
	isSprinting: boolean,
}

CombatTypes.AttackKind = {
	Light = "Light",
	Heavy = "Heavy",
}

CombatTypes.PlayerState = {
	Idle = "Idle",
	Attacking = "Attacking",
	Stunned = "Stunned",
	Blocking = "Blocking",
	Sprinting = "Sprinting",
}

return CombatTypes
