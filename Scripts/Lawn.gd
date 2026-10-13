extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var grid: LawnGrid = $Grid
@onready var background: Node2D = $Background
@onready var plants_container: Node2D = $Plants
@onready var suns_container: Node2D = $Suns
@onready var zombies_container: Node2D = $Zombies
@onready var seed_bank: SeedBank = $HUD/SeedBank
@onready var start_banner: Control = $HUD/StartBanner
@onready var start_label: Label = $HUD/StartBanner/StartLabel
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
var zombie_scene: PackedScene = preload("res://Scenes/Zombie.tscn")

const PLANT_REGISTRY: Array[Dictionary] = [
	{
		"id": "peashooter",
		"name": "Peashooter",
		"anim_json": "res://Assets/Plants/peashooter.anim.json",
		"tex_dir": "res://Assets/Plants/peashooter.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "sunflower",
		"name": "Sunflower",
		"anim_json": "res://Assets/Plants/sunflower.anim.json",
		"tex_dir": "res://Assets/Plants/sunflower.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "wallnut",
		"name": "Wall-nut",
		"anim_json": "res://Assets/Plants/wallnut.anim.json",
		"tex_dir": "res://Assets/Plants/wallnut.xfl/library/",
		"health": 4000.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "potatomine",
		"name": "Potato Mine",
		"anim_json": "res://Assets/Plants/potatomine.anim.json",
		"tex_dir": "res://Assets/Plants/potatomine.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "cabbagepult",
		"name": "Cabbage-pult",
		"anim_json": "res://Assets/Plants/cabbagepult.anim.json",
		"tex_dir": "res://Assets/Plants/cabbagepult.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "lingfugu",
		"name": "LingFugu",
		"anim_json": "res://Assets/Plants/lingfugu.anim.json",
		"tex_dir": "res://Assets/Plants/lingfugu.xfl/library/",
		"scale": 1.0,
		"offset": Vector2.ZERO,
		"health": 300.0,
	},
	{
		"id": "clivia",
		"name": "Clivia",
		"anim_json": "res://Assets/Plants/clivia.anim.json",
		"tex_dir": "res://Assets/Plants/clivia.xfl/LIBRARY/",
		"scale": 1.8,
		"offset": Vector2(-25.0, 34.0),
		"health": 300.0,
	},
	{
		"id": "garlic",
		"name": "Garlic",
		"anim_json": "res://Assets/Plants/garlic.anim.json",
		"tex_dir": "res://Assets/Plants/garlic.xfl/LIBRARY/",
		"scale": 1.8,
		"offset": Vector2(-15.0, 56.0),
		"health": 600.0,
	},
]

var level_started: bool = false
var debug_mode: bool = false
var plant_count: int = 0
var selected_plant_index: int = 0
var sun_amount: int = 50
var sky_sun_timer: float = 6.0
var zombie_spawn_timer: float = 16.0

func _ready() -> void:
	camera.position = Vector2(CAM_ZOMBIE_X, CAM_Y)

	# Initial plant count and PvZ2 depth sorting for pre-placed plants
	plant_count = plants_container.get_child_count()
	for p in plants_container.get_children():
		var r = p.get("row") if p.get("row") != null else 2
		var c = p.get("col") if p.get("col") != null else 1
		p.z_index = grid.get_depth_z_index(r, c)
		# Align pre-placed plants down slightly
		var spr = p.get_node_or_null("XFLSprite2D")
		if spr:
			spr.position = Vector2(0.0, 34.0)
		var shd = p.get_node_or_null("Shadow")
		if shd:
			shd.position = Vector2(0.0, 44.0)

	_update_hud()

	if seed_bank:
		seed_bank.update_sun_display(sun_amount)
		seed_bank.set_active(false)

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(cys_music)

	get_tree().create_timer(0.6).timeout.connect(_start_camera_pan)

func _start_camera_pan() -> void:
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera, "position:x", CAM_GAMEPLAY_X, 2.2)
	tween.finished.connect(_on_pan_finished)

