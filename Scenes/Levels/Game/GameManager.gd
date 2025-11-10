extends Node2D

@onready var players: Node2D = %Players

var player_chars := {} # { peer_id: "MC1" }
var expected_players := []
var ready_players := []

func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	print("Ready!")

	if multiplayer.is_server():
		print("Sono Host!")
		player_chars[multiplayer.get_unique_id()] = Singleton.selectedChar
		expected_players = [multiplayer.get_unique_id()] + Array(multiplayer.get_peers())

		# Se sono solo, spawn immediato
		if expected_players.size() == 1:
			print("👤 Solo host presente, spawn immediato")
			_spawn_player(multiplayer.get_unique_id())
	else:
		print("Sono Client!")
		# Avviso l'host che ho caricato la scena
		rpc_id(1, "client_ready", multiplayer.get_unique_id())
		# E invio anche il mio personaggio
		rpc_id(1, "send_selected_char", multiplayer.get_unique_id(), Singleton.selectedChar)


# ---------------------------
# --- SYNC PERSONAGGI -------
# ---------------------------

@rpc("any_peer")
func send_selected_char(peer_id: int, char_name: String):
	if not multiplayer.is_server():
		return

	player_chars[peer_id] = char_name
	print("Host ha ricevuto selezione:", peer_id, "->", char_name)
	rpc("update_player_chars", player_chars)

	check_start_conditions()


@rpc("any_peer", "call_local")
func update_player_chars(chars: Dictionary):
	player_chars = chars
	print("Aggiornato dizionario personaggi:", player_chars)


# ---------------------------
# --- SYNC READY STATE ------
# ---------------------------

@rpc("any_peer")
func client_ready(peer_id: int):
	if not multiplayer.is_server():
		return

	print("Client", peer_id, "ha caricato la scena.")
	if not ready_players.has(peer_id):
		ready_players.append(peer_id)

	check_start_conditions()


func check_start_conditions():
	if not multiplayer.is_server():
		return

	# Controlla se tutti sono pronti e hanno inviato il personaggio
	var everyone_ready = ready_players.size() == (expected_players.size() - 1)
	var everyone_chosen = player_chars.size() == expected_players.size()

	if everyone_ready and everyone_chosen:
		print("✅ Tutti pronti, spawn in corso!")
		rpc("start_spawn")


# ---------------------------
# --- SPAWN PLAYER ----------
# ---------------------------

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
	print("👤 Spawnato ", MCName, " per peer ", peer_id, " su ", multiplayer.get_unique_id())


@rpc("any_peer", "call_local")
func start_spawn():
	print("🚀 Inizio spawn per tutti...")
	for peer_id in player_chars.keys():
		_spawn_player(peer_id)
