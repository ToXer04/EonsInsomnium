# UmbralDepth.gd
extends Node2D

@onready var biome_music_player: AudioStreamPlayer = $UmbralDepthsMusic_Player 

func _ready():

	if biome_music_player:
		MusicManager.play_song(biome_music_player, MusicManager.SONG_ECHOES) 
		print("music")
	
