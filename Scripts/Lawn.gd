extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var grid: LawnGrid = $Grid
@onready var background: Node2D = $Background
@onready var plants_container: Node2D = $Plants
@onready var suns_container: Node2D = $Suns
@onready var seed_bank: SeedBank = $HUD/SeedBank
@onready var peashooter_count_label: Label = $HUD/MarginContainer/VBoxContainer/CountLabel
@onready var debug_status_label: Label = $HUD/MarginContainer/VBoxContainer/DebugLabel

const CAM_ZOMBIE_X: float = 1816.0
const CAM_GAMEPLAY_X: float = 1194.0
const CAM_Y: float = 540.0

var cys_music: AudioStream = preload("res://Audio/BGM/Worlds/Modern Day/modern_CYS.mp3")
var battle_music: AudioStream = preload("res://Audio/BGM/Worlds/Modern Day/modern_first_wave.mp3")

var plant_scene: PackedScene = preload("res://Scenes/Plant.tscn")
var peashooter_scene: PackedScene = preload("res://Scenes/Peashooter.tscn")
var sun_scene: PackedScene = preload("res://Scenes/Sun.tscn")

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
		"scale": 1.0,
		"offset": Vector2.ZERO,
	},
	{
		"id": "clivia",
		"name": "Clivia",
		"anim_json": "res://Assets/Plants/clivia.anim.json",
		"tex_dir": "res://Assets/Plants/clivia.xfl/LIBRARY/",
		"scale": 1.8,
		"offset": Vector2(-25.0, 0.0),
	},
	{
		"id": "garlic",
		"name": "Garlic",
		"anim_json": "res://Assets/Plants/garlic.anim.json",
		"tex_dir": "res://Assets/Plants/garlic.xfl/LIBRARY/",
		"scale": 1.8,
		"offset": Vector2(-15.0, 45.0),
	},
]

var debug_mode: bool = false
var plant_count: int = 0
var selected_plant_index: int = 0
var sun_amount: int = 50
var sky_sun_timer: float = 6.0

func _ready() -> void:
	camera.position = Vector2(CAM_ZOMBIE_X, CAM_Y)

	# Initial plant count from pre-placed plants
	plant_count = plants_container.get_child_count()
	_update_hud()

	if seed_bank:
		seed_bank.update_sun_display(sun_amount)

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

func _process(delta: float) -> void:
	# Periodic sky sun falling
	sky_sun_timer -= delta
	if sky_sun_timer <= 0.0:
		sky_sun_timer = randf_range(8.5, 11.5)
		_spawn_sky_sun()

func _spawn_sky_sun() -> void:
	if not sun_scene:
		return
	var rand_col = randi_range(0, grid.columns - 1)
	var rand_row = randi_range(0, grid.rows - 1)
	var land_pos = grid.cell_to_world(rand_col, rand_row)
	var start_pos = Vector2(land_pos.x, CAM_Y - 580.0)

	var sun_inst: Sun = sun_scene.instantiate()
	if suns_container:
		suns_container.add_child(sun_inst)
	else:
		add_child(sun_inst)

	sun_inst.spawn_from_sky(start_pos, land_pos)
	sun_inst.collected.connect(func(val):
		add_sun(val)
	)

func add_sun(val: int) -> void:
	sun_amount += val
	if seed_bank:
		seed_bank.update_sun_display(sun_amount)

func spend_sun(val: int) -> bool:
	if sun_amount >= val:
		sun_amount -= val
		if seed_bank:
			seed_bank.update_sun_display(sun_amount)
		return true
	return false

func is_cell_occupied(col: int, row: int) -> bool:
	for p in plants_container.get_children():
		if p.get("col") == col and p.get("row") == row:
			return true
	return false

func get_plant_index_by_id(id: String) -> int:
	for i in range(PLANT_REGISTRY.size()):
		if PLANT_REGISTRY[i]["id"] == id:
			return i
	return -1

func _unhandled_input(event: InputEvent) -> void:
	# Press G to toggle debug mode
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			debug_mode = !debug_mode
			grid.debug_draw_grid = debug_mode
			grid.queue_redraw()
			_update_hud()
			print("[Lawn] Debug mode is now: %s" % ("ON" if debug_mode else "OFF"))

		# Number keys 1-8 to select active plant to spawn (debug feature)
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

	# Mouse clicks for planting / actions
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var cell = grid.world_to_cell(mouse_pos)

		# Left-click to plant selected seed packet
		if event.button_index == MOUSE_BUTTON_LEFT:
			if seed_bank and seed_bank.selected_packet != null:
				var pkt = seed_bank.selected_packet
				if grid.is_valid_cell(cell.x, cell.y):
					var occupied = is_cell_occupied(cell.x, cell.y)
					if not occupied or debug_mode:
						if spend_sun(pkt.sun_cost):
							var plant_idx = get_plant_index_by_id(pkt.plant_id)
							if plant_idx != -1:
								spawn_plant_at(cell.x, cell.y, plant_idx)
								seed_bank.on_plant_placed()

		# Right-click cancels selection, or spawns plant if in debug mode
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if seed_bank and seed_bank.selected_packet != null:
				seed_bank.deselect_all()
			elif debug_mode and grid.is_valid_cell(cell.x, cell.y):
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

	var v_scale: float = float(info.get("scale", 1.0))
	var v_offset: Vector2 = info.get("offset", Vector2.ZERO)
	plant_node.set("visual_scale", v_scale)
	plant_node.set("visual_offset", v_offset)
	plant_node.scale = Vector2.ONE

	var spr = plant_node.get_node_or_null("XFLSprite2D")
	if spr:
		spr.scale = Vector2(v_scale, v_scale)
		spr.position = v_offset
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
