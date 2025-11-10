extends Node2D 
@onready var players: Node2D = %Players 
# Called when the node enters the scene tree for the first time. 
func _ready(): 
	multiplayer.multiplayer_peer = SteamLobbyManager.peer 
	print("Ready!") 
	if multiplayer.is_server(): 
		print("Sono Host!") 
		spawn_players() # solo l'host fa spawn! # GameManager.gd 

@rpc("any_peer", "call_local")
func _spawn_player(peer_id):
	var MCName = Singleton.selectedChar 
	var scene_path = "res://Scenes/MC/%s/%s.tscn" % [MCName, MCName] 
	var player_scene = load(scene_path) 
	var player = player_scene.instantiate() 
	player.name = "Player_%s" % peer_id 
	player.set_multiplayer_authority(peer_id) 
	players.add_child(player) 

func spawn_players():
	# Spawna l'host
	_spawn_player(multiplayer.get_unique_id())

	# Spawna i client sia localmente che su di loro
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "_spawn_player", peer_id)
		_spawn_player(peer_id)
