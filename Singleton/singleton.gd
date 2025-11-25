extends Node

var replicated_players_path := "/root/Game/Players/"
var synced := false
var player: CharacterBody2D
var selectedChar: String = "Eon"
var playerSelected: bool = false
var current_scene := "MainMenu"
var replicated_effects_path := "/root/Game/ReplicatedEffects"
