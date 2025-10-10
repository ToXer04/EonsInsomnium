# SteamLobbyManager.gd
extends Node

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
	# Tipo: FRIENDS_ONLY => join solo tramite invite o link
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

	# Genera e salva un codice casuale nella lobby
	var code = generate_lobby_code()
	Steam.setLobbyData(lobby_id, "lobby_code", code)

	# Mostra il codice nell'interfaccia
	if lobby_code_label:
		lobby_code_label.text = code
	else:
		print("ATTENZIONE: lobby_code_label non assegnato!")
	
	get_tree().call_group("MainMenu", "update_lobby_players_ui")

func on_invite_button_pressed() -> void:
	print(lobby_id)
	if lobby_id == 0:
		print("Devi prima creare una lobby")
		return
	# apre l'overlay Steam invitando amici alla lobby corrente
	Steam.activateGameOverlayInviteDialog(lobby_id)

# ------------------------
# JOIN VIA CODICE
# ------------------------
func join_by_code(code: String) -> void:
	# Imposta il filtro PRIMA della richiesta
	Steam.addRequestLobbyListResultCountFilter(1)
	Steam.addRequestLobbyListStringFilter("lobby_code", code, Steam.LOBBY_COMPARISON_EQUAL)

	# Richiedi la lista filtrata
	Steam.requestLobbyList()


func _on_lobby_match_list(lobbies_found: Array) -> void:
	if lobbies_found.size() == 0:
		print("Nessuna lobby trovata con quel codice")
		return

	var lobby_found = lobbies_found[0]
	print("Lobby trovata, joinando:", lobby_found)
	Steam.joinLobby(lobby_found)

# ------------------------
# CALLBACKS / JOIN REQUEST (quando un amico clicca l'invito)
# ------------------------
func _on_lobby_join_requested(this_lobby_id: int, friend_id: int) -> void:
	print("Invite da:", Steam.getFriendPersonaName(friend_id))
	Steam.joinLobby(this_lobby_id)

func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		lobby_id = this_lobby_id
		print("Join avvenuto:", lobby_id)
		
		get_tree().call_group("MainMenu", "update_lobby_players_ui")
		# imposta il MultiplayerPeer per comunicare via Steam (dipende dal plugin scelto)
		# es: multiplayer.multiplayer_peer = SteamMultiplayerPeer.new()
		# poi client-side fai smp.connect_to_lobby(lobby_id) oppure smp.create_client(host_steam_id)

func get_lobby_members() -> Array:
	var members = []
	if lobby_id == 0:
		return members

	var member_count = Steam.getNumLobbyMembers(lobby_id)
	for i in range(member_count):
		var steam_id = Steam.getLobbyMemberByIndex(lobby_id, i)
		var player_name = Steam.getFriendPersonaName(steam_id)
		members.append(player_name)
	return members
