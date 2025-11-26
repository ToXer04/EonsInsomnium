extends Node

# --- MUSIC ---
const SONG_MENU = preload("res://Content/SFX/Music/MainMenu/Eternal_Reverie.WAV")
const SONG_GAMEPLAY = preload("res://Content/SFX/Music/Songs/Echoes_Beyond.WAV")

# --- SFX ---
const SFX_STEP = preload("res://Content/SFX/MC/Walk/MC_GrassStep1_SFX.WAV")
const SFX_JUMPSTART = preload("res://Content/SFX/MC/Jump/JumpStart_SFX/MC_Jump_SFX.WAV")
const SFX_JUMPLAND = preload("res://Content/SFX/MC/Jump/Land_SFX/MC_Landing_SFX.WAV")
const SFX_ATTACK = preload("res://Content/SFX/MC/Attack/MC_Attack_SFX.WAV")
const SFX_DASH = preload("res://Content/SFX/MC/Jump/Dash_SFX/MC_Dash_SFX.WAV")
const SFX_DEATH = preload("res://Content/SFX/MC/Death/MC_Death_SFX.WAV")
const SFX_DAMAGE = preload("res://Content/SFX/Damages/Damages_1__SFX.WAV")

# --- MENU SFX ---
const SFX_ESC = preload("res://Content/SFX/MainMenu/Esc/Esc_SFX.WAV")
const SFX_ENT = preload("res://Content/SFX/MainMenu/Enter/Enter_SFX.WAV")
const SFX_APPLY = preload("res://Content/SFX/MainMenu/Apply/Apply_SFX.WAV")
const SFX_DELETE = preload("res://Content/SFX/MainMenu/Delete/Delete_SFX.WAV")
const SFX_SWITCH = preload("res://Content/SFX/MainMenu/Switch/Switch_SFX.WAV")


# --- AUDIO PLAYERS ---
var gameplay_music_player: AudioStreamPlayer
var menu_music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready():
	# Player musica gameplay
	if not gameplay_music_player:
		gameplay_music_player = AudioStreamPlayer.new()
		add_child(gameplay_music_player)
		gameplay_music_player.bus = "Music"
		gameplay_music_player.autoplay = false

	# Player musica menu (ma non parte subito)
	if not menu_music_player:
		menu_music_player = AudioStreamPlayer.new()
		add_child(menu_music_player)
		menu_music_player.bus = "Music"
		menu_music_player.autoplay = false
		menu_music_player.stream = SONG_MENU

	# Player SFX
	if not sfx_player:
		sfx_player = AudioStreamPlayer.new()
		add_child(sfx_player)
		sfx_player.bus = "SFX"

# --- MUSIC FUNCTIONS ---
func start_menu_music():
	if not menu_music_player.playing:
		menu_music_player.play()

func play_gameplay_music():
	if gameplay_music_player.stream != SONG_GAMEPLAY or not gameplay_music_player.playing:
		gameplay_music_player.stream = SONG_GAMEPLAY
		gameplay_music_player.play()

func stop_gameplay_music():
	gameplay_music_player.stop()

# --- SFX FUNCTIONS ---
func play_sfx(sfx_stream: AudioStream):
	sfx_player.stream = sfx_stream
	sfx_player.play()

func play_ent_sfx():
	sfx_player.stream = SFX_ENT
	sfx_player.play()
	
func stop_menu_music():
	menu_music_player.stop()

func play_mc_step_sfx():
	sfx_player.stream = SFX_STEP
	sfx_player.play()
