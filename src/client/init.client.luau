--!strict
-- Client entry point for Smash Showdown
-- Handles local player input, UI, and client-side rendering

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

print("[Client] Smash Showdown client starting...")

-- Wait for character
LocalPlayer.CharacterAdded:Connect(function(character)
	print("[Client] Character spawned")
end)

print("[Client] Smash Showdown client initialized!")
