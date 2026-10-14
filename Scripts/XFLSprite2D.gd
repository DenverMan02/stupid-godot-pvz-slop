extends Node2D
class_name XFLSprite2D

## High-performance, zero-node XFL sprite renderer for Godot 4
## Renders pre-compiled XFL animation frames with native 2D transform matrices.
## Shares immutable animation data and textures statically across all instances.

signal anim_event(event_name: String)
signal anim_finished(anim_name: String)

# Global caches so hundreds of plants share the same resources
static var _anim_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}

@export_file("*.json") var anim_data_path: String = "res://Assets/Plants/peashooter.anim.json"
@export var textures_base_dir: String = "res://Assets/Plants/peashooter.xfl/library/"
@export var default_animation: String = "idle"
@export var autoplay: bool = true

var current_animation: String = "idle"
var is_playing: bool = false
var loop: bool = true
var current_frame: int = 0
var time_accumulator: float = 0.0

@export var has_armor_cone: bool = false
@export var armor_cone_state: int = 0 # 0: norm, 1: dmg1, 2: dmg2
@export var has_lost_arm: bool = false
@export var armor_type: String = "none" # "none", "cone", "bucket", "brick"
@export var armor_state: int = 0 # 0: norm, 1: dmg1, 2: dmg2
@export var plantfood_armor_active: bool = false
@export var plantfood_armor_stage: int = 0 # 0: armor_01, 1: armor_02, 2: armor_03

var _anim_data: Dictionary = {}
var _loaded_textures: Array[Texture2D] = []
var _frame_rate: float = 30.0
var _frame_duration: float = 1.0 / 30.0
var _accumulated_ground_delta: float = 0.0

func _ready() -> void:
	_load_resources()
	if autoplay:
		play(default_animation, true)

func set_animation_source(data_path: String, tex_dir: String) -> void:
	anim_data_path = data_path
	textures_base_dir = tex_dir
	_load_resources()

func has_animation(anim_name: String) -> bool:
	var anims = _anim_data.get("animations", {})
	return anims.has(anim_name)

func get_animation_names() -> Array[String]:
	var anims = _anim_data.get("animations", {})
	var names: Array[String] = []
	for k in anims.keys():
		names.append(str(k))
	return names

func _load_resources() -> void:
	if anim_data_path.is_empty():
		return

	# 1. Load Animation Data (shared in static dictionary)
	if not _anim_cache.has(anim_data_path):
		if FileAccess.file_exists(anim_data_path):
			var file = FileAccess.open(anim_data_path, FileAccess.READ)
			var json_str = file.get_as_text()
			var parsed = JSON.parse_string(json_str)
			if parsed is Dictionary:
				_anim_cache[anim_data_path] = parsed
			else:
				push_error("[XFLSprite2D] Failed to parse JSON: " + anim_data_path)
				return
		else:
			push_error("[XFLSprite2D] Animation data file not found: " + anim_data_path)
			return

	_anim_data = _anim_cache[anim_data_path]
	_frame_rate = float(_anim_data.get("frame_rate", 30.0))
	_frame_duration = 1.0 / _frame_rate

	# 2. Load Textures (shared in static dictionary)
	var raw_textures = _anim_data.get("textures", [])
	_loaded_textures.clear()
	for rel_path in raw_textures:
		var full_path = textures_base_dir.path_join(rel_path)
		
		# Fallback to alternate library/LIBRARY directory casing if not directly found
		if not ResourceLoader.exists(full_path):
			var alt_dir = textures_base_dir
			if "library" in alt_dir:
				alt_dir = alt_dir.replace("library", "LIBRARY")
			elif "LIBRARY" in alt_dir:
				alt_dir = alt_dir.replace("LIBRARY", "library")
			var alt_path = alt_dir.path_join(rel_path)
			if ResourceLoader.exists(alt_path):
				full_path = alt_path

		if not _texture_cache.has(full_path):
			if ResourceLoader.exists(full_path):
				_texture_cache[full_path] = load(full_path)
			else:
				push_warning("[XFLSprite2D] Texture not found: " + full_path)
				_texture_cache[full_path] = null
		_loaded_textures.append(_texture_cache[full_path])

func play(anim_name: String, should_loop: bool = true) -> void:
	var anims = _anim_data.get("animations", {})
	if not anims.has(anim_name):
		push_warning("[XFLSprite2D] Animation not found: " + anim_name)
		return

	current_animation = anim_name
	loop = should_loop
	current_frame = 0
	time_accumulator = 0.0
	is_playing = true
	_accumulated_ground_delta = 0.0
	_check_frame_events(0)
	queue_redraw()

func stop() -> void:
	is_playing = false

func has_ground_track() -> bool:
	var anims = _anim_data.get("animations", {})
	var anim_info = anims.get(current_animation, {})
	return anim_info.has("ground_track")

func consume_ground_delta() -> float:
	var d = _accumulated_ground_delta
	_accumulated_ground_delta = 0.0
	return d

