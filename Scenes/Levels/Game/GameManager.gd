extends Node2D

@onready var players: Node2D = %Players

# Called when the node enters the scene tree for the first time.
var peer_characters = {}  # peer_id -> character_name

func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	if multiplayer.is_server():
		print("Sono Host!")
		var my_id = multiplayer.get_unique_id()
		var my_char = Singleton.selectedChar
		peer_characters[my_id] = my_char
		_spawn_player(my_id, my_char)  # spawn locale dell’host
	else:
		rpc_id(1, "request_spawn", Singleton.selectedChar)  # invia scelta al server

@rpc("any_peer")  # chiunque può chiamare
func request_spawn(character_name):
	var peer_id = multiplayer.get_rpc_sender_id()
	peer_characters[peer_id] = character_name
	_spawn_player(peer_id, character_name)

func _spawn_player(peer_id, character_name):
	var scene_path = "res://Scenes/MC/%s/%s.tscn" % [character_name, character_name]
	var player_scene = load(scene_path)
	var player = player_scene.instantiate()
	player.name = "Player_%s" % peer_id
	player.set_multiplayer_authority(peer_id)
	players.add_child(player)
	
	# Notifica tutti i client che il player è stato spawnato
	rpc("client_add_player", peer_id, character_name)


@rpc("call_local")
func client_add_player(peer_id, character_name):
	if multiplayer.get_unique_id() == peer_id:
		return # già spawnato localmente
	var scene_path = "res://Scenes/MC/%s/%s.tscn" % [character_name, character_name]
	var player_scene = load(scene_path)
	var player = player_scene.instantiate()
	player.name = "Player_%s" % peer_id
	players.add_child(player)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
