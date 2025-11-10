extends Node2D

@onready var players: Node2D = %Players

var player_chars := {} # {peer_id: "NomePersonaggio"}
var total_players_expected := 0

func _ready():
	multiplayer.multiplayer_peer = SteamLobbyManager.peer
	print("Ready!")

	if multiplayer.is_server():
		print("Sono Host!")
		# Conta host + tutti i client
		total_players_expected = multiplayer.get_peers().size() + 1
	else:
		print("Sono Client!")

	# Invia la selezione del personaggio all’host (peer 1)
	rpc_id(1, "send_selected_char", multiplayer.get_unique_id(), Singleton.selectedChar)

	# Se sono host, mi registro subito nel dizionario
	if multiplayer.is_server():
		player_chars[multiplayer.get_unique_id()] = Singleton.selectedChar


# ---------------------------
# --- SYNC PERSONAGGI -------
# ---------------------------

@rpc("any_peer")
func send_selected_char(peer_id: int, char_name: String):
	if not multiplayer.is_server():
		return

	player_chars[peer_id] = char_name
	print("Host ha ricevuto selezione:", peer_id, "->", char_name)

	# Rimanda il dizionario aggiornato a tutti
	rpc("update_player_chars", player_chars)

	# Quando tutti i peer hanno inviato la loro selezione, si può spawnare
	if player_chars.size() == total_players_expected:
		print("Tutti i giocatori registrati, procedo con lo spawn.")
		spawn_players()


@rpc("any_peer", "call_local")
func update_player_chars(chars: Dictionary):
	player_chars = chars
	print("Aggiornato dizionario personaggi:", player_chars)


# ---------------------------
# --- SPAWN PLAYER ----------
# ---------------------------

@rpc("any_peer", "call_local")
func _spawn_player(peer_id: int):
	if not player_chars.has(peer_id):
		print("Attenzione: nessun personaggio definito per peer", peer_id)
		return

	var MCName = player_chars[peer_id]
	var scene_path = "res://Scenes/MC/%s/%s.tscn" % [MCName, MCName]
	var player_scene = load(scene_path)
	var player = player_scene.instantiate()
	player.name = "Player_%s" % peer_id
	player.set_multiplayer_authority(peer_id)
	players.add_child(player)
	print("Spawnato", MCName, "per peer", peer_id, "su", multiplayer.get_unique_id())


func spawn_players():
	print("Spawning players...")

	# Spawna l'host
	_spawn_player(multiplayer.get_unique_id())

	# Spawna tutti i client (sia localmente che sui loro peer)
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "_spawn_player", peer_id)
		_spawn_player(peer_id)
