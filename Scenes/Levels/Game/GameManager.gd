extends Node2D

@onready var players: Node2D = $Players

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	print("Ready!")
	if multiplayer.is_server():
		print("Sono Host!")
		spawn_players()  # solo l'host fa spawn!

# GameManager.gd

@rpc("authority", "call_local")
func _spawn_player(peer_id):
	var player = preload("res://Scenes/MC/Player.tscn").instantiate()
	player.name = "Player_%s" % peer_id
	player.set_multiplayer_authority(peer_id)
	players.add_child(player)

func spawn_players():
	# spawn host
	_spawn_player(multiplayer.get_unique_id())

	# spawn tutti i client sul host
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "_spawn_player", peer_id) # manda RPC al client
		# contemporaneamente spawn anche sul host
		_spawn_player(peer_id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
