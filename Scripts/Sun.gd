extends Area2D
class_name Sun

signal collected(value: int)

@export var value: int = 50
@export var fall_speed: float = 120.0
@export var auto_collect: bool = false

var target_pos: Vector2 = Vector2.ZERO
var is_falling: bool = false
var is_collected: bool = false
var lifetime: float = 14.0

@onready var sprite: XFLSprite2D = $XFLSprite2D

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)

	if sprite:
		sprite.play("animation", true)

	# Gentle scale-in animation when spawned
	scale = Vector2(0.2, 0.2)
	var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2(0.85, 0.85), 0.4)

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

	# Fall downwards towards landing target
	if is_falling:
		global_position.y += fall_speed * delta
		if global_position.y >= target_pos.y:
			global_position.y = target_pos.y
			is_falling = false

	# Despawn if neglected
	lifetime -= delta
	if lifetime <= 0.0:
		var fade_tw = create_tween()
		fade_tw.tween_property(self, "modulate:a", 0.0, 0.6)
		fade_tw.finished.connect(queue_free)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_collected:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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

	if get_node_or_null("/root/AudioManager"):
		if ResourceLoader.exists("res://Audio/SFX/points.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/points.ogg"))
		elif ResourceLoader.exists("res://Audio/SFX/match.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/match.ogg"))

	# Fly smoothly towards Sun Bank in top-left
	var cam = get_viewport().get_camera_2d()
	var world_target = target_ui_pos
	if cam:
		world_target = cam.get_screen_center_position() - (get_viewport_rect().size * 0.5) + target_ui_pos

	var tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_position", world_target, 0.55)
	tw.tween_property(self, "scale", Vector2(0.25, 0.25), 0.55)
	tw.chain().tween_callback(queue_free)
