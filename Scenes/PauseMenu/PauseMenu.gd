extends CanvasLayer

@onready var container: Control = $SectionsContainer
@onready var menu_buttons := [%ContinueButton, %SettingsButton, %QuitButton]
@onready var settings_sections := [%Settings, %Video, %Audio, %Language]
@onready var settings_buttons := [%VideoButton, %AudioButton, %LanguageButton]
@onready var video_settings_buttons := [%WindowMode, %Resolution, %Quality, %"V-Sync", %ResetToDefaultButtonVideo, %ApplyButtonVideo]
@onready var audio_settings_buttons := [%Master, %Music, %Sound, %Ambience, %ResetToDefaultButtonAudio, %ApplyButtonAudio]
@onready var navigation_sound: AudioStreamPlayer = $NavigationSound
@onready var enter_sound: AudioStreamPlayer = $EnterSound
@onready var esc_sound: AudioStreamPlayer = $EscSound

const save_location = "user://Settings.json"
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

# General
var tween_active := false

# MainMenu Section
var current_menu_button := 0

# Settings Section
var settings_open := false
var current_settings_button := 0
var current_settings_section := 0
var total_settings_sections := 5

# Video Settings Section
var current_video_settings_button := 0
var window_modes := [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN]
var default_window_mode_index := 0
var current_window_mode_index := 0
var supported_resolutions = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
var default_resolution_index = 1
var current_resolution_index = 1
var quality_levels := ["Low", "Medium", "High", "Ultra"]
var quality_presets := [
	{ "msaa_2d": Viewport.MSAA_DISABLED,  "scaling_3d_scale": 0.8, "screen_space_aa": Viewport.SCREEN_SPACE_AA_DISABLED, "shadow_atlas_size": 1024 },
	{ "msaa_2d": Viewport.MSAA_2X,   "scaling_3d_scale": 1.0, "screen_space_aa": Viewport.SCREEN_SPACE_AA_SMAA,    "shadow_atlas_size": 2048 },
	{ "msaa_2d": Viewport.MSAA_4X,   "scaling_3d_scale": 1.0, "screen_space_aa": Viewport.SCREEN_SPACE_AA_SMAA,    "shadow_atlas_size": 4096 },
	{ "msaa_2d": Viewport.MSAA_8X,   "scaling_3d_scale": 1.0, "screen_space_aa": Viewport.SCREEN_SPACE_AA_SMAA,    "shadow_atlas_size": 8192 }
]
var default_quality_index := 2
var current_quality_index := 2
var default_vsync_enabled = false
var vsync_enabled = false

# Sound Settings Section
var current_audio_settings_button := 0
var default_master_audio := 10
var current_master_audio := 10
var default_music_audio := 10
var current_music_audio := 10
var default_sound_audio := 10
var current_sound_audio := 10
var default_ambience_audio := 10
var current_ambience_audio := 10

# Language Settings Section
var available_languages = ["en", "it", "es", "fr", "de"]
var current_language_index = 0

func _save():
	var file = FileAccess.open_encrypted_with_pass(save_location, FileAccess.WRITE, "19191919")
	settings_dictionary.window_mode = current_window_mode_index
	settings_dictionary.resolution = current_resolution_index
	settings_dictionary.quality = current_quality_index
	settings_dictionary.vsync = vsync_enabled
	settings_dictionary.master_audio = current_master_audio
	settings_dictionary.music_audio = current_music_audio
	settings_dictionary.sound_audio = current_sound_audio
	settings_dictionary.ambience_audio = current_ambience_audio
	settings_dictionary.current_language = current_language_index
	file.store_var(settings_dictionary.duplicate())
	file.close()

func _load():
	if FileAccess.file_exists(save_location):
		var file = FileAccess.open_encrypted_with_pass(save_location, FileAccess.READ, "19191919")
		var data = file.get_var()
		file.close()
		settings_dictionary = data
		var save_data = data.duplicate()
		loadVideoSettings(save_data)
		loadAudioSettings(save_data)
		loadLanguageSettings(save_data)

