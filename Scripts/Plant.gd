extends Node2D
class_name Plant

@onready var sprite: XFLSprite2D = $XFLSprite2D

@export var plant_type: String = "peashooter"
@export var display_name: String = "Peashooter"
@export var row: int = 2
@export var col: int = 1
@export var anim_data_path: String = "res://Assets/Plants/peashooter.anim.json"
@export var textures_base_dir: String = "res://Assets/Plants/peashooter.xfl/library/"
@export var visual_scale: float = 1.0
@export var visual_offset: Vector2 = Vector2.ZERO
@export var max_health: float = 300.0
@export var health: float = 300.0

# Wall-nut properties (4000 HP, 8000 HP armor)
@export var wallnut_has_armor: bool = false
@export var wallnut_armor_health: float = 0.0
@export var wallnut_max_armor_health: float = 8000.0

# Potato Mine state
enum PotatoState {
	UNARMED,
	ARMING,
	ARMED,
	ATTACKING,
	EXPLODED
}
var potato_state: PotatoState = PotatoState.UNARMED
var arm_timer: float = 15.0
var is_prearmed: bool = false
var is_ignored_by_zombies: bool = false
var potatomine_pf_spawns_left: int = 0
var peashooter_pf_firing: bool = false
var peashooter_pf_peas_remaining: int = 0
var peashooter_pf_timer: float = 0.0
var plantfood_glow_material: ShaderMaterial = null

var eaten_timer: float = 0.0

func _set_plantfood_glow(enabled: bool) -> void:
	if not sprite:
		return
	if enabled:
		if plantfood_glow_material == null:
			if ResourceLoader.exists("res://Shaders/plantfood_glow.gdshader"):
				var shader_res = load("res://Shaders/plantfood_glow.gdshader")
				plantfood_glow_material = ShaderMaterial.new()
				plantfood_glow_material.shader = shader_res
		if plantfood_glow_material:
			plantfood_glow_material.set_shader_parameter("effect_enabled", true)
			plantfood_glow_material.set_shader_parameter("params", Color(0.4, 1.0, 0.45, 0.65))
			plantfood_glow_material.set_shader_parameter("intensity", 0.8)
			sprite.material = plantfood_glow_material
	else:
		if sprite.material == plantfood_glow_material:
			sprite.material = null


func setup_prearmed() -> void:
	is_prearmed = true
	potato_state = PotatoState.ARMED
	if sprite:
		sprite.play("plantfood2", false)

func take_damage(amount: float, is_bite: bool = false) -> void:
	if plant_type == "wallnut":
		_take_damage_wallnut(amount, is_bite)
		return

	health -= amount
	if is_bite:
		# When being eaten, always remain lighter on sprite
		eaten_timer = 0.2
		if sprite:
			sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
	else:
		# Flash bright white on normal hit
		if sprite:
			sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
			var tw = create_tween()
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.08)

	if health <= 0.0:
		queue_free()

func _take_damage_wallnut(amount: float, is_bite: bool) -> void:
	if is_bite:
		eaten_timer = 0.2
		if sprite:
			sprite.modulate = Color(1.5, 1.5, 1.5, 1.0)
	else:
		if sprite:
			sprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
			var tw = create_tween()
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.08)

	# 1. Armor absorbs damage first (8000 HP, 3 degrades)
	if wallnut_has_armor and wallnut_armor_health > 0.0:
		var dmg_to_armor = minf(wallnut_armor_health, amount)
		var excess_dmg = amount - dmg_to_armor
		wallnut_armor_health -= dmg_to_armor
		if wallnut_armor_health > 0.0:
			var stage = clamp(int((1.0 - (wallnut_armor_health / wallnut_max_armor_health)) * 3), 0, 2)
			if sprite:
				sprite.set_plantfood_armor(true, stage)
		else:
			wallnut_has_armor = false
			wallnut_armor_health = 0.0
			if sprite:
				sprite.set_plantfood_armor(false, 0)
		if excess_dmg > 0.0:
			_apply_wallnut_body_damage(excess_dmg)
	else:
		_apply_wallnut_body_damage(amount)

