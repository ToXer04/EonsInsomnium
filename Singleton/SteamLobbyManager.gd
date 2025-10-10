# SteamLobbyManager.gd
extends Node

signal kick_player(target_steam_id: int)

var lobby_code_label: Label = null
var lobby_id: int = 0

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

func generate_lobby_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]
	return code

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

	var code = generate_lobby_code()
	Steam.setLobbyData(lobby_id, "lobby_code", code)

	if lobby_code_label:
		lobby_code_label.text = code
	else:
		print("ATTENZIONE: lobby_code_label non assegnato!")

	get_tree().call_group("MainMenu", "update_lobby_players_ui")
	
	var peer = SteamMultiplayerPeer.new()
	peer.create_host(lobby_id)
	multiplayer.multiplayer_peer = peer


func on_invite_button_pressed() -> void:
	if lobby_id == 0:
		print("Devi prima creare una lobby")
		return
	Steam.activateGameOverlayInviteDialog(lobby_id)

# ------------------------
# JOIN VIA CODICE
# ------------------------
func join_by_code(code: String) -> void:
	Steam.addRequestLobbyListResultCountFilter(1)
	Steam.addRequestLobbyListStringFilter("lobby_code", code, Steam.LOBBY_COMPARISON_EQUAL)
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
		print("Join avvenuto:", lobby_id)
		get_tree().call_group("MainMenu", "update_lobby_players_ui")
		get_tree().call_group("MainMenu", "go_to_section", 3)
		var peer = SteamMultiplayerPeer.new()
		peer.join_host(lobby_id)
		multiplayer.multiplayer_peer = peer


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
			var player_name = Steam.getFriendPersonaName(steam_id)
			members.append(player_name)
	return members

# ------------------------
# DISBAND / KICK
# ------------------------
func disband_lobby_pressed():
	if lobby_id == 0:
		print("Non c'è una lobby da disbandare")
		return
	print("Disband Lobby: RPC inviato a tutti i client")
	rpc_disband_lobby()  # invia a tutti i client

func kick_player_pressed(target_steam_id: int) -> void:
	if lobby_id == 0:
		print("Non c'è una lobby attiva")
		return
	print("Kick Player:", Steam.getFriendPersonaName(target_steam_id))
	rpc_id(target_steam_id, "rpc_kick_player")  # invia RPC solo al target

@rpc("authority", "call_remote", "reliable")
func rpc_disband_lobby():
	print("Lobby disbandata! Torno al menu principale")
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
	get_tree().call_group("MainMenu", "go_to_section", 0)


@rpc("any_peer", "call_remote", "reliable")
func rpc_kick_player():
	print("Sei stato kickato dalla lobby!")
	if lobby_id != 0:
		Steam.leaveLobby(lobby_id)
		lobby_id = 0
	get_tree().call_group("MainMenu", "go_to_section", 0)
