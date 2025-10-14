# SteamLobbyManager.gd
extends Node

var lobby_code_label: Label = null
var lobby_id: int = 0
var code: String = ""
@export var max_players: int = 4  # max players including host
@export var enet_port: int = 8910  # porta ENet

var _enet_peer: ENetMultiplayerPeer = null
var _is_host: bool = false

# ------------------------
# Ready
# ------------------------
func _ready() -> void:
	Steam.steamInit(3961570)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

func _process(_delta):
	Steam.run_callbacks()
	_read_p2p_messages()

# ------------------------
# P2P messages
# ------------------------
func _read_p2p_messages():
	while Steam.getAvailableP2PPacketSize(0) > 0:
		var packet = Steam.readP2PPacket(Steam.getAvailableP2PPacketSize(0), 0)
		if packet and packet.has("data"):
			var message = packet.data.get_string_from_utf8()
			match message:
				"DISBAND":
					_on_disband_received()
				"KICK":
					_on_kick_received()
				"START_GAME":
					# Host ha iniziato la partita via Steam: riceviamo l'indicazione
					_start_game_rpc()
				_:
					if message.begins_with("HOSTINFO:"):
						# formato: HOSTINFO:ip:port
						var payload = message.substr("HOSTINFO:".length(), message.length())
						var parts = payload.split(":")
						print("DEBUG: ricevuto HOSTINFO parts:", parts)
						if parts.size() >= 2:
							var ip = parts[0]
							var port = int(parts[1])
							connect_to_enet_host(ip, port)
						else:
							push_warning("HOSTINFO malformato: %s" % payload)
					else:
						# eventuali messaggi custom
						pass

# ------------------------
# Send message to all lobby members via Steam P2P
# ------------------------
func send_message_to_all(message: String):
	var buffer = message.to_utf8_buffer()
	for member_id in get_lobby_members():
		if int(member_id) != Steam.getSteamID():
			Steam.acceptP2PSessionWithUser(int(member_id))
			Steam.sendP2PPacket(int(member_id), buffer, Steam.P2PSend.P2P_SEND_RELIABLE, 0)

# ------------------------
# Host starts the game (Steam + ENet)
# ------------------------
func start_hosting_game():
	# Verifica che siamo davvero l'owner Steam della lobby
	if not _am_i_lobby_owner():
		push_error("Solo il proprietario della lobby può avviare la partita.")
		return

	print("📡 Host avvia il gioco (owner confirmed). SteamID:", Steam.getSteamID(), "LobbyOwner:", Steam.getLobbyOwner(lobby_id))
	_is_host = true

	# 1) crea ENet server (solo host)
	start_enet_server()

	# 2) notifica everyone via Steam che la partita parte
	send_message_to_all("START_GAME")

	# 3) poi lancia la scena (start_game_rpc è locale per l'host e sarà ricevuto via STEAM dai client)
	_start_game_rpc()

# ------------------------
# RPC-like function called when START_GAME received
# ------------------------
func _start_game_rpc():
	print("🔁 Cambio scena a Game.tscn")
	# Nota: la scena verrà cambiata sia sull'host che sui client che riceveranno START_GAME
	get_tree().change_scene_to_file("res://Scenes/Levels/Game/Game.tscn")

# ------------------------
# Lobby creation/joining
# ------------------------
func generate_lobby_code():
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]

func host_lobby() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, max_players)

func _on_lobby_created(result: int, this_lobby_id: int) -> void:
	if result != 1:
		return
	lobby_id = this_lobby_id
	Steam.setLobbyJoinable(lobby_id, true)
	generate_lobby_code()
	Steam.setLobbyData(lobby_id, "lobby_code", code)
	get_tree().call_group("MainMenu", "update_lobby_players_ui")
	print("Lobby creata:", lobby_id, "code:", code)

