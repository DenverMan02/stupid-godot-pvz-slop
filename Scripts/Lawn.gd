extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var grid: LawnGrid = $Grid
@onready var background: Node2D = $Background
@onready var plants_container: Node2D = $Plants
@onready var projectiles_container: Node2D = $Projectiles
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
var midwave_music: AudioStream = preload("res://Audio/BGM/Worlds/Modern Day/modern_midwave_a.mp3")
var final_wave_music: AudioStream = preload("res://Audio/BGM/Worlds/Modern Day/modern_final_wave.mp3")
var midwave_tracks: Array[AudioStream] = [
	preload("res://Audio/BGM/Worlds/Modern Day/modern_midwave_a.mp3"),
	preload("res://Audio/BGM/Worlds/Modern Day/modern_midwave_b.mp3"),
]
var last_midwave_index: int = -1

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
	{
		"id": "repeater",
		"name": "Repeater",
		"anim_json": "res://Assets/Plants/repeater.anim.json",
		"tex_dir": "res://Assets/Plants/repeater.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "sunflower_twin",
		"name": "Twin Sunflower",
		"anim_json": "res://Assets/Plants/sunflower_twin.anim.json",
		"tex_dir": "res://Assets/Plants/sunflower_twin.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "peashooter_super",
		"name": "Gatling Pea",
		"anim_json": "res://Assets/Plants/peashooter_super.anim.json",
		"tex_dir": "res://Assets/Plants/peashooter_super.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "threepeater",
		"name": "Threepeater",
		"anim_json": "res://Assets/Plants/threepeater.anim.json",
		"tex_dir": "res://Assets/Plants/threepeater.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
	{
		"id": "three_head_sunflower",
		"name": "Triplet Sunflower",
		"anim_json": "res://Assets/Plants/three_head_sunflower.anim.json",
		"tex_dir": "res://Assets/Plants/three_head_sunflower.xfl/library/",
		"health": 300.0,
		"offset": Vector2(0.0, 34.0),
	},
]

var level_started: bool = false
var debug_mode: bool = false
var anim_viewer_instance: Node = null
var plant_count: int = 0
var selected_plant_index: int = 0
var sun_amount: int = 50
var sky_sun_timer: float = 6.0

# Wave Mechanics
const TOTAL_WAVES: int = 10
var current_wave: int = 0
var wave_timer: float = 0.0
var wave_time_limit: float = 24.0
var level_finished: bool = false
var is_huge_wave_spawning: bool = false

# Plant Food System
var plant_food_count: int = 1
const MAX_PLANT_FOOD: int = 3
var is_plant_food_active: bool = false
var plant_food_slots: Array[TextureRect] = []
var plant_food_glows: Array[TextureRect] = []
var pf_main_btn: TextureButton = null
var floating_pf_icon: Sprite2D = null

# Shovel System
var is_shovel_active: bool = false
var shovel_btn: TextureButton = null
var floating_shovel_icon: Sprite2D = null

# Turbo / Speedup System
var is_turbo: bool = false
var turbo_btn: TextureButton = null
var turbo_tex_normal: Texture2D = preload("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/2x.png")
var turbo_tex_selected: Texture2D = preload("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/2x_selected.png")
var sfx_speed_up: AudioStream = preload("res://Audio/SFX/speed_up.ogg")
var sfx_speed_down: AudioStream = preload("res://Audio/SFX/speed_down.ogg")
var sfx_shovel: AudioStream = preload("res://Audio/SFX/shovel.ogg")
var sfx_shovel_plant: AudioStream = preload("res://Audio/SFX/shovel_plant.ogg")
var sfx_pause: AudioStream = preload("res://Audio/SFX/pause.ogg")

# Pause System
var pause_btn: TextureButton = null
var pause_menu: Control = null

# GameOver and Victory Dialogs (Authentic PvZ2 GameOverDialog & VictoryOutro)
var level_lost: bool = false
var level_won: bool = false
var game_over_screen: Control = null
var victory_screen: Control = null
var trophy_node: Node2D = null

# LawnMowers
var lawn_mowers_container: Node2D = null
var mower_scene: PackedScene = preload("res://Scenes/LawnMower.tscn")

# Progress Meter UI nodes
var meter_fill: NinePatchRect = null
var zombie_head_icon: TextureRect = null
var mid_flag_icon: TextureRect = null
var final_flag_icon: TextureRect = null
var meter_tween: Tween = null
var current_meter_progress: float = 0.0

func _ready() -> void:
	camera.position = Vector2(CAM_ZOMBIE_X, CAM_Y)

	# Initial plant count and PvZ2 depth sorting for pre-placed plants
	plant_count = plants_container.get_child_count()
	for p in plants_container.get_children():
		var r = p.get("row") if p.get("row") != null else 2
		var c = p.get("col") if p.get("col") != null else 1
		p.z_index = grid.get_depth_z_index(r, c)
		var spr = p.get_node_or_null("XFLSprite2D")
		if spr:
			spr.position = Vector2(0.0, 34.0)
		var shd = p.get_node_or_null("Shadow")
		if shd:
			shd.position = Vector2(0.0, 36.0)

	_setup_hud()
	_setup_lawn_mowers()
	_update_hud()
	_update_wave_meter(0.0)
	_update_plant_food_display()

	if seed_bank:
		seed_bank.update_sun_display(sun_amount)
		seed_bank.set_active(false)

	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(cys_music)

	get_tree().create_timer(0.6).timeout.connect(_start_camera_pan)

