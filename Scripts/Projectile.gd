extends Node2D
class_name Projectile

enum Trajectory {
	STRAIGHT,
	LOBBED
}

@export var projectile_type: String = "pea" # "pea", "cabbage", or "cabbage_giant"
@export var damage: float = 20.0
@export var speed: float = 700.0
@export var row: int = 2
@export var trajectory: Trajectory = Trajectory.STRAIGHT

var target_zombie: Node2D = null
var target_cell: Vector2i = Vector2i.ZERO
var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var lob_time: float = 0.0
var lob_duration: float = 0.65
var arc_height: float = 180.0
var has_hit: bool = false
var prev_pos_x: float = 0.0

@onready var sprite: XFLSprite2D = $XFLSprite2D

func _ready() -> void:
	_apply_sprite_config()

func _apply_sprite_config() -> void:
	if not sprite:
		return
	if projectile_type == "pea":
		sprite.scale = Vector2(0.7, 0.7)
		z_index = (row * 100) + 65
		sprite.set_animation_source("res://Assets/Projectiles/t_pea_projectile.anim.json", "res://Assets/Projectiles/T_pea_projectile.xfl/library/")
		sprite.play("animation", true)
	elif projectile_type == "cabbage":
		sprite.scale = Vector2(0.75, 0.75)
		z_index = 600 # Lobbed projectiles fly high over the lawn
		sprite.set_animation_source("res://Assets/Projectiles/t_cabbagepult_projectile.anim.json", "res://Assets/Projectiles/T_cabbagepult_projectile.xfl/library/")
		sprite.play("animation", true)
	elif projectile_type == "cabbage_giant":
		sprite.scale = Vector2(0.85, 0.85)
		z_index = 650
		sprite.set_animation_source("res://Assets/Projectiles/cabbagepult_plantfood_projectile.anim.json", "res://Assets/Projectiles/cabbagepult_plantfood_projectile.xfl/library/")
		sprite.play("plantfood_cabbage", true)
	elif projectile_type == "potato_pf":
		sprite.scale = Vector2(0.85, 0.85)
		z_index = 650
		sprite.set_animation_source("res://Assets/Plants/potatomine.anim.json", "res://Assets/Plants/potatomine.xfl/library/")
		sprite.play("plantfood3", true)

func setup_straight(p_row: int, p_pos: Vector2, p_damage: float = 20.0) -> void:
	trajectory = Trajectory.STRAIGHT
	projectile_type = "pea"
	row = p_row
	global_position = p_pos
	prev_pos_x = p_pos.x
	damage = p_damage
	if is_node_ready():
		_apply_sprite_config()

func setup_lobbed(p_row: int, p_start: Vector2, p_target: Vector2, p_target_zombie: Node2D = null, p_damage: float = 40.0, p_is_giant: bool = false) -> void:
	trajectory = Trajectory.LOBBED
	projectile_type = "cabbage_giant" if p_is_giant else "cabbage"
	row = p_row
	global_position = p_start
	start_pos = p_start
	target_pos = p_target
	target_zombie = p_target_zombie
	damage = p_damage
	lob_time = 0.0

	var dist = abs(target_pos.x - start_pos.x)
	lob_duration = clamp(dist / 650.0, 0.45, 0.95)
	arc_height = clamp(dist * 0.35, 120.0, 260.0)
	if p_is_giant:
		arc_height = clamp(dist * 0.45, 180.0, 360.0)

	if is_node_ready():
		_apply_sprite_config()

func setup_potato_launch(p_start: Vector2, p_target: Vector2, p_col: int, p_row: int) -> void:
	trajectory = Trajectory.LOBBED
	projectile_type = "potato_pf"
	row = p_row
	target_cell = Vector2i(p_col, p_row)
	global_position = p_start
	start_pos = p_start
	target_pos = p_target
	lob_time = 0.0
	lob_duration = 0.55 # Faster than cabbage
	arc_height = 200.0
	if is_node_ready():
		_apply_sprite_config()

func _process(delta: float) -> void:
	if has_hit:
		return

	# Despawn if >500px outside screen boundaries
	if global_position.x < -266.0 or global_position.x > 2654.0 or global_position.y < -500.0 or global_position.y > 1580.0:
		queue_free()
		return

	match trajectory:
		Trajectory.STRAIGHT:
			prev_pos_x = global_position.x
			global_position.x += speed * delta
			_check_straight_collision()

		Trajectory.LOBBED:
			lob_time += delta
			var t = clamp(lob_time / lob_duration, 0.0, 1.0)

			# Pure parabolic arc trajectory
			var cur_x = lerp(start_pos.x, target_pos.x, t)
			var cur_y = lerp(start_pos.y, target_pos.y, t) - (4.0 * arc_height * t * (1.0 - t))
			global_position = Vector2(cur_x, cur_y)

			if t >= 1.0:
				_on_lobbed_land()

func _check_straight_collision() -> void:
	var lawn = get_tree().current_scene
	if not lawn:
		return
	var zombies_node = lawn.get_node_or_null("Zombies")
	if not zombies_node:
		return

	for z in zombies_node.get_children():
		if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion():
			if z.row == row and z.health > 0.0:
				var z_x = z.global_position.x
				# Swept collision: checks if pea crossed or is within zombie impact zone
				if (global_position.x >= z_x - 35.0 and prev_pos_x <= z_x + 35.0) or abs(global_position.x - z_x) < 35.0:
					_hit_zombie(z)
					return