func _apply_wallnut_body_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		queue_free()
		return
	_update_wallnut_degrade_anim()

func _update_wallnut_degrade_anim() -> void:
	if is_in_plantfood_sequence:
		return
	var target_anim = "idle"
	if health > max_health * 0.75: # > 3000 HP
		# 1 in 50 chance to play water animation when healthy
		if sprite and sprite.has_animation("water") and randi_range(1, 50) == 1:
			sprite.play("water", false)
			return
		if idle_animations.size() > 1:
			target_anim = idle_animations[current_idle_index]
		else:
			target_anim = "idle"
	elif health > max_health * 0.50: # 2000 - 3000 HP
		target_anim = "damage"
	elif health > max_health * 0.25: # 1000 - 2000 HP
		target_anim = "damage2"
	else: # 0 - 1000 HP
		target_anim = "damage3"

	if sprite and (sprite.current_animation != target_anim or not sprite.is_playing):
		var should_loop = (target_anim in ["damage", "damage2", "damage3"] or idle_animations.size() == 1)
		sprite.play(target_anim, should_loop)

## Custom idle mappings for plants with oddly named idle animations or specific idle states
const IDLE_MAP: Dictionary = {
	"wallnut": ["idle", "idle2"],
}

var idle_animations: Array[String] = []
var current_idle_index: int = 0
var is_performing_action: bool = false

var plantfood_sequence: Array[String] = []
var plantfood_sequence_index: int = 0
var is_in_plantfood_sequence: bool = false

var sun_scene: PackedScene = preload("res://Scenes/Sun.tscn")
var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var sunflower_timer: float = 7.0
var attack_timer: float = 0.0
var target_zombie_for_shot: Node2D = null

func _process(delta: float) -> void:
	# Despawn if >500px outside screen in any direction
	if global_position.x < -266.0 or global_position.x > 2654.0 or global_position.y < -500.0 or global_position.y > 1580.0:
		queue_free()
		return

	if eaten_timer > 0.0:
		eaten_timer -= delta
		if eaten_timer <= 0.0:
			if sprite:
				sprite.modulate = Color.WHITE

	var lawn = get_tree().current_scene
	var level_started = lawn.get("level_started") if (lawn and "level_started" in lawn) else true
	if not level_started:
		return

	# Sunflower sun production
	if plant_type == "sunflower" and not is_performing_action:
		sunflower_timer -= delta
		if sunflower_timer <= 0.0:
			sunflower_timer = 24.0
			_produce_sun()

	# Peashooter plant food continuous firing: 60 peas in 2 seconds
	if plant_type == "peashooter" and peashooter_pf_firing:
		peashooter_pf_timer -= delta
		while peashooter_pf_timer <= 0.0 and peashooter_pf_peas_remaining > 0:
			peashooter_pf_timer += 2.0 / 60.0
			_spawn_pea_projectile()
			peashooter_pf_peas_remaining -= 1

		if peashooter_pf_peas_remaining <= 0:
			peashooter_pf_firing = false
			if sprite and sprite.has_animation("plantfood_off"):
				sprite.play("plantfood_off", false)
			else:
				is_in_plantfood_sequence = false
				is_performing_action = false
				_set_plantfood_glow(false)
				_play_current_idle()

	# Peashooter and Cabbage-pult lane targeting & attacking
	elif (plant_type == "peashooter" or plant_type == "cabbagepult") and not is_performing_action and not is_in_plantfood_sequence:
		var target = _find_zombie_in_row()
		if target:
			attack_timer -= delta
			if attack_timer <= 0.0:
				var cooldown_time = 1.425 if plant_type == "peashooter" else 2.85
				attack_timer = cooldown_time
				target_zombie_for_shot = target
				play_attack()
		else:
			# Keep attack timer nearly primed so it reacts quickly when a zombie enters the lane
			attack_timer = min(attack_timer, 0.2)

	# Potato Mine arming & zombie trigger
	elif plant_type == "potatomine" and not is_in_plantfood_sequence:
		if potato_state == PotatoState.UNARMED:
			arm_timer -= delta
			if arm_timer <= 0.0:
				potato_state = PotatoState.ARMING
				if sprite:
					sprite.play("recover", false)
		elif potato_state == PotatoState.ARMED and not is_performing_action:
			var target_z = _find_zombie_for_mine()
			if target_z:
				potato_state = PotatoState.ATTACKING
				is_ignored_by_zombies = true
				is_performing_action = true
				if sprite:
					sprite.play("attack", false)

