extends Node


var pause_menu_scene := preload("res://Scenes/PauseMenu/PauseMenu.tscn")
var pause_menu_instance: CanvasLayer = null

func _ready():
	# Istanzia subito
	pause_menu_instance = pause_menu_scene.instantiate()
	pause_menu_instance.hide()

	# Aggiungilo alla scena quando Godot ha finito di respirare
	get_tree().get_root().call_deferred("add_child", pause_menu_instance)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		pause_game()

func pause_game():
	get_tree().paused = true
	pause_menu_instance.show()

func resume_game():
	pause_menu_instance.hide()
	get_tree().paused = false

func quit_to_menu():
	get_tree().paused = false
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu/MainMenu.tscn")
	queue_free()