func _setup_hud() -> void:
	var hud = get_node_or_null("HUD")
	if not hud:
		return

	# Adjust MarginContainer so top-right labels don't overlap Turbo and Pause buttons
	var margin_c = hud.get_node_or_null("MarginContainer")
	if margin_c:
		margin_c.offset_left = -780.0
		margin_c.offset_right = -190.0

	# 1. Plant Food Bank (bottom-left, right next to seed packets column)
	var pf_bank_ctrl = Control.new()
	pf_bank_ctrl.name = "PlantFoodBank"
	pf_bank_ctrl.position = Vector2(185.0, 936.0)
	pf_bank_ctrl.custom_minimum_size = Vector2(202.0, 114.0)
	pf_bank_ctrl.size = Vector2(202.0, 114.0)

	var pf_bg = TextureRect.new()
	pf_bg.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_bank.png")
	pf_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pf_bg.size = Vector2(202.0, 114.0)
	pf_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	pf_bank_ctrl.add_child(pf_bg)

	# Main round plant food button (displays green leaf, only gone when selecting a plant to plantfood)
	pf_main_btn = TextureButton.new()
	pf_main_btn.name = "PlantFoodButton"
	pf_main_btn.position = Vector2(22.0, 23.0)
	pf_main_btn.custom_minimum_size = Vector2(68.0, 72.0)
	pf_main_btn.size = Vector2(68.0, 72.0)
	pf_main_btn.ignore_texture_size = true
	pf_main_btn.stretch_mode = TextureButton.STRETCH_SCALE
	pf_main_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_button.png")
	pf_main_btn.texture_pressed = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_button_down.png")
	pf_main_btn.focus_mode = Control.FOCUS_NONE
	pf_main_btn.pressed.connect(toggle_plant_food_armed)
	pf_main_btn.visible = (plant_food_count >= 1) and (!is_plant_food_active)
	pf_bank_ctrl.add_child(pf_main_btn)

	# 2 small socket slots for extra plant food charges (base MAX_PLANT_FOOD = 3: 1 leaf + 2 extra charge sockets)
	var slot_offsets = [Vector2(96.0, 41.0), Vector2(126.0, 41.0)]
	plant_food_slots.clear()
	plant_food_glows.clear()
	for i in range(MAX_PLANT_FOOD - 1):
		var slot_tex = TextureRect.new()
		slot_tex.name = "PlantFoodSlot_%d" % i
		slot_tex.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_bank_filled_slot.png")
		slot_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot_tex.size = Vector2(32.0, 32.0)
		slot_tex.position = slot_offsets[i]
		slot_tex.visible = (plant_food_count >= (i + 2))
		slot_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Glowing dot effect around each filled slot
		var glow_tex = TextureRect.new()
		glow_tex.name = "GlowDot"
		glow_tex.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_bank_filling_slot.png")
		glow_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glow_tex.size = Vector2(40.0, 40.0)
		glow_tex.position = Vector2(-4.0, -4.0)
		glow_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow_tex.modulate = Color(1.2, 2.0, 1.2, 0.8)
		slot_tex.add_child(glow_tex)
		plant_food_glows.append(glow_tex)

		pf_bank_ctrl.add_child(slot_tex)
		plant_food_slots.append(slot_tex)

	hud.add_child(pf_bank_ctrl)

	# 2. Shovel Button (bottom-right corner, matching official PvZ2)
	shovel_btn = TextureButton.new()
	shovel_btn.name = "ShovelButton"
	shovel_btn.position = Vector2(1780.0, 935.0)
	shovel_btn.custom_minimum_size = Vector2(110.0, 110.0)
	shovel_btn.size = Vector2(110.0, 110.0)
	shovel_btn.ignore_texture_size = true
	shovel_btn.stretch_mode = TextureButton.STRETCH_SCALE
	shovel_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/shovel_button.png")
	shovel_btn.texture_pressed = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/shovel_button_down.png")
	shovel_btn.focus_mode = Control.FOCUS_NONE
	shovel_btn.pressed.connect(toggle_shovel)
	hud.add_child(shovel_btn)

	# 3. Floating Cursors for Shovel and Plant Food (Plant Food uses the leaf rather than the orb)
	floating_shovel_icon = Sprite2D.new()
	floating_shovel_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/shovel_icon.png")
	floating_shovel_icon.scale = Vector2(0.35, 0.35)
	floating_shovel_icon.offset = Vector2(10.0, -10.0)
	floating_shovel_icon.visible = false
	floating_shovel_icon.z_index = 200
	hud.add_child(floating_shovel_icon)

	floating_pf_icon = Sprite2D.new()
	floating_pf_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_button.png")
	floating_pf_icon.scale = Vector2(0.55, 0.55)
	floating_pf_icon.visible = false
	floating_pf_icon.z_index = 200
	hud.add_child(floating_pf_icon)

	# 4. Wave Progress Meter & Level Name Label (Top-Center, filling right-to-left)
	var meter_ctrl = Control.new()
	meter_ctrl.name = "WaveMeter"
	meter_ctrl.position = Vector2(750.0, 14.0)
	meter_ctrl.custom_minimum_size = Vector2(420.0, 96.0)
	meter_ctrl.size = Vector2(420.0, 96.0)

	# Level Name Label positioned on TOP of the wave meter, bigger font size
	var level_name_lbl = Label.new()
	level_name_lbl.name = "LevelNameLabel"
	level_name_lbl.text = "Modern Day - Day 1"
	level_name_lbl.position = Vector2(-20.0, 0.0)
	level_name_lbl.size = Vector2(460.0, 36.0)
	level_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_path = "res://Fonts/PvZ2 Regular By Beast and MF.ttf"
	if ResourceLoader.exists(font_path):
		var custom_font = load(font_path)
		level_name_lbl.add_theme_font_override("font", custom_font)
	level_name_lbl.add_theme_font_size_override("font_size", 30)
	level_name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	level_name_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	level_name_lbl.add_theme_constant_override("outline_size", 5)
	meter_ctrl.add_child(level_name_lbl)

	# Wave progress meter background placed BELOW the level label
	var meter_bg = TextureRect.new()
	meter_bg.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter.png")
	meter_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meter_bg.size = Vector2(420.0, 50.0)
	meter_bg.position = Vector2(0.0, 40.0)
	meter_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(meter_bg)

	# Green fill bar (fills RIGHT TO LEFT)
	# Track bounds: left = 22.0, right = 398.0, max_w = 376.0
	meter_fill = NinePatchRect.new()
	meter_fill.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter_fill.png")
	meter_fill.patch_margin_left = 6
	meter_fill.patch_margin_right = 6
	meter_fill.patch_margin_top = 4
	meter_fill.patch_margin_bottom = 4
	meter_fill.position = Vector2(405.0, 51.0)
	meter_fill.size = Vector2(0.0, 28.0)
	meter_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(meter_fill)

	# Flags (unraised by default, raise when reached)
	# Progress moves from right (0%) to left (100%)
	# Mid-flag at 50% (x ≈ 200), Final flag at 100% (x ≈ 14)
	mid_flag_icon = TextureRect.new()
	mid_flag_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter_flag_default.png")
	mid_flag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mid_flag_icon.size = Vector2(30.0, 25.0)
	mid_flag_icon.position = Vector2(195.0, 56.0) # Unraised (lowered)
	mid_flag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(mid_flag_icon)

	final_flag_icon = TextureRect.new()
	final_flag_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter_flag_default.png")
	final_flag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	final_flag_icon.size = Vector2(30.0, 25.0)
	final_flag_icon.position = Vector2(14.0, 56.0) # Unraised (lowered)
	final_flag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(final_flag_icon)

	zombie_head_icon = TextureRect.new()
	zombie_head_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter_zombiehead.png")
	zombie_head_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	zombie_head_icon.size = Vector2(40.0, 42.0)
	zombie_head_icon.position = Vector2(378.0, 42.0) # Starts at far right
	zombie_head_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(zombie_head_icon)

	hud.add_child(meter_ctrl)

	# 5. Top-Right Controls: Turbo Button & Pause Button
	var top_right = Control.new()
	top_right.name = "TopRightControls"
	top_right.position = Vector2(1730.0, 20.0)
	top_right.size = Vector2(165.0, 75.0)
	top_right.mouse_filter = Control.MOUSE_FILTER_PASS

	turbo_btn = TextureButton.new()
	turbo_btn.name = "TurboButton"
	turbo_btn.position = Vector2(0.0, 0.0)
	turbo_btn.custom_minimum_size = Vector2(75.0, 75.0)
	turbo_btn.size = Vector2(75.0, 75.0)
	turbo_btn.ignore_texture_size = true
	turbo_btn.stretch_mode = TextureButton.STRETCH_SCALE
	turbo_btn.texture_normal = turbo_tex_normal
	turbo_btn.focus_mode = Control.FOCUS_NONE
	turbo_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	turbo_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	turbo_btn.pressed.connect(toggle_turbo)
	top_right.add_child(turbo_btn)

	pause_btn = TextureButton.new()
	pause_btn.name = "PauseButton"
	pause_btn.position = Vector2(85.0, 0.0)
	pause_btn.custom_minimum_size = Vector2(75.0, 75.0)
	pause_btn.size = Vector2(75.0, 75.0)
	pause_btn.ignore_texture_size = true
	pause_btn.stretch_mode = TextureButton.STRETCH_SCALE
	pause_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/pause_button.png")
	pause_btn.texture_pressed = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/pause_button_down.png")
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_btn.pressed.connect(toggle_pause)
	top_right.add_child(pause_btn)
	hud.add_child(top_right)

	# 6. Pause Menu Modal
	_setup_pause_menu(hud)

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
		# Set... (all same red color)
		tw.tween_callback(func():
			start_label.text = "Set..."
			start_label.set("theme_override_colors/font_color", Color(0.92, 0.05, 0.05, 1.0))
			start_label.scale = Vector2(0.65, 0.65)
		)
		tw.tween_property(start_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.35)
		# PLANT! (all same red color)
		tw.tween_callback(func():
			start_label.text = "PLANT!"
			start_label.set("theme_override_colors/font_color", Color(0.92, 0.05, 0.05, 1.0))
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
	_start_wave(1)

func _process(delta: float) -> void:
	# Pulsing glow animation for plant food glowing dots
	if not plant_food_glows.is_empty():
		var pulse = 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.007)
		for g in plant_food_glows:
			if is_instance_valid(g) and g.is_visible_in_tree():
				g.modulate = Color(1.1 + 0.4 * pulse, 1.6 + 0.8 * pulse, 1.1 + 0.4 * pulse, 0.6 + 0.4 * pulse)

	if not level_started or level_finished:
		return

	# Periodic sky sun falling
	sky_sun_timer -= delta
	if sky_sun_timer <= 0.0:
		sky_sun_timer = randf_range(8.5, 11.5)
		_spawn_sky_sun()

	# Wave timer progression (meter only updates when new wave cluster spawns)
	wave_timer += delta

	var living_zombies = 0
	if zombies_container:
		for z in zombies_container.get_children():
			if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion() and z.health > 0.0:
				living_zombies += 1
				# Authentic PvZ2 Breach Detection: Zombie reaching the house threshold
				if z.global_position.x <= 620.0 and not level_lost and not level_won:
					_trigger_game_over(z)
					return

	if not level_lost and not level_won:
		if (living_zombies == 0 and wave_timer >= 6.0 and not is_huge_wave_spawning) or (wave_timer >= wave_time_limit and not is_huge_wave_spawning):
			if current_wave < TOTAL_WAVES:
				_start_wave(current_wave + 1)
			elif current_wave >= TOTAL_WAVES and living_zombies == 0:
				_on_level_victory()

