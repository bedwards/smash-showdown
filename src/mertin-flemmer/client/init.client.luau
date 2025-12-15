--!strict
-- Mertin-Flemmer Client
-- Survival horror client-side systems

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("[Client] Mertin-Flemmer loading...")
print("[Client] Stay near the light. Survive the night.")

LocalPlayer.CharacterAdded:Connect(function(character)
	print("[Client] You awaken in the forest...")
end)

print("[Client] Mertin-Flemmer ready!")
