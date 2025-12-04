extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var container: Control = $SectionsContainer
@onready var startup_buttons := [%PlayButton, %SettingsButton]
@onready var slots := [%File1Container, %File2Container, %File3Container]
@onready var delete_button: TextureRect = %DeleteFileButton
@onready var menu_buttons := [%EnterDreamButton, %InviteDreamersButton, %ChallengesButton]
@onready var settings_sections := [%Settings, %Video, %Audio, %Language]
@onready var settings_buttons := [%VideoButton, %AudioButton, %LanguageButton]
@onready var video_settings_buttons := [%WindowMode, %Resolution, %Quality, %"V-Sync", %ResetToDefaultButtonVideo, %ApplyButtonVideo]
@onready var audio_settings_buttons := [%Master, %Music, %Sound, %Ambience, %ResetToDefaultButtonAudio, %ApplyButtonAudio]
@onready var players_container: Node = %PlayersFramesContainer
@onready var disband_node: TextureRect = %DisbandDream

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
const SECTION_WIDTH := 1920
const SECTION_HEIGHT := 1080
var current_horizontal_section := 0
var total_horizontal_sections := 4
var current_vertical_section := 0
var total_vertical_sections := 2
var tween_active := true
var slot_tween_active := false

# Startup Section
var current_startup_button := 0

# SelectSaveFile Section
var current_slot := 0
var current_button := 0
var in_delete_layer := false
var previous_slot := 0

# MainMenu Section
var current_menu_button := 0

# Lobby Section
var lobby_nav_index := 0
const LOBBY_NAV_SLOTS := 3 
var last_lobby_slot_index := 0

# Settings Section
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
	{ "msaa_2d": Viewport.MSAA_8X,   "scaling_3d_scale": 1.0, "screen_space_aa": Viewport.SCREEN_SPACE_AA_SMAA,    "shadow_atlas_size": 8192 }]
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
	var master_idx = AudioServer.get_bus_index("Master")
	var sfx_idx = AudioServer.get_bus_index("SFX")
	var ambience_idx = AudioServer.get_bus_index("Ambience")
	var music_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(current_master_audio / 10.0))
	AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(current_sound_audio / 10.0))
	AudioServer.set_bus_volume_db(ambience_idx, linear_to_db(current_ambience_audio / 10.0))
	AudioServer.set_bus_volume_db(music_idx, linear_to_db(current_music_audio / 10.0))

func loadLanguageSettings(save_data):
	current_language_index = save_data.current_language
	%LanguageValue.text = available_languages[current_language_index]
	TranslationServer.set_locale(available_languages[current_language_index])

func _ready() -> void:
	SoundManager.stop_sitidle_sfx()
	Singleton.current_scene = "MainMenu"
	animation_player.play("FadeLogo")
	initial_update_selection_visual()
	_update_lobby_nav_visual()
	

func _process(_delta):
	if SteamLobbyManager.lobby_id != 0:
		update_lobby_players_ui()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "FadeLogo":
		tween_active = false
		SoundManager.start_menu_music()

func _input(event):
	if tween_active or slot_tween_active:
		return
	match (current_vertical_section):
		0:
			match (current_horizontal_section):
				0:
					_handle_0_input(event)
				1:
					_handle_1_input(event)
				2:
					_handle_2_input(event)
				3:
					_handle_3_input(event)
		1:
			match (current_horizontal_section):
				0:
					match (current_settings_section):
						0:
							_handle_settings_input(event)
						1:
							_handle_video_settings_input(event)
						2:
							_handle_audio_settings_input(event)
						3:
							_handle_language_settings_input(event)

func _play_nav_sound() -> void:
	SoundManager.play_sfx(SoundManager.SFX_SWITCH)
		
func _play_esc_sound() -> void:
	SoundManager.play_sfx(SoundManager.SFX_ESC)
	
func _play_apply_sound() -> void:
	SoundManager.play_sfx(SoundManager.SFX_APPLY)
	
func _play_delete_sound() -> void: 
	SoundManager.play_sfx(SoundManager.SFX_DELETE)
		
func _handle_0_input(event):
	if event.is_action_pressed("Move_Right"):
		return
	elif event.is_action_pressed("Move_Left"):
		return
	elif event.is_action_pressed("Move_Up"):
		var prev_slot = current_startup_button
		current_startup_button = clamp(current_startup_button - 1, 0, startup_buttons.size()-1)
		if prev_slot != current_startup_button:
			_play_nav_sound()
	elif event.is_action_pressed("Move_Down"):
		var prev_slot = current_startup_button
		current_startup_button = clamp(current_startup_button + 1, 0, startup_buttons.size()-1)
		if prev_slot != current_startup_button:
			_play_nav_sound()
	elif event.is_action_pressed("Click"):
		if current_startup_button == 0:
			go_to_horizontal_section(1)
			SoundManager.play_ent_sfx()
		else:
			go_to_vertical_section(1)
			SoundManager.play_ent_sfx()
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound() 
		return
		
	update_selection_visual()