func _find_zombie_for_mine() -> Node2D:
	var lawn = get_tree().current_scene
	if not lawn:
		return null
	var zombies_node = lawn.get_node_or_null("Zombies")
	if not zombies_node:
		return null

	for z in zombies_node.get_children():
		if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion() and z.health > 0.0:
			if z.row == row:
				var dist_x = z.global_position.x - global_position.x
				if dist_x >= -45.0 and dist_x <= 70.0:
					return z
	return null

func _find_zombie_in_row() -> Node2D:
	var lawn = get_tree().current_scene
	if not lawn:
		return null
	var zombies_node = lawn.get_node_or_null("Zombies")
	if not zombies_node:
		return null

	var closest_zombie: Node2D = null
	var min_dist: float = 999999.0

	for z in zombies_node.get_children():
		if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion():
			if z.row == row and z.health > 0.0 and z.global_position.x > (global_position.x - 30.0):
				var dist = z.global_position.x - global_position.x
				if dist < min_dist:
					min_dist = dist
					closest_zombie = z

	return closest_zombie

func _produce_sun() -> void:
	play_attack()
	get_tree().create_timer(0.8).timeout.connect(Callable(self, "_spawn_sun_at_plant"))

func _spawn_sun_at_plant() -> void:
	var sun_inst: Sun = sun_scene.instantiate()
	var lawn = get_tree().current_scene
	if lawn:
		var suns_container = lawn.get_node_or_null("Suns")
		if suns_container:
			suns_container.add_child(sun_inst)
		else:
			lawn.add_child(sun_inst)
		sun_inst.spawn_from_sunflower(global_position)
		sun_inst.collected.connect(func(val):
			if lawn.has_method("add_sun"):
				lawn.add_sun(val)
		)

func _ready() -> void:
	health = max_health
	if sprite:
		sprite.scale = Vector2(visual_scale, visual_scale)
		sprite.position = visual_offset

		if not anim_data_path.is_empty():
			sprite.anim_data_path = anim_data_path
			sprite.textures_base_dir = textures_base_dir
			sprite.autoplay = false
			sprite._load_resources()

		sprite.anim_event.connect(_on_anim_event)
		sprite.anim_finished.connect(_on_anim_finished)

		if plant_type == "potatomine":
			_setup_potatomine()
		else:
			_setup_idle_animations()
			_play_current_idle()

func _setup_potatomine() -> void:
	idle_animations = ["idle", "idle2"]
	current_idle_index = 0
	if is_prearmed:
		potato_state = PotatoState.ARMED
		is_ignored_by_zombies = false
		if sprite:
			sprite.play("plantfood2", false)
	else:
		potato_state = PotatoState.UNARMED
		is_ignored_by_zombies = false
		arm_timer = 15.0
		if sprite:
			sprite.play("plant", false)

func configure_plant(type_id: String, disp_name: String, anim_json: String, tex_dir: String, v_scale: float = 1.0, v_offset: Vector2 = Vector2.ZERO) -> void:
	plant_type = type_id
	display_name = disp_name
	anim_data_path = anim_json
	textures_base_dir = tex_dir
	visual_scale = v_scale
	visual_offset = v_offset
	if sprite:
		sprite.scale = Vector2(v_scale, v_scale)
		sprite.position = v_offset
		sprite.set_animation_source(anim_json, tex_dir)
		_setup_idle_animations()
		_play_current_idle()

