extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var title_music: AudioStream = preload("res://Audio/BGM/Title.mp3")
var universe_music: AudioStream = preload("res://Audio/BGM/Menu.mp3")

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "BGM"
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"
	add_child(sfx_player)

	play_music(title_music)


func play_music(stream: AudioStream) -> void:
	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	music_player.stop()


func play_sfx(stream: AudioStream) -> void:
	sfx_player.stream = stream
	sfx_player.play()