func _play_random_midwave() -> void:
	if midwave_tracks.is_empty():
		return
	var available_indices: Array[int] = []
	for i in range(midwave_tracks.size()):
		if i != last_midwave_index:
			available_indices.append(i)
	if available_indices.is_empty():
		available_indices = [0]
	var chosen_index = available_indices.pick_random()
	last_midwave_index = chosen_index
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(midwave_tracks[chosen_index])

func _advance_wave_meter(target_progress: float) -> void:
	if meter_tween and meter_tween.is_valid():
		meter_tween.kill()
	meter_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	meter_tween.tween_method(_update_wave_meter, current_meter_progress, target_progress, 0.7)
	current_meter_progress = target_progress

func _start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_timer = 0.0
	print("[Lawn] === Starting Wave %d / %d ===" % [current_wave, TOTAL_WAVES])

	# Visual wave progress meter advances smoothly when each wave cluster spawns
	var total_progress = float(current_wave) / float(TOTAL_WAVES)
	_advance_wave_meter(total_progress)

	match current_wave:
		1:
			wave_time_limit = 18.0
			spawn_zombie(-1, 2254.0, "none")
		2:
			wave_time_limit = 20.0
			spawn_zombie(-1, 2254.0, "none")
			spawn_zombie(-1, 2354.0, "none")
		3:
			wave_time_limit = 22.0
			spawn_zombie(-1, 2254.0, "none")
			spawn_zombie(-1, 2354.0, "cone", true) # Plant Food Zombie!
		4:
			wave_time_limit = 22.0
			spawn_zombie(-1, 2254.0, "cone")
			spawn_zombie(-1, 2320.0, "none")
			spawn_zombie(-1, 2390.0, "cone")
		5:
			# Mid-wave (Huge wave 1)
			wave_time_limit = 32.0
			_announce_huge_wave(false)
		6:
			wave_time_limit = 22.0
			spawn_zombie(-1, 2254.0, "cone")
			spawn_zombie(-1, 2320.0, "bucket")
			spawn_zombie(-1, 2380.0, "none")
		7:
			wave_time_limit = 24.0
			spawn_zombie(-1, 2254.0, "bucket", true) # Plant Food Zombie!
			spawn_zombie(-1, 2320.0, "cone")
			spawn_zombie(-1, 2390.0, "none")
		8:
			wave_time_limit = 24.0
			spawn_zombie(-1, 2254.0, "brick")
			spawn_zombie(-1, 2320.0, "cone")
			spawn_zombie(-1, 2390.0, "bucket")
		9:
			wave_time_limit = 26.0
			spawn_zombie(-1, 2254.0, "brick")
			spawn_zombie(-1, 2320.0, "bucket")
			spawn_zombie(-1, 2390.0, "cone")
			spawn_zombie(-1, 2450.0, "none")
		10:
			# Final Wave (Huge wave 2)
			wave_time_limit = 45.0
			_announce_huge_wave(true)

func _announce_huge_wave(is_final: bool) -> void:
	is_huge_wave_spawning = true
	if get_node_or_null("/root/AudioManager"):
		if ResourceLoader.exists("res://Audio/SFX/huge_wave_incoming.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/huge_wave_incoming.ogg"))

	var text = "FINAL WAVE!" if is_final else "A HUGE WAVE OF ZOMBIES IS APPROACHING!"
	_show_banner_message(text, Color(0.95, 0.1, 0.1, 1.0), 3.0)

	var tw = create_tween()
	tw.tween_interval(2.4)
	tw.tween_callback(func():
		is_huge_wave_spawning = false
		if get_node_or_null("/root/AudioManager"):
			if ResourceLoader.exists("res://Audio/SFX/huge_wave.ogg"):
				AudioManager.play_sfx(load("res://Audio/SFX/huge_wave.ogg"))
			if is_final:
				AudioManager.play_music(final_wave_music)
				_raise_final_flag()
			else:
				# A RANDOM midwave song plays after every flag besides the last one, never repeating the same track
				_play_random_midwave()
				_raise_mid_flag()
		_spawn_huge_wave_roster(is_final)
	)

func _spawn_huge_wave_roster(is_final: bool) -> void:
	if not is_final:
		# Mid-wave: 1 Flag zombie, 2 Coneheads, 1 Buckethead, 3 Basics
		spawn_zombie(2, 2254.0, "none", false, true)
		spawn_zombie(0, 2320.0, "cone")
		spawn_zombie(1, 2360.0, "none")
		spawn_zombie(3, 2330.0, "bucket")
		spawn_zombie(4, 2370.0, "cone")
		spawn_zombie(randi_range(0, 4), 2420.0, "none")
	else:
		# Final wave: 1 Flag zombie, 2 Brickheads, 2 Bucketheads, 3 Coneheads, 4 Basics
		spawn_zombie(2, 2254.0, "none", false, true)
		spawn_zombie(0, 2310.0, "brick")
		spawn_zombie(4, 2320.0, "brick")
		spawn_zombie(1, 2360.0, "bucket")
		spawn_zombie(3, 2370.0, "bucket")
		spawn_zombie(0, 2410.0, "cone")
		spawn_zombie(2, 2420.0, "cone")
		spawn_zombie(4, 2430.0, "cone")
		for r in range(4):
			spawn_zombie(r, randf_range(2450.0, 2550.0), "none")

func _raise_mid_flag() -> void:
	if mid_flag_icon:
		var tw = create_tween()
		tw.tween_property(mid_flag_icon, "position:y", 26.0, 0.45).set_trans(Tween.TRANS_BOUNCE)

func _drop_mid_flag() -> void:
	_raise_mid_flag()

func _raise_final_flag() -> void:
	if final_flag_icon:
		var tw = create_tween()
		tw.tween_property(final_flag_icon, "position:y", 26.0, 0.45).set_trans(Tween.TRANS_BOUNCE)

func _drop_final_flag() -> void:
	_raise_final_flag()

func _update_wave_meter(progress: float) -> void:
	var clamped_p = clampf(progress, 0.0, 1.0)
	var track_right = 405.0
	var max_fill_w = 390.0
	var fill_w = max_fill_w * clamped_p
	if meter_fill:
		# Fills from RIGHT to LEFT
		meter_fill.position.x = track_right - fill_w
		meter_fill.size.x = fill_w
		meter_fill.visible = (fill_w > 2.0)
	if zombie_head_icon:
		# Zombie head walks from RIGHT to LEFT
		zombie_head_icon.position.x = track_right - fill_w - 20.0

