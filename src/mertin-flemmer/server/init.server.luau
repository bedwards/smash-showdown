--!strict
-- Mertin-Flemmer Server
-- Survival horror - survive the night in a mysterious location

local Players = game:GetService("Players")

print("[Server] Mertin-Flemmer starting...")
print("[Server] Survive the night. Find the light.")

Players.PlayerAdded:Connect(function(player)
	print("[Server] Survivor joined:", player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	print("[Server] Survivor left:", player.Name)
end)

print("[Server] Mertin-Flemmer ready!")
