# SteamLobbyManager.gd
extends Node

var lobby_code_label: Label = null
var lobby_id: int = 0
var code: String = ""
@export var max_players: int = 4  # max players including host
@export var enet_port: int = 8910  # porta ENet

var _enet_peer: ENetMultiplayerPeer = null

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
					_start_game_rpc()
				_:
					if message.begins_with("HOSTINFO:"):
						var parts = message.substr(9, message.length()).split(":")
						if parts.size() == 2:
							var ip = parts[0]
							var port = int(parts[1])
							connect_to_enet_host(ip, port)
						continue

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
	print("📡 Host avvia il gioco")
	start_enet_server()
	send_message_to_all("START_GAME")
	_start_game_rpc()

# ------------------------
# RPC-like function called when START_GAME received
# ------------------------
func _start_game_rpc():
	print("🔁 Cambio scena a Game.tscn")
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
	for member in get_lobby_members():
		if int(member) != Steam.getSteamID():
			Steam.acceptP2PSessionWithUser(int(member))

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
	if multiplayer.multiplayer_peer != null:
		print("ENet server/client già creato")
		return
	
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(enet_port, max_players - 1)
	if err != OK:
		push_error("Fallita creazione ENet server: %s" % str(err))
		return

	multiplayer.multiplayer_peer = peer
	_enet_peer = peer
	print("✅ ENet server creato sulla porta %d" % enet_port)

	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	peer.connection_failed.connect(_on_connection_failed)
	peer.server_disconnected.connect(_on_server_disconnected)

	var ip = _get_public_ip()
	var msg = "HOSTINFO:%s:%d" % [ip, enet_port]
	send_message_to_all(msg)
	print("✉️ HOSTINFO inviato ai membri della lobby:", msg)

func connect_to_enet_host(ip: String, port: int):
	if multiplayer.multiplayer_peer != null:
		print("ENet client già connesso")
		return
	
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Fallita creazione ENet client: %s" % str(err))
		return

	multiplayer.multiplayer_peer = peer
	_enet_peer = peer
	print("🔌 ENet client creato, connettendo a %s:%d" % [ip, port])

	peer.peer_connected.connect(_on_peer_connected)
	peer.peer_disconnected.connect(_on_peer_disconnected)
	peer.connection_failed.connect(_on_connection_failed)
	peer.server_disconnected.connect(_on_server_disconnected)

# ------------------------
# ENet signals
# ------------------------
func _on_peer_connected(id):
	print("✅ ENet peer connesso:", id)

func _on_peer_disconnected(id):
	print("❌ ENet peer disconnesso:", id)

func _on_connection_failed():
	print("💀 Connessione ENet fallita")

func _on_server_disconnected():
	print("⚡ Disconnesso dal server ENet")

# ------------------------
# Helper: trova IP locale o pubblico
# ------------------------
func _get_public_ip() -> String:
	var addrs = IP.get_local_addresses()
	for a in addrs:
		if typeof(a) == TYPE_STRING and a.is_valid_ip_address() and not a.begins_with("127.") and not a.contains(":"):
			return a
	return "127.0.0.1"
