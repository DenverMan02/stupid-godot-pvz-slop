extends Node2D
class_name Zombie

enum State {
	WALK,
	EAT,
	DIE
}

@export var max_health: float = 200.0
@export var health: float = 200.0
@export var walk_speed: float = 23.0
@export var bite_damage: float = 100.0 # damage per second
@export var row: int = 2
@export var is_female: bool = false

var current_state: State = State.WALK
var target_plant: Node2D = null
var eat_sfx_timer: float = 0.0

@onready var sprite: XFLSprite2D = $XFLSprite2D
@onready var shadow: Sprite2D = $Shadow

func set_female_variant(val: bool) -> void:
	is_female = val
	var anim_json = "res://Assets/Zombies/zombie_tutorialfem.anim.json" if val else "res://Assets/Zombies/zombie_tutorial.anim.json"
	var tex_dir = "res://Assets/Zombies/zombie_tutorialfem.xfl/library/" if val else "res://Assets/Zombies/zombie_tutorial.xfl/library/"
	if sprite:
		sprite.anim_data_path = anim_json
		sprite.textures_base_dir = tex_dir
		if sprite.is_inside_tree():
			sprite.set_animation_source(anim_json, tex_dir)
			if sprite.is_playing:
				sprite.play(sprite.current_animation, sprite.loop)

func _ready() -> void:
	health = max_health
	if is_female:
		set_female_variant(true)
	if sprite:
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
			if sprite:
				sprite.play("die", false)
			var tw = create_tween()
			tw.tween_interval(1.5)
			tw.tween_property(self, "modulate:a", 0.0, 0.5)
			tw.tween_callback(queue_free)

func take_damage(amount: float) -> void:
	if current_state == State.DIE:
		return
	health -= amount

	# Flash white on hit
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.08)

	if health <= 0.0:
		_set_state(State.DIE)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "die":
		queue_free()
