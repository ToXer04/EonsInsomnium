extends CanvasLayer

@onready var animation_player: AnimationPlayer = $TextureRect/AnimationPlayer
var animation_started := false
var skipped := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# Attendi qualche secondo prima di far partire l'animazione
	await get_tree().create_timer(2).timeout
	if not skipped:
		animation_started = true
		animation_player.play("Startup")

func _input(event: InputEvent) -> void:
	# Se il giocatore clicca o preme un tasto, salta l’animazione
	if (event is InputEventMouseButton or event is InputEventKey) and event.pressed and not skipped:
		skipped = true
		# Ferma eventuale animazione in corso
		if animation_started:
			animation_player.stop()
		_go_to_menu()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Startup" and not skipped:
		_go_to_menu()

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu/MainMenu.tscn")
