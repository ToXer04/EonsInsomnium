extends CanvasLayer
@onready var title: Label = $Control/VBoxContainer/Title
@onready var item_name: Label = $Control/VBoxContainer/ItemName
@onready var item_icon: TextureRect = $Control/VBoxContainer/ItemIcon
@onready var item_desc: Label = $Control/VBoxContainer/ItemDesc


var is_open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

func show_ability(key: String) -> void:
	var data = AbilityManager.get_info(key)

	title.text = "Hai sbloccato un nuovo item!"
	item_name.text = data["name"]
	item_icon.texture = data["icon"]
	item_desc.text = data["description"]

	visible = true
	is_open = true

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	
	# Chiudi su qualsiasi tasto o click
	if event.is_pressed():
		visible = false
		is_open = false
