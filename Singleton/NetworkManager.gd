extends Node

var peer: ENetMultiplayerPeer

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id):
	print("Giocatore connesso con ID: ", id)

func _on_peer_disconnected(id):
	print("Giocatore disconnesso con ID: ", id)

func host_game(port := 7000):
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, 2) # massimo 2 giocatori
	if result != OK:
		push_error("Impossibile avviare il server!")
		return
	multiplayer.multiplayer_peer = peer
	print("Hosting game su porta ", port)

func join_game(ip: String, port := 7000):
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, port)
	if result != OK:
		push_error("Impossibile connettersi al server!")
		return
	multiplayer.multiplayer_peer = peer
	print("Connesso al server ", ip, ":", port)
