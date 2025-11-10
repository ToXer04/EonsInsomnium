extends Node2D

@onready var players: Node2D = %Players

var expected_players := []
var ready_players := []

func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	print("Ready!")
	if multiplayer.is_server():
		print("Sono Host!")
	else:
		print("Sono Client!")
	rpc("_spawn_player")

# ---------------------------
# --- SPAWN PLAYER ----------
# ---------------------------

@rpc("any_peer", "call_local")
func _spawn_player():
	print("Spawn")
	var peer_id = multiplayer.get_unique_id()
	var MCName = Singleton.selectedChar
	var scene_path = "res://Scenes/MC/%s/%s.tscn" % [MCName, MCName]
	var player_scene = load(scene_path)
	var player = player_scene.instantiate()
	player.name = "Player_%s" % peer_id
	player.set_multiplayer_authority(peer_id)
	players.add_child(player)
	print("👤 Spawnato ", MCName, " per peer ", peer_id, " su ", multiplayer.get_unique_id())
