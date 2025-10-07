extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var container: Control = $SectionsContainer

var current_section := 0
const SECTION_WIDTH := 1920
var tween_active := true

func _ready() -> void:
	animation_player.play("FadeLogo")



func _process(_delta: float) -> void:
	pass

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "FadeLogo":
		tween_active = false

func go_to_section(index: int) -> void:
	# Blocca se il tween è ancora attivo
	if tween_active:
		return
	
	current_section = clamp(index, 0, 2)
	var target_x = -current_section * SECTION_WIDTH

	var tween = create_tween()
	tween_active = true
	
	tween.tween_property(container, "position:x", target_x, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	# Quando il tween finisce, sblocca l’input
	tween.finished.connect(func(): tween_active = false)

func _on_options_pressed():
	go_to_section(1)

func _on_home_pressed():
	go_to_section(0)

func _input(event):
	# Blocca input se tween è attivo
	if tween_active:
		return

	if event.is_action_pressed("Move_Right"):
		go_to_section(1)
	elif event.is_action_pressed("Move_Left"):
		go_to_section(0)
