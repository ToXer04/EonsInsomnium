extends Node2D

# Questo è il nodo che conterrà i player spawnati (come nel tuo script)
@onready var players: Node2D = %Players
# Questo è il nodo Spawner che hai già nella scena
@onready var spawner: MultiplayerSpawner = %MultiplayerSpawner

func _ready() -> void:
	for i in 100:
		await get_tree().process_frame
	if multiplayer.is_server():
		print("Sono Host")
		spawnPlayer(1, Singleton.selectedChar)
	else:
		print("Sono Client")
		rpc_id(1, "spawnPlayer", multiplayer.get_unique_id(), Singleton.selectedChar)

@rpc("any_peer", "call_remote")
func spawnPlayer(id: int, character: String):
	var path : String = "res://Scenes/MC/Player/Player.tscn"
	var player = load(path).instantiate()

	# Imposti l'authority desiderata prima che _enter_tree venga chiamato
	player.assigned_authority = id
	player.name = character + str(id)

	# Aggiungi il nodo alla scena
	players.add_child(player)
