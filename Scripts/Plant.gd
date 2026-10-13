extends Node2D
class_name Plant

@onready var sprite: XFLSprite2D = $XFLSprite2D

@export var plant_type: String = "peashooter"
@export var display_name: String = "Peashooter"
@export var row: int = 2
@export var col: int = 1
@export var anim_data_path: String = "res://Assets/Plants/peashooter.anim.json"
@export var textures_base_dir: String = "res://Assets/Plants/peashooter.xfl/library/"

## Custom idle mappings for plants with oddly named idle animations
## Format: { "plant_id": ["intro", "loop"], ... }
const IDLE_MAP: Dictionary = {
	# Add any non-standard plant idle mappings here
	# e.g. "lingfugu": ["idle"],
}

var idle_animations: Array[String] = []
var current_idle_index: int = 0
var is_performing_action: bool = false

func _ready() -> void:
	if sprite:
		# If path was configured via export or script, configure sprite
		if not anim_data_path.is_empty():
			sprite.anim_data_path = anim_data_path
			sprite.textures_base_dir = textures_base_dir
			sprite.autoplay = false
			sprite._load_resources()

		sprite.anim_event.connect(_on_anim_event)
		sprite.anim_finished.connect(_on_anim_finished)

		_setup_idle_animations()
		_play_current_idle()

func configure_plant(type_id: String, disp_name: String, anim_json: String, tex_dir: String) -> void:
	plant_type = type_id
	display_name = disp_name
	anim_data_path = anim_json
	textures_base_dir = tex_dir
	if sprite:
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
	var anim_name = idle_animations[current_idle_index]
	# If only 1 idle animation exists, loop it continuously.
	# If multiple idles exist (idle, idle2, idle3), play sequentially without looping.
	var should_loop = (idle_animations.size() == 1)
	sprite.play(anim_name, should_loop)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name in idle_animations:
		if idle_animations.size() > 1:
			# Advance sequentially to the next idle animation in the list
			current_idle_index = (current_idle_index + 1) % idle_animations.size()
			_play_current_idle()
	else:
		# Finished an attack, plantfood, or special animation -> resume idle cycling
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
		sprite.play(target_anim, false)
	else:
		push_warning("[%s] No attack/special animation found" % display_name)

## Trigger plant food animation
func play_plantfood() -> void:
	if not sprite:
		return

	var target_anim = ""
	if sprite.has_animation("plantfood"):
		target_anim = "plantfood"
	elif sprite.has_animation("plantfood_on"):
		target_anim = "plantfood_on"

	if not target_anim.is_empty():
		is_performing_action = true
		sprite.play(target_anim, false)
		if get_node_or_null("/root/AudioManager"):
			var pf_sfx = preload("res://Audio/SFX/plantfood.ogg")
			AudioManager.play_sfx(pf_sfx)
	else:
		push_warning("[%s] No plantfood animation found" % display_name)

func _input(event: InputEvent) -> void:
	# Debug mode check: actions can only be forced when debug mode is ON
	var lawn = get_tree().current_scene
	var is_debug = lawn.get("debug_mode") if (lawn and "debug_mode" in lawn) else false
	if not is_debug:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		if global_position.distance_to(mouse_pos) < 60.0:
			if event.button_index == MOUSE_BUTTON_LEFT:
				play_attack()
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				play_plantfood()
