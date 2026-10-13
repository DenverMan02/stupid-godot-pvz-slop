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

var plant_scene: PackedScene = preload("res://Scenes/Plant.tscn")
var peashooter_scene: PackedScene = preload("res://Scenes/Peashooter.tscn")

const PLANT_REGISTRY: Array[Dictionary] = [
	{
		"id": "peashooter",
		"name": "Peashooter",
		"anim_json": "res://Assets/Plants/peashooter.anim.json",
		"tex_dir": "res://Assets/Plants/peashooter.xfl/library/",
	},
	{
		"id": "sunflower",
		"name": "Sunflower",
		"anim_json": "res://Assets/Plants/sunflower.anim.json",
		"tex_dir": "res://Assets/Plants/sunflower.xfl/library/",
	},
	{
		"id": "wallnut",
		"name": "Wall-nut",
		"anim_json": "res://Assets/Plants/wallnut.anim.json",
		"tex_dir": "res://Assets/Plants/wallnut.xfl/library/",
	},
	{
		"id": "potatomine",
		"name": "Potato Mine",
		"anim_json": "res://Assets/Plants/potatomine.anim.json",
		"tex_dir": "res://Assets/Plants/potatomine.xfl/library/",
	},
	{
		"id": "cabbagepult",
		"name": "Cabbage-pult",
		"anim_json": "res://Assets/Plants/cabbagepult.anim.json",
		"tex_dir": "res://Assets/Plants/cabbagepult.xfl/library/",
	},
	{
		"id": "lingfugu",
		"name": "LingFugu",
		"anim_json": "res://Assets/Plants/lingfugu.anim.json",
		"tex_dir": "res://Assets/Plants/lingfugu.xfl/library/",
	},
	{
		"id": "clivia",
		"name": "Clivia",
		"anim_json": "res://Assets/Plants/clivia.anim.json",
		"tex_dir": "res://Assets/Plants/clivia.xfl/LIBRARY/",
	},
	{
		"id": "garlic",
		"name": "Garlic",
		"anim_json": "res://Assets/Plants/garlic.anim.json",
		"tex_dir": "res://Assets/Plants/garlic.xfl/LIBRARY/",
	},
]

var debug_mode: bool = false
var plant_count: int = 0
var selected_plant_index: int = 0

func _ready() -> void:
	camera.position = Vector2(CAM_ZOMBIE_X, CAM_Y)

	# Initial plant count from pre-placed plants
	plant_count = plants_container.get_child_count()
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

		# Number keys 1-8 to select active plant to spawn
		elif event.keycode in [KEY_1, KEY_KP_1]:
			_select_plant(0)
		elif event.keycode in [KEY_2, KEY_KP_2]:
			_select_plant(1)
		elif event.keycode in [KEY_3, KEY_KP_3]:
			_select_plant(2)
		elif event.keycode in [KEY_4, KEY_KP_4]:
			_select_plant(3)
		elif event.keycode in [KEY_5, KEY_KP_5]:
			_select_plant(4)
		elif event.keycode in [KEY_6, KEY_KP_6]:
			_select_plant(5)
		elif event.keycode in [KEY_7, KEY_KP_7]:
			_select_plant(6)
		elif event.keycode in [KEY_8, KEY_KP_8]:
			_select_plant(7)

	# Right-click on tile spawns the currently selected plant (only in debug mode)
	if debug_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var mouse_pos = get_global_mouse_position()
		var cell = grid.world_to_cell(mouse_pos)
		if grid.is_valid_cell(cell.x, cell.y):
			spawn_plant_at(cell.x, cell.y, selected_plant_index)

func _select_plant(index: int) -> void:
	if index >= 0 and index < PLANT_REGISTRY.size():
		selected_plant_index = index
		_update_hud()
		print("[Lawn] Selected plant: [%d] %s" % [index + 1, PLANT_REGISTRY[index]["name"]])
		if get_node_or_null("/root/AudioManager"):
			var select_sfx = preload("res://Audio/SFX/select_plant.ogg")
			AudioManager.play_sfx(select_sfx)

func spawn_plant_at(col: int, row: int, plant_idx: int) -> void:
	var info = PLANT_REGISTRY[plant_idx]
	var plant_pos = grid.cell_to_world(col, row)
	var plant_node: Node2D

	if info["id"] == "peashooter":
		plant_node = peashooter_scene.instantiate()
	else:
		plant_node = plant_scene.instantiate()

	plant_node.position = plant_pos
	plant_node.z_index = grid.get_row_z_index(row) + (plant_count % 10)
	plant_node.set("row", row)
	plant_node.set("col", col)
	plant_node.set("plant_type", info["id"])
	plant_node.set("display_name", info["name"])
	plant_node.set("anim_data_path", info["anim_json"])
	plant_node.set("textures_base_dir", info["tex_dir"])

	var spr = plant_node.get_node_or_null("XFLSprite2D")
	if spr:
		spr.anim_data_path = info["anim_json"]
		spr.textures_base_dir = info["tex_dir"]
		spr.autoplay = false

	plants_container.add_child(plant_node)
	plant_count += 1
	_update_hud()

	if get_node_or_null("/root/AudioManager"):
		var plant_sfx = preload("res://Audio/SFX/planted.ogg")
		AudioManager.play_sfx(plant_sfx)

func _update_hud() -> void:
	var selected_name = PLANT_REGISTRY[selected_plant_index]["name"]
	if peashooter_count_label:
		peashooter_count_label.text = "PLANTS: %d | [%d] %s" % [plant_count, selected_plant_index + 1, selected_name]
	if debug_status_label:
		if debug_mode:
			debug_status_label.text = "[DEBUG ON] 1-8: Select | R-Click: Spawn | L-Click: Atk | M-Click: PlantFood"
			debug_status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		else:
			debug_status_label.text = "Press 'G' for Debug Mode"
			debug_status_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