func _handle_1_input(event):
	if event.is_action_pressed("Move_Right"):
		if not in_delete_layer:
			select_slot(current_slot + 1)
			_play_nav_sound() 
	elif event.is_action_pressed("Move_Left"):
		if not in_delete_layer:
			select_slot(current_slot - 1)
			_play_nav_sound() 
	elif event.is_action_pressed("Move_Up"):
		if in_delete_layer:
			in_delete_layer = false
			_play_nav_sound() 
	elif event.is_action_pressed("Move_Down"):
		if not in_delete_layer:
			in_delete_layer = true
			_play_nav_sound()
	elif event.is_action_pressed("Click"):
		if in_delete_layer:
			print("Delete File selected for slot ", current_slot + 1)
			SoundManager.play_ent_sfx()
		else:
			SaveManager.load_game(current_slot + 1)
			go_to_horizontal_section(2)
			SoundManager.play_ent_sfx()
	elif event.is_action_pressed("ui_cancel"):
		go_to_horizontal_section(current_horizontal_section - 1)
		_play_esc_sound() 

	update_selection_visual()

func _handle_2_input(event):
	if event.is_action_pressed("Move_Right"):
		return
	elif event.is_action_pressed("Move_Left"):
		return
	elif event.is_action_pressed("Move_Up"):
		var prev_slot = current_menu_button
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) or SteamLobbyManager.lobby_id == 0:
			current_menu_button = clamp(current_menu_button - 1, 0, menu_buttons.size()-1)
			if prev_slot != current_menu_button:
				_play_nav_sound()
		else:
			current_menu_button = clamp(current_menu_button - 1, 1, menu_buttons.size()-2)
			_play_nav_sound()
			if prev_slot != current_menu_button:
				_play_nav_sound()
	elif event.is_action_pressed("Move_Down"):
		var prev_slot = current_menu_button
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) or SteamLobbyManager.lobby_id == 0:
			current_menu_button = clamp(current_menu_button + 1, 0, menu_buttons.size()-1)
			if prev_slot != current_menu_button:
				_play_nav_sound()
		else:
			current_menu_button = clamp(current_menu_button + 1, 1, menu_buttons.size()-2)
			if prev_slot != current_menu_button:
				_play_nav_sound()
	elif event.is_action_pressed("Click"):
		match current_menu_button:
			0:
				SoundManager.stop_menu_music()
				SteamLobbyManager.start_hosting_game()
			1:
				if SteamLobbyManager.lobby_id == 0:
					SteamLobbyManager.host_lobby()
				go_to_horizontal_section(3)
				SoundManager.play_ent_sfx()
				
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound() 
		go_to_horizontal_section(current_horizontal_section - 1)

	update_selection_visual()

func _handle_3_input(event):
	if event.is_action_pressed("Move_Right"):
		if lobby_nav_index == LOBBY_NAV_SLOTS:
			lobby_nav_index = LOBBY_NAV_SLOTS - 1
			_play_nav_sound()
		else:
			lobby_nav_index = (lobby_nav_index + 1) % LOBBY_NAV_SLOTS
			_play_nav_sound()
	elif event.is_action_pressed("Move_Left"):
		if lobby_nav_index == LOBBY_NAV_SLOTS:
			lobby_nav_index = 0
			_play_nav_sound()
		else:
			lobby_nav_index = (lobby_nav_index - 1 + LOBBY_NAV_SLOTS) % LOBBY_NAV_SLOTS
			_play_nav_sound()
	elif event.is_action_pressed("Move_Up"):
		if lobby_nav_index == LOBBY_NAV_SLOTS:
			lobby_nav_index = last_lobby_slot_index
			_play_nav_sound()
			_update_lobby_nav_visual()
		elif Steam.getLobbyMemberByIndex(SteamLobbyManager.lobby_id, lobby_nav_index) == Steam.getSteamID():
			var frame = players_container.get_child(lobby_nav_index)
			var img = frame.get_node("BG/PlayerImage")
			var tex = img.texture
			var tex_path = tex.resource_path.get_file() # solo il nome file
			match tex_path:
				"Eon.png":
					Singleton.selectedChar = "Lyra"
					rpc("rpc_swap_texture", img.get_path(), "Lyra.png")
				"Lyra.png":
					Singleton.selectedChar = "Eon"
					rpc("rpc_swap_texture", img.get_path(), "Eon.png")
	elif event.is_action_pressed("Move_Down"):
		if lobby_nav_index < LOBBY_NAV_SLOTS:
			last_lobby_slot_index = lobby_nav_index
			_play_nav_sound()
		lobby_nav_index = LOBBY_NAV_SLOTS
	elif event.is_action_pressed("Click"):
		SoundManager.play_ent_sfx()
		_handle_lobby_click()
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound() 
		go_to_horizontal_section(2)
	update_selection_visual()

