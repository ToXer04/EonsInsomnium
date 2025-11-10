extends Area2D

@onready var label: Label = $"../Label"
@onready var marker_2d: Marker2D = $"../Marker2D"


var player_in_range = false
var player_ref: CharacterBody2D = null

func _on_body_entered(body: Node2D) -> void:
		player_ref = body
		player_in_range = true
		label.show()

func _on_body_exited(body: Node2D) -> void:
		player_ref = null
		player_in_range = false
		label.hide()

func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("Interact"):
		label.hide()
		SaveScript.contents_to_save.jumpCount =  player_ref.jumpcount
		SaveScript._save()
		if player_ref and marker_2d:
			player_ref.move_to_target(marker_2d.global_position)
		
