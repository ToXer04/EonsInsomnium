extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	print("Ready!")
	if multiplayer.is_server():
		print("Sono Host!")
		spawn_players()  # solo l'host fa spawn!

func spawn_players():
	for peer_id in multiplayer.get_peers():
		_spawn_player(peer_id)
	_spawn_player(multiplayer.get_unique_id()) # anche l'host

func spawn_players_steam():
	for steam_id in SteamLobbyManager.get_lobby_members():
		_spawn_player(steam_id)

func _spawn_player(id):
	print("Spawno per: ", id)
	var player = preload("res://Scenes/MC/Player.tscn").instantiate()
	player.name = "Player_%s" % id
	player.global_position = Vector2(7000.0, 2800.0)
	add_child(player)
	player.set_multiplayer_authority(id)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	print(multiplayer.get_peers().size())
