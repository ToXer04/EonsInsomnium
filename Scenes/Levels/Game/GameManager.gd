extends Node2D

# Questo è il nodo che conterrà i player spawnati (come nel tuo script)
@onready var players: Node2D = %Players
# Questo è il nodo Spawner che hai già nella scena
@onready var spawner: MultiplayerSpawner = %MultiplayerSpawner


func _ready():
	print("Level Ready!")
	if not multiplayer.is_server():
		return

	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)

	for id in multiplayer.get_peers():
		add_player(id)
	add_player(1)

func add_player(id: int):
	print("Add player: " + str(id))
	var character = load("res://Scenes/MC/Eon/Eon.tscn").instantiate()
	character.name = str(id)
	character.set_multiplayer_authority(id)
	players.add_child(character)

func del_player(id: int):
	if not players.has_node(str(id)):
		return
	players.get_node(str(id)).queue_free()

func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_connected.disconnect(add_player)
	multiplayer.peer_disconnected.disconnect(del_player)