func loadVideoSettings(save_data):
		current_window_mode_index = save_data.window_mode
		current_resolution_index = save_data.resolution
		current_quality_index = save_data.quality
		vsync_enabled = save_data.vsync
		var names = ["Windowed", "Fullscreen"]
		%WindowModeValue.text = names[current_window_mode_index]
		var res = supported_resolutions[current_resolution_index]
		%ResolutionValue.text = str(res.x) + "x" + str(res.y)
		%QualityValue.text = quality_levels[current_quality_index]
		%"V-SyncValue".text = str(vsync_enabled).replace("true", "On").replace("false", "Off")

func loadAudioSettings(save_data):
	current_master_audio = save_data.master_audio
	current_music_audio = save_data.music_audio
	current_sound_audio = save_data.sound_audio
	current_ambience_audio = save_data.ambience_audio
	%MasterValue.text = str(current_master_audio)
	%MusicValue.text = str(current_music_audio)
	%SoundValue.text = str(current_sound_audio)
	%AmbienceValue.text = str(current_ambience_audio)

func loadLanguageSettings(save_data):
	current_language_index = save_data.current_language
	%LanguageValue.text = available_languages[current_language_index]

func _ready() -> void:
	_load()
	update_selection_visual()

func _input(event):
	if tween_active or Singleton.current_scene != "Game":
		return
	if not settings_open:
		_handle_main_input(event)
	else:
		match (current_settings_section):
			0:
				_handle_settings_input(event)
			1:
				_handle_video_settings_input(event)
			2:
				_handle_audio_settings_input(event)
			3:
				_handle_language_settings_input(event)

func _play_ent_sound() -> void:
	if enter_sound and not enter_sound.is_playing():
		enter_sound.play()

func _play_nav_sound() -> void:
	if navigation_sound and not navigation_sound.is_playing():
		navigation_sound.play()
		
func _play_esc_sound() -> void:
	if esc_sound and not esc_sound.is_playing():
		esc_sound.play()
		
func _handle_main_input(event):
	if event.is_action_pressed("Move_Right"):
		return
	elif event.is_action_pressed("Move_Left"):
		return
	elif event.is_action_pressed("Move_Up"):
		var prev_slot = current_menu_button
		current_menu_button = clamp(current_menu_button - 1, 0, menu_buttons.size()-1)
		if prev_slot != current_menu_button:
			_play_nav_sound()
	elif event.is_action_pressed("Move_Down"):
		var prev_slot = current_menu_button
		current_menu_button = clamp(current_menu_button + 1, 0, menu_buttons.size()-1)
		if prev_slot != current_menu_button:
			_play_nav_sound()
	elif event.is_action_pressed("Click"):
		match(current_menu_button):
			0:
				continue_game()
			1:
				open_settings()
			2:
				quit_to_menu()
	elif event.is_action_pressed("ui_cancel"):
		continue_game()
	update_selection_visual()

func continue_game():
	var timer = Timer.new()
	timer.wait_time = 0.01       # imposta il tempo di attesa
	timer.one_shot = true        # fa scattare il timer solo una volta
	add_child(timer)             # devi aggiungerlo alla scena
	timer.timeout.connect(PauseManager.resume_game)  # SENZA parentesi!
	timer.start()

func open_settings():
	_play_ent_sound()
	settings_open = true
	var from_section = %MainContainer
	var to_section = settings_sections[current_settings_section]
	tween_active = true
	var tween = create_tween()
	tween.tween_property(from_section, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		from_section.visible = false
		to_section.visible = true
		to_section.modulate.a = 0.0
		var tween_in = create_tween()
		tween_in.tween_property(to_section, "modulate:a", 1.0, 0.3)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		tween_in.tween_callback(func():
			tween_active = false
		)
	)