func join_by_code(join_code: String) -> void:
	Steam.addRequestLobbyListResultCountFilter(1)
	Steam.addRequestLobbyListStringFilter("lobby_code", join_code, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void: 
	if lobby_id != this_lobby_id: 
		Steam.leaveLobby(lobby_id) 
		Steam.joinLobby(this_lobby_id)

func _on_lobby_match_list(lobbies_found: Array) -> void:
	if lobbies_found.size() == 0:
		return
	var lobby_found = lobbies_found[0]
	if lobby_id != lobby_found:
		Steam.leaveLobby(lobby_id)
		Steam.joinLobby(lobby_found)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		return
	lobby_id = this_lobby_id
	code = Steam.getLobbyData(lobby_id, "lobby_code")
	lobby_code_label.text = code
	get_tree().call_group("MainMenu", "update_lobby_players_ui")
	get_tree().call_group("MainMenu", "go_to_section", 3)

	# accetta P2P session con tutti i membri (utile per passare HOSTINFO etc.)
	for member in get_lobby_members():
		if int(member) != Steam.getSteamID():
			Steam.acceptP2PSessionWithUser(int(member))

	print("Joined lobby:", lobby_id, "my SteamID:", Steam.getSteamID(), "owner:", Steam.getLobbyOwner(lobby_id))

func _on_lobby_left():
	lobby_id = 0
	code = ""
	get_tree().call_group("MainMenu", "go_to_section", 0)
	get_tree().call_group("MainMenu", "update_lobby_players_ui")

# ------------------------
# Helpers
# ------------------------
func get_lobby_members() -> Array:
	var members = []
	if lobby_id == 0:
		return members
	var member_count = Steam.getNumLobbyMembers(lobby_id)
	for i in range(member_count):
		var steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		if steam_id:
			members.append(steam_id)
	return members

func get_lobby_members_names() -> Array: 
	var members = [] 
	if lobby_id == 0: 
		return members 
	var member_count = Steam.getNumLobbyMembers(lobby_id) 
	for i in range(member_count): 
		var steam_id = Steam.getLobbyMemberByIndex(lobby_id, i) 
		if steam_id: 
			var player_name = Steam.getFriendPersonaName(steam_id) 
			members.append(player_name) 
	return members

func _am_i_lobby_owner() -> bool:
	if lobby_id == 0:
		return false
	return Steam.getSteamID() == Steam.getLobbyOwner(lobby_id)

# ------------------------
# Disband / Kick
# ------------------------
func _on_disband_received():
	Steam.leaveLobby(lobby_id)
	_on_lobby_left()

func _on_kick_received():
	Steam.leaveLobby(lobby_id)
	_on_lobby_left()

func kick_player(player_steam_id):
	var target_id = int(player_steam_id)
	Steam.sendP2PPacket(target_id, "KICK".to_utf8_buffer(), Steam.P2PSend.P2P_SEND_RELIABLE, 0)

func disband_lobby():
	send_message_to_all("DISBAND")
	Steam.leaveLobby(lobby_id)
	_on_lobby_left()

# ------------------------
# ENet Networking
# ------------------------
func start_enet_server():
	# SOLO l'owner della lobby può creare il server ENet
	if not _am_i_lobby_owner():
		push_error("start_enet_server chiamato da un client! Solo l'owner può creare il server.")
		return

	# Se è già presente un peer, logga e non sovrascrivere (per sicurezza)
	if multiplayer.multiplayer_peer != null:
		print("ENet peer già presente, tipo:", multiplayer.multiplayer_peer)
		return
	
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(enet_port, max_players - 1)
	if err != OK:
		push_error("Fallita creazione ENet server: %s" % str(err))
		return

	# assegna e salva
	multiplayer.multiplayer_peer = peer
	_enet_peer = peer
	print("✅ ENet server creato sulla porta %d" % enet_port)

	# collega segnali sul multiplayer globale (non solo sull'oggetto peer)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# invia HOSTINFO ai membri (IP usato solo per debug/port forwarding; in Internet reale servirebbe IP pubblico/relay)
	var ip = _get_public_ip()
	var msg = "HOSTINFO:%s:%d" % [ip, enet_port]
	send_message_to_all(msg)
	print("✉️ HOSTINFO inviato ai membri della lobby:", msg)

func connect_to_enet_host(ip: String, port: int):
	# I client chiamano questa funzione quando ricevono HOSTINFO via Steam
	if _am_i_lobby_owner():
		print("Sono l'owner, non devo connettermi al mio stesso host.")
		return

	# Se ho già un peer attivo, non faccio nulla
	if multiplayer.multiplayer_peer != null:
		print("ENet peer già presente sul client, non connetto di nuovo.")
		return

	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Fallita creazione ENet client: %s" % str(err))
		return

	# assegna e salva
	multiplayer.multiplayer_peer = peer
	_enet_peer = peer
	print("🔌 ENet client creato, connettendo a %s:%d" % [ip, port])

	# collega segnali (globali)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	# Notare: la connessione è asincrona. Aspettare i segnali per sapere se è andata a buon fine.

# ------------------------
# ENet signals
# ------------------------
func _on_peer_connected(id):
	print("✅ ENet peer connesso:", id, " (connected_peers size:", multiplayer.get_connected_peers().size(), ")")
	# Solo l'host (server) vedrà i client connessi via get_connected_peers()

func _on_peer_disconnected(id):
	print("❌ ENet peer disconnesso:", id)

func _on_connection_failed():
	print("💀 Connessione ENet fallita")

func _on_server_disconnected():
	print("⚡ Disconnesso dal server ENet")

# ------------------------
# Helper: trova IP locale o pubblico (evitiamo APIPA 169.x.x.x)
# ------------------------
func _get_public_ip() -> String:
	var addrs = IP.get_local_addresses()
	for a in addrs:
		# cerchiamo un ipv4 valido non-loopback e non APIPA (169.254.x.x)
		if typeof(a) == TYPE_STRING and a.is_valid_ip_address() and not a.begins_with("127.") and not a.begins_with("169.254.") and not a.contains(":"):
			return a
	# fallback brutale per testing locale (se test su stessa macchina)
	return "127.0.0.1"
