extends Node2D
class_name Plant

@onready var sprite: XFLSprite2D = $XFLSprite2D

@export var plant_type: String = "peashooter"
@export var display_name: String = "Peashooter"
@export var row: int = 2
@export var col: int = 1
@export var anim_data_path: String = "res://Assets/Plants/peashooter.anim.json"
@export var textures_base_dir: String = "res://Assets/Plants/peashooter.xfl/library/"
@export var visual_scale: float = 1.0
@export var visual_offset: Vector2 = Vector2.ZERO

## Custom idle mappings for plants with oddly named idle animations or specific idle states
## Wall-nut uses only "idle" so it does not cycle into its post-plantfood armored state
const IDLE_MAP: Dictionary = {
	"wallnut": ["idle"],
}

var idle_animations: Array[String] = []
var current_idle_index: int = 0
var is_performing_action: bool = false

var plantfood_sequence: Array[String] = []
var plantfood_sequence_index: int = 0
var is_in_plantfood_sequence: bool = false

var sun_scene: PackedScene = preload("res://Scenes/Sun.tscn")
var sunflower_timer: float = 7.0

func _process(delta: float) -> void:
	if plant_type == "sunflower" and not is_performing_action:
		sunflower_timer -= delta
		if sunflower_timer <= 0.0:
			sunflower_timer = 24.0
			_produce_sun()

func _produce_sun() -> void:
	play_attack()
	get_tree().create_timer(0.8).timeout.connect(func():
		_spawn_sun_at_plant()
	)

func _spawn_sun_at_plant() -> void:
	var sun_inst: Sun = sun_scene.instantiate()
	var lawn = get_tree().current_scene
	if lawn:
		var suns_container = lawn.get_node_or_null("Suns")
		if suns_container:
			suns_container.add_child(sun_inst)
		else:
			lawn.add_child(sun_inst)
		sun_inst.spawn_from_sunflower(global_position)
		sun_inst.collected.connect(func(val):
			if lawn.has_method("add_sun"):
				lawn.add_sun(val)
		)

func _ready() -> void:
	if sprite:
		sprite.scale = Vector2(visual_scale, visual_scale)
		sprite.position = visual_offset

		if not anim_data_path.is_empty():
			sprite.anim_data_path = anim_data_path
			sprite.textures_base_dir = textures_base_dir
			sprite.autoplay = false
			sprite._load_resources()

		sprite.anim_event.connect(_on_anim_event)
		sprite.anim_finished.connect(_on_anim_finished)

		_setup_idle_animations()
		_play_current_idle()

func configure_plant(type_id: String, disp_name: String, anim_json: String, tex_dir: String, v_scale: float = 1.0, v_offset: Vector2 = Vector2.ZERO) -> void:
	plant_type = type_id
	display_name = disp_name
	anim_data_path = anim_json
	textures_base_dir = tex_dir
	visual_scale = v_scale
	visual_offset = v_offset
	if sprite:
		sprite.scale = Vector2(v_scale, v_scale)
		sprite.position = v_offset
		sprite.set_animation_source(anim_json, tex_dir)
		_setup_idle_animations()
		_play_current_idle()

func _setup_idle_animations() -> void:
	if not sprite:
		return

	idle_animations.clear()
	current_idle_index = 0

	# 1. Check IDLE_MAP for custom overrides
	var key = plant_type.to_lower()
	if IDLE_MAP.has(key):
		var custom_list = IDLE_MAP[key]
		if custom_list is Array:
			for anim_name in custom_list:
				if sprite.has_animation(str(anim_name)):
					idle_animations.append(str(anim_name))
		if not idle_animations.is_empty():
			return

	# 2. Check for standard idles: "idle", "idle2", "idle3", etc.
	var all_anims = sprite.get_animation_names()
	if "idle" in all_anims:
		idle_animations.append("idle")

	var idx: int = 2
	while true:
		var cand = "idle" + str(idx)
		if cand in all_anims:
			idle_animations.append(cand)
			idx += 1
		else:
			break

	# 3. Fallback: check for any animation containing "idle" (e.g. "plant_idle")
	if idle_animations.is_empty():
		for a in all_anims:
			if "idle" in a.to_lower():
				idle_animations.append(a)

	# 4. Final fallback: use default or first available animation
	if idle_animations.is_empty():
		if sprite.has_animation(sprite.default_animation):
			idle_animations.append(sprite.default_animation)
		elif not all_anims.is_empty():
			idle_animations.append(all_anims[0])

func _play_current_idle() -> void:
	if not sprite or idle_animations.is_empty():
		return

	is_performing_action = false
	is_in_plantfood_sequence = false
	var anim_name = idle_animations[current_idle_index]
	var should_loop = (idle_animations.size() == 1)
	sprite.play(anim_name, should_loop)