func quit_to_menu():
	_play_esc_sound()
	SoundManager.stop_gameplay_music()
	PauseManager.quit_to_menu()

func close_settings():
	_play_esc_sound()
	settings_open = false
	var from_section = settings_sections[current_settings_section]
	var to_section = %MainContainer
	tween_active = true
	var tween = create_tween()
	tween.tween_property(from_section, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		from_section.visible = false
		to_section.visible = true
		to_section.modulate.a = 0.0
		var tween_in = create_tween()
		tween_in.tween_property(to_section, "modulate:a", 1.0, 0.3)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		tween_in.tween_callback(func():
			tween_active = false
		)
	)

func _handle_settings_input(event):
	if event.is_action_pressed("Move_Right"):
		return
	elif event.is_action_pressed("Move_Left"):
		return
	elif event.is_action_pressed("Move_Up"):
		var prev_slot = current_settings_button
		current_settings_button = clamp(current_settings_button - 1, 0, settings_buttons.size()-1)
		if prev_slot != current_settings_button:
			_play_nav_sound()
	elif event.is_action_pressed("Move_Down"):
		var prev_slot = current_settings_button
		current_settings_button = clamp(current_settings_button + 1, 0, settings_buttons.size()-1)
		if prev_slot != current_settings_button:
			_play_nav_sound()
	elif event.is_action_pressed("Click"):
		_play_ent_sound()
		match(current_settings_button):
			0:
				go_to_settings_section(1)
			1:
				go_to_settings_section(2)
			2:
				go_to_settings_section(3)
	elif event.is_action_pressed("ui_cancel"):
		close_settings()
		return
	update_selection_visual()

