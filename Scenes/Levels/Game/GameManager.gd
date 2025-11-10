extends Node2D

@onready var players: Node2D = %Players

var player_chars := {} # esempio: {1: "MC1", 2: "MC2"}
var expected_players := [] # lista dei peer che ci aspettiamo (compresi host e client)

func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	print("Ready!")

	if multiplayer.is_server():
		print("Sono Host!")
		player_chars[multiplayer.get_unique_id()] = Singleton.selectedChar
		expected_players = [multiplayer.get_unique_id()] + Array(multiplayer.get_peers())

		# se sono completamente solo, spawn subito
		if expected_players.size() == 1:
			print("👤 Solo host presente, spawn immediato")
			_spawn_player(multiplayer.get_unique_id())
	else:
		print("Sono Client!")
		rpc_id(1, "send_selected_char", multiplayer.get_unique_id(), Singleton.selectedChar)


@rpc("any_peer")
func send_selected_char(peer_id: int, char_name: String):
	if not multiplayer.is_server():
		return

	player_chars[peer_id] = char_name
	print("Host ha ricevuto selezione:", peer_id, "->", char_name)
	rpc("update_player_chars", player_chars)

	if player_chars.size() == expected_players.size():
		print("Tutti i giocatori hanno scelto, spawn in corso...")
		rpc("start_spawn")


@rpc("any_peer", "call_local")
func update_player_chars(chars: Dictionary):
	player_chars = chars
	print("Aggiornato dizionario personaggi:", player_chars)


@rpc("any_peer", "call_local")
func _spawn_player(peer_id: int):
	if not player_chars.has(peer_id):
		print("⚠️ Nessun personaggio definito per peer", peer_id)
		return

	var MCName = player_chars[peer_id]
	var scene_path = "res://Scenes/MC/%s/%s.tscn" % [MCName, MCName]
	var player_scene = load(scene_path)
	var player = player_scene.instantiate()
	player.name = "Player_%s" % peer_id
	player.set_multiplayer_authority(peer_id)
	players.add_child(player)
	print("✅ Spawnato ", MCName, " per peer ", peer_id, " su ", multiplayer.get_unique_id())


@rpc("any_peer", "call_local")
func start_spawn():
	print("🚀 Inizio spawn per tutti...")
	for peer_id in player_chars.keys():
		_spawn_player(peer_id)
