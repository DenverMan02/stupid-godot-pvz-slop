extends Node2D
class_name PlantFoodItem

signal collected

@onready var sprite: Sprite2D = $Sprite2D
@onready var area: Area2D = $Area2D

var xfl_sprite: XFLSprite2D = null
var is_collected: bool = false
var ground_y: float = 0.0
var despawn_timer: float = 16.0

func _ready() -> void:
	ground_y = position.y
	_setup_sprite()
	# Pop up arc
	var tw = create_tween().set_parallel(false)
	var peak_y = ground_y - 65.0
	tw.tween_property(self, "position:y", peak_y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", ground_y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(_start_idle_bob)

	if area:
		area.input_event.connect(_on_input_event)

func _setup_sprite() -> void:
	var pf_json = "res://Assets/Misc/LevelCommon/resource/images/initial/effects/plantfood_pickup/plantfood_pickup.anim.json"
	var pf_tex = "res://Assets/Misc/LevelCommon/resource/images/initial/effects/plantfood_pickup/plantfood_pickup.xfl/library/"
	if ResourceLoader.exists(pf_json):
		var spr_node = get_node_or_null("Sprite2D")
		if spr_node:
			spr_node.visible = false
		xfl_sprite = XFLSprite2D.new()
		xfl_sprite.name = "XFLSprite2D"
		xfl_sprite.anim_data_path = pf_json
		xfl_sprite.textures_base_dir = pf_tex
		xfl_sprite.scale = Vector2(0.85, 0.85)
		xfl_sprite.autoplay = false
		add_child(xfl_sprite)
		xfl_sprite._load_resources()
		xfl_sprite.play("idle", true)

func _start_idle_bob() -> void:
	if is_collected:
		return
	var target_node = xfl_sprite if xfl_sprite else sprite
	if target_node:
		var tw = create_tween().set_loops()
		tw.tween_property(target_node, "position:y", -8.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(target_node, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
	tw.finished.connect(_on_fly_finished)

func _on_fly_finished() -> void:
	var l = get_tree().current_scene if get_tree() else null
	if l and l.has_method("add_plant_food"):
		l.add_plant_food(1)
	queue_free()
