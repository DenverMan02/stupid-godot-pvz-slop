extends Area2D
class_name Sun

signal collected(value: int)

@export var value: int = 50
@export var fall_speed: float = 120.0
@export var auto_collect: bool = false

const BASE_SCALE: float = 0.85

var target_pos: Vector2 = Vector2.ZERO
var is_falling: bool = false
var is_collected: bool = false
var lifetime: float = 10.0
var is_fading: bool = false

@onready var sprite: XFLSprite2D = $XFLSprite2D

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	add_to_group("suns")

	if sprite:
		sprite.play("animation", true)

	# Scale in based on sun value
	scale = Vector2(0.2, 0.2)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", get_target_scale(), 0.35)

func get_target_scale() -> Vector2:
	# Scaled relative to 50 sun: min size 0.25, max size 4.0
	var scale_val = clamp(BASE_SCALE * sqrt(float(value) / 50.0), 0.25, 4.0)
	return Vector2(scale_val, scale_val)

func spawn_from_sky(start_pos: Vector2, end_pos: Vector2) -> void:
	global_position = start_pos
	target_pos = end_pos
	is_falling = true

func spawn_from_sunflower(origin_pos: Vector2) -> void:
	global_position = origin_pos
	var angle = randf_range(-PI * 0.75, -PI * 0.25)
	var dist = randf_range(50.0, 90.0)
	var land_pos = origin_pos + Vector2(cos(angle) * dist, sin(angle) * dist + 40.0)

	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "global_position:x", land_pos.x, 0.6)
	var y_tw = create_tween()
	y_tw.tween_property(self, "global_position:y", origin_pos.y - 45.0, 0.3).set_ease(Tween.EASE_OUT)
	y_tw.tween_property(self, "global_position:y", land_pos.y, 0.3).set_ease(Tween.EASE_IN)

func _process(delta: float) -> void:
	if is_collected:
		return

	# Despawn if >500px outside screen in any direction
	if global_position.x < -266.0 or global_position.x > 2654.0 or global_position.y < -500.0 or global_position.y > 1580.0:
		queue_free()
		return

	# Collect if mouse touches sun
	var m_pos = get_global_mouse_position()
	var touch_radius = 55.0 * max(scale.x / BASE_SCALE, 0.4)
	if global_position.distance_to(m_pos) <= touch_radius:
		_trigger_collect()
		return

	# Fall downwards towards landing target
	if is_falling:
		global_position.y += fall_speed * delta
		if global_position.y >= target_pos.y:
			global_position.y = target_pos.y
			is_falling = false

	# Sun merging: if >= 25 suns on screen, gravitate like a magnet within 150px and merge infinitely
	var all_suns = get_tree().get_nodes_in_group("suns")
	if all_suns.size() >= 25 and not is_falling:
		for other in all_suns:
			if other is Sun and other != self and is_instance_valid(other) and not other.is_collected and not other.is_falling:
				var dist = global_position.distance_to(other.global_position)
				if dist < 150.0 and dist > 0.1:
					var dir = (other.global_position - global_position).normalized()
					global_position += dir * (120.0 * delta)
					if dist < 35.0 and get_instance_id() < other.get_instance_id():
						value += other.value
						other.is_collected = true
						other.queue_free()
						lifetime = 10.0 # reset decay timer on merge
						var stw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
						stw.tween_property(self, "scale", get_target_scale(), 0.3)
						break

	# Lifetime: 10 seconds before fade, 0.5s fade out
	if not is_fading and not is_falling:
		lifetime -= delta
		if lifetime <= 0.0:
			is_fading = true
			var fade_tw = create_tween()
			fade_tw.tween_property(self, "modulate:a", 0.0, 0.5)
			fade_tw.finished.connect(queue_free)

func _on_mouse_entered() -> void:
	_trigger_collect()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_collected:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_trigger_collect()

func _trigger_collect() -> void:
	if is_collected:
		return
	var lawn = get_tree().current_scene
	var target_pos = Vector2(90, 60)
	if lawn and lawn.get_node_or_null("HUD/SeedBank"):
		var sb = lawn.get_node("HUD/SeedBank")
		if sb.has_method("get_sun_icon_global_pos"):
			target_pos = sb.get_sun_icon_global_pos()
	collect(target_pos)

func collect(target_ui_pos: Vector2 = Vector2(100, 60)) -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit(value)

	# Play sun_collect sound variations based on value
	if get_node_or_null("/root/AudioManager"):
		var sfx_path = "res://Audio/SFX/sun_collect.ogg"
		var r = randf()
		if value > 50:
			if r < 0.60:
				sfx_path = "res://Audio/SFX/sun_collect_speeder.ogg"
			elif r < 0.85:
				sfx_path = "res://Audio/SFX/sun_collect_speed.ogg"
			else:
				sfx_path = "res://Audio/SFX/sun_collect.ogg"
		else:
			if r < 0.34:
				sfx_path = "res://Audio/SFX/sun_collect.ogg"
			elif r < 0.68:
				sfx_path = "res://Audio/SFX/sun_collect_speed.ogg"
			else:
				sfx_path = "res://Audio/SFX/sun_collect_speeder.ogg"

		if ResourceLoader.exists(sfx_path):
			AudioManager.play_sfx(load(sfx_path))

	# Fly smoothly towards Sun Bank in top-left
	var cam = get_viewport().get_camera_2d()
	var world_target = target_ui_pos
	if cam:
		world_target = cam.get_screen_center_position() - (get_viewport_rect().size * 0.5) + target_ui_pos

	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_position", world_target, 0.55)
	tw.tween_property(self, "scale", Vector2(0.25, 0.25), 0.55)
	tw.chain().tween_callback(queue_free)