func _advance_ground_track(anim_info: Dictionary, from_f: int, to_f: int, total_f: int, did_loop: bool) -> void:
	if not anim_info.has("ground_track"):
		return
	var track: Array = anim_info["ground_track"]
	if track.is_empty():
		return
	if not did_loop:
		if to_f < track.size() and from_f < track.size():
			var d = float(track[to_f]) - float(track[from_f])
			_accumulated_ground_delta += d
	else:
		var last_val = float(track[track.size() - 1])
		var from_val = float(track[from_f]) if from_f < track.size() else last_val
		var to_val = float(track[to_f]) if to_f < track.size() else 0.0
		var step = float(track[1]) - float(track[0]) if track.size() > 1 else 0.0
		var d = (last_val - from_val) + step + to_val
		_accumulated_ground_delta += d

func _process(delta: float) -> void:
	if not is_playing:
		return

	var anims = _anim_data.get("animations", {})
	var anim_info = anims.get(current_animation, {})
	var total_frames = int(anim_info.get("frame_count", 1))
	if total_frames <= 0:
		return

	time_accumulator += delta
	var frame_changed = false

	# Advance 30 FPS timeline using time accumulator
	while time_accumulator >= _frame_duration:
		time_accumulator -= _frame_duration
		var prev_frame = current_frame
		var next_frame = current_frame + 1

		if next_frame >= total_frames:
			if loop:
				current_frame = 0
				_advance_ground_track(anim_info, prev_frame, 0, total_frames, true)
				_check_frame_events(0)
				frame_changed = true
				anim_finished.emit(current_animation)
				continue
			else:
				current_frame = total_frames - 1
				_advance_ground_track(anim_info, prev_frame, current_frame, total_frames, false)
				is_playing = false
				_check_frame_events(current_frame)
				frame_changed = true
				var finished_anim = current_animation
				anim_finished.emit(finished_anim)
				break
		else:
			current_frame = next_frame
			_advance_ground_track(anim_info, prev_frame, next_frame, total_frames, false)
			_check_frame_events(current_frame)
			frame_changed = true

	if frame_changed:
		queue_redraw()

func _check_frame_events(frame_idx: int) -> void:
	var anims = _anim_data.get("animations", {})
	var anim_info = anims.get(current_animation, {})
	var events_map = anim_info.get("events", {})
	var key = str(frame_idx)
	if events_map.has(key):
		var event_name = events_map[key]
		anim_event.emit(event_name)

func set_armor(p_armor_type: String, p_state: int = 0) -> void:
	armor_type = p_armor_type
	armor_state = p_state
	has_armor_cone = (p_armor_type == "cone")
	armor_cone_state = p_state
	queue_redraw()

func set_armor_cone(active: bool, state: int = 0) -> void:
	has_armor_cone = active
	armor_cone_state = state
	armor_type = "cone" if active else "none"
	armor_state = state
	queue_redraw()

func set_plantfood_armor(active: bool, stage: int = 0) -> void:
	plantfood_armor_active = active
	plantfood_armor_stage = stage
	queue_redraw()

func set_arm_lost(lost: bool) -> void:
	has_lost_arm = lost
	queue_redraw()

func _is_tag_visible(tag: int) -> bool:
	match tag:
		1: # Cone norm
			return (armor_type == "cone" or has_armor_cone) and (armor_state == 0)
		2: # Cone dmg 1
			return (armor_type == "cone" or has_armor_cone) and (armor_state == 1)
		3: # Cone dmg 2
			return (armor_type == "cone" or has_armor_cone) and (armor_state == 2)
		4: # Arm flesh
			return not has_lost_arm and current_animation != "die"
		5: # Arm bone stump
			return has_lost_arm or current_animation == "die"
		6: # Bucket norm
			return armor_type == "bucket" and armor_state == 0
		7: # Bucket dmg 1
			return armor_type == "bucket" and armor_state == 1
		8: # Bucket dmg 2
			return armor_type == "bucket" and armor_state == 2
		9: # Brick norm
			return armor_type == "brick" and armor_state == 0
		10: # Brick dmg 1
			return armor_type == "brick" and armor_state == 1
		11: # Brick dmg 2
			return armor_type == "brick" and armor_state == 2
		12: # Wallnut plantfood armor 1
			return plantfood_armor_active and plantfood_armor_stage == 0
		13: # Wallnut plantfood armor 2
			return plantfood_armor_active and plantfood_armor_stage == 1
		14: # Wallnut plantfood armor 3
			return plantfood_armor_active and plantfood_armor_stage == 2
		_:
			return true

func _draw() -> void:
	var anims = _anim_data.get("animations", {})
	var anim_info = anims.get(current_animation, {})
	var frames = anim_info.get("frames", [])
	if current_frame < 0 or current_frame >= frames.size():
		return

	var slice_list = frames[current_frame]
	for slice in slice_list:
		if slice.size() > 7:
			var tag = int(slice[7])
			if not _is_tag_visible(tag):
				continue

		var tex_id = int(slice[0])
		if tex_id < 0 or tex_id >= _loaded_textures.size():
			continue
		var tex = _loaded_textures[tex_id]
		if tex == null:
			continue

		# Native 2D matrix transformation: Transform2D(x_basis, y_basis, origin)
		var a = float(slice[1])
		var b = float(slice[2])
		var c = float(slice[3])
		var d = float(slice[4])
		var tx = float(slice[5])
		var ty = float(slice[6])

		var x_basis = Vector2(a, b)
		var y_basis = Vector2(c, d)
		var origin_pos = Vector2(tx, ty)
		var xform = Transform2D(x_basis, y_basis, origin_pos)

		draw_set_transform_matrix(xform)
		draw_texture(tex, Vector2.ZERO)
