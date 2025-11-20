extends TextureRect

var fog_image : Image
var fog_texture : ImageTexture

# Bordo mondo reale
const WORLD_LEFT = -6904.0
const WORLD_RIGHT = 13930.0
const WORLD_TOP = -6134.0
const WORLD_BOTTOM = 2827.0

# Bordi UI del marker
const UI_LEFT = -15.0
const UI_RIGHT = 1700.0
const UI_TOP = 0.0
const UI_BOTTOM = 870.0

var circle_offsets = []

func _ready():
	precalc_circle(50)
	var base_texture = texture
	var w = base_texture.get_width()
	var h = base_texture.get_height()

	# Un solo canale, più veloce
	fog_image = Image.create(w, h, false, Image.FORMAT_RF)
	fog_image.fill(Color(0, 0, 0, 1))

	fog_texture = ImageTexture.create_from_image(fog_image)
	material.set("shader_parameter/fog_map", fog_texture)

func precalc_circle(radius):
	circle_offsets.clear()
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x*x + y*y <= radius*radius:
				circle_offsets.append(Vector2i(x, y))

func _process(_delta):
	$"../../../..".visible = Input.is_key_pressed(KEY_TAB)
	var player = Singleton.player
	if not player:
		return
	if Input.is_key_pressed(KEY_TAB):
		%PlayerIcon.position = get_ui_position(player.global_position)

	var map_pos = world_to_map_coords(player.global_position)
	reveal_area(map_pos)


func world_to_map_coords(world_pos: Vector2) -> Vector2:
	var norm_x = (world_pos.x - WORLD_LEFT) / (WORLD_RIGHT - WORLD_LEFT)
	var norm_y = (world_pos.y - WORLD_TOP) / (WORLD_BOTTOM - WORLD_TOP)

	return Vector2(
		norm_x * fog_image.get_width(),
		norm_y * fog_image.get_height()
	)


func reveal_area(center: Vector2):
	for o in circle_offsets:
		var x = center.x + o.x
		var y = center.y + o.y
		if x>=0 and y>=0 and x<fog_image.get_width() and y<fog_image.get_height():
			fog_image.set_pixel(x, y, Color(1,0,0))
	fog_texture.update(fog_image)

func get_ui_position(world_pos: Vector2) -> Vector2:
	var norm_x = (world_pos.x - WORLD_LEFT) / (WORLD_RIGHT - WORLD_LEFT)
	var norm_y = (world_pos.y - WORLD_TOP) / (WORLD_BOTTOM - WORLD_TOP)

	var ui_x = lerp(UI_LEFT, UI_RIGHT, norm_x)
	var ui_y = lerp(UI_TOP, UI_BOTTOM, norm_y) - 30

	return Vector2(ui_x, ui_y)