func _show_banner_message(msg: String, col: Color = Color.WHITE, duration: float = 2.5) -> void:
	if not start_label:
		return
	if start_banner:
		start_banner.visible = true
	start_label.visible = true
	start_label.text = msg
	start_label.modulate = Color(col.r, col.g, col.b, 0.0)
	start_label.set("theme_override_colors/font_color", col)
	start_label.scale = Vector2(0.7, 0.7)
	start_label.pivot_offset = Vector2(450.0, 90.0)

	var tw = create_tween()
	tw.tween_property(start_label, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(start_label, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(duration - 0.6)
	tw.tween_property(start_label, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		start_label.visible = false
		if start_banner:
			start_banner.visible = false
	)

func _trigger_game_over(breaching_zombie: Zombie = null) -> void:
	if level_lost or level_won:
		return
	level_lost = true
	level_finished = true
	print("[Lawn] *** GAME OVER - THE ZOMBIES ATE YOUR BRAINS! ***")

	# Stop background battle music
	if get_node_or_null("/root/AudioManager"):
		AudioManager.stop_music()
		if ResourceLoader.exists("res://Audio/SFX/failure.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/failure.ogg"))
		if ResourceLoader.exists("res://Audio/BGM/Worlds/Modern Day/modern_lose.mp3"):
			AudioManager.play_music(load("res://Audio/BGM/Worlds/Modern Day/modern_lose.mp3"))

	# Freeze gameplay actions & seed bank
	if seed_bank:
		seed_bank.set_active(false)
	set_shovel_active(false)
	set_plant_food_active(false)

	# Stop all zombie movement
	if zombies_container:
		for z in zombies_container.get_children():
			if z is Zombie and is_instance_valid(z):
				z.walk_speed = 0.0
				z.set_process(false)
				var spr = z.get_node_or_null("XFLSprite2D")
				if spr:
					spr.set_process(false)

	_setup_game_over_dialog()

func _setup_game_over_dialog() -> void:
	var hud = get_node_or_null("HUD")
	if not hud:
		return

	game_over_screen = Control.new()
	game_over_screen.name = "GameOverDialog"
	game_over_screen.anchors_preset = Control.PRESET_FULL_RECT
	game_over_screen.size = Vector2(1920.0, 1080.0)
	game_over_screen.z_index = 400
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS

	# 1. Dark background overlay fading in
	var bg = ColorRect.new()
	bg.name = "Overlay"
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.size = Vector2(1920.0, 1080.0)
	bg.color = Color(0.0, 0.0, 0.0, 0.0)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_screen.add_child(bg)

	# 2. Authentic PvZ2 Brain / Game Over Graphic (fail_screen_brain_only.png)
	var brain_rect = TextureRect.new()
	brain_rect.name = "BrainGraphic"
	var brain_path = "res://Assets/UI/UI_GameOver/resource/images/initial/UI/gameover/fail_screen_brain_only.png"
	if ResourceLoader.exists(brain_path):
		brain_rect.texture = load(brain_path)
	brain_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var brain_w = 980.0
	var brain_h = 640.0
	brain_rect.size = Vector2(brain_w, brain_h)
	brain_rect.pivot_offset = Vector2(brain_w / 2.0, brain_h / 2.0)
	brain_rect.position = Vector2((1920.0 - brain_w) / 2.0, 120.0)
	brain_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	brain_rect.scale = Vector2(0.2, 0.2)
	brain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_over_screen.add_child(brain_rect)

	# 3. Action Buttons container (Try Again & Exit To Map)
	var btn_container = Control.new()
	btn_container.name = "Buttons"
	btn_container.position = Vector2(0.0, 800.0)
	btn_container.size = Vector2(1920.0, 150.0)
	btn_container.modulate = Color(1.0, 1.0, 1.0, 0.0)
	game_over_screen.add_child(btn_container)

	var b_size = Vector2(280.0, 95.0)
	# TRY AGAIN (Green button)
	_create_dialog_button(btn_container, "TRY AGAIN", Vector2(1920.0 / 2.0 - b_size.x - 30.0, 20.0), b_size, "green", _restart_game)
	# EXIT TO MAP / TOWN (Brown button)
	_create_dialog_button(btn_container, "EXIT TO MAP", Vector2(1920.0 / 2.0 + 30.0, 20.0), b_size, "brown", _on_save_and_exit_pressed)

	hud.add_child(game_over_screen)

	# Animating brain popup & fade in (matching 2C GameOverDialog StartImageFade / StartImageScale)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(bg, "color:a", 0.78, 0.8)
	tw.tween_property(brain_rect, "modulate:a", 1.0, 0.55)
	tw.tween_property(brain_rect, "scale", Vector2.ONE, 0.85).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var tw_btn = create_tween()
	tw_btn.tween_interval(0.7)
	tw_btn.tween_property(btn_container, "modulate:a", 1.0, 0.35)

func _on_level_victory() -> void:
	if level_finished or level_won or level_lost:
		return
	level_won = true
	level_finished = true
	print("[Lawn] *** LEVEL COMPLETE! Starting VictoryOutro... ***")

	# 1. Stop combat music and trigger victory fanfare
	if get_node_or_null("/root/AudioManager"):
		AudioManager.stop_music()
		if ResourceLoader.exists("res://Audio/BGM/Worlds/Modern Day/modern_victory.mp3"):
			AudioManager.play_music(load("res://Audio/BGM/Worlds/Modern Day/modern_victory.mp3"))

	_show_banner_message("VICTORY!", Color(1.0, 0.88, 0.15, 1.0), 3.0)

	# 2. Victory Outro Coin Shower from remaining lawn mowers (PvZ2 VictoryOutroModule)
	_start_victory_mower_shower()

func _start_victory_mower_shower() -> void:
	var ready_mowers: Array[LawnMower] = []
	if lawn_mowers_container:
		for m in lawn_mowers_container.get_children():
			if m is LawnMower and m.state == LawnMower.State.READY:
				ready_mowers.append(m)

	print("[Lawn] VictoryOutro: %d lawn mowers remaining for bonus coins" % ready_mowers.size())

	if ready_mowers.is_empty():
		# Directly drop trophy after brief delay
		get_tree().create_timer(1.2).timeout.connect(_spawn_victory_trophy)
		return

	# Launch remaining mowers across the lawn with coin showers (CoinsPerMower = 5)
	for i in range(ready_mowers.size()):
		var m = ready_mowers[i]
		var delay = 0.5 + float(i) * 0.25
		get_tree().create_timer(delay).timeout.connect(func():
			if is_instance_valid(m) and m.state == LawnMower.State.READY:
				m.trigger()
				_spawn_mower_coin_burst(m.global_position)
		)

	var total_mower_time = 0.5 + float(ready_mowers.size()) * 0.25 + 1.2
	get_tree().create_timer(total_mower_time).timeout.connect(_spawn_victory_trophy)

func _spawn_mower_coin_burst(origin: Vector2) -> void:
	# PvZ2 CoinsPerMower = 5 coins dropped per surviving mower
	var coin_tex_path = "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/coin.png"
	var coin_tex = load(coin_tex_path) if ResourceLoader.exists(coin_tex_path) else null
	if not coin_tex:
		return

	if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/coin_drop.ogg"):
		AudioManager.play_sfx(load("res://Audio/SFX/coin_drop.ogg"))

	for c in range(5):
		var coin = Sprite2D.new()
		coin.texture = coin_tex
		coin.scale = Vector2(0.45, 0.45)
		coin.global_position = origin + Vector2(randf_range(-20.0, 20.0), randf_range(-15.0, 15.0))
		coin.z_index = 250
		add_child(coin)

		# Pop out in small arc then fly to HUD top-left
		var target_pop = coin.global_position + Vector2(randf_range(-70.0, 70.0), randf_range(-80.0, 10.0))
		var tw = create_tween()
		tw.tween_property(coin, "global_position", target_pop, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.2 + float(c) * 0.08)
		# Fly toward coin bank / sun bank
		var dest = Vector2(250.0, 60.0)
		tw.tween_property(coin, "global_position", dest, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(coin, "scale", Vector2(0.2, 0.2), 0.45)
		tw.tween_callback(func():
			if is_instance_valid(coin):
				coin.queue_free()
			if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/coin_collect.ogg"):
				AudioManager.play_sfx(load("res://Audio/SFX/coin_collect.ogg"))
			add_sun(10)
		)

func _spawn_victory_trophy() -> void:
	var trophy_path = "res://Assets/Misc/CollectableUnique/resource/images/full/endlevel/modern_trophy.png"
	var trophy_tex = load(trophy_path) if ResourceLoader.exists(trophy_path) else null
	if not trophy_tex:
		_show_victory_award_dialog()
		return

	trophy_node = Node2D.new()
	trophy_node.name = "VictoryTrophy"
	trophy_node.z_index = 320

	var spr = Sprite2D.new()
	spr.name = "Sprite2D"
	spr.texture = trophy_tex
	spr.scale = Vector2(1.15, 1.15)
	trophy_node.add_child(spr)

	# Interactive Area2D for clicking to collect the trophy
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 90.0
	col.shape = shape
	area.add_child(col)
	area.input_pickable = true
	trophy_node.add_child(area)

	var land_pos = Vector2(1380.0, 520.0)
	var spawn_pos = Vector2(land_pos.x, -160.0)
	trophy_node.position = spawn_pos
	add_child(trophy_node)

	if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/world_unlock.ogg"):
		AudioManager.play_sfx(load("res://Audio/SFX/world_unlock.ogg"))

	# Fall down with bounce
	var tw = create_tween()
	tw.tween_property(trophy_node, "position:y", land_pos.y, 0.85).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	var is_collected = [false]
	var on_collect = func():
		if is_collected[0]:
			return
		is_collected[0] = true
		if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/coin_collect.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/coin_collect.ogg"))
		var c_tw = create_tween().set_parallel(true)
		c_tw.tween_property(trophy_node, "scale", Vector2(1.4, 1.4), 0.25)
		c_tw.tween_property(trophy_node, "modulate:a", 0.0, 0.3)
		c_tw.finished.connect(func():
			if is_instance_valid(trophy_node):
				trophy_node.queue_free()
				trophy_node = null
			_show_victory_award_dialog()
		)

	area.input_event.connect(func(_vp: Node, event: InputEvent, _shape_idx: int):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			on_collect.call()
	)

	# Auto-collect after 3 seconds if user hasn't clicked
	get_tree().create_timer(3.2).timeout.connect(func():
		if not is_collected[0]:
			on_collect.call()
	)

func _show_victory_award_dialog() -> void:
	var hud = get_node_or_null("HUD")
	if not hud:
		return

	victory_screen = Control.new()
	victory_screen.name = "VictoryScreen"
	victory_screen.anchors_preset = Control.PRESET_FULL_RECT
	victory_screen.size = Vector2(1920.0, 1080.0)
	victory_screen.z_index = 450
	victory_screen.process_mode = Node.PROCESS_MODE_ALWAYS

	# Dark background overlay
	var bg = ColorRect.new()
	bg.name = "Overlay"
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.size = Vector2(1920.0, 1080.0)
	bg.color = Color(0.0, 0.0, 0.0, 0.65)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	victory_screen.add_child(bg)

	# Main Dialog Box (matching PvZ2 VictoryScreen / AwardScreen)
	var diag_w = 940.0
	var diag_h = 490.0
	var dialog = Control.new()
	dialog.name = "DialogBox"
	dialog.size = Vector2(diag_w, diag_h)
	dialog.position = Vector2((1920.0 - diag_w) / 2.0, 390.0)
	dialog.mouse_filter = Control.MOUSE_FILTER_PASS

	# Wooden panel background texture
	var bg_wood = NinePatchRect.new()
	bg_wood.name = "WoodBackground"
	bg_wood.texture = load("res://Assets/UI/UI_AlwaysLoaded_Uncompressed/Dialog_Asset/dialogtexture.png")
	bg_wood.size = Vector2(diag_w, diag_h)
	bg_wood.patch_margin_left = 60
	bg_wood.patch_margin_right = 60
	bg_wood.patch_margin_top = 60
	bg_wood.patch_margin_bottom = 60
	dialog.add_child(bg_wood)

	# Golden border frame
	var border_frame = NinePatchRect.new()
	border_frame.name = "GoldenBorder"
	border_frame.texture = load("res://Assets/UI/UI_AlwaysLoaded_Uncompressed/Dialog_Asset/dialogborder.png")
	border_frame.size = Vector2(diag_w, diag_h)
	border_frame.patch_margin_left = 60
	border_frame.patch_margin_right = 60
	border_frame.patch_margin_top = 60
	border_frame.patch_margin_bottom = 60
	dialog.add_child(border_frame)

	# Sunflower topper on dialog
	var sunflower_tex = load("res://Assets/UI/UI_PauseMenu/resource/images/initial/UI/pausemenu/sunflower_topper.png")
	var sunflower = TextureRect.new()
	sunflower.texture = sunflower_tex
	sunflower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sunflower.size = Vector2(215.0, 180.0)
	sunflower.position = Vector2((diag_w - 215.0) / 2.0, -110.0)
	dialog.add_child(sunflower)

	# Title: LEVEL COMPLETE!
	var title_lbl = Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.text = "LEVEL COMPLETE!"
	title_lbl.position = Vector2(0.0, -165.0)
	title_lbl.size = Vector2(diag_w, 60.0)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_path = "res://Fonts/PvZ2 Regular By Beast and MF.ttf"
	if ResourceLoader.exists(font_path):
		title_lbl.add_theme_font_override("font", load(font_path))
	title_lbl.add_theme_font_size_override("font_size", 52)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	title_lbl.add_theme_constant_override("outline_size", 12)
	dialog.add_child(title_lbl)

	# Trophy display icon inside dialog
	var trophy_path = "res://Assets/Misc/CollectableUnique/resource/images/full/endlevel/modern_trophy.png"
	if ResourceLoader.exists(trophy_path):
		var trophy_icon = TextureRect.new()
		trophy_icon.texture = load(trophy_path)
		trophy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		trophy_icon.size = Vector2(140.0, 190.0)
		trophy_icon.position = Vector2(80.0, 120.0)
		dialog.add_child(trophy_icon)

	# Summary text
	var summary_lbl = Label.new()
	summary_lbl.text = "Modern Day - Day 1\n\nYou defended your lawn\nand defeated the zombie invasion!"
	summary_lbl.position = Vector2(250.0, 130.0)
	summary_lbl.size = Vector2(620.0, 170.0)
	if ResourceLoader.exists(font_path):
		summary_lbl.add_theme_font_override("font", load(font_path))
	summary_lbl.add_theme_font_size_override("font_size", 30)
	summary_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	summary_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	summary_lbl.add_theme_constant_override("outline_size", 6)
	dialog.add_child(summary_lbl)

	# Action Buttons: REPLAY (Brown) and CONTINUE (Green)
	var btn_size = Vector2(260.0, 95.0)
	var btn_y = diag_h - 50.0
	_create_dialog_button(dialog, "REPLAY", Vector2(170.0, btn_y), btn_size, "brown", _restart_game)
	_create_dialog_button(dialog, "CONTINUE", Vector2(510.0, btn_y), btn_size, "green", _on_save_and_exit_pressed)

	victory_screen.add_child(dialog)
	hud.add_child(victory_screen)

	# Pop dialog in
	dialog.scale = Vector2(0.4, 0.4)
	dialog.pivot_offset = Vector2(diag_w / 2.0, diag_h / 2.0)
	dialog.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(dialog, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(dialog, "modulate:a", 1.0, 0.35)

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

func spawn_zombie(row_idx: int = -1, start_x: float = 2254.0, armor: String = "none", p_has_pf: bool = false, p_is_flag: bool = false) -> void:
	if not zombie_scene:
		return
	if row_idx < 0 or row_idx >= grid.rows:
		row_idx = randi_range(0, grid.rows - 1)

	var spawn_y = grid.cell_to_world(0, row_idx).y
	var z_inst: Zombie = null
	if armor == "bucket":
		var b_scene = load("res://Scenes/BucketheadZombie.tscn")
		if b_scene:
			z_inst = b_scene.instantiate()
	elif armor == "brick":
		var k_scene = load("res://Scenes/BrickheadZombie.tscn")
		if k_scene:
			z_inst = k_scene.instantiate()

	if not z_inst:
		z_inst = zombie_scene.instantiate()
		if armor != "none":
			z_inst.setup_armor(armor)

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

	if p_is_flag and z_inst.has_method("setup_flag_variant"):
		z_inst.setup_flag_variant()

	if p_has_pf and z_inst.has_method("setup_plant_food"):
		z_inst.setup_plant_food(true)

	if zombies_container:
		zombies_container.add_child(z_inst)
	else:
		add_child(z_inst)
	print("[Lawn] Spawned %s%s%szombie on row %d at x=%.1f" % [
		("flag " if p_is_flag else ""),
		((armor + "head ") if armor != "none" else ""),
		("female " if is_fem else ""),
		row_idx,
		start_x
	])

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

# Plant Food System Methods
func add_plant_food(amount: int = 1) -> void:
	plant_food_count = clampi(plant_food_count + amount, 0, MAX_PLANT_FOOD)
	_update_plant_food_display()
	print("[Lawn] Plant food count: %d" % plant_food_count)

func _update_plant_food_display() -> void:
	if pf_main_btn:
		# Plantfood leaf should only be gone when selecting a plant to plantfood (or if 0 plant food)
		pf_main_btn.visible = (plant_food_count >= 1) and (!is_plant_food_active)
	for i in range(plant_food_slots.size()):
		if plant_food_slots[i]:
			# The leaf is charge #1; small slots display extra charges #2 and #3
			plant_food_slots[i].visible = (plant_food_count >= (i + 2))

func toggle_plant_food_armed() -> void:
	if plant_food_count <= 0 and not is_plant_food_active and not debug_mode:
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx(load("res://Audio/SFX/failure.ogg"))
		return
	set_plant_food_active(!is_plant_food_active)

func set_plant_food_active(val: bool) -> void:
	is_plant_food_active = val
	if is_plant_food_active:
		set_shovel_active(false)
		if seed_bank:
			seed_bank.deselect_all()
	_update_plant_food_display()
	if floating_pf_icon:
		floating_pf_icon.visible = is_plant_food_active
	print("[Lawn] Plant food active: %s" % is_plant_food_active)

func use_plant_food_on(plant: Node2D) -> bool:
	if plant_food_count <= 0 and not debug_mode:
		return false
	if plant.get("is_in_plantfood_sequence") == true:
		return false
	if plant.has_method("play_plantfood"):
		if not debug_mode:
			plant_food_count -= 1
			_update_plant_food_display()
		plant.play_plantfood()
		set_plant_food_active(false)
		return true
	return false

# Shovel System Methods
func toggle_shovel() -> void:
	set_shovel_active(!is_shovel_active)

func set_shovel_active(val: bool) -> void:
	is_shovel_active = val
	if is_shovel_active:
		set_plant_food_active(false)
		if seed_bank:
			seed_bank.deselect_all()
		if get_node_or_null("/root/AudioManager"):
			AudioManager.play_sfx(sfx_shovel)
	if shovel_btn:
		shovel_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/shovel_button_down.png") if is_shovel_active else load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/shovel_button.png")
	if floating_shovel_icon:
		floating_shovel_icon.visible = is_shovel_active
	print("[Lawn] Shovel active: %s" % is_shovel_active)

func dig_plant_at(col: int, row: int) -> bool:
	for p in plants_container.get_children():
		if p.get("col") == col and p.get("row") == row and not p.is_queued_for_deletion():
			p.queue_free()
			plant_count = max(0, plant_count - 1)
			_update_hud()
			if get_node_or_null("/root/AudioManager"):
				AudioManager.play_sfx(sfx_shovel_plant)
			set_shovel_active(false)
			return true
	return false

# Turbo System Methods
func toggle_turbo() -> void:
	is_turbo = !is_turbo
	Engine.time_scale = 1.5 if is_turbo else 1.0
	if turbo_btn:
		turbo_btn.texture_normal = turbo_tex_selected if is_turbo else turbo_tex_normal
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx(sfx_speed_up if is_turbo else sfx_speed_down)
	print("[Lawn] Turbo speed: %s (time_scale=%.1f)" % [("1.5x" if is_turbo else "1.0x"), Engine.time_scale])

# Pause System Methods
func _setup_pause_menu(hud: CanvasLayer) -> void:
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.anchors_preset = Control.PRESET_FULL_RECT
	pause_menu.size = Vector2(1920.0, 1080.0)
	pause_menu.visible = false
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.z_index = 300

	# Dark semi-transparent background overlay
	var overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	overlay.size = Vector2(1920.0, 1080.0)
	overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_menu.add_child(overlay)

	# Main Dialog Box (matching PvZ2 NewOptionsDialog & Picture 6)
	var dialog = Control.new()
	dialog.name = "DialogBox"
	var diag_w = 920.0
	var diag_h = 420.0
	dialog.size = Vector2(diag_w, diag_h)
	dialog.position = Vector2((1920.0 - diag_w) / 2.0, 420.0)
	dialog.mouse_filter = Control.MOUSE_FILTER_PASS

	# Wooden panel background texture
	var bg_wood = NinePatchRect.new()
	bg_wood.name = "WoodBackground"
	bg_wood.texture = load("res://Assets/UI/UI_AlwaysLoaded_Uncompressed/Dialog_Asset/dialogtexture.png")
	bg_wood.size = Vector2(diag_w, diag_h)
	bg_wood.patch_margin_left = 60
	bg_wood.patch_margin_right = 60
	bg_wood.patch_margin_top = 60
	bg_wood.patch_margin_bottom = 60
	bg_wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(bg_wood)

	# Golden rounded border frame
	var border_frame = NinePatchRect.new()
	border_frame.name = "GoldenBorder"
	border_frame.texture = load("res://Assets/UI/UI_AlwaysLoaded_Uncompressed/Dialog_Asset/dialogborder.png")
	border_frame.size = Vector2(diag_w, diag_h)
	border_frame.patch_margin_left = 60
	border_frame.patch_margin_right = 60
	border_frame.patch_margin_top = 60
	border_frame.patch_margin_bottom = 60
	border_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(border_frame)

	# Flowerbox Toppers (Back grass, Sunflower, Front grass + gears)
	var topper_back_tex = load("res://Assets/UI/UI_PauseMenu/resource/images/initial/UI/pausemenu/windowtopper_back_half.png")
	var sunflower_tex = load("res://Assets/UI/UI_PauseMenu/resource/images/initial/UI/pausemenu/sunflower_topper.png")
	var topper_front_tex = load("res://Assets/UI/UI_PauseMenu/resource/images/initial/UI/pausemenu/windowtopper.png")

	var w_front = 1040.0
	var h_front = 203.0
	var top_grass_y = -h_front + 45.0

	# 1. Back half grass
	var topper_back = TextureRect.new()
	topper_back.name = "TopperBack"
	topper_back.texture = topper_back_tex
	topper_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var w_back = 293.0
	var h_back = 135.0
	topper_back.size = Vector2(w_back, h_back)
	topper_back.position = Vector2((diag_w - w_back) / 2.0, top_grass_y + 35.0)
	topper_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(topper_back)

	# 2. Smiling Sunflower nestled into grass blades
	var sunflower = TextureRect.new()
	sunflower.name = "SunflowerTopper"
	sunflower.texture = sunflower_tex
	sunflower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var w_sun = 235.0
	var h_sun = 196.0
	sunflower.size = Vector2(w_sun, h_sun)
	sunflower.position = Vector2((diag_w - w_sun) / 2.0, top_grass_y - 25.0)
	sunflower.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(sunflower)

	# 3. Front grass with metal gear bolts draping over wooden edges
	var topper_front = TextureRect.new()
	topper_front.name = "TopperFront"
	topper_front.texture = topper_front_tex
	topper_front.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	topper_front.size = Vector2(w_front, h_front)
	topper_front.position = Vector2((diag_w - w_front) / 2.0, top_grass_y)
	topper_front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog.add_child(topper_front)

	# 4. GAME PAUSED Header Text above sunflower
	var title_lbl = Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.text = "GAME PAUSED"
	title_lbl.position = Vector2(0.0, top_grass_y - 75.0)
	title_lbl.size = Vector2(diag_w, 55.0)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_path = "res://Fonts/PvZ2 Regular By Beast and MF.ttf"
	if ResourceLoader.exists(font_path):
		title_lbl.add_theme_font_override("font", load(font_path))
	title_lbl.add_theme_font_size_override("font_size", 48)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	title_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	title_lbl.add_theme_constant_override("outline_size", 10)
	dialog.add_child(title_lbl)

	# Volume Sliders (Music & Sound FX)
	_create_volume_slider_row(dialog, "Music", 130.0, "BGM")
	_create_volume_slider_row(dialog, "Sound FX", 215.0, "SFX")

	# Bottom Action Buttons (SAVE AND EXIT, RESTART, RESUME)
	var btn_size = Vector2(250.0, 90.0)
	var btn_y = diag_h - 50.0 # Slightly overlaps bottom frame edge like official game
	_create_pause_button(dialog, "SAVE AND EXIT", Vector2(42.0, btn_y), btn_size, false, _on_save_and_exit_pressed)
	_create_pause_button(dialog, "RESTART", Vector2(335.0, btn_y), btn_size, false, _restart_game)
	_create_pause_button(dialog, "RESUME", Vector2(628.0, btn_y), btn_size, true, _resume_game)

	pause_menu.add_child(dialog)
	hud.add_child(pause_menu)

func _create_volume_slider_row(parent: Control, label_text: String, pos_y: float, bus_name: String) -> Control:
	var row = Control.new()
	row.position = Vector2(0.0, pos_y)
	row.size = Vector2(920.0, 60.0)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.position = Vector2(60.0, 2.0)
	lbl.size = Vector2(290.0, 48.0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_path = "res://Fonts/PvZ2 Regular By Beast and MF.ttf"
	if ResourceLoader.exists(font_path):
		lbl.add_theme_font_override("font", load(font_path))
	lbl.add_theme_font_size_override("font_size", 38)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	lbl.add_theme_constant_override("outline_size", 8)
	row.add_child(lbl)

	# Slider track container
	var slider_ctrl = Control.new()
	slider_ctrl.name = "Slider_" + bus_name
	slider_ctrl.position = Vector2(380.0, 4.0)
	var slider_w = 420.0
	var slider_h = 44.0
	slider_ctrl.size = Vector2(slider_w, slider_h)
	slider_ctrl.mouse_filter = Control.MOUSE_FILTER_STOP

	# Track background (audio-bar.png)
	var track = NinePatchRect.new()
	track.texture = load("res://Assets/UI/UI_AlwaysLoaded/Generic/audio-bar.png")
	track.size = Vector2(slider_w, slider_h)
	track.patch_margin_left = 22
	track.patch_margin_right = 22
	track.patch_margin_top = 16
	track.patch_margin_bottom = 16
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slider_ctrl.add_child(track)

	# Green progress fill (audio-fill.png)
	var fill = NinePatchRect.new()
	fill.texture = load("res://Assets/UI/UI_AlwaysLoaded/Generic/audio-fill.png")
	fill.patch_margin_left = 18
	fill.patch_margin_right = 18
	fill.patch_margin_top = 12
	fill.patch_margin_bottom = 12
	fill.position = Vector2(4.0, 4.0)
	var max_fill_w = slider_w - 8.0
	var fill_h = slider_h - 8.0
	fill.size = Vector2(max_fill_w, fill_h)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slider_ctrl.add_child(fill)

	# Bolt gear knob (slider_bolt.png)
	var knob = TextureRect.new()
	knob.texture = load("res://Assets/UI/UI_PauseMenu/resource/images/initial/UI/pausemenu/slider_bolt.png")
	knob.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var knob_size = 52.0
	knob.size = Vector2(knob_size, knob_size)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slider_ctrl.add_child(knob)

	var bus_idx = AudioServer.get_bus_index(bus_name)
	var current_vol = 1.0
	if bus_idx != -1:
		if AudioServer.is_bus_mute(bus_idx):
			current_vol = 0.0
		else:
			current_vol = clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_idx)), 0.0, 1.0)

	var update_slider_visuals = func(vol: float):
		var clamped = clampf(vol, 0.0, 1.0)
		var fw = max_fill_w * clamped
		fill.size.x = max(fw, 0.0)
		fill.visible = (clamped > 0.02)
		knob.position = Vector2(clamped * (slider_w - knob_size), (slider_h - knob_size) / 2.0)
		if bus_idx != -1:
			if clamped <= 0.02:
				AudioServer.set_bus_mute(bus_idx, true)
			else:
				AudioServer.set_bus_mute(bus_idx, false)
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(clamped))

	update_slider_visuals.call(current_vol)

	var is_dragging = [false]
	slider_ctrl.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				is_dragging[0] = event.pressed
				if event.pressed:
					var ratio = clampf(event.position.x / slider_w, 0.0, 1.0)
					update_slider_visuals.call(ratio)
		elif event is InputEventMouseMotion and is_dragging[0]:
			var ratio = clampf(event.position.x / slider_w, 0.0, 1.0)
			update_slider_visuals.call(ratio)
	)

	row.add_child(slider_ctrl)
	parent.add_child(row)
	return row