func _handle_lobby_click():
	if lobby_nav_index == LOBBY_NAV_SLOTS:
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
			SteamLobbyManager.disband_lobby()
		else:
			Steam.leaveLobby(SteamLobbyManager.lobby_id)
			SteamLobbyManager._on_lobby_left()
		_update_lobby_nav_visual()
		return
	var slot_idx = lobby_nav_index  
	var members = SteamLobbyManager.get_lobby_members_names()
	var target_member_index = slot_idx + 1
	if target_member_index < members.size():
		var steam_id = Steam.getLobbyMemberByIndex(SteamLobbyManager.lobby_id, target_member_index)
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) and Steam.getSteamID() != steam_id:
			SteamLobbyManager.kick_player(steam_id)
	else:
		Steam.activateGameOverlayInviteDialog(SteamLobbyManager.lobby_id)

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
		SoundManager.play_ent_sfx()
		match(current_settings_button):
			0:
				go_to_settings_section(1)
			1:
				go_to_settings_section(2)
			2:
				go_to_settings_section(3)
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound() 
		go_to_vertical_section(0)
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
				SoundManager.play_ent_sfx()
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
				SoundManager.play_ent_sfx()
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

@rpc("call_local", "any_peer")
func rpc_swap_texture(img_path: NodePath, img_name: String):
	var img = get_node(img_path)
	var base_path = "res://Scenes/Levels/MainMenu/Assets/Players/%s" % img_name
	img.texture = load(base_path)

func go_to_horizontal_section(index: int) -> void:
	if tween_active:
		return
	current_horizontal_section = clamp(index, 0, total_horizontal_sections)
	var target_x = -current_horizontal_section * SECTION_WIDTH
	var tween = create_tween()
	tween_active = true
	tween.tween_property(container, "position:x", target_x, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): tween_active = false)

func go_to_vertical_section(index: int) -> void:
	if tween_active:
		return
	current_vertical_section = clamp(index, 0, total_vertical_sections)
	var target_y = -current_vertical_section * SECTION_HEIGHT
	var tween = create_tween()
	tween_active = true
	tween.tween_property(container, "position:y", target_y, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): tween_active = false)

func go_to_settings_section(index: int) -> void:
	if tween_active:
		return
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

func select_slot(index: int):
	if tween_active or slot_tween_active:
		return
	var prev_slot := current_slot
	current_slot = wrapi(index, 0, slots.size())
	if prev_slot == current_slot:
		return
	slot_tween_active = true
	var tween = create_tween()
	var duration := 0.1
	for i in range(slots.size()):
		var slot_content = slots[i]
		var target_scale: Vector2
		var target_color: Color
		if i == current_slot:
			target_scale = Vector2(1.01, 1.01)
			target_color = Color(1, 1, 1, 1)
		else:
			target_scale = Vector2(1, 1)
			target_color = Color(0.5, 0.5, 0.5, 1)
		tween.parallel().tween_property(slot_content, "scale", target_scale, duration)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(slot_content, "modulate", target_color, duration)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		slot_tween_active = false
		update_selection_visual()
	)

func initial_update_selection_visual():
	current_startup_button = clamp(current_startup_button, 0, startup_buttons.size()-1)
	for i in range(startup_buttons.size()):
		var btn = startup_buttons[i]
		var tween = create_tween()
		if i == current_startup_button:
			tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.1)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1, 1.01)
		else:
			tween.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5, 1), 0.1)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1, 1)
	for i in range(slots.size()):
		var slot = slots[i]
		if i == current_slot and not in_delete_layer:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(1,1,1,1), 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1.01, 1.01)
		elif in_delete_layer and i == previous_slot:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.749, 0.0, 0.0, 0.75), 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1.01,1.01)
		else:
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.5,0.5,0.5,1), 0.2)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN_OUT)
			slot.scale = Vector2(1,1)
	delete_button.modulate = Color(1, 1, 1, 1) if in_delete_layer else Color(0.6, 0.6, 0.6, 1)
	if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) or SteamLobbyManager.lobby_id == 0:
		current_menu_button = clamp(current_menu_button, 0, menu_buttons.size()-1)
	else:
		current_menu_button = clamp(current_menu_button, 1, menu_buttons.size()-2)
	for i in range(menu_buttons.size()):
		var btn = menu_buttons[i]
		var tween = create_tween()
		if i == current_menu_button:
			tween.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.2)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1, 1.01)
		else:
			tween.tween_property(btn, "modulate", Color(0.5, 0.5, 0.5, 1), 0.1)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			btn.scale = Vector2(1, 1)