func _on_pan_finished() -> void:
	print("[Lawn] Camera pan finished! Playing Ready... Set... Plant!")
	if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/ready.ogg"):
		AudioManager.play_sfx(load("res://Audio/SFX/ready.ogg"))

	if start_label:
		if start_banner:
			start_banner.visible = true
		start_label.visible = true
		start_label.pivot_offset = Vector2(450.0, 90.0)
		start_label.scale = Vector2(0.5, 0.5)
		start_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		start_label.text = "Ready..."
		start_label.set("theme_override_colors/font_color", Color(0.92, 0.05, 0.05, 1.0))
		start_label.set("theme_override_colors/font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		start_label.set("theme_override_constants/outline_size", 28)

		var tw = create_tween()
		# Ready...
		tw.tween_property(start_label, "modulate:a", 1.0, 0.15)
		tw.parallel().tween_property(start_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.4)
		# Set...
		tw.tween_callback(func():
			start_label.text = "Set..."
			start_label.scale = Vector2(0.65, 0.65)
		)
		tw.tween_property(start_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.35)
		# PLANT!
		tw.tween_callback(func():
			start_label.text = "PLANT!"
			start_label.scale = Vector2(0.65, 0.65)
		)
		tw.tween_property(start_label, "scale", Vector2(1.3, 1.3), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.45)
		tw.tween_property(start_label, "modulate:a", 0.0, 0.25)
		tw.tween_callback(func():
			start_label.visible = false
			if start_banner:
				start_banner.visible = false
			_on_gameplay_start()
		)
	else:
		_on_gameplay_start()

func _on_gameplay_start() -> void:
	level_started = true
	if seed_bank:
		seed_bank.set_active(true)
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(battle_music)

func _process(delta: float) -> void:
	if not level_started:
		return

	# Periodic sky sun falling
	sky_sun_timer -= delta
	if sky_sun_timer <= 0.0:
		sky_sun_timer = randf_range(8.5, 11.5)
		_spawn_sky_sun()

	# Periodic zombie waves
	zombie_spawn_timer -= delta
	if zombie_spawn_timer <= 0.0:
		zombie_spawn_timer = randf_range(14.0, 20.0)
		spawn_zombie()

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

func spawn_zombie(row_idx: int = -1, start_x: float = 2254.0) -> void:
	if not zombie_scene:
		return
	if row_idx < 0 or row_idx >= grid.rows:
		row_idx = randi_range(0, grid.rows - 1)

	var spawn_y = grid.cell_to_world(0, row_idx).y
	var z_inst: Zombie = zombie_scene.instantiate()
	z_inst.row = row_idx
	z_inst.position = Vector2(start_x, spawn_y)

	# 50% chance to replace with fem variant
	var is_fem = randf() < 0.5
	if is_fem:
		if z_inst.has_method("set_female_variant"):
			z_inst.set_female_variant(true)
		else:
			var spr = z_inst.get_node_or_null("XFLSprite2D")
			if spr:
				spr.anim_data_path = "res://Assets/Zombies/zombie_tutorialfem.anim.json"
				spr.textures_base_dir = "res://Assets/Zombies/zombie_tutorialfem.xfl/library/"

	if zombies_container:
		zombies_container.add_child(z_inst)
	else:
		add_child(z_inst)
	print("[Lawn] Spawned %szombie on row %d at x=%.1f" % ["female " if is_fem else "", row_idx, start_x])

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

		# Z key to spawn a zombie
		elif event.keycode == KEY_Z:
			var mouse_pos = get_global_mouse_position()
			var cell = grid.world_to_cell(mouse_pos)
			var target_row = cell.y if grid.is_valid_cell(cell.x, cell.y) else randi_range(0, grid.rows - 1)
			var spawn_x = mouse_pos.x if debug_mode else 2254.0
			spawn_zombie(target_row, spawn_x)

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
					else:
						# Cell is already occupied: play failure SFX
						if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/failure.ogg"):
							AudioManager.play_sfx(load("res://Audio/SFX/failure.ogg"))

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
	# PvZ2 Depth Ordering: lower row = higher priority, more right col = higher priority
	plant_node.z_index = grid.get_depth_z_index(row, col)
	plant_node.set("row", row)
	plant_node.set("col", col)
	plant_node.set("plant_type", info["id"])
	plant_node.set("display_name", info["name"])
	plant_node.set("anim_data_path", info["anim_json"])
	plant_node.set("textures_base_dir", info["tex_dir"])

	var p_health: float = float(info.get("health", 300.0))
	plant_node.set("max_health", p_health)
	plant_node.set("health", p_health)

	var v_scale: float = float(info.get("scale", 1.0))
	var v_offset: Vector2 = info.get("offset", Vector2(0.0, 20.0))
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

	if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/planted.ogg"):
		AudioManager.play_sfx(load("res://Audio/SFX/planted.ogg"))

func _update_hud() -> void:
	var selected_name = PLANT_REGISTRY[selected_plant_index]["name"]
	if peashooter_count_label:
		peashooter_count_label.text = "PLANTS: %d | [%d] %s" % [plant_count, selected_plant_index + 1, selected_name]
	if debug_status_label:
		if debug_mode:
			debug_status_label.text = "[DEBUG ON] 1-8: Select | R-Click: Spawn | Z: Zombie | L-Click: Atk | M-Click: PlantFood"
			debug_status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		else:
			debug_status_label.text = "Press 'G' for Debug Mode"
			debug_status_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