func _create_dialog_button(parent: Control, text: String, pos: Vector2, b_size: Vector2, color_type: String, on_pressed: Callable) -> TextureButton:
	var btn = TextureButton.new()
	btn.custom_minimum_size = b_size
	btn.size = b_size
	btn.position = pos
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE
	var norm_path = "res://Assets/UI/UI_AlwaysLoaded/Generic/GreenButton.png"
	var down_path = "res://Assets/UI/UI_AlwaysLoaded/Generic/GreenButton_Down.png"
	if color_type == "purple":
		norm_path = "res://Assets/UI/UI_AlwaysLoaded/Generic/PurpleButton.png"
		down_path = "res://Assets/UI/UI_AlwaysLoaded/Generic/PurpleButton_Down.png"
	elif color_type == "brown":
		norm_path = "res://Assets/UI/UI_AlwaysLoaded/Generic/BrownButton.png"
		down_path = "res://Assets/UI/UI_AlwaysLoaded/Generic/BrownButton_Down.png"
	btn.texture_normal = load(norm_path)
	btn.texture_pressed = load(down_path)
	btn.focus_mode = Control.FOCUS_NONE
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.pressed.connect(on_pressed)

	var lbl = Label.new()
	lbl.text = text
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	lbl.size = b_size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_path = "res://Fonts/PvZ2 Regular By Beast and MF.ttf"
	if ResourceLoader.exists(font_path):
		lbl.add_theme_font_override("font", load(font_path))
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	lbl.add_theme_constant_override("outline_size", 6)
	btn.add_child(lbl)

	parent.add_child(btn)
	return btn