func _on_anim_finished(anim_name: String) -> void:
	# 1. Advance through plant food sequence if active
	if is_in_plantfood_sequence:
		plantfood_sequence_index += 1
		if plantfood_sequence_index < plantfood_sequence.size():
			sprite.play(plantfood_sequence[plantfood_sequence_index], false)
			return
		else:
			is_in_plantfood_sequence = false
			_play_current_idle()
			return

	# 2. Advance through sequential idles if idle completed
	if anim_name in idle_animations:
		if idle_animations.size() > 1:
			current_idle_index = (current_idle_index + 1) % idle_animations.size()
			_play_current_idle()
	else:
		# Finished an attack or single special animation -> resume idle
		_play_current_idle()

## Receives animation events pulsed from the XFL timeline
func _on_anim_event(event_name: String) -> void:
	match event_name:
		"use_action":
			_on_use_action()
		"use_special":
			_on_use_special()
		_:
			push_warning("[%s] Unhandled animation event: %s" % [display_name, event_name])

func _on_use_action() -> void:
	print("[%s] use_action pulsed at row %d, col %d!" % [display_name, row, col])
	if get_node_or_null("/root/AudioManager"):
		var click_sfx = preload("res://Audio/SFX/click_buy_button.ogg")
		AudioManager.play_sfx(click_sfx)

func _on_use_special() -> void:
	print("[%s] use_special pulsed at row %d, col %d!" % [display_name, row, col])
	if get_node_or_null("/root/AudioManager"):
		var match_sfx = preload("res://Audio/SFX/match.ogg")
		AudioManager.play_sfx(match_sfx)

## Trigger normal attack / special action
func play_attack() -> void:
	if not sprite:
		return

	var target_anim = ""
	if sprite.has_animation("attack"):
		target_anim = "attack"
	elif sprite.has_animation("special"):
		target_anim = "special"
	elif sprite.has_animation("buff"):
		target_anim = "buff"

	if not target_anim.is_empty():
		is_performing_action = true
		is_in_plantfood_sequence = false
		sprite.play(target_anim, false)
	else:
		push_warning("[%s] No attack/special animation found" % display_name)

## Trigger sequential plant food animation:
## Plays plantfood_on -> plantfood/plantfood_loop -> plantfood2/3 -> plantfood_off in order
func play_plantfood() -> void:
	if not sprite:
		return

	plantfood_sequence.clear()
	plantfood_sequence_index = 0

	var all_anims = sprite.get_animation_names()

	# 1. plantfood_on
	if "plantfood_on" in all_anims:
		plantfood_sequence.append("plantfood_on")

	# 2. plantfood or plantfood_loop
	if "plantfood" in all_anims:
		plantfood_sequence.append("plantfood")
	elif "plantfood_loop" in all_anims:
		plantfood_sequence.append("plantfood_loop")

	# 3. Additional plantfood stages (plantfood2, plantfood3, etc.)
	var p_idx: int = 2
	while true:
		var cand = "plantfood" + str(p_idx)
		if cand in all_anims:
			plantfood_sequence.append(cand)
			p_idx += 1
		else:
			break

	# 4. plantfood_off
	if "plantfood_off" in all_anims:
		plantfood_sequence.append("plantfood_off")

	# Fallback if none of the standard names were found
	if plantfood_sequence.is_empty():
		for a in all_anims:
			if "plantfood" in a.to_lower():
				plantfood_sequence.append(a)

	if not plantfood_sequence.is_empty():
		is_performing_action = true
		is_in_plantfood_sequence = true
		if plant_type == "sunflower":
			for i in range(3):
				get_tree().create_timer(0.3 * (i + 1)).timeout.connect(_spawn_sun_at_plant)
		if get_node_or_null("/root/AudioManager"):
			var pf_sfx = preload("res://Audio/SFX/plantfood.ogg")
			AudioManager.play_sfx(pf_sfx)
		sprite.play(plantfood_sequence[0], false)
	else:
		push_warning("[%s] No plantfood animation found" % display_name)

func _input(event: InputEvent) -> void:
	# Debug mode check: actions can only be forced when debug mode is ON
	var lawn = get_tree().current_scene
	var is_debug = lawn.get("debug_mode") if (lawn and "debug_mode" in lawn) else false
	if not is_debug:
		return
	if lawn and "seed_bank" in lawn and lawn.seed_bank and lawn.seed_bank.selected_packet != null:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		if global_position.distance_to(mouse_pos) < 60.0:
			if event.button_index == MOUSE_BUTTON_LEFT:
				play_attack()
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				play_plantfood()
