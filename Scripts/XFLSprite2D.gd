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

var _anim_data: Dictionary = {}
var _loaded_textures: Array[Texture2D] = []
var _frame_rate: float = 30.0
var _frame_duration: float = 1.0 / 30.0

func _ready() -> void:
	_load_resources()
	if autoplay:
		play(default_animation, true)

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
	_check_frame_events(0)
	queue_redraw()

func stop() -> void:
	is_playing = false

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
		var next_frame = current_frame + 1

		if next_frame >= total_frames:
			anim_finished.emit(current_animation)
			if loop:
				next_frame = 0
			else:
				next_frame = total_frames - 1
				is_playing = false
				_check_frame_events(next_frame)
				frame_changed = true
				break

		current_frame = next_frame
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

func _draw() -> void:
	var anims = _anim_data.get("animations", {})
	var anim_info = anims.get(current_animation, {})
	var frames = anim_info.get("frames", [])
	if current_frame < 0 or current_frame >= frames.size():
		return

	var slice_list = frames[current_frame]
	for slice in slice_list:
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
