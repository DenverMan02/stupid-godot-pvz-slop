extends Node2D
class_name Peashooter

@onready var sprite: XFLSprite2D = $XFLSprite2D

@export var row: int = 2
@export var col: int = 1

func _ready() -> void:
	if sprite:
		sprite.anim_event.connect(_on_anim_event)
		sprite.anim_finished.connect(_on_anim_finished)

## Receives animation events pulsed from the XFL timeline
func _on_anim_event(event_name: String) -> void:
	match event_name:
		"use_action":
			_on_use_action()
		_:
			# Logs a warning if unhandled without crashing
			push_warning("[%s] Unhandled animation event: %s" % [name, event_name])

func _on_use_action() -> void:
	print("[%s] use_action triggered! Shooting pea at row %d, col %d!" % [name, row, col])
	if get_node_or_null("/root/AudioManager"):
		var click_sfx = preload("res://Audio/SFX/click_buy_button.ogg")
		AudioManager.play_sfx(click_sfx)

func _on_anim_finished(anim_name: String) -> void:
	# Return smoothly to idle after attack or plantfood
	if anim_name == "attack" or anim_name == "plantfood":
		sprite.play("idle", true)

## Trigger an attack sequence
func shoot() -> void:
	if sprite and sprite.current_animation != "attack":
		sprite.play("attack", false)

func _input(event: InputEvent) -> void:
	# Can only force attack if debug mode is active
	var lawn = get_tree().current_scene
	var is_debug = lawn.get("debug_mode") if (lawn and "debug_mode" in lawn) else false
	if not is_debug:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		if global_position.distance_to(mouse_pos) < 60.0:
			shoot()
