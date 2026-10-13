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

var current_state: State = State.WALK
var target_plant: Node2D = null

@onready var sprite: XFLSprite2D = $XFLSprite2D
@onready var shadow: Sprite2D = $Shadow

func _ready() -> void:
	health = max_health
	if sprite:
		sprite.play("walk", true)
		sprite.anim_finished.connect(_on_anim_finished)

func _process(delta: float) -> void:
	var lawn = get_tree().current_scene
	var level_started = lawn.get("level_started") if (lawn and "level_started" in lawn) else true
	if not level_started:
		return

	# Dynamic PvZ2 visual depth ordering
	var lawn_grid = lawn.get_node_or_null("Grid") if lawn else null
	if lawn_grid:
		var cell = lawn_grid.world_to_cell(global_position)
		var col_val = clamp(cell.x, 0, 9)
		z_index = (row * 100) + (col_val * 5) + 3
	else:
		z_index = (row * 100) + 15

	match current_state:
		State.WALK:
			position.x -= walk_speed * delta
			_check_for_plants_to_eat()

		State.EAT:
			if target_plant == null or not is_instance_valid(target_plant):
				target_plant = null
				_set_state(State.WALK)
			else:
				if target_plant.has_method("take_damage"):
					target_plant.take_damage(bite_damage * delta)
				elif "health" in target_plant:
					target_plant.health -= bite_damage * delta
					if target_plant.health <= 0.0:
						target_plant.queue_free()
						target_plant = null
						_set_state(State.WALK)

		State.DIE:
			pass

func _check_for_plants_to_eat() -> void:
	var lawn = get_tree().current_scene
	if not lawn:
		return
	var plants_node = lawn.get_node_or_null("Plants")
	if not plants_node:
		return

	for plant in plants_node.get_children():
		if plant.get("row") == row:
			# Check distance to plant
			var dist_x = global_position.x - plant.global_position.x
			# Zombie attacks when slightly in front of plant (dist_x between 0 and 40)
			if dist_x >= -10.0 and dist_x <= 35.0:
				target_plant = plant
				_set_state(State.EAT)
				break

func _set_state(new_state: State) -> void:
	if current_state == new_state or current_state == State.DIE:
		return
	current_state = new_state

	match current_state:
		State.WALK:
			if sprite:
				sprite.play("walk", true)
		State.EAT:
			if sprite:
				sprite.play("eat", true)
			if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/chomp.ogg"):
				AudioManager.play_sfx(load("res://Audio/SFX/chomp.ogg"))
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
	
	# Damage flash
	modulate = Color(1.5, 0.6, 0.6, 1.0)
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)

	if health <= 0.0:
		_set_state(State.DIE)

func _on_anim_finished(anim_name: String) -> void:
	if anim_name == "die":
		queue_free()
