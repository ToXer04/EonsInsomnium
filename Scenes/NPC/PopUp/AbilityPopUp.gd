extends CanvasLayer
@onready var title: Label = $Control/VBoxContainer/Title
@onready var ability_name: Label = $Control/VBoxContainer/AbilityName
@onready var ability_icon: TextureRect = $Control/VBoxContainer/AbilityIcon
@onready var ability_desc: Label = $Control/VBoxContainer/AbilityDesc

var is_open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

func show_ability(key: String) -> void:
	var data = AbilityManager.get_info(key)

	title.text = "Hai sbloccato una nuova abilità!"
	ability_name.text = data["name"]
	ability_icon.texture = data["icon"]
	ability_desc.text = data["description"]

	visible = true
	is_open = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	
	# Chiudi su qualsiasi tasto o click
	if event.is_pressed():
		await get_tree().create_timer(1.0).timeout
		visible = false
		is_open = false
