--!strict

local Players = game:GetService("Players")

local SharedUtil = {}

function SharedUtil.isCharacterAlive(character: Model?): boolean
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	return humanoid.Health > 0
end

function SharedUtil.getHumanoidAndRoot(character: Model?): (Humanoid?, BasePart?)
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		return nil, nil
	end
	return humanoid, root
end

function SharedUtil.findPlayerFromCharacter(character: Model?): Player?
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

function SharedUtil.isEnemy(attacker: Player, targetCharacter: Model, allowFriendlyFire: boolean): boolean
	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	if not targetPlayer then
		return true
	end
	if targetPlayer == attacker then
		return false
	end
	if allowFriendlyFire then
		return true
	end
	if attacker.Team ~= nil and targetPlayer.Team ~= nil and attacker.Team == targetPlayer.Team then
		return false
	end
	return true
end

function SharedUtil.debugLog(enabled: boolean, ...: any)
	if enabled then
		print("[Combat]", ...)
	end
end

return SharedUtil
