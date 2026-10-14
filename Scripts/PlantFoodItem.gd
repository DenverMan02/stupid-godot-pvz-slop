extends Node2D
class_name PlantFoodItem

signal collected

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

var is_collected: bool = false
var ground_y: float = 0.0
var despawn_timer: float = 16.0

func _ready() -> void:
	ground_y = position.y
	# Pop up arc
	var tw = create_tween().set_parallel(false)
	var peak_y = ground_y - 65.0
	tw.tween_property(self, "position:y", peak_y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", ground_y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(_start_idle_bob)

	if area:
		area.input_event.connect(_on_input_event)

func _start_idle_bob() -> void:
	if is_collected:
		return
	var tw = create_tween().set_loops()
	tw.tween_property(sprite, "position:y", -8.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _process(delta: float) -> void:
	if is_collected:
		return
	despawn_timer -= delta
	if despawn_timer <= 0.0:
		# Auto collect so player never permanently misses dropped plant food
		collect()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_collected:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect()

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit()

	if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/plantfood.ogg"):
		AudioManager.play_sfx(load("res://Audio/SFX/plantfood.ogg"))

	# Fly toward HUD Plant Food Bank at bottom left
	var lawn = get_tree().current_scene
	var target_pos = Vector2(80.0, 980.0)
	if lawn and lawn.has_node("HUD/PlantFoodBank"):
		target_pos = lawn.get_node("HUD/PlantFoodBank").global_position + Vector2(60.0, 50.0)

	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "global_position", target_pos, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "scale", Vector2(0.4, 0.4), 0.55)
	tw.finished.connect(func():
		if lawn and lawn.has_method("add_plant_food"):
			lawn.add_plant_food(1)
		queue_free()
	)
