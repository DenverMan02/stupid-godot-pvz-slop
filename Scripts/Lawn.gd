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

# Progress Meter UI nodes
var meter_fill: NinePatchRect = null
var zombie_head_icon: TextureRect = null
var mid_flag_icon: TextureRect = null
var final_flag_icon: TextureRect = null

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
	pf_bank_ctrl.custom_minimum_size = Vector2(268.0, 114.0)
	pf_bank_ctrl.size = Vector2(268.0, 114.0)

	var pf_bg = TextureRect.new()
	pf_bg.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_bank.png")
	pf_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pf_bg.size = Vector2(268.0, 114.0)
	pf_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	pf_bank_ctrl.add_child(pf_bg)

	# Main round plant food button (displays green leaf when charges >= 1)
	pf_main_btn = TextureButton.new()
	pf_main_btn.name = "PlantFoodButton"
	pf_main_btn.position = Vector2(21.0, 21.0)
	pf_main_btn.custom_minimum_size = Vector2(68.0, 72.0)
	pf_main_btn.size = Vector2(68.0, 72.0)
	pf_main_btn.ignore_texture_size = true
	pf_main_btn.stretch_mode = TextureButton.STRETCH_SCALE
	pf_main_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_button.png")
	pf_main_btn.texture_pressed = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_button_down.png")
	pf_main_btn.focus_mode = Control.FOCUS_NONE
	pf_main_btn.pressed.connect(toggle_plant_food_armed)
	pf_main_btn.visible = (plant_food_count >= 1)
	pf_bank_ctrl.add_child(pf_main_btn)

	# 3 small leaf slots for extra plant food charges (aligned with sockets in plantfood_bank.png)
	var slot_offsets = [Vector2(98.0, 41.0), Vector2(130.0, 41.0), Vector2(163.0, 41.0)]
	plant_food_slots.clear()
	for i in range(3):
		var slot_tex = TextureRect.new()
		slot_tex.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_bank_filled_slot.png")
		slot_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot_tex.size = Vector2(32.0, 33.0)
		slot_tex.position = slot_offsets[i]
		slot_tex.visible = (plant_food_count >= (i + 2))
		slot_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	# 3. Floating Cursors for Shovel and Plant Food
	floating_shovel_icon = Sprite2D.new()
	floating_shovel_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/shovel_icon.png")
	floating_shovel_icon.scale = Vector2(0.35, 0.35)
	floating_shovel_icon.offset = Vector2(10.0, -10.0)
	floating_shovel_icon.visible = false
	floating_shovel_icon.z_index = 200
	hud.add_child(floating_shovel_icon)

	floating_pf_icon = Sprite2D.new()
	floating_pf_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_bank_collect.png")
	floating_pf_icon.scale = Vector2(0.4, 0.4)
	floating_pf_icon.visible = false
	floating_pf_icon.z_index = 200
	hud.add_child(floating_pf_icon)

	# 4. Wave Progress Meter (Top-Center, filling left-to-right, matching official PvZ2)
	var meter_ctrl = Control.new()
	meter_ctrl.name = "WaveMeter"
	meter_ctrl.position = Vector2(750.0, 20.0)
	meter_ctrl.custom_minimum_size = Vector2(420.0, 50.0)
	meter_ctrl.size = Vector2(420.0, 50.0)

	var meter_bg = TextureRect.new()
	meter_bg.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter.png")
	meter_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meter_bg.size = Vector2(420.0, 50.0)
	meter_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(meter_bg)

	meter_fill = NinePatchRect.new()
	meter_fill.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter_fill.png")
	meter_fill.patch_margin_left = 6
	meter_fill.patch_margin_right = 6
	meter_fill.patch_margin_top = 4
	meter_fill.patch_margin_bottom = 4
	meter_fill.position = Vector2(22.0, 11.0)
	meter_fill.size = Vector2(0.0, 28.0)
	meter_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(meter_fill)

	# Flags (Wave 5 at 50%, Wave 10 at 100%)
	mid_flag_icon = TextureRect.new()
	mid_flag_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter_flag_default.png")
	mid_flag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mid_flag_icon.size = Vector2(30.0, 25.0)
	mid_flag_icon.position = Vector2(198.0, -10.0)
	mid_flag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(mid_flag_icon)

	final_flag_icon = TextureRect.new()
	final_flag_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter_flag_default.png")
	final_flag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	final_flag_icon.size = Vector2(30.0, 25.0)
	final_flag_icon.position = Vector2(380.0, -10.0)
	final_flag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(final_flag_icon)

	zombie_head_icon = TextureRect.new()
	zombie_head_icon.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/progress_meter_zombiehead.png")
	zombie_head_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	zombie_head_icon.size = Vector2(40.0, 42.0)
	zombie_head_icon.position = Vector2(4.0, 2.0)
	zombie_head_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter_ctrl.add_child(zombie_head_icon)

	# Level Name Label centered directly below the progress meter
	var level_name_lbl = Label.new()
	level_name_lbl.name = "LevelNameLabel"
	level_name_lbl.text = "Modern Day - Day 1"
	level_name_lbl.position = Vector2(-20.0, 52.0)
	level_name_lbl.size = Vector2(460.0, 32.0)
	level_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_path = "res://Fonts/PvZ2 Regular By Beast and MF.ttf"
	if ResourceLoader.exists(font_path):
		var custom_font = load(font_path)
		level_name_lbl.add_theme_font_override("font", custom_font)
	level_name_lbl.add_theme_font_size_override("font_size", 24)
	level_name_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	level_name_lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	level_name_lbl.add_theme_constant_override("outline_size", 4)
	meter_ctrl.add_child(level_name_lbl)

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
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.visible = false
	pause_menu.mouse_filter = Control.MOUSE_FILTER_STOP

	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_menu.add_child(overlay)

	var panel = NinePatchRect.new()
	panel.texture = load("res://Assets/UI/UI_AlwaysLoaded_Uncompressed/Dialog_Asset/dialogborder.png")
	panel.patch_margin_left = 64
	panel.patch_margin_right = 64
	panel.patch_margin_top = 64
	panel.patch_margin_bottom = 64
	panel.custom_minimum_size = Vector2(500.0, 360.0)
	panel.size = Vector2(500.0, 360.0)
	panel.position = Vector2((1920.0 - 500.0) * 0.5, (1080.0 - 360.0) * 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var p_vbox = VBoxContainer.new()
	p_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	p_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	p_vbox.add_theme_constant_override("separation", 28)

	var p_title = Label.new()
	p_title.text = "GAME PAUSED"
	p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p_title.add_theme_font_size_override("font_size", 44)
	p_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2, 1.0))
	p_title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	p_title.add_theme_constant_override("outline_size", 14)
	p_vbox.add_child(p_title)

	var resume_btn = Button.new()
	resume_btn.text = "RESUME"
	resume_btn.custom_minimum_size = Vector2(260.0, 56.0)
	resume_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume_btn.add_theme_font_size_override("font_size", 26)
	resume_btn.focus_mode = Control.FOCUS_NONE
	resume_btn.pressed.connect(_resume_game)
	p_vbox.add_child(resume_btn)

	var restart_btn = Button.new()
	restart_btn.text = "RESTART LEVEL"
	restart_btn.custom_minimum_size = Vector2(260.0, 56.0)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_btn.add_theme_font_size_override("font_size", 26)
	restart_btn.focus_mode = Control.FOCUS_NONE
	restart_btn.pressed.connect(_restart_game)
	p_vbox.add_child(restart_btn)

	panel.add_child(p_vbox)
	pause_menu.add_child(panel)
	hud.add_child(pause_menu)

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
	_start_wave(1)