func update_selection_visual():
	match (current_vertical_section):
		0:
			match (current_horizontal_section):
				0:
					current_startup_button = clamp(current_startup_button, 0, startup_buttons.size()-1)
					for i in range(startup_buttons.size()):
						var btn = startup_buttons[i]
						var tween = create_tween()
						if i == current_startup_button:
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
					for i in range(slots.size()):
						var slot = slots[i]
						if i == current_slot and not in_delete_layer:
							var tween = create_tween()
							tween.tween_property(slot, "modulate", Color(1,1,1,1), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
							slot.scale = Vector2(1.01, 1.01)
						elif in_delete_layer and i == current_slot:
							var tween = create_tween()
							tween.tween_property(slot, "modulate", Color(0.749, 0.0, 0.0, 0.75), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
							slot.scale = Vector2(1.01, 1.01)
						else:
							var tween = create_tween()
							tween.tween_property(slot, "modulate", Color(0.5,0.5,0.5,1), 0.1)\
							.set_trans(Tween.TRANS_SINE)\
							.set_ease(Tween.EASE_IN_OUT)
							slot.scale = Vector2(1, 1)
					delete_button.modulate = Color(1, 1, 1, 1) if in_delete_layer else Color(0.6, 0.6, 0.6, 1)
				2:
					if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) or SteamLobbyManager.lobby_id == 0:
						current_menu_button = clamp(current_menu_button, 0, menu_buttons.size()-1)
					else:
						current_menu_button = clamp(current_menu_button, 1, menu_buttons.size()-2)
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
		1:
			match (current_horizontal_section):
				0:
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

func update_lobby_players_ui():
	var members = SteamLobbyManager.get_lobby_members_names()
	var frame1 = players_container.get_child(0)
	var player1_name = frame1.get_node("BG/NameContainer/TextureRect/Label")
	if members.size() > 0:
		player1_name.text = members[0]
	else:
		player1_name.text = "Unknown"
	for i in range(1, 4):
		var frame = players_container.get_child(i)
		var player_container = frame.get_node("BG")
		var invite_label = player_container.get_node("InviteLabel")
		var player_name = player_container.get_node("NameContainer/TextureRect/Label")
		if i < members.size():
			player_container.get_node("ArrowImage").visible = true
			player_container.get_node("PlayerImage").visible = true
			player_container.get_node("NameContainer").visible = true
			player_name.text = members[i]
			invite_label.visible = false
		else:
			player_container.get_node("ArrowImage").visible = false
			player_container.get_node("PlayerImage").visible = false
			player_container.get_node("NameContainer").visible = false
			invite_label.visible = true
	disband_node.get_node("DisbandDreamLabel").visible = Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id)
	disband_node.get_node("LeaveDreamLabel").visible = Steam.getSteamID() != Steam.getLobbyOwner(SteamLobbyManager.lobby_id)
	_update_lobby_nav_visual()

func _set_panel_border(panel: PanelContainer, white: bool) -> void:
	var sb = null
	if panel.has_method("get_theme_stylebox"):
		sb = panel.get_theme_stylebox("panel")
	if sb == null:
		if panel.has_meta("custom_styles"):
			sb = panel.get("custom_styles/panel")
	if sb and sb is StyleBoxFlat:
		var copy = sb.duplicate()
		copy.border_color = Color(1,1,1,1) if white else Color(0,0,0,1)
		panel.add_theme_stylebox_override("panel", copy)
	else:
		panel.self_modulate = Color(1,1,1,1) if white else Color(1,1,1,1)

func _update_lobby_nav_visual():
	for i in range(0, 4):
		var frame = players_container.get_child(i)
		if lobby_nav_index == i - 1:
			_set_panel_border(frame, true)
		else:
			_set_panel_border(frame, false)
	if lobby_nav_index == LOBBY_NAV_SLOTS:
		disband_node.modulate = Color(1,1,1,1)
	else:
		disband_node.modulate = Color(0.6,0.6,0.6,1)
