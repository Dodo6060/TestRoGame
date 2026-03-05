--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local combatFolder = ServerScriptService:WaitForChild("Combat")
local CombatService = require(combatFolder:WaitForChild("CombatService") :: ModuleScript)

CombatService.init()
