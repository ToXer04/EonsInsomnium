extends Node


const SONG_ECHOES = preload("res://Content/SFX/Music/Songs/Echoes_Beyond.WAV")

func play_song(player: AudioStreamPlayer, song_stream: AudioStream): 
	if player.stream == song_stream and player.is_playing():
		return
	
	player.stream = song_stream
	player.play()
	
func stop_music(player: AudioStreamPlayer):
	player.stop()
