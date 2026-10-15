extends Node2D
class_name LawnMower

enum State {
	READY,
	TRIGGERED,
	FINISHED
}

@export var row: int = 0
@export var speed: float = 650.0

var state: State = State.READY
var sprite: XFLSprite2D = null

func _ready() -> void:
	z_index = 40 + row * 10
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = XFLSprite2D.new()
	sprite.name = "XFLSprite2D"
	sprite.anim_data_path = "res://Assets/Mowers/mower_modern.anim.json"
	sprite.textures_base_dir = "res://Assets/Mowers/mower_modern.xfl/library/"
	sprite.scale = Vector2(0.9, 0.9)
	sprite.position = Vector2(0.0, 10.0)
	sprite.autoplay = false
	add_child(sprite)
	sprite._load_resources()
	sprite.play("idle", true)

func _process(delta: float) -> void:
	match state:
		State.READY:
			_check_zombie_trigger()
		State.TRIGGERED:
			_move_and_mow(delta)

func _check_zombie_trigger() -> void:
	var lawn = get_tree().current_scene
	if not lawn:
		return
	var zombies_container = lawn.get_node_or_null("Zombies")
	if not zombies_container:
		return

	for z in zombies_container.get_children():
		if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion() and z.health > 0.0:
			if z.row == row:
				# Trigger when zombie approaches the lawnmower
				if z.global_position.x <= (global_position.x + 60.0):
					trigger()
					break

func trigger() -> void:
	if state != State.READY:
		return
	state = State.TRIGGERED
	print("[LawnMower] Row %d mower TRIGGERED!" % row)
	if get_node_or_null("/root/AudioManager"):
		if ResourceLoader.exists("res://Audio/SFX/speed_up.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/speed_up.ogg"))
	if sprite:
		if sprite.has_animation("attack"):
			sprite.play("attack", true)
		elif sprite.has_animation("transition"):
			sprite.play("transition", false)

func _move_and_mow(delta: float) -> void:
	position.x += speed * delta

	# Check collisions with zombies in this row
	var lawn = get_tree().current_scene
	if lawn:
		var zombies_container = lawn.get_node_or_null("Zombies")
		if zombies_container:
			for z in zombies_container.get_children():
				if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion() and z.health > 0.0:
					if z.row == row:
						var dist_x = z.global_position.x - global_position.x
						if dist_x >= -60.0 and dist_x <= 75.0:
							_mow_zombie(z)

	# Exited screen
	if global_position.x > 2400.0:
		state = State.FINISHED
		queue_free()

func _mow_zombie(z: Zombie) -> void:
	print("[LawnMower] Mowing down zombie at x=%.1f" % z.global_position.x)
	z.take_damage(99999.0)
	if get_node_or_null("/root/AudioManager"):
		if ResourceLoader.exists("res://Audio/SFX/metalhit_2.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/metalhit_2.ogg"))
