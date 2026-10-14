extends Node2D
class_name Zombie

enum State {
	WALK,
	EAT,
	DIE
}

# Official PvZ2 OBB stats: ZombieTutorialDefault Hitpoints = 190.0
@export var max_health: float = 190.0
@export var health: float = 190.0
@export var walk_speed: float = 33.38
@export var bite_damage: float = 100.0 # damage per second
@export var row: int = 2
@export var is_female: bool = false

# Armor configuration: ConeDefault BaseHealth = 370.0
@export var armor_type: String = "none" # "none" or "cone"
@export var armor_health: float = 0.0
@export var max_armor_health: float = 370.0
@export var has_lost_arm: bool = false

var current_state: State = State.WALK
var target_plant: Node2D = null
var eat_sfx_timer: float = 0.0

@onready var sprite: XFLSprite2D = $XFLSprite2D
@onready var shadow: Sprite2D = $Shadow

func setup_armor(p_armor_type: String) -> void:
	armor_type = p_armor_type
	match armor_type:
		"cone":
			max_armor_health = 370.0
			armor_health = 370.0
		"bucket":
			max_armor_health = 1100.0
			armor_health = 1100.0
		"brick":
			max_armor_health = 2200.0
			armor_health = 2200.0
		_:
			armor_type = "none"
			max_armor_health = 0.0
			armor_health = 0.0
	if sprite:
		sprite.set_armor(armor_type, 0)

func set_female_variant(val: bool) -> void:
	is_female = val
	var anim_json = "res://Assets/Zombies/zombie_tutorialfem.anim.json" if val else "res://Assets/Zombies/zombie_tutorial.anim.json"
	var tex_dir = "res://Assets/Zombies/zombie_tutorialfem.xfl/library/" if val else "res://Assets/Zombies/zombie_tutorial.xfl/library/"
	if sprite:
		sprite.anim_data_path = anim_json
		sprite.textures_base_dir = tex_dir
		if sprite.is_inside_tree():
			sprite.set_animation_source(anim_json, tex_dir)
			var cur_stage = 0
			if max_armor_health > 0.0 and armor_health > 0.0:
				cur_stage = clamp(int((1.0 - (armor_health / max_armor_health)) * 3), 0, 2)
			sprite.set_armor(armor_type if armor_health > 0.0 else "none", cur_stage)
			sprite.has_lost_arm = has_lost_arm
			if sprite.is_playing:
				sprite.play(sprite.current_animation, sprite.loop)

func _ready() -> void:
	health = max_health
	if is_female:
		set_female_variant(true)
	if armor_type != "none":
		setup_armor(armor_type)
	if sprite:
		sprite.has_lost_arm = has_lost_arm
		sprite.play("walk", true)
		sprite.anim_finished.connect(_on_anim_finished)

func _process(delta: float) -> void:
	var lawn = get_tree().current_scene
	var level_started = lawn.get("level_started") if (lawn and "level_started" in lawn) else true
	if not level_started:
		return

	# Despawn if >500px outside screen in any direction
	if global_position.x < -266.0 or global_position.x > 2654.0 or global_position.y < -500.0 or global_position.y > 1580.0:
		queue_free()
		return

	# Dynamic PvZ2 visual depth ordering: zombies ALWAYS render over plants in the same row
	# Plants in row have z_index up to row*100 + 47. Zombies get row*100 + 70 + col_offset.
	var lawn_grid = lawn.get_node_or_null("Grid") if lawn else null
	if lawn_grid:
		var cell = lawn_grid.world_to_cell(global_position)
		var col_val = clamp(cell.x, 0, 9)
		z_index = (row * 100) + 70 + clamp(int(col_val * 2), 0, 20)
	else:
		z_index = (row * 100) + 70

	match current_state:
		State.WALK:
			if sprite and sprite.has_ground_track():
				var g_delta = sprite.consume_ground_delta()
				var mult = 2.0 if position.x > 1788.7 else 1.0
				position.x -= g_delta * mult
			else:
				# 2x walk speed until entering the lawn (x <= 1788.7)
				var cur_speed = (walk_speed * 2.0) if position.x > 1788.7 else walk_speed
				position.x -= cur_speed * delta

			var found = _find_plant_to_eat()
			if found:
				target_plant = found
				_set_state(State.EAT)

		State.EAT:
			# If current target is destroyed, immediately check if another plant is right here
			if target_plant == null or not is_instance_valid(target_plant) or target_plant.is_queued_for_deletion() or (target_plant.get("health") != null and target_plant.health <= 0.0):
				target_plant = _find_plant_to_eat()
				if target_plant == null:
					_set_state(State.WALK)
					return

			# Deal damage every frame
			if target_plant.has_method("take_damage"):
				target_plant.take_damage(bite_damage * delta, true)
			elif "health" in target_plant:
				target_plant.health -= bite_damage * delta
				if target_plant.health <= 0.0:
					target_plant.queue_free()

			# Check if damage killed the plant this frame - seamlessly find next plant without pausing
			if target_plant == null or not is_instance_valid(target_plant) or target_plant.is_queued_for_deletion() or (target_plant.get("health") != null and target_plant.health <= 0.0):
				target_plant = _find_plant_to_eat()
				if target_plant == null:
					_set_state(State.WALK)
					return

			# Play eating SFX every second (randomly eating or eating_2)
			eat_sfx_timer -= delta
			if eat_sfx_timer <= 0.0:
				eat_sfx_timer = randf_range(0.85, 1.15)
				_play_eat_sfx()

		State.DIE:
			pass

