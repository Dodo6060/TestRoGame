--!strict

--[[
	Server-side hitbox utility. Uses spatial query against workspace with OverlapParams.
	This service never trusts client hit reports.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedUtil = require(ReplicatedStorage.Combat.SharedUtil)

local HitboxService = {}

export type HitboxQueryData = {
	attacker: Player,
	attackerCharacter: Model,
	hitboxSize: Vector3,
	forwardOffset: number,
	heightOffset: number,
	debugEnabled: boolean,
}

function HitboxService.performHitboxQuery(data: HitboxQueryData): { Model }
	local _, root = SharedUtil.getHumanoidAndRoot(data.attackerCharacter)
	if not root then
		return {}
	end

	local cframe = root.CFrame * CFrame.new(0, data.heightOffset, -data.forwardOffset)

	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { data.attackerCharacter }

	local parts = workspace:GetPartBoundsInBox(cframe, data.hitboxSize, params)
	local uniqueCharacters: { [Model]: boolean } = {}
	local hitCharacters: { Model } = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not uniqueCharacters[model] then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				uniqueCharacters[model] = true
				table.insert(hitCharacters, model)
			end
		end
	end

	if data.debugEnabled then
		local debugPart = Instance.new("Part")
		debugPart.Name = "CombatHitboxDebug"
		debugPart.Anchored = true
		debugPart.CanCollide = false
		debugPart.CanTouch = false
		debugPart.CanQuery = false
		debugPart.Transparency = 0.8
		debugPart.Material = Enum.Material.Neon
		debugPart.Color = Color3.fromRGB(255, 120, 80)
		debugPart.Size = data.hitboxSize
		debugPart.CFrame = cframe
		debugPart.Parent = workspace
		task.delay(0.08, function()
			debugPart:Destroy()
		end)
	end

	return hitCharacters
end

function HitboxService.resolveTargets(attacker: Player, hitCharacters: { Model }, allowFriendlyFire: boolean): { Player | Model }
	local targets: { Player | Model } = {}

	for _, character in ipairs(hitCharacters) do
		if SharedUtil.isEnemy(attacker, character, allowFriendlyFire) then
			local targetPlayer = Players:GetPlayerFromCharacter(character)
			if targetPlayer then
				table.insert(targets, targetPlayer)
			else
				table.insert(targets, character)
			end
		end
	end

	return targets
end

return HitboxService
