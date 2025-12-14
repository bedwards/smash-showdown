--!strict
-- Server entry point for Smash Showdown
-- Handles game initialization, player connections, and server-side logic

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[Server] Smash Showdown server starting...")

-- Player connection handling
Players.PlayerAdded:Connect(function(player: Player)
	print("[Server] Player joined:", player.Name)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	print("[Server] Player left:", player.Name)
end)

print("[Server] Smash Showdown server initialized!")