func _handle_video_settings_input(event):
	if event.is_action_pressed("Move_Right"):
		match (current_video_settings_button):
			0:
				current_window_mode_index = (current_window_mode_index + 1) % window_modes.size()
				var names = ["Windowed", "Fullscreen"]
				%WindowModeValue.text = names[current_window_mode_index]
				_play_nav_sound()
			1:
				current_resolution_index = (current_resolution_index + 1) % supported_resolutions.size()
				var res = supported_resolutions[current_resolution_index]
				%ResolutionValue.text = str(res.x) + "x" + str(res.y)
				_play_nav_sound()
			2:
				current_quality_index = (current_quality_index + 1) % quality_levels.size()
				%QualityValue.text = quality_levels[current_quality_index]
				_play_nav_sound()
			3:
				vsync_enabled = not vsync_enabled
				%"V-SyncValue".text = str(vsync_enabled).replace("true", "On").replace("false", "Off")
				_play_nav_sound()
	elif event.is_action_pressed("Move_Left"):
		match (current_video_settings_button):
			0:
				current_window_mode_index = (current_window_mode_index - 1 + window_modes.size()) % window_modes.size()
				var names = ["Windowed", "Fullscreen"]
				%WindowModeValue.text = names[current_window_mode_index]
				_play_nav_sound()
			1:
				current_resolution_index = (current_resolution_index - 1 + supported_resolutions.size()) % supported_resolutions.size()
				var res = supported_resolutions[current_resolution_index]
				%ResolutionValue.text = str(res.x) + "x" + str(res.y)
				_play_nav_sound()
			2:
				current_quality_index = (current_quality_index - 1 + quality_levels.size()) % quality_levels.size()
				%QualityValue.text = quality_levels[current_quality_index]
				_play_nav_sound()
			3:
				vsync_enabled = not vsync_enabled
				%"V-SyncValue".text = str(vsync_enabled).replace("true", "On").replace("false", "Off")
				_play_nav_sound()
	elif event.is_action_pressed("Move_Up"):
		var prev_button = current_video_settings_button
		current_video_settings_button = clamp(current_video_settings_button - 1, 0, video_settings_buttons.size()-1)
		if prev_button != current_video_settings_button:
			_play_nav_sound()
	elif event.is_action_pressed("Move_Down"):
		var prev_button = current_video_settings_button
		current_video_settings_button = clamp(current_video_settings_button + 1, 0, video_settings_buttons.size()-1)
		if prev_button != current_video_settings_button:
			_play_nav_sound()
	elif event.is_action_pressed("Click"):
		match(current_video_settings_button):
			4:
				_play_esc_sound()
				current_window_mode_index = default_window_mode_index
				var names = ["Windowed", "Fullscreen"]
				%WindowModeValue.text = names[current_window_mode_index]
				current_resolution_index = default_resolution_index
				var res = supported_resolutions[current_resolution_index]
				%ResolutionValue.text = str(res.x) + "x" + str(res.y)
				current_quality_index = default_quality_index
				%QualityValue.text = quality_levels[current_quality_index]
				vsync_enabled = default_vsync_enabled
				%"V-SyncValue".text = str(vsync_enabled).replace("true", "On").replace("false", "Off")
				DisplayServer.window_set_mode(window_modes[current_window_mode_index])
				var preset = quality_presets[current_quality_index]
				var root_vp = get_tree().get_root()
				root_vp.msaa_2d = preset.msaa_2d
				root_vp.scaling_3d_scale = preset.scaling_3d_scale
				root_vp.screen_space_aa = preset.screen_space_aa
				var vp_rid = root_vp.get_viewport_rid()
				RenderingServer.viewport_set_msaa_2d(vp_rid, preset.msaa_2d)
				RenderingServer.viewport_set_scaling_3d_scale(vp_rid, preset.scaling_3d_scale)
				ProjectSettings.set_setting("rendering/quality/shadows/atlas_size", preset.shadow_atlas_size)
				DisplayServer.window_set_size(res)
				if vsync_enabled:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
				else:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
			5:
				_play_ent_sound()
				DisplayServer.window_set_mode(window_modes[current_window_mode_index])
				var preset = quality_presets[current_quality_index]
				var root_vp = get_tree().get_root()
				root_vp.msaa_2d = preset.msaa_2d
				root_vp.scaling_3d_scale = preset.scaling_3d_scale
				root_vp.screen_space_aa = preset.screen_space_aa
				var vp_rid = root_vp.get_viewport_rid()
				RenderingServer.viewport_set_msaa_2d(vp_rid, preset.msaa_2d)
				RenderingServer.viewport_set_scaling_3d_scale(vp_rid, preset.scaling_3d_scale)
				ProjectSettings.set_setting("rendering/quality/shadows/atlas_size", preset.shadow_atlas_size)
				var res = supported_resolutions[current_resolution_index]
				DisplayServer.window_set_size(res)
				if vsync_enabled:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
				else:
					DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
				_save()
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound()
		current_window_mode_index = settings_dictionary.window_mode
		var names = ["Windowed", "Fullscreen"]
		%WindowModeValue.text = names[current_window_mode_index]
		current_resolution_index = settings_dictionary.resolution
		var res = supported_resolutions[current_resolution_index]
		%ResolutionValue.text = str(res.x) + "x" + str(res.y)
		current_quality_index = settings_dictionary.quality
		%QualityValue.text = quality_levels[current_quality_index]
		vsync_enabled = settings_dictionary.vsync
		%"V-SyncValue".text = str(vsync_enabled).replace("true", "On").replace("false", "Off")
		go_to_settings_section(0)
		return
	update_selection_visual()