func _setup_idle_animations() -> void:
	if not sprite:
		return

	idle_animations.clear()
	current_idle_index = 0

	# 1. Check IDLE_MAP for custom overrides
	var key = plant_type.to_lower()
	if IDLE_MAP.has(key):
		var custom_list = IDLE_MAP[key]
		if custom_list is Array:
			for anim_name in custom_list:
				if sprite.has_animation(str(anim_name)):
					idle_animations.append(str(anim_name))
		if not idle_animations.is_empty():
			return

	# 2. Check for standard idles: "idle", "idle2", "idle3", etc.
	var all_anims = sprite.get_animation_names()
	if "idle" in all_anims:
		idle_animations.append("idle")

	var idx: int = 2
	while true:
		var cand = "idle" + str(idx)
		if cand in all_anims:
			idle_animations.append(cand)
			idx += 1
		else:
			break

	# 3. Fallback: check for any animation containing "idle" (e.g. "plant_idle")
	if idle_animations.is_empty():
		for a in all_anims:
			if "idle" in a.to_lower():
				idle_animations.append(a)

	# 4. Final fallback: use default or first available animation
	if idle_animations.is_empty():
		if sprite.has_animation(sprite.default_animation):
			idle_animations.append(sprite.default_animation)
		elif not all_anims.is_empty():
			idle_animations.append(all_anims[0])

func _play_current_idle() -> void:
	if not sprite or idle_animations.is_empty():
		return

	is_performing_action = false
	is_in_plantfood_sequence = false

	if plant_type == "wallnut":
		_update_wallnut_degrade_anim()
		return

	# Potato Mine when unarmed MUST strictly stay in plant_idle
	if plant_type == "potatomine" and potato_state == PotatoState.UNARMED:
		sprite.play("plant_idle", true)
		return

	# 1 in 50 chance to play "water" animation (if available) whenever a new idle is attempted
	if sprite.has_animation("water") and randi_range(1, 50) == 1:
		sprite.play("water", false)
		return

	var anim_name = idle_animations[current_idle_index]
	var should_loop = (idle_animations.size() == 1)
	sprite.play(anim_name, should_loop)

func _on_anim_finished(anim_name: String) -> void:
	if plant_type == "potatomine":
		if anim_name == "plant" or (anim_name == "plant_idle" and potato_state == PotatoState.UNARMED):
			sprite.play("plant_idle", true)
			return
		elif anim_name == "recover":
			potato_state = PotatoState.ARMED
			is_ignored_by_zombies = false
			_play_current_idle()
			return
		elif anim_name == "plantfood2":
			potato_state = PotatoState.ARMED
			is_ignored_by_zombies = false
			_play_current_idle()
			return
		elif anim_name == "attack":
			_explode_potatomine()
			return
		elif anim_name == "plantfood_on":
			_trigger_potatomine_pf_spawn()
			return
		elif anim_name == "plantfood":
			if potatomine_pf_spawns_left > 0:
				_trigger_potatomine_pf_spawn()
			else:
				sprite.play("plantfood_off", false)
			return
		elif anim_name == "plantfood_off":
			is_in_plantfood_sequence = false
			is_performing_action = false
			_set_plantfood_glow(false)
			potato_state = PotatoState.ARMED
			is_ignored_by_zombies = false
			_play_current_idle()
			return

	if plant_type == "peashooter":
		if anim_name == "plantfood_on":
			if sprite:
				sprite.play("plantfood", false)
			return
		elif anim_name == "plantfood":
			if peashooter_pf_firing:
				if sprite:
					sprite.play("plantfood", false)
				return
			else:
				if sprite and sprite.has_animation("plantfood_off"):
					sprite.play("plantfood_off", false)
				else:
					is_in_plantfood_sequence = false
					is_performing_action = false
					_set_plantfood_glow(false)
					_play_current_idle()
				return
		elif anim_name == "plantfood_off":
			is_in_plantfood_sequence = false
			is_performing_action = false
			_set_plantfood_glow(false)
			_play_current_idle()
			return

	if plant_type == "wallnut" and is_in_plantfood_sequence:
		is_in_plantfood_sequence = false
		is_performing_action = false
		_set_plantfood_glow(false)
		if sprite:
			sprite.set_plantfood_armor(true, 0)
			sprite.play("idle", true)
		return

	# 1. Advance through plant food sequence if active
	if is_in_plantfood_sequence:
		plantfood_sequence_index += 1
		if plantfood_sequence_index < plantfood_sequence.size():
			sprite.play(plantfood_sequence[plantfood_sequence_index], false)
			return
		else:
			is_in_plantfood_sequence = false
			is_performing_action = false
			_set_plantfood_glow(false)
			_play_current_idle()
			return

	# 2. Advance through sequential idles if idle completed
	if anim_name in idle_animations:
		if idle_animations.size() > 1:
			current_idle_index = (current_idle_index + 1) % idle_animations.size()
			_play_current_idle()
	else:
		# Finished an attack or single special animation -> resume idle
		_play_current_idle()

