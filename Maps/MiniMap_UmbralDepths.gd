extends TextureRect

# --- Variabili ---
var fog_image : Image
var fog_texture : ImageTexture
var brush : Image

# Bordo mondo reale
const WORLD_LEFT = -6904.0
const WORLD_RIGHT = 13930.0
const WORLD_TOP = -6134.0
const WORLD_BOTTOM = 2827.0

# Bordi UI del marker
const UI_LEFT = -15.0
const UI_RIGHT = 1700.0
const UI_TOP = 40.0
const UI_BOTTOM = 775.0

func _ready():
	pass

func _process(_delta: float) -> void:
	# Mostra minimappa solo con Tab
	$"../../..".visible = Input.is_key_pressed(KEY_TAB)
	var player = Singleton.player
	if player and Input.is_key_pressed(KEY_TAB):
		# 3. Aggiorna la posizione del marker sulla UI
		%PlayerIcon.position = get_ui_position(player.global_position)


# --- Converte posizione mondo direttamente in pixel UI per il marker ---
func get_ui_position(world_pos: Vector2) -> Vector2:
	var norm_x = (world_pos.x - WORLD_LEFT) / (WORLD_RIGHT - WORLD_LEFT)
	var norm_y = (world_pos.y - WORLD_TOP) / (WORLD_BOTTOM - WORLD_TOP)

	var ui_x = lerp(UI_LEFT, UI_RIGHT, norm_x)
	var ui_y = lerp(UI_TOP, UI_BOTTOM, norm_y)

	return Vector2(ui_x, ui_y)
