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

	print("SteamLobbyManager ready")

func _process(_delta):
	Steam.run_callbacks()


func encode_lobby_code(id: int) -> String:
	var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	if id <= 0:
		return ""
	var s := ""
	var n := int(id) # attenzione ai tipi
	while n > 0:
		var rem := n % 36
		s = chars[rem] + s
		@warning_ignore("integer_division")
		n = n / 36
	return s

func decode_lobby_code(code: String) -> int:
	var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	var n := int(0)
	for c in code.strip_edges().to_upper():
		var idx := chars.find(c)
		if idx == -1:
			return 0
		n = n * 36 + idx
	return int(n)



# ------------------------
# HOST / INVITE
# ------------------------
func host_lobby(max_players: int = 4) -> void:
	# Tipo: FRIENDS_ONLY => join solo tramite invite o link
	print("Avvio Creazione Lobby")
	Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY, max_players)
	print("Termine Creazione Lobby")

func _on_lobby_created(result: int, this_lobby_id: int) -> void:
	print("Lobby Creata")
	if result != 1:
		print("Errore creazione lobby:", result)
		return
	lobby_id = this_lobby_id
	Steam.setLobbyJoinable(lobby_id, true)
	# Mostra il codice all'utente
	
	if lobby_code_label:
		lobby_code_label.text = encode_lobby_code(lobby_id)
	else:
		print("ATTENZIONE: lobby_code_label non assegnato!")
	# Se usi un SteamMultiplayerPeer (plugin) -> imposta il multiplayer peer e fai host
	# esempio (dipende dal plugin che hai installato):
	# var peer = SteamMultiplayerPeer.new()
	# multiplayer.multiplayer_peer = peer
	# peer.host_with_lobby(lobby_id)

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
	var id = decode_lobby_code(code)
	if id == 0:
		print("Codice non valido")
		return
	# Tenta di unirti
	Steam.joinLobby(id)

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
		# imposta il MultiplayerPeer per comunicare via Steam (dipende dal plugin scelto)
		# es: multiplayer.multiplayer_peer = SteamMultiplayerPeer.new()
		# poi client-side fai smp.connect_to_lobby(lobby_id) oppure smp.create_client(host_steam_id)
