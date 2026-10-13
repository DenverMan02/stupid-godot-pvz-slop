extends Node2D

@onready var camera: Camera2D = 
@onready var grid: LawnGrid = 
@onready var background: Node2D = 

# Camera pan positions in 1080p space:
# Right position: showing incoming zombies on the street
const CAM_ZOMBIE_X: float = 1816.0
# Gameplay position: centered on the 9x5 lawn
const CAM_GAMEPLAY_X: float = 1194.0
const CAM_Y: float = 540.0

var cys_music: AudioStream = preload("res://Audio/BGM/Worlds/Modern Day/modern_CYS.mp3")
var battle_music: AudioStream = preload("res://Audio/BGM/Worlds/Modern Day/modern_first_wave.mp3")

func _ready() -> void:
	# Set initial camera position on the street preview
	camera.position = Vector2(CAM_ZOMBIE_X, CAM_Y)

	# Play Choose Your Seeds / intro music
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(cys_music)

	# Start camera pan after a brief opening pause
	get_tree().create_timer(0.6).timeout.connect(_start_camera_pan)

func _start_camera_pan() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position:x", CAM_GAMEPLAY_X, 2.2)
	tween.finished.connect(_on_pan_finished)

func _on_pan_finished() -> void:
	print("[Lawn] Camera pan finished! Ready... Set... Plant!")
	# Transition to first wave music
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(battle_music)
