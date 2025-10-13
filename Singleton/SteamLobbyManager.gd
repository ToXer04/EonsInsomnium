# SteamLobbyManager.gd
extends Node

var lobby_code_label: Label = null
var lobby_id: int = 0
var code: String = ""

func _ready() -> void:
	var init_result = Steam.steamInit(3961570)
	print("Steam Init Result:", init_result)
	print("Steam Running:", Steam.isSteamRunning())
	print("User:", Steam.getPersonaName())

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.join_requested.connect(_on_lobby_join_requested)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	
	print("SteamLobbyManager ready")
	
func _process(_delta):
	Steam.run_callbacks()
	_read_p2p_messages()

func _read_p2p_messages():
	while Steam.getAvailableP2PPacketSize(0) > 0:
		var packet = Steam.readP2PPacket(Steam.getAvailableP2PPacketSize(0), 0)
		print("Ricevuto")
		if packet and packet.has("data"):
			var message = packet.data.get_string_from_utf8()
			print(message)
			print("Ricevuto da ", "sender", ": ", message)
			match message:
				"DISBAND":
					_on_disband_received()
				"KICK":
					_on_kick_received()


func generate_lobby_code():
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]

# ------------------------
# HOST / INVITE
# ------------------------
func host_lobby(max_players: int = 4) -> void:
	print("Avvio Creazione Lobby")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, max_players)
	print("Termine Creazione Lobby")

func _on_lobby_created(result: int, this_lobby_id: int) -> void:
	print("Lobby Creata")
	if result != 1:
		print("Errore creazione lobby:", result)
		return

	lobby_id = this_lobby_id
	Steam.setLobbyJoinable(lobby_id, true)

	generate_lobby_code()
	Steam.setLobbyData(lobby_id, "lobby_code", code)

	get_tree().call_group("MainMenu", "update_lobby_players_ui")

func on_invite_button_pressed() -> void:
	if lobby_id == 0:
		print("Devi prima creare una lobby")
		return
	Steam.activateGameOverlayInviteDialog(lobby_id)

# ------------------------
# JOIN VIA CODICE
# ------------------------
func join_by_code(JoinCode: String) -> void:
	Steam.addRequestLobbyListResultCountFilter(1)
	Steam.addRequestLobbyListStringFilter("lobby_code", JoinCode, Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()

func _on_lobby_match_list(lobbies_found: Array) -> void:
	if lobbies_found.size() == 0:
		print("Nessuna lobby trovata con quel codice")
		return

	var lobby_found = lobbies_found[0]
	print("Lobby trovata, joinando:", lobby_found)
	Steam.joinLobby(lobby_found)

# ------------------------
# CALLBACKS / JOIN REQUEST
# ------------------------
func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	print("Invite da:", Steam.getFriendPersonaName(friend_id))
	Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		lobby_code_label.text = code
		print("Joined lobby:", lobby_id)
		get_tree().call_group("MainMenu", "update_lobby_players_ui")
		get_tree().call_group("MainMenu", "go_to_section", 3)
		for member in get_lobby_members():
			if int(member) != Steam.getSteamID():
				Steam.acceptP2PSessionWithUser(int(member))

# ------------------------
# LOBBY MEMBERS
# ------------------------
func get_lobby_members() -> Array:
	var members = []
	if lobby_id == 0:
		return members

	var member_count = Steam.getNumLobbyMembers(lobby_id)
	for i in range(member_count):
		var steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		if steam_id:
			members.append(steam_id) # <--- qui metti l'id, non il nome
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
# DISBAND / KICK
# ------------------------
func _on_disband_received():
	Steam.leaveLobby(lobby_id)
	get_tree().call_group("MainMenu", "go_to_section", 0)

func _on_kick_received():
	Steam.leaveLobby(lobby_id)
	get_tree().call_group("MainMenu", "go_to_section", 0)

func send_message_to_all(message: String):
	var buffer = message.to_utf8_buffer()

	for member_id in get_lobby_members():
		if int(member_id) != Steam.getSteamID(): # non inviare a te stesso
			Steam.acceptP2PSessionWithUser(int(member_id)) # apri sessione se non già aperta
			Steam.sendP2PPacket(int(member_id), buffer, Steam.P2PSend.P2P_SEND_RELIABLE, 0)



func kick_player(player_steam_id):
	var target_id = int(player_steam_id)
	Steam.sendP2PPacket(target_id, "KICK".to_utf8_buffer(), Steam.P2PSend.P2P_SEND_RELIABLE, 0)

func disband_lobby():
	send_message_to_all("DISBAND")
