extends Node2D

@onready var players: Node2D = $Players

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	print("Ready!")
	if multiplayer.is_server():
		print("Sono Host!")
		spawn_players()  # solo l'host fa spawn!

func spawn_players():
	_spawn_player.rpc(multiplayer.get_unique_id()) # anche l'host
	for peer_id in multiplayer.get_peers():
		_spawn_player.rpc(peer_id)

func spawn_players_steam():
	for steam_id in SteamLobbyManager.get_lobby_members():
		_spawn_player(steam_id)

@rpc("authority", "call_local") 
func _spawn_player(id): 
	print("Spawno per: ", id) 
	var player = preload("res://Scenes/MC/Player.tscn").instantiate() 
	player.name = "Player_%s" % id 
	player.set_multiplayer_authority(id) 
	player.global_position = Vector2(7000.0, 2800.0) 
	players.add_child(player)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
