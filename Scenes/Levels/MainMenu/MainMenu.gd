extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var container: Control = $SectionsContainer
@onready var startup_buttons := [%PlayButton, %SettingsButton]
@onready var slots := [%File1Container, %File2Container, %File3Container]
@onready var delete_button: TextureRect = %DeleteFileButton
@onready var menu_buttons := [%EnterDreamButton, %InviteDreamersButton, %ChallengesButton]
@onready var players_container: Node = %PlayersFramesContainer
@onready var disband_node: TextureRect = %DisbandDream
@onready var navigation_sound: AudioStreamPlayer = $NavigationSound
@onready var enter_sound: AudioStreamPlayer = $EnterSound
@onready var theme_song_player: AudioStreamPlayer = $MainThemeSong
@onready var esc_sound: AudioStreamPlayer = $EscSound

# General
const SECTION_WIDTH := 1920
var current_section := 0
var total_sections := 4
var tween_active := true
var slot_tween_active := false

# Section 0
var current_startup_button := 0

# Section 1
var current_slot := 0
var current_button := 0
var in_delete_layer := false
var previous_slot := 0

# Section 2
var current_menu_button := 0

# Section 3
var lobby_nav_index := 0
const LOBBY_NAV_SLOTS := 3 
var last_lobby_slot_index := 0




func _ready() -> void:
	animation_player.play("FadeLogo")
	initial_update_selection_visual()
	_update_lobby_nav_visual()
	if theme_song_player:
		theme_song_player.play()

func _process(_delta):
	if SteamLobbyManager.lobby_id != 0:
		update_lobby_players_ui()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "FadeLogo":
		tween_active = false

func _input(event):
	if tween_active or slot_tween_active:
		return
	match (current_section):
		0:
			_handle_0_input(event)
		1:
			_handle_1_input(event)
		2:
			_handle_2_input(event)
		3:
			_handle_3_input(event)


func _play_ent_sound() -> void:
	if enter_sound and not enter_sound.is_playing():
		enter_sound.play()

func _play_nav_sound() -> void:
	if navigation_sound and not navigation_sound.is_playing():
		navigation_sound.play()
		
func _play_esc_sound() -> void:
	if esc_sound and not esc_sound.is_playing():
		esc_sound.play()		
		
func _handle_0_input(event):
	if event.is_action_pressed("Move_Right"):
		return
		
	elif event.is_action_pressed("Move_Left"):
		return
		
	elif event.is_action_pressed("Move_Up"):
		current_startup_button = clamp(current_startup_button - 1, 0, startup_buttons.size()-1)
		_play_nav_sound() 
		
	elif event.is_action_pressed("Move_Down"):
		current_startup_button = clamp(current_startup_button + 1, 0, startup_buttons.size()-1)
		_play_nav_sound() 
		
	elif event.is_action_pressed("Click"):
		if current_startup_button == 0:
			go_to_section(1)
			_play_ent_sound() 
			
			
		else:
			print("Settings")
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
			_play_ent_sound() 
		else:
			go_to_section(2)
			_play_ent_sound()
	elif event.is_action_pressed("ui_cancel"):
		if Steam.getSteamID() != Steam.getLobbyOwner(SteamLobbyManager.lobby_id):
			_play_esc_sound() 
			return
		else:
			go_to_section(current_section - 1)
			_play_esc_sound() 

	update_selection_visual()


func _handle_2_input(event):
	if event.is_action_pressed("Move_Right"):
		_play_nav_sound()
		return
	elif event.is_action_pressed("Move_Left"):
		_play_nav_sound()
		return
	elif event.is_action_pressed("Move_Up"):
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) or SteamLobbyManager.lobby_id == 0:
			current_menu_button = clamp(current_menu_button - 1, 0, menu_buttons.size()-1)
			_play_nav_sound()
		else:
			current_menu_button = clamp(current_menu_button - 1, 1, menu_buttons.size()-2)
			_play_nav_sound()
	elif event.is_action_pressed("Move_Down"):
		if Steam.getSteamID() == Steam.getLobbyOwner(SteamLobbyManager.lobby_id) or SteamLobbyManager.lobby_id == 0:
			current_menu_button = clamp(current_menu_button + 1, 0, menu_buttons.size()-1)
			_play_nav_sound()
		else:
			current_menu_button = clamp(current_menu_button + 1, 1, menu_buttons.size()-2)
			_play_nav_sound()
	elif event.is_action_pressed("Click"):
		match current_menu_button:
			0:
				SteamLobbyManager.start_hosting_game()
			1:
				if SteamLobbyManager.lobby_id == 0:
					SteamLobbyManager.host_lobby()
				go_to_section(3)
				_play_ent_sound()
				
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound() 
		go_to_section(current_section - 1)

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
		_play_ent_sound()
		_handle_lobby_click()
	elif event.is_action_pressed("ui_cancel"):
		_play_esc_sound() 
		go_to_section(2)
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

@rpc("call_local", "any_peer")
func rpc_swap_texture(img_path: NodePath, img_name: String):
	var img = get_node(img_path)
	var base_path = "res://Scenes/Levels/MainMenu/Assets/Players/%s" % img_name
	img.texture = load(base_path)

func go_to_section(index: int) -> void:
	if tween_active:
		return
	current_section = clamp(index, 0, total_sections)
	var target_x = -current_section * SECTION_WIDTH
	var tween = create_tween()
	tween_active = true
	tween.tween_property(container, "position:x", target_x, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): tween_active = false)

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
	if current_section == 0:
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
	elif current_section == 1:
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
	elif current_section == 2:
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
