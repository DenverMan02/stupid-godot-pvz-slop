extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var grid: LawnGrid = $Grid
@onready var background: Node2D = $Background
@onready var plants_container: Node2D = $Plants
@onready var peashooter_count_label: Label = $HUD/MarginContainer/VBoxContainer/CountLabel
@onready var debug_status_label: Label = $HUD/MarginContainer/VBoxContainer/DebugLabel

const CAM_ZOMBIE_X: float = 1816.0
const CAM_GAMEPLAY_X: float = 1194.0
const CAM_Y: float = 540.0

var cys_music: AudioStream = preload("res://Audio/BGM/Worlds/Modern Day/modern_CYS.mp3")
var battle_music: AudioStream = preload("res://Audio/BGM/Worlds/Modern Day/modern_first_wave.mp3")
var peashooter_scene: PackedScene = preload("res://Scenes/Peashooter.tscn")

var debug_mode: bool = false
var peashooter_count: int = 0

func _ready() -> void:
	camera.position = Vector2(CAM_ZOMBIE_X, CAM_Y)

	# Initial peashooter count from pre-placed plants
	peashooter_count = plants_container.get_child_count()
	_update_hud()

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(cys_music)

	get_tree().create_timer(0.6).timeout.connect(_start_camera_pan)

func _start_camera_pan() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position:x", CAM_GAMEPLAY_X, 2.2)
	tween.finished.connect(_on_pan_finished)

func _on_pan_finished() -> void:
	print("[Lawn] Camera pan finished! Ready... Set... Plant!")
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(battle_music)

func _unhandled_input(event: InputEvent) -> void:
	# Press G to toggle debug mode
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			debug_mode = !debug_mode
			grid.debug_draw_grid = debug_mode
			grid.queue_redraw()
			_update_hud()
			print("[Lawn] Debug mode is now: %s" % ("ON" if debug_mode else "OFF"))

	# Right-click on tile spawns a Peashooter (only in debug mode)
	if debug_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var mouse_pos = get_global_mouse_position()
		var cell = grid.world_to_cell(mouse_pos)
		if grid.is_valid_cell(cell.x, cell.y):
			spawn_peashooter(cell.x, cell.y)

func spawn_peashooter(col: int, row: int) -> void:
	var peashooter = peashooter_scene.instantiate()
	var plant_pos = grid.cell_to_world(col, row)
	peashooter.position = plant_pos
	peashooter.z_index = grid.get_row_z_index(row)
	peashooter.row = row
	peashooter.col = col
	plants_container.add_child(peashooter)
	peashooter_count += 1
	_update_hud()

	if get_node_or_null("/root/AudioManager"):
		var plant_sfx = preload("res://Audio/SFX/planted.ogg")
		AudioManager.play_sfx(plant_sfx)

func _update_hud() -> void:
	if peashooter_count_label:
		peashooter_count_label.text = "PEASHOOTERS: %d" % peashooter_count
	if debug_status_label:
		if debug_mode:
			debug_status_label.text = "[DEBUG ON] R-Click: Spawn | L-Click: Attack"
			debug_status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		else:
			debug_status_label.text = "Press 'G' for Debug Mode"
			debug_status_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