func _process(delta: float) -> void:
	if not level_started or level_finished:
		return

	# Periodic sky sun falling
	sky_sun_timer -= delta
	if sky_sun_timer <= 0.0:
		sky_sun_timer = randf_range(8.5, 11.5)
		_spawn_sky_sun()

	# Wave progression
	wave_timer += delta
	var wave_ratio = clampf(wave_timer / wave_time_limit, 0.0, 1.0)
	var total_progress = (float(current_wave - 1) + wave_ratio) / float(TOTAL_WAVES)
	_update_wave_meter(total_progress)

	var living_zombies = 0
	if zombies_container:
		for z in zombies_container.get_children():
			if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion() and z.health > 0.0:
				living_zombies += 1

	if (living_zombies == 0 and wave_timer >= 6.0 and not is_huge_wave_spawning) or (wave_timer >= wave_time_limit and not is_huge_wave_spawning):
		if current_wave < TOTAL_WAVES:
			_start_wave(current_wave + 1)
		elif current_wave >= TOTAL_WAVES and living_zombies == 0:
			_on_level_victory()

func _start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_timer = 0.0
	print("[Lawn] === Starting Wave %d / %d ===" % [current_wave, TOTAL_WAVES])

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
				_drop_final_flag()
			else:
				AudioManager.play_music(midwave_music)
				_drop_mid_flag()
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

func _drop_mid_flag() -> void:
	if mid_flag_icon:
		var tw = create_tween()
		tw.tween_property(mid_flag_icon, "position:y", 12.0, 0.4).set_trans(Tween.TRANS_BOUNCE)

func _drop_final_flag() -> void:
	if final_flag_icon:
		var tw = create_tween()
		tw.tween_property(final_flag_icon, "position:y", 12.0, 0.4).set_trans(Tween.TRANS_BOUNCE)

func _update_wave_meter(progress: float) -> void:
	var clamped_p = clampf(progress, 0.0, 1.0)
	var start_x = 22.0
	var max_fill_w = 376.0
	var fill_w = max_fill_w * clamped_p
	if meter_fill:
		meter_fill.position.x = start_x
		meter_fill.size.x = fill_w
		meter_fill.visible = (fill_w > 2.0)
	if zombie_head_icon:
		zombie_head_icon.position.x = start_x + fill_w - 18.0

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

func _on_level_victory() -> void:
	if level_finished:
		return
	level_finished = true
	print("[Lawn] *** LEVEL COMPLETE! ***")
	_show_banner_message("VICTORY!", Color(1.0, 0.85, 0.1, 1.0), 6.0)

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
		pf_main_btn.visible = (plant_food_count >= 1)
		pf_main_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_button_down.png") if is_plant_food_active else load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_button.png")
	for i in range(plant_food_slots.size()):
		if plant_food_slots[i]:
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

func is_cell_occupied(col: int, row: int) -> bool:
	for p in plants_container.get_children():
		if p.get("col") == col and p.get("row") == row:
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

		# Middle-click directly triggers plant food on hovered plant
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
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
			debug_status_label.text = "[DEBUG ON] 1-8: Plant | Z/C/B/K: Zombies | A: AnimViewer | Shovel | PF"
			debug_status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		else:
			debug_status_label.text = "Press 'G' for Debug Mode"
			debug_status_label.modulate = Color(0.8, 0.8, 0.8, 0.7)