func _create_pause_button(parent: Control, text: String, pos: Vector2, b_size: Vector2, is_purple: bool, on_pressed: Callable) -> TextureButton:
	return _create_dialog_button(parent, text, pos, b_size, "purple" if is_purple else "brown", on_pressed)

func toggle_pause() -> void:
	var new_paused = !get_tree().paused
	get_tree().paused = new_paused
	if pause_menu:
		pause_menu.visible = new_paused
	if new_paused:
		if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/pause.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/pause.ogg"))
	print("[Lawn] Game paused: %s" % new_paused)

func _resume_game() -> void:
	get_tree().paused = false
	if pause_menu:
		pause_menu.visible = false

func _restart_game() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _on_save_and_exit_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if ResourceLoader.exists("res://Scenes/Town.tscn"):
		get_tree().change_scene_to_file("res://Scenes/Town.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")

func is_cell_occupied(col: int, row: int, ignore_projectile: Projectile = null) -> bool:
	for p in plants_container.get_children():
		if p.get("col") == col and p.get("row") == row and not p.is_queued_for_deletion():
			return true
	var proj_container = get_node_or_null("Projectiles")
	if proj_container:
		for pr in proj_container.get_children():
			if pr is Projectile and not pr.is_queued_for_deletion() and pr != ignore_projectile and pr.projectile_type == "potato_pf":
				if pr.target_cell == Vector2i(col, row):
					return true
	return false