func _handle_audio_settings_input(event):
	if event.is_action_pressed("Move_Right"):
		match (current_audio_settings_button):
			0:
				var prev_value = current_master_audio
				current_master_audio = clamp(current_master_audio + 1, 0, 10)
				%MasterValue.text = str(current_master_audio)
				if (prev_value != current_master_audio):
					_play_nav_sound()
			1:
				var prev_value = current_music_audio
				current_music_audio = clamp(current_music_audio + 1, 0, 10)
				%MusicValue.text = str(current_music_audio)
				if (prev_value != current_music_audio):
					_play_nav_sound()
			2:
				var prev_value = current_sound_audio
				current_sound_audio = clamp(current_sound_audio + 1, 0, 10)
				%SoundValue.text = str(current_sound_audio)
				if (prev_value != current_sound_audio):
					_play_nav_sound()
			3:
				var prev_value = current_ambience_audio
				current_ambience_audio = clamp(current_ambience_audio + 1, 0, 10)
				%AmbienceValue.text = str(current_ambience_audio)
				if (prev_value != current_ambience_audio):
					_play_nav_sound()
	elif event.is_action_pressed("Move_Left"):
		match (current_audio_settings_button):
			0:
				var prev_value = current_master_audio
				current_master_audio = clamp(current_master_audio - 1, 0, 10)
				%MasterValue.text = str(current_master_audio)
				if (prev_value != current_master_audio):
					_play_nav_sound()
			1:
				var prev_value = current_music_audio
				current_music_audio = clamp(current_music_audio - 1, 0, 10)
				%MusicValue.text = str(current_music_audio)
				if (prev_value != current_music_audio):
					_play_nav_sound()
			2:
				var prev_value = current_sound_audio
				current_sound_audio = clamp(current_sound_audio - 1, 0, 10)
				%SoundValue.text = str(current_sound_audio)
				if (prev_value != current_sound_audio):
					_play_nav_sound()
			3:
				var prev_value = current_ambience_audio
				current_ambience_audio = clamp(current_ambience_audio - 1, 0, 10)
				%AmbienceValue.text = str(current_ambience_audio)
				if (prev_value != current_ambience_audio):
					_play_nav_sound()
	elif event.is_action_pressed("Move_Up"):
		var prev_button = current_audio_settings_button
		current_audio_settings_button = clamp(current_audio_settings_button - 1, 0, audio_settings_buttons.size()-1)
		if prev_button != current_audio_settings_button:
			_play_nav_sound()
	elif event.is_action_pressed("Move_Down"):
		var prev_button = current_audio_settings_button
		current_audio_settings_button = clamp(current_audio_settings_button + 1, 0, audio_settings_buttons.size()-1)
		if prev_button != current_audio_settings_button:
			_play_nav_sound()
	elif event.is_action_pressed("Click"):
		match(current_audio_settings_button):
			4:
				_play_esc_sound()
				current_master_audio = default_master_audio
				%MasterValue.text = str(current_master_audio)
				current_music_audio = default_music_audio
				%MusicValue.text = str(current_music_audio)
				current_sound_audio = default_sound_audio
				%SoundValue.text = str(current_sound_audio)
				current_ambience_audio = default_ambience_audio
				%AmbienceValue.text = str(current_ambience_audio)
			5:
				_play_ent_sound()
				var master_idx = AudioServer.get_bus_index("Master")
				var sfx_idx = AudioServer.get_bus_index("SFX")
				var ambience_idx = AudioServer.get_bus_index("Ambience")
				var music_idx = AudioServer.get_bus_index("Music")

				AudioServer.set_bus_volume_db(master_idx, linear_to_db(current_master_audio / 10.0))
				AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(current_sound_audio / 10.0))
				AudioServer.set_bus_volume_db(ambience_idx, linear_to_db(current_ambience_audio / 10.0))
				AudioServer.set_bus_volume_db(music_idx, linear_to_db(current_music_audio / 10.0))
				_save()
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound() 
		current_master_audio = settings_dictionary.master_audio
		%MasterValue.text = str(current_master_audio)
		current_music_audio = settings_dictionary.music_audio
		%MusicValue.text = str(current_music_audio)
		current_sound_audio = settings_dictionary.sound_audio
		%SoundValue.text = str(current_sound_audio)
		current_ambience_audio = settings_dictionary.ambience_audio
		%AmbienceValue.text = str(current_ambience_audio)
		go_to_settings_section(0)
		return
	update_selection_visual()

