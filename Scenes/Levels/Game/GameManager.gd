extends Node2D

@onready var players: Node2D = %Players
@onready var spawner: MultiplayerSpawner = %MultiplayerSpawner

func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	print("Ready!")

	if multiplayer.is_server():
		print("Sono Host!")
	else:
		print("Sono Client!")

	# Configura lo spawner per generare i giocatori automaticamente
	spawner.spawn_path = players.get_path()
	spawner.spawn_function = Callable(self, "_create_player")
	spawner.spawn_limit = 0  # Nessun limite di giocatori

	# Se sei host, spawna te stesso (gli altri verranno gestiti automaticamente)
	if multiplayer.is_server():
		_spawn_local_player()

# ---------------------------
# --- CREAZIONE PLAYER ------
# ---------------------------

func _create_player(peer_id: int):
	var MCName = Singleton.selectedChar
	var scene_path = "res://Scenes/MC/%s/%s.tscn" % [MCName, MCName]
	var player_scene = load(scene_path)
	var player = player_scene.instantiate()
	player.name = "Player_%s" % peer_id
	player.set_multiplayer_authority(peer_id)
	return player

func _spawn_local_player():
	var peer_id = multiplayer.get_unique_id()
	print("👤 Creo player locale per peer ", peer_id)
	var player = _create_player(peer_id)
	players.add_child(player)
