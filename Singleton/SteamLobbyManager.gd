# SteamLobbyManager.gd
extends Node

# --- existing fields (kept) ---
var lobby_code_label: Label = null
var lobby_id: int = 0
var code: String = ""

# --- networking config ---
@export var enet_port: int = 8910           # change if you want another port
@export var max_players: int = 4           # max players including host
const HOSTINFO_PREFIX = "HOSTINFO:"        # message format: HOSTINFO:ip:port

# cached enet peer
var _enet_peer: ENetMultiplayerPeer = null

func _ready() -> void:
	# Steam init & signals (your existing)
	Steam.steamInit(3961570)
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

	# Steam P2P reading will keep working like before
	# Also connect multiplayer signals used for ENet
	multiplayer.connect("peer_connected", Callable(self, "_on_peer_connected"))
	multiplayer.connect("peer_disconnected", Callable(self, "_on_peer_disconnected"))
	multiplayer.connect("connection_failed", Callable(self, "_on_connection_failed"))

func _process(_delta):
	Steam.run_callbacks()
	_read_p2p_messages()

# ------------------------
# P2P messages (existing read, extended)
# ------------------------
func _read_p2p_messages():
	while Steam.getAvailableP2PPacketSize(0) > 0:
		var packet = Steam.readP2PPacket(Steam.getAvailableP2PPacketSize(0), 0)
		if packet and packet.has("data"):
			var message = packet.data.get_string_from_utf8()
			if message.begins_with(HOSTINFO_PREFIX):
				_handle_hostinfo_message(message)
				continue

			match message:
				"DISBAND":
					_on_disband_received()
				"KICK":
					_on_kick_received()
				_:
					# handle other custom messages
					pass

# ------------------------
# HELPERS: send simple messages (reuses your send_message_to_all)
# ------------------------
func send_message_to_all(message: String):
	var buffer = message.to_utf8_buffer()
	for member_id in get_lobby_members():
		if int(member_id) != Steam.getSteamID(): # non inviare a te stesso
			Steam.acceptP2PSessionWithUser(int(member_id)) # apri sessione se non già aperta
			Steam.sendP2PPacket(int(member_id), buffer, Steam.P2PSend.P2P_SEND_RELIABLE, 0)

# ------------------------
# HOSTING (ENet) - called when owner clicks "Start Game"
# ------------------------
func start_hosting_game():
	# only the lobby owner should call this
	# 1) create ENet server
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(enet_port, max_players - 1) # max_clients is players minus host
	if err != OK:
		push_error("Failed to create ENet server: %s" % str(err))
		# you may want to show a UI error
		return

	# 2) assign as the global multiplayer peer (so RPCs work)
	multiplayer.multiplayer_peer = peer
	_enet_peer = peer

	# 3) send host connection info to lobby members over Steam P2P
	var host_ip = _get_local_ip_for_clients()
	var host_msg = "%s%s:%d" % [HOSTINFO_PREFIX, host_ip, enet_port]
	send_message_to_all(host_msg)

	# 4) now call the RPC to change scene for everyone (host included)
	# Decorated function start_game_rpc will run locally and on clients after their ENet connects.
	rpc("start_game_rpc")

# ------------------------
# CLIENT: handle HOSTINFO received via Steam P2P, then connect ENet
# ------------------------
func _handle_hostinfo_message(msg: String) -> void:
	# expected format HOSTINFO:ip:port
	var payload = msg.substr(HOSTINFO_PREFIX.length(), msg.length())
	var parts = payload.split(":")
	if parts.size() < 2:
		push_error("Bad HOSTINFO payload: %s" % payload)
		return
	var ip = parts[0]
	var port = int(parts[1])

	# create ENet client and attempt connect
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("ENet client failed to create: %s" % str(err))
		return

	# set as multiplayer peer (this will trigger multiplayer signals)
	multiplayer.multiplayer_peer = peer
	_enet_peer = peer
	# note: we do NOT call start_game here - the host will rpc start_game_rpc
	# once everyone is connected (or immediately after sending HOSTINFO - depends on your logic)

# ------------------------
# RPC that actually performs the scene change (runs on everyone)
# ------------------------
@rpc("any_peer", "call_local", "reliable")
func start_game_rpc() -> void:
	# Ensure multiplayer peer is set before changing scene. If a client hasn't connected ENet yet,
	# their multiplayer.multiplayer_peer might still be null. In that case we wait a bit.
	if multiplayer.multiplayer_peer == null:
		# naive wait: spawn a short timer that checks again. You can replace with better UI/timeout.
		var t = Timer.new()
		t.one_shot = true
		t.wait_time = 0.25
		add_child(t)
		t.start()
		t.timeout.connect(Callable(self, "_on_start_game_retry"))
		return

	# Now change scene. replace path with your real game scene path
	var scene_path = "res://Scenes/Levels/Game/Game.tscn"
	get_tree().change_scene_to_file(scene_path)

func _on_start_game_retry():
	# retry entrypoint for start_game
	if multiplayer.multiplayer_peer == null:
		# last resort: proceed anyway to avoid infinite wait. If this happens,
		# the client will not have multiplayer set and won't receive RPCs properly.
		push_warning("Proceeding to game scene without ENet peer set. Multiplayer may malfunction.")
	get_tree().change_scene_to_file("res://Scenes/Levels/Game/Game.tscn")

# ------------------------
# ENet multiplayer signals
# ------------------------
func _on_peer_connected(id: int) -> void:
	# runs on host when a client connects, and on clients when the host connects (id = 1 typically)
	print("Peer connected: %s" % str(id))
	# optional: when host sees all expected peers, you can rpc start or spawn players
	if multiplayer.is_server():
		# check if we have enough connected peers (peer count excludes host)
		var connected = multiplayer.get_connected_peers().size()
		print("Connected peers count: %d" % connected)
		# if you want start only when all joined:
		# if connected >= max_players - 1:
		#     rpc("start_game_rpc")

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: %s" % str(id))

func _on_connection_failed() -> void:
	push_error("Connection failed (ENet)")

# ------------------------
# small helper to pick a local IP to advertise (useful on LAN)
# If internet play, you must supply your public IP or use NAT traversal.
# ------------------------
func _get_local_ip_for_clients() -> String:
	# prefer non-loopback IPv4
	var addrs = IP.get_local_addresses()
	for a in addrs:
		if typeof(a) == TYPE_STRING and a != "127.0.0.1" and not a.begins_with("::"):
			return a
	# fallback
	return "127.0.0.1"

# ------------------------
# keep your other lobby code...
# ------------------------
func generate_lobby_code():
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]

# Host / Invite
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

func on_invite_button_pressed() -> void:
	if lobby_id == 0:
		return
	Steam.activateGameOverlayInviteDialog(lobby_id)

# Join via code
func join_by_code(JoinCode: String) -> void:
	Steam.addRequestLobbyListResultCountFilter(1)
	Steam.addRequestLobbyListStringFilter("lobby_code", JoinCode, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies_found: Array) -> void:
	if lobbies_found.size() == 0:
		return

	var lobby_found = lobbies_found[0]
	if lobby_id != lobby_found:
		Steam.leaveLobby(lobby_id)
		Steam.joinLobby(lobby_found)

func _on_lobby_join_requested(this_lobby_id: int, _friend_id: int) -> void:
	if lobby_id != this_lobby_id:
		Steam.leaveLobby(lobby_id)
		Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
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

# Lobby members helpers (unchanged)
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

# Disband / kick (keeps your existing behavior)
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