func _get_plant_at_cell(col: int, row: int) -> Node2D:
	for p in plants_container.get_children():
		if p.get("col") == col and p.get("row") == row and not p.is_queued_for_deletion():
			return p
	return null

func get_plant_index_by_id(id: String) -> int:
	for i in range(PLANT_REGISTRY.size()):
		if PLANT_REGISTRY[i]["id"] == id:
			return i
	return -1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if floating_shovel_icon and floating_shovel_icon.visible:
			floating_shovel_icon.global_position = event.position
		if floating_pf_icon and floating_pf_icon.visible:
			floating_pf_icon.global_position = event.position

func _unhandled_input(event: InputEvent) -> void:
	# Escape key to toggle pause
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			toggle_pause()
			return

		# Press G to toggle debug mode
		elif event.keycode == KEY_G:
			debug_mode = !debug_mode
			grid.debug_draw_grid = debug_mode
			grid.queue_redraw()
			_update_hud()
			print("[Lawn] Debug mode is now: %s" % ("ON" if debug_mode else "OFF"))

		# All debug shortcuts below are strictly gated behind debug_mode
		elif debug_mode:
			# Z key to spawn a zombie
			if event.keycode == KEY_Z:
				var mouse_pos = get_global_mouse_position()
				var cell = grid.world_to_cell(mouse_pos)
				var target_row = cell.y if grid.is_valid_cell(cell.x, cell.y) else randi_range(0, grid.rows - 1)
				spawn_zombie(target_row, mouse_pos.x, "none")

			# C key to spawn a conehead zombie
			elif event.keycode == KEY_C:
				var mouse_pos = get_global_mouse_position()
				var cell = grid.world_to_cell(mouse_pos)
				var target_row = cell.y if grid.is_valid_cell(cell.x, cell.y) else randi_range(0, grid.rows - 1)
				spawn_zombie(target_row, mouse_pos.x, "cone")

			# B key to spawn a buckethead zombie
			elif event.keycode == KEY_B:
				var mouse_pos = get_global_mouse_position()
				var cell = grid.world_to_cell(mouse_pos)
				var target_row = cell.y if grid.is_valid_cell(cell.x, cell.y) else randi_range(0, grid.rows - 1)
				spawn_zombie(target_row, mouse_pos.x, "bucket")

			# K key to spawn a brickhead zombie
			elif event.keycode == KEY_K:
				var mouse_pos = get_global_mouse_position()
				var cell = grid.world_to_cell(mouse_pos)
				var target_row = cell.y if grid.is_valid_cell(cell.x, cell.y) else randi_range(0, grid.rows - 1)
				spawn_zombie(target_row, mouse_pos.x, "brick")

			# D key to trigger Game Over / Death Screen test
			elif event.keycode == KEY_D:
				_trigger_game_over()

			# V key to trigger Victory Outro test
			elif event.keycode == KEY_V:
				_on_level_victory()

			# A key during debug mode toggles animation viewer
			elif event.keycode == KEY_A:
				_toggle_animation_viewer()

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
			elif event.keycode in [KEY_9, KEY_KP_9]:
				_select_plant(8)
			elif event.keycode in [KEY_0, KEY_KP_0]:
				_select_plant(9)

	# Mouse clicks for planting / actions
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var cell = grid.world_to_cell(mouse_pos)

		if event.button_index == MOUSE_BUTTON_LEFT:
			# 1. Shovel tool active: dig plant
			if is_shovel_active:
				if grid.is_valid_cell(cell.x, cell.y):
					dig_plant_at(cell.x, cell.y)
				else:
					set_shovel_active(false)

			# 2. Plant food tool active: feed plant
			elif is_plant_food_active:
				var target_p = _get_plant_at_cell(cell.x, cell.y)
				if target_p:
					use_plant_food_on(target_p)
				else:
					set_plant_food_active(false)

			# 3. Regular seed packet planting
			elif seed_bank and seed_bank.selected_packet != null:
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
						if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/failure.ogg"):
							AudioManager.play_sfx(load("res://Audio/SFX/failure.ogg"))

		# Right-click cancels shovel, plant food, or packet selection
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if is_shovel_active:
				set_shovel_active(false)
			elif is_plant_food_active:
				set_plant_food_active(false)
			elif seed_bank and seed_bank.selected_packet != null:
				seed_bank.deselect_all()
			elif debug_mode and grid.is_valid_cell(cell.x, cell.y):
				spawn_plant_at(cell.x, cell.y, selected_plant_index)

		# Middle-click directly triggers plant food on hovered plant (debug cheat only)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and debug_mode:
			var target_p = _get_plant_at_cell(cell.x, cell.y)
			if target_p:
				use_plant_food_on(target_p)