func _play_eat_sfx() -> void:
	if get_node_or_null("/root/AudioManager"):
		var sfx_name = "res://Audio/SFX/eating.ogg" if randf() < 0.5 else "res://Audio/SFX/eating_2.ogg"
		if ResourceLoader.exists(sfx_name):
			AudioManager.play_sfx(load(sfx_name))

func _find_plant_to_eat() -> Node2D:
	var lawn = get_tree().current_scene
	if not lawn:
		return null
	var plants_node = lawn.get_node_or_null("Plants")
	if not plants_node:
		return null

	for plant in plants_node.get_children():
		if plant.get("row") == row and is_instance_valid(plant) and not plant.is_queued_for_deletion() and plant.get("health") != null and plant.health > 0.0:
			if plant.get("is_ignored_by_zombies") == true:
				continue
			var dist_x = global_position.x - plant.global_position.x
			# Zombie attacks when within bite reach (dist_x between -10 and 35)
			if dist_x >= -10.0 and dist_x <= 35.0:
				return plant
	return null

func _set_state(new_state: State) -> void:
	if current_state == new_state or current_state == State.DIE:
		return
	current_state = new_state

	match current_state:
		State.WALK:
			if sprite:
				sprite.play("walk", true)
		State.EAT:
			eat_sfx_timer = 0.0 # Trigger initial bite sound promptly
			if sprite:
				sprite.play("eat", true)
		State.DIE:
			if not has_lost_arm and sprite:
				sprite.set_arm_lost(true)
			# Drop head particle on death
			drop_head()
			if sprite:
				sprite.play("die", false)
			var tw = create_tween()
			tw.tween_interval(1.5)
			tw.tween_property(self, "modulate:a", 0.0, 0.5)
			tw.tween_callback(queue_free)

var hurt_tween: Tween = null

func _flash_hurt() -> void:
	if not sprite:
		return
	if hurt_tween and hurt_tween.is_valid():
		hurt_tween.kill()
	sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
	hurt_tween = create_tween()
	hurt_tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)

func take_damage(amount: float) -> void:
	if current_state == State.DIE:
		return

	# Flash white on hit smoothly without tween overlap
	_flash_hurt()

	# 1. Armor absorbs damage first (Cone, Bucket, Brick)
	if armor_health > 0.0 and armor_type != "none":
		var dmg_to_armor = minf(armor_health, amount)
		var excess_dmg = amount - dmg_to_armor
		armor_health -= dmg_to_armor

		if armor_health > 0.0:
			# Degradation health ranges based on 3 stages (full, dmg1, dmg2):
			# 100% for full (stage 0), 66.6% for stage 1, 33.3% for stage 2
			var num_stages = 3
			var stage = clamp(int((1.0 - (armor_health / max_armor_health)) * num_stages), 0, num_stages - 1)
			if sprite:
				sprite.set_armor(armor_type, stage)
		else:
			# Armor destroyed! Drop particle
			drop_armor()
			armor_health = 0.0

		if excess_dmg > 0.0:
			_apply_body_damage(excess_dmg)
	else:
		_apply_body_damage(amount)

func _apply_body_damage(amount: float) -> void:
	health -= amount

	# Arm particles dropped at half health specifically (health <= max_health * 0.5)
	if not has_lost_arm and health <= max_health * 0.5:
		drop_arm()

	if health <= 0.0:
		if hurt_tween and hurt_tween.is_valid():
			hurt_tween.kill()
		if sprite:
			sprite.modulate = Color.WHITE
		if armor_health > 0.0:
			drop_armor()
			armor_health = 0.0
		_set_state(State.DIE)

func drop_arm() -> void:
	if has_lost_arm:
		return
	has_lost_arm = true
	if sprite:
		sprite.set_arm_lost(true)

	var tex_dir = sprite.textures_base_dir if sprite else "res://Assets/Zombies/zombie_tutorial.xfl/library/"
	var particle = ZombieParticle.new()
	particle.setup_arm(tex_dir, global_position.y)
	# Shoulder socket offset relative to zombie root
	particle.global_position = global_position + Vector2(5.0, -80.0)
	particle.z_index = z_index + 1

	var target_parent = get_parent() if get_parent() else get_tree().current_scene
	if target_parent:
		target_parent.add_child(particle)

func drop_head() -> void:
	var tex_dir = sprite.textures_base_dir if sprite else "res://Assets/Zombies/zombie_tutorial.xfl/library/"
	var particle = ZombieParticle.new()
	particle.setup_head(tex_dir, global_position.y, is_female)
	# Neck offset relative to zombie root
	particle.global_position = global_position + Vector2(-15.0, -45.0)
	particle.z_index = z_index + 1

	var target_parent = get_parent() if get_parent() else get_tree().current_scene
	if target_parent:
		target_parent.add_child(particle)

func drop_armor() -> void:
	if sprite:
		sprite.set_armor("none", 0)

	var tex_dir = sprite.textures_base_dir if sprite else "res://Assets/Zombies/zombie_tutorial.xfl/library/"
	var particle = ZombieParticle.new()
	match armor_type:
		"cone":
			particle.setup_cone(tex_dir, global_position.y, 2)
		"bucket":
			particle.setup_bucket(tex_dir, global_position.y, 2)
		"brick":
			particle.setup_brick(tex_dir, global_position.y, 2)
		_:
			return

	# Head/armor offset relative to zombie root
	particle.global_position = global_position + Vector2(-15.0, -65.0)
	particle.z_index = z_index + 2

	var target_parent = get_parent() if get_parent() else get_tree().current_scene
	if target_parent:
		target_parent.add_child(particle)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "die":
		queue_free()