func _on_lobbed_land() -> void:
	if has_hit:
		return

	if projectile_type == "potato_pf":
		_on_potato_land()
		return

	# If target zombie is at landing spot, hit it directly
	if target_zombie and is_instance_valid(target_zombie) and not target_zombie.is_queued_for_deletion():
		if target_zombie.health > 0.0 and abs(global_position.x - target_zombie.global_position.x) < 65.0:
			_hit_zombie(target_zombie)
			return

	# Otherwise, check if any zombie in that row is nearby the impact point
	var lawn = get_tree().current_scene
	if lawn:
		var zombies_node = lawn.get_node_or_null("Zombies")
		if zombies_node:
			for z in zombies_node.get_children():
				if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion():
					if z.row == row and z.health > 0.0:
						if abs(global_position.x - z.global_position.x) < 65.0:
							_hit_zombie(z)
							return

	# If no zombie hit, still splat on the ground
	_spawn_splat_effect()
	queue_free()

func _hit_zombie(z: Node2D) -> void:
	if has_hit:
		return
	has_hit = true

	# Deal damage
	if z.has_method("take_damage"):
		z.take_damage(damage)
	elif "health" in z:
		z.health -= damage
		if z.health <= 0.0:
			z.queue_free()

	# Play impact sound
	_play_hit_sfx()

	# Spawn visual splat effect
	_spawn_splat_effect()

	queue_free()

func _play_hit_sfx() -> void:
	if get_node_or_null("/root/AudioManager"):
		var sfx_name = "res://Audio/SFX/hurting.ogg" if randf() < 0.5 else "res://Audio/SFX/hurting_2.ogg"
		if ResourceLoader.exists(sfx_name):
			AudioManager.play_sfx(load(sfx_name))

func _spawn_splat_effect() -> void:
	var lawn = get_tree().current_scene
	if not lawn:
		return

	if projectile_type == "cabbage":
		var splat = Node2D.new()
		splat.global_position = global_position
		splat.z_index = (row * 100) + 75

		var spr = XFLSprite2D.new()
		spr.anim_data_path = "res://Assets/Projectiles/splat_cabbagepult.anim.json"
		spr.textures_base_dir = "res://Assets/Projectiles/splat_cabbagepult.xfl/library/"
		spr.autoplay = false
		splat.add_child(spr)
		lawn.add_child(splat)

		spr._load_resources()
		spr.play("animation", false)
		spr.anim_finished.connect(func(_a): splat.queue_free())
		get_tree().create_timer(0.4).timeout.connect(func():
			if is_instance_valid(splat):
				splat.queue_free()
		)
	elif projectile_type == "cabbage_giant":
		var splat = Node2D.new()
		splat.global_position = global_position
		splat.z_index = (row * 100) + 75

		var spr = XFLSprite2D.new()
		spr.anim_data_path = "res://Assets/Projectiles/cabbagepult_plantfood_projectile.anim.json"
		spr.textures_base_dir = "res://Assets/Projectiles/cabbagepult_plantfood_projectile.xfl/library/"
		spr.autoplay = false
		splat.add_child(spr)
		lawn.add_child(splat)

		spr._load_resources()
		spr.play("plantfood_cabbageExplode", false)
		spr.anim_finished.connect(func(_a): splat.queue_free())
		get_tree().create_timer(0.6).timeout.connect(func():
			if is_instance_valid(splat):
				splat.queue_free()
		)

func _on_potato_land() -> void:
	if has_hit:
		return

	var lawn = get_tree().current_scene
	if not lawn:
		has_hit = true
		queue_free()
		return

	# If target cell is already occupied, bounce to another unoccupied tile or launch off-screen
	if lawn.has_method("is_cell_occupied") and lawn.is_cell_occupied(target_cell.x, target_cell.y):
		var grid = lawn.get("grid")
		if grid and ("rows" in grid) and ("columns" in grid):
			var unoccupied: Array[Vector2i] = []
			for r in range(grid.rows):
				for c in range(grid.columns):
					if not lawn.is_cell_occupied(c, r):
						unoccupied.append(Vector2i(c, r))

			if not unoccupied.is_empty():
				# Bounce off to another unoccupied cell!
				var new_cell = unoccupied.pick_random()
				start_pos = global_position
				target_cell = new_cell
				target_pos = grid.cell_to_world(new_cell.x, new_cell.y)
				lob_time = 0.0
				lob_duration = 0.55
				arc_height = 120.0
				return
			else:
				# Nowhere for it to go on lawn: launch off-screen to despawn
				start_pos = global_position
				target_pos = Vector2(global_position.x + 800.0, -300.0)
				lob_time = 0.0
				lob_duration = 0.7
				arc_height = 200.0
				target_cell = Vector2i(-999, -999)
				return

	# If targeted off-screen or out-of-bounds, just despawn
	if target_cell.x < 0 or target_cell.y < 0:
		has_hit = true
		queue_free()
		return

	has_hit = true
	if lawn.has_method("spawn_plant_at"):
		var pot_idx = -1
		if "PLANT_REGISTRY" in lawn:
			for i in range(lawn.PLANT_REGISTRY.size()):
				if lawn.PLANT_REGISTRY[i]["id"] == "potatomine":
					pot_idx = i
					break
		if pot_idx != -1:
			var spawned = lawn.spawn_plant_at(target_cell.x, target_cell.y, pot_idx)
			if spawned and is_instance_valid(spawned) and spawned.has_method("setup_prearmed"):
				spawned.setup_prearmed()
	queue_free()