func _toggle_animation_viewer() -> void:
	if anim_viewer_instance and is_instance_valid(anim_viewer_instance):
		anim_viewer_instance.close_viewer()
		anim_viewer_instance = null
	else:
		var viewer_script = load("res://Scripts/AnimationViewer.gd")
		if viewer_script:
			anim_viewer_instance = viewer_script.new()
			add_child(anim_viewer_instance)
			anim_viewer_instance.closed.connect(func(): anim_viewer_instance = null)

func _setup_lawn_mowers() -> void:
	lawn_mowers_container = Node2D.new()
	lawn_mowers_container.name = "LawnMowers"
	add_child(lawn_mowers_container)

	var num_rows = grid.rows if grid else 5
	for r in range(num_rows):
		var mower = mower_scene.instantiate()
		mower.row = r
		var row_y = grid.cell_to_world(0, r).y if grid else (345.0 + r * 137.0)
		mower.position = Vector2(705.0, row_y)
		lawn_mowers_container.add_child(mower)

func _select_plant(index: int) -> void:
	if index >= 0 and index < PLANT_REGISTRY.size():
		selected_plant_index = index
		_update_hud()
		print("[Lawn] Selected plant: [%d] %s" % [index + 1, PLANT_REGISTRY[index]["name"]])
		if get_node_or_null("/root/AudioManager"):
			var select_sfx = preload("res://Audio/SFX/select_plant.ogg")
			AudioManager.play_sfx(select_sfx)

func spawn_plant_at(col: int, row: int, plant_idx: int) -> Node2D:
	var info = PLANT_REGISTRY[plant_idx]
	var plant_pos = grid.cell_to_world(col, row)
	var plant_node: Node2D

	if info["id"] == "peashooter":
		plant_node = peashooter_scene.instantiate()
	else:
		plant_node = plant_scene.instantiate()

	plant_node.position = plant_pos
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

	return plant_node

func _update_hud() -> void:
	var selected_name = PLANT_REGISTRY[selected_plant_index]["name"]
	if peashooter_count_label:
		peashooter_count_label.text = "PLANTS: %d | [%d] %s" % [plant_count, selected_plant_index + 1, selected_name]
	if debug_status_label:
		if debug_mode:
			debug_status_label.text = "[DEBUG ON] 1-0: Plant | Z/C/B/K: Zombies | D: Death | V: Victory | A: Anim"
			debug_status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		else:
			debug_status_label.text = "Press 'G' for Debug Mode"
			debug_status_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