func _explode_potatomine() -> void:
	if potato_state == PotatoState.EXPLODED:
		return
	potato_state = PotatoState.EXPLODED

	var lawn = get_tree().current_scene
	if lawn:
		# 1. Spawn explosion animation (SPUDOW!)
		var exp_node = Node2D.new()
		exp_node.global_position = global_position + Vector2(0.0, 10.0)
		exp_node.z_index = (row * 100) + 85
		var exp_spr = XFLSprite2D.new()
		exp_spr.anim_data_path = "res://Assets/Plants/potatomine_explosion.anim.json"
		exp_spr.textures_base_dir = "res://Assets/Plants/potatomine_explosion.xfl/library/"
		exp_spr.autoplay = false
		exp_node.add_child(exp_spr)
		lawn.add_child(exp_node)
		exp_spr._load_resources()
		exp_spr.play("animation", false)
		exp_spr.anim_finished.connect(func(_a):
			if is_instance_valid(exp_node) and not exp_node.is_queued_for_deletion():
				exp_node.queue_free()
		)

		# 2. Damage zombies in range (1800 dmg)
		# Extended slightly more left to catch zombies eating a wallnut on the adjacent tile
		var zombies_node = lawn.get_node_or_null("Zombies")
		if zombies_node:
			for z in zombies_node.get_children():
				if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion() and z.health > 0.0:
					var diff_x = z.global_position.x - global_position.x
					if z.row == row and diff_x >= -145.0 and diff_x <= 110.0:
						if z.has_method("take_damage"):
							z.take_damage(1800.0)

		# 3. Play explosion SFX
		if get_node_or_null("/root/AudioManager"):
			var exp_sfx = "res://Audio/SFX/explosion.ogg"
			if ResourceLoader.exists(exp_sfx):
				AudioManager.play_sfx(load(exp_sfx))

	queue_free()

func _play_potatomine_plantfood() -> void:
	is_performing_action = true
	is_in_plantfood_sequence = true
	_set_plantfood_glow(true)
	potatomine_pf_spawns_left = 2
	if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/plantfood.ogg"):
		AudioManager.play_sfx(load("res://Audio/SFX/plantfood.ogg"))
	sprite.play("plantfood_on", false)

func _trigger_potatomine_pf_spawn() -> void:
	potatomine_pf_spawns_left -= 1
	sprite.play("plantfood", false)

	# Launch potato mine projectile to a random tile
	var lawn = get_tree().current_scene
	if not lawn or not ("grid" in lawn) or not lawn.grid:
		return
	var grid = lawn.grid
	var valid_cells: Array[Vector2i] = []
	for r in range(grid.rows):
		for c in range(grid.columns):
			if not lawn.is_cell_occupied(c, r):
				valid_cells.append(Vector2i(c, r))

	var start_p = global_position + Vector2(0.0, -20.0)
	var proj: Projectile = projectile_scene.instantiate()

	if valid_cells.is_empty():
		proj.setup_potato_launch(start_p, Vector2(global_position.x + 800.0, -300.0), -999, -999)
	else:
		var target_c = valid_cells.pick_random()
		var target_wpos = grid.cell_to_world(target_c.x, target_c.y)
		proj.setup_potato_launch(start_p, target_wpos, target_c.x, target_c.y)
	var proj_container = lawn.get_node_or_null("Projectiles")
	if proj_container:
		proj_container.add_child(proj)
	else:
		lawn.add_child(proj)

