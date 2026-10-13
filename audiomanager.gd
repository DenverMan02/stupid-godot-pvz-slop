extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var title_music: AudioStream = preload("res://Audio/BGM/Title.mp3")
var universe_music: AudioStream = preload("res://Audio/BGM/Menu.mp3")

const SFX_POOL_SIZE: int = 12
var sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	if AudioServer.get_bus_index("BGM") != -1:
		music_player.bus = "BGM"
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)

	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		if AudioServer.get_bus_index("SFX") != -1:
			p.bus = "SFX"
		add_child(p)
		sfx_players.append(p)

	if not sfx_players.is_empty():
		sfx_player = sfx_players[0]

	play_music(title_music)


func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	if music_player.stream == stream and music_player.playing:
		return

	# Ensure stream loops indefinitely
	if "loop" in stream:
		stream.loop = true

	music_player.stream = stream
	music_player.play()


func _on_music_finished() -> void:
	if music_player.stream != null:
		music_player.play()


func stop_music() -> void:
	if music_player:
		music_player.stop()


func play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return

	# Find an idle SFX player from the pool
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.play()
			return

	# If all are busy, cycle round-robin
	var p = sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	p.stream = stream
	p.play()