func _handle_language_settings_input(event):
	if event.is_action_pressed("Move_Right"):
		return
	elif event.is_action_pressed("Move_Left"):
		return
	elif event.is_action_pressed("Move_Up"):
		_play_nav_sound()
		current_language_index = (current_language_index - 1 + available_languages.size()) % available_languages.size()
		var lang = available_languages[current_language_index]
		%LanguageValue.text = lang
		TranslationServer.set_locale(lang)
	elif event.is_action_pressed("Move_Down"):
		_play_nav_sound()
		current_language_index = (current_language_index + 1) % available_languages.size()
		var lang = available_languages[current_language_index]
		%LanguageValue.text = lang
		TranslationServer.set_locale(lang)
	elif event.is_action_pressed("Click"):
		return
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound()
		go_to_settings_section(0)
		return
	_save()

func go_to_settings_section(index: int) -> void:
	var prev_section = current_settings_section
	current_settings_section = clamp(index, 0, total_settings_sections)
	var from_section = settings_sections[prev_section]
	var to_section = settings_sections[current_settings_section]
	tween_active = true
	var tween = create_tween()
	tween.tween_property(from_section, "modulate:a", 0.0, 0.3)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		from_section.visible = false
		to_section.visible = true
		to_section.modulate.a = 0.0
		var tween_in = create_tween()
		tween_in.tween_property(to_section, "modulate:a", 1.0, 0.3)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
		tween_in.tween_callback(func():
			tween_active = false
		)
	)

func update_selection_visual():
	if not settings_open:
		current_menu_button = clamp(current_menu_button, 0, menu_buttons.size() - 1)
		for i in range(menu_buttons.size()):
			var btn = menu_buttons[i]
			var tween = create_tween()
			if i == current_menu_button:
				tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				btn.scale = Vector2(1, 1.01)
			else:
				tween.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5, 1), 0.1)\
					.set_trans(Tween.TRANS_SINE)\
					.set_ease(Tween.EASE_IN_OUT)
				btn.scale = Vector2(1, 1)
	else:
		match (current_settings_section):
			0:
				current_settings_button = clamp(current_settings_button, 0, settings_buttons.size() - 1)
				for i in range(settings_buttons.size()):
					var btn = settings_buttons[i]
					var tween = create_tween()
					if i == current_settings_button:
						tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
						btn.scale = Vector2(1, 1.01)
					else:
						tween.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5, 1), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
						btn.scale = Vector2(1, 1)
			1:
				current_video_settings_button = clamp(current_video_settings_button, 0, video_settings_buttons.size() - 1)
				for i in range(video_settings_buttons.size()):
					var btn = video_settings_buttons[i]
					var tween = create_tween()
					var has_value = i < 4
					var value_node = null
					if has_value:
						value_node = get_node(str(btn.get_path()) + "Value")
					if i == current_video_settings_button:
						tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
						btn.scale = Vector2(1, 1.01)
						if has_value:
							value_node.modulate = Color(1, 1, 1, 1)
					else:
						tween.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5, 1), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
						btn.scale = Vector2(1, 1)
						if has_value:
							value_node.modulate = Color(0.5, 0.5, 0.5, 1)
			2:
				current_audio_settings_button = clamp(current_audio_settings_button, 0, audio_settings_buttons.size() - 1)
				for i in range(audio_settings_buttons.size()):
					var btn = audio_settings_buttons[i]
					var tween = create_tween()
					var has_value = i < 4
					var value_node = null
					if has_value:
						value_node = get_node(str(btn.get_path()) + "Value")
					if i == current_audio_settings_button:
						tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
						btn.scale = Vector2(1, 1.01)
						if has_value:
							value_node.modulate = Color(1, 1, 1, 1)
					else:
						tween.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5, 1), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
						btn.scale = Vector2(1, 1)
						if has_value:
							value_node.modulate = Color(0.5, 0.5, 0.5, 1)