## Receives animation events pulsed from the XFL timeline
func _on_anim_event(event_name: String) -> void:
	match event_name:
		"use_action":
			_on_use_action()
		"use_special":
			_on_use_special()
		_:
			push_warning("[%s] Unhandled animation event: %s" % [display_name, event_name])

func _on_use_action() -> void:
	if plant_type == "peashooter":
		if is_in_plantfood_sequence:
			# Plant food rapid shooting is managed by timer in _process
			pass
		else:
			_spawn_pea_projectile()
	elif plant_type == "cabbagepult":
		if is_in_plantfood_sequence:
			_fire_cabbagepult_plantfood()
		else:
			_spawn_cabbage_projectile(target_zombie_for_shot)
	elif plant_type == "sunflower":
		pass
	else:
		if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/click_buy_button.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/click_buy_button.ogg"))

func _spawn_pea_projectile() -> void:
	var lawn = get_tree().current_scene
	if not lawn:
		return
	var proj: Projectile = projectile_scene.instantiate()
	var spawn_pos = global_position + Vector2(28.0, -18.0)
	proj.setup_straight(row, spawn_pos, 20.0)
	var proj_container = lawn.get_node_or_null("Projectiles")
	if proj_container:
		proj_container.add_child(proj)
	else:
		lawn.add_child(proj)

func _spawn_cabbage_projectile(target: Node2D = null) -> void:
	var lawn = get_tree().current_scene
	if not lawn:
		return
	if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
		target = _find_zombie_in_row()

	var target_pos = (target.global_position + Vector2(-20.0, -10.0)) if (target and is_instance_valid(target)) else Vector2(global_position.x + 600.0, global_position.y)
	var proj: Projectile = projectile_scene.instantiate()
	var spawn_pos = global_position + Vector2(10.0, -25.0)
	proj.setup_lobbed(row, spawn_pos, target_pos, target, 40.0, false)
	var proj_container = lawn.get_node_or_null("Projectiles")
	if proj_container:
		proj_container.add_child(proj)
	else:
		lawn.add_child(proj)

func _spawn_cabbage_projectile_at(p_row: int, p_target_pos: Vector2, p_target_zombie: Node2D = null, p_is_giant: bool = false) -> void:
	var lawn = get_tree().current_scene
	if not lawn:
		return
	var proj: Projectile = projectile_scene.instantiate()
	var spawn_pos = global_position + Vector2(10.0, -25.0)
	var dmg = 300.0 if p_is_giant else 40.0
	proj.setup_lobbed(p_row, spawn_pos, p_target_pos, p_target_zombie, dmg, p_is_giant)
	var proj_container = lawn.get_node_or_null("Projectiles")
	if proj_container:
		proj_container.add_child(proj)
	else:
		lawn.add_child(proj)

func _fire_peashooter_plantfood() -> void:
	peashooter_pf_firing = true
	peashooter_pf_peas_remaining = 60
	peashooter_pf_timer = 0.0

func _fire_cabbagepult_plantfood() -> void:
	var lawn = get_tree().current_scene
	if not lawn:
		return
	var zombies_node = lawn.get_node_or_null("Zombies")
	var targets: Array[Node2D] = []
	if zombies_node:
		for z in zombies_node.get_children():
			if z is Zombie and is_instance_valid(z) and not z.is_queued_for_deletion() and z.health > 0.0:
				targets.append(z)

	# Summon all projectiles at once
	if targets.is_empty():
		for i in range(5):
			var r = i
			var fake_target = Vector2(randf_range(1100.0, 1800.0), 300.0 + r * 130.0)
			_spawn_cabbage_projectile_at(r, fake_target, null, true)
	else:
		for tgt in targets:
			var tgt_row = tgt.row if "row" in tgt else row
			var landing_pos = tgt.global_position if is_instance_valid(tgt) else Vector2(1400.0, 500.0)
			_spawn_cabbage_projectile_at(tgt_row, landing_pos, tgt, true)

