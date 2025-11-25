extends Node

var players := {}
var synced := false
var player: CharacterBody2D
var selectedChar: String = "Eon"
var playerSelected: bool = false
var current_scene := "MainMenu"
var replicated_effects_path := "/root/Game/ReplicatedEffects"


func _process(_delta: float) -> void:
	if not synced:
		if multiplayer.is_server():
			if players.size() == multiplayer.get_peers().size():
				rpc("sync_singleton", players)

@rpc("any_peer", "call_local")
func sync_singleton(server_players := {}):
	players = server_players
	synced = true
