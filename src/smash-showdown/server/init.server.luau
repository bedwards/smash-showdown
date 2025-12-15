--!strict
-- Server entry point for Smash Showdown
-- Other server scripts handle specific systems:
-- - Arena.server.luau: Arena generation
-- - Ball.server.luau: Ball physics
-- - Combat.server.luau: Combat system
-- - Health.server.luau: Health and KO

local Players = game:GetService("Players")

print("[Server] Smash Showdown server starting...")
print("[Server] Game systems loading...")

-- Track player count
Players.PlayerAdded:Connect(function(player: Player)
	print("[Server] Player joined:", player.Name, "| Total:", #Players:GetPlayers())
end)

Players.PlayerRemoving:Connect(function(player: Player)
	print("[Server] Player left:", player.Name)
end)

print("[Server] Smash Showdown ready!")