func _on_use_special() -> void:
	if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/match.ogg"):
		AudioManager.play_sfx(load("res://Audio/SFX/match.ogg"))

## Trigger normal attack / special action
func play_attack() -> void:
	if not sprite:
		return

	var target_anim = ""
	if sprite.has_animation("attack"):
		target_anim = "attack"
	elif sprite.has_animation("special"):
		target_anim = "special"
	elif sprite.has_animation("buff"):
		target_anim = "buff"

	if not target_anim.is_empty():
		is_performing_action = true
		is_in_plantfood_sequence = false
		sprite.play(target_anim, false)
	else:
		push_warning("[%s] No attack/special animation found" % display_name)

## Trigger sequential plant food animation:
## Plays plantfood_on -> plantfood/plantfood_loop -> plantfood2/3 -> plantfood_off in order
func play_plantfood() -> void:
	if not sprite:
		return

	if plant_type == "potatomine":
		_play_potatomine_plantfood()
		return
	elif plant_type == "wallnut":
		health = max_health
		wallnut_has_armor = true
		wallnut_max_armor_health = 8000.0
		wallnut_armor_health = 8000.0
		is_performing_action = true
		is_in_plantfood_sequence = true
		_set_plantfood_glow(true)
		if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/plantfood.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/plantfood.ogg"))
		sprite.play("plantfood_on", false)
		return
	elif plant_type == "peashooter":
		is_performing_action = true
		is_in_plantfood_sequence = true
		_set_plantfood_glow(true)
		_fire_peashooter_plantfood()
		if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/plantfood.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/plantfood.ogg"))
		if sprite.has_animation("plantfood_on"):
			sprite.play("plantfood_on", false)
		else:
			sprite.play("plantfood", false)
		return

	plantfood_sequence.clear()
	plantfood_sequence_index = 0

	var all_anims = sprite.get_animation_names()

	# 1. plantfood_on
	if "plantfood_on" in all_anims:
		plantfood_sequence.append("plantfood_on")

	# 2. plantfood or plantfood_loop
	if "plantfood" in all_anims:
		plantfood_sequence.append("plantfood")
	elif "plantfood_loop" in all_anims:
		plantfood_sequence.append("plantfood_loop")

	# 3. Additional plantfood stages (plantfood2, plantfood3, etc.)
	var p_idx: int = 2
	while true:
		var cand = "plantfood" + str(p_idx)
		if cand in all_anims:
			plantfood_sequence.append(cand)
			p_idx += 1
		else:
			break

	# 4. plantfood_off
	if "plantfood_off" in all_anims:
		plantfood_sequence.append("plantfood_off")

	# Fallback if none of the standard names were found
	if plantfood_sequence.is_empty():
		for a in all_anims:
			if "plantfood" in a.to_lower():
				plantfood_sequence.append(a)

	if not plantfood_sequence.is_empty():
		is_performing_action = true
		is_in_plantfood_sequence = true
		_set_plantfood_glow(true)
		if plant_type == "sunflower":
			for i in range(3):
				get_tree().create_timer(0.3 * (i + 1)).timeout.connect(_spawn_sun_at_plant)
		if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/plantfood.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/plantfood.ogg"))
		sprite.play(plantfood_sequence[0], false)
	else:
		push_warning("[%s] No plantfood animation found" % display_name)

func _input(event: InputEvent) -> void:
	var lawn = get_tree().current_scene
	var is_debug = lawn.get("debug_mode") if (lawn and "debug_mode" in lawn) else false
	if lawn and "seed_bank" in lawn and lawn.seed_bank and lawn.seed_bank.selected_packet != null:
		return

	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position()
		if global_position.distance_to(mouse_pos) < 60.0:
			if event.button_index == MOUSE_BUTTON_LEFT and is_debug:
				play_attack()
			elif event.button_index == MOUSE_BUTTON_MIDDLE:
				play_plantfood()
