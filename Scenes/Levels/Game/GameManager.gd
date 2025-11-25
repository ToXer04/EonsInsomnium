extends Node2D

# Questo è il nodo che conterrà i player spawnati (come nel tuo script)
@onready var players: Node2D = %Players
# Questo è il nodo Spawner che hai già nella scena
@onready var spawner: MultiplayerSpawner = %MultiplayerSpawner

@onready var spawn_points := get_tree().get_nodes_in_group("SpawnPoints")

func _ready() -> void:
	Singleton.current_scene = "Game"
	for i in 100:
		await get_tree().process_frame
	if multiplayer.is_server():
		print("Sono Host")
		spawnPlayer(multiplayer.get_unique_id(), Singleton.selectedChar)
	else:
		print("Sono Client")
		rpc_id(1, "spawnPlayer", multiplayer.get_unique_id(), Singleton.selectedChar)

@rpc("any_peer", "call_remote")
func spawnPlayer(id: int, character: String):
	print("Spawn per " +  str(id))
	var path : String = "res://Scenes/MC/%s/%s.tscn" % [character, character]
	var player = load(path).instantiate()
	player.name = str(id)
	players.add_child(player)
	Singleton.players[id] = player
	print("Players registrati:", Singleton.players.keys())

func get_spawn_position(id: int) -> Vector2:
	for sp in spawn_points:
		if sp.id == id:
			return sp.global_position
	# se non trova niente… vabbè, fai tornare un default
	return Vector2.ZERO
