extends Node

var pause_menu_scene := preload("res://Scenes/PauseMenu/PauseMenu.tscn")
var pause_menu_instance: CanvasLayer = null

func _ready():
	pause_menu_instance = pause_menu_scene.instantiate()
	pause_menu_instance.hide()
	get_tree().get_root().call_deferred("add_child", pause_menu_instance)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not get_tree().paused and Singleton.current_scene == "Game":
		pause_game()

func pause_game():
	SoundManager.stop_sitidle_sfx()
	SoundManager.stop_gameplay_music() 
	get_tree().paused = true
	pause_menu_instance.show()

func resume_game():
	SoundManager.play_sitidle_sfx()
	SoundManager.play_gameplay_music()  
	pause_menu_instance.hide()
	get_tree().paused = false

func quit_to_menu():
	get_tree().paused = false
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://Scenes/Levels/MainMenu/MainMenu.tscn")
	queue_free()
