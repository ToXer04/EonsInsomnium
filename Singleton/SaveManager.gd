extends Node

# Settings
const settings_save_location = "user://Settings.json"
var settings_dictionary: Dictionary = {
	"window_mode": 0,
	"resolution" : 1,
	"quality" : 2,
	"vsync" : false,
	"master_audio": 10,
	"music_audio": 10,
	"sound_audio": 10,
	"ambience_audio": 10,
	"current_language": 0,
}
var settings_supported_resolutions = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
var settings_available_languages = ["en", "it", "es", "fr", "de"]
var settings_window_modes := [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN]
var settings_quality_presets := [
	{ "msaa_2d": Viewport.MSAA_DISABLED,  "scaling_3d_scale": 0.8, "screen_space_aa": Viewport.SCREEN_SPACE_AA_DISABLED, "shadow_atlas_size": 1024 },
	{ "msaa_2d": Viewport.MSAA_2X,   "scaling_3d_scale": 1.0, "screen_space_aa": Viewport.SCREEN_SPACE_AA_SMAA,    "shadow_atlas_size": 2048 },
	{ "msaa_2d": Viewport.MSAA_4X,   "scaling_3d_scale": 1.0, "screen_space_aa": Viewport.SCREEN_SPACE_AA_SMAA,    "shadow_atlas_size": 4096 },
	{ "msaa_2d": Viewport.MSAA_8X,   "scaling_3d_scale": 1.0, "screen_space_aa": Viewport.SCREEN_SPACE_AA_SMAA,    "shadow_atlas_size": 8192 }
]

#Save File
const SAVE_SLOTS = {
	1: "user://Save1.save",
	2: "user://Save2.save",
	3: "user://Save3.save"
}
var current_slot := 0
var flasks := 0
var last_spawn_point : int = 0
var abilities := {}
var items := {}

func _ready():
	for i in 100:
		await get_tree().process_frame
	load_settings()

func save_settings():
	var settings_file = FileAccess.open_encrypted_with_pass(settings_save_location, FileAccess.WRITE, "19191919")
	settings_file.store_var(settings_dictionary.duplicate())
	settings_file.close()

func load_settings():
	print("LOADING")
	if FileAccess.file_exists(settings_save_location):
		var settings_file = FileAccess.open_encrypted_with_pass(settings_save_location, FileAccess.READ, "19191919")
		var settings_data = settings_file.get_var()
		settings_file.close()
		settings_dictionary = settings_data
		var settings_save_data = settings_data.duplicate()
		loadVideoSettings(settings_save_data)
		loadAudioSettings(settings_save_data)
		loadLanguageSettings(settings_save_data)

func loadVideoSettings(save_data):
		settings_dictionary.window_mode = save_data.window_mode
		settings_dictionary.resolution = save_data.resolution
		settings_dictionary.quality = save_data.quality
		settings_dictionary.vsync = save_data.vsync
		DisplayServer.window_set_mode(settings_window_modes[settings_dictionary.window_mode])
		var preset = settings_quality_presets[settings_dictionary.quality]
		var root_vp = get_tree().get_root()
		root_vp.msaa_2d = preset.msaa_2d
		root_vp.scaling_3d_scale = preset.scaling_3d_scale
		root_vp.screen_space_aa = preset.screen_space_aa
		var vp_rid = root_vp.get_viewport_rid()
		RenderingServer.viewport_set_msaa_2d(vp_rid, preset.msaa_2d)
		RenderingServer.viewport_set_scaling_3d_scale(vp_rid, preset.scaling_3d_scale)
		ProjectSettings.set_setting("rendering/quality/shadows/atlas_size", preset.shadow_atlas_size)
		var res = settings_supported_resolutions[settings_dictionary.resolution]
		DisplayServer.window_set_size(res)
		if settings_dictionary.vsync:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		else:
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func loadAudioSettings(save_data):
	settings_dictionary.master_audio = save_data.master_audio
	settings_dictionary.music_audio = save_data.music_audio
	settings_dictionary.sound_audio = save_data.sound_audio
	settings_dictionary.ambience_audio = save_data.ambience_audio
	var master_idx = AudioServer.get_bus_index("Master")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	var ambience_idx = AudioServer.get_bus_index("Ambience")
	var music_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(settings_dictionary.master_audio / 10.0))
	AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(settings_dictionary.music_audio / 10.0))
	AudioServer.set_bus_volume_db(ambience_idx, linear_to_db(settings_dictionary.sound_audio / 10.0))
	AudioServer.set_bus_volume_db(music_idx, linear_to_db(settings_dictionary.ambience_audio / 10.0))

func loadLanguageSettings(save_data):
	settings_dictionary.current_language = save_data.current_language
	TranslationServer.set_locale(settings_available_languages[settings_dictionary.current_language])

func _build_save_data() -> Dictionary:
	var data := {}
	data.version = "0.0.1"
	data.flasks = flasks
	data.last_spawn_point = last_spawn_point 

	var unlocked_abilities := []
	for key in abilities.keys():
		if abilities[key].unlocked:
			unlocked_abilities.append(key)
	data.unlocked_abilities = unlocked_abilities

	# Oggetti sbloccati
	var unlocked_items := []
	for key in items.keys():
		if items[key].unlocked:
			unlocked_items.append(key)
	data.unlocked_items = unlocked_items

	return data

func save_game():
	if not SAVE_SLOTS.has(current_slot):
		return
	
	var path = SAVE_SLOTS[current_slot]
	var save_data = _build_save_data()

	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(save_data)
	file.close()

	print("Salvataggio completato nello slot ", current_slot)

func load_game(slot: int):
	if not SAVE_SLOTS.has(slot):
		return null
	
	current_slot = slot
	var path = SAVE_SLOTS[slot]

	if not FileAccess.file_exists(path):
		print("Nessun file di salvataggio nello slot ", slot)
		return null
	
	var file = FileAccess.open(path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	_apply_loaded_data(data)

	print("Caricamento completato dallo slot ", slot)
	return data

func _apply_loaded_data(data: Dictionary) -> void:
	# Versione (ti può servire più avanti)
	if data.has("version"):
		# puoi controllare la versione qui se vuoi
		pass

	# Flasks
	if data.has("flasks"):
		flasks = data.flasks

	# Spawn point
	if data.has("last_spawn_point"):
		last_spawn_point = data.last_spawn_point

	# Abilità
	if data.has("unlocked_abilities"):
		for key in abilities.keys():
			abilities[key].unlocked = key in data.unlocked_abilities

	# Items
	if data.has("unlocked_items"):
		for key in items.keys():
			items[key].unlocked = key in data.unlocked_items
