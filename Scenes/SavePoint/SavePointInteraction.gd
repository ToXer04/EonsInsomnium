extends Area2D

@onready var label: Label = $"../Label"
@onready var marker_2d: Marker2D = $"../Marker2D"


var player_in_range = false
var player_ref: CharacterBody2D = null

func _on_body_entered(body: Node2D) -> void:
		player_ref = body
		print(player_ref)
		player_in_range = true
		label.show()

func _on_body_exited(_body: Node2D) -> void:
		player_ref = null
		player_in_range = false
		label.hide()

func _process(_delta: float) -> void:
	if player_ref:
		if player_in_range and (Input.is_action_just_pressed("Interact") or player_ref.spawning):
			if player_ref.stop:
				label.show()
			else:
				label.hide()
				SaveManager.last_spawn_point = $"..".id
				SaveManager.save_game()
				player_ref.move_to_target(marker_2d.global_position)
