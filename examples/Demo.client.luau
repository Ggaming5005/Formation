--!strict
local Players = game:GetService("Players")
local Demo = require(game:GetService("ReplicatedStorage").FormationExamples.Demo)
Demo.start(Players.LocalPlayer)
