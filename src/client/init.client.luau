--!strict
-- Client entry point for Smash Showdown
-- Other client scripts handle specific systems:
-- - Controller.client.luau: Movement and combat input
-- - BallClient.client.luau: Ball hitting
-- - UI.client.luau: Health bars and HUD

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

print("[Client] Smash Showdown client starting...")

LocalPlayer.CharacterAdded:Connect(function(character)
	print("[Client] Character ready!")
end)

print("[Client] Smash Showdown client ready!")
