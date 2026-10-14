extends Node2D
class_name ZombieParticle

## Lightweight physics particle for zombie body parts and armor (arm, cone, head)
## Matches PvZ2 ZombieParticle bounce physics and fade-out behavior without extra node bloat.

enum ParticleType {
	ARM,
	CONE,
	HEAD,
	BUCKET,
	BRICK
}

var particle_type: ParticleType = ParticleType.ARM
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 750.0
var angular_velocity: float = 0.0
var ground_y: float = 0.0
var settled: bool = false

# Static texture cache shared across all particles
static var _tex_cache: Dictionary = {}

var _draw_entries: Array = []

func setup_arm(base_dir: String, p_ground_y: float) -> void:
	particle_type = ParticleType.ARM
	ground_y = p_ground_y
	# Initial toss up and slightly forward/backward as in PvZ2
	velocity = Vector2(randf_range(-70.0, 30.0), randf_range(-260.0, -190.0))
	angular_velocity = randf_range(-6.0, 6.0)

	var path_lower = base_dir.path_join("media/zombie_tutorial_23x41.png")
	var path_hand = base_dir.path_join("media/zombie_tutorial_36x39.png")
	var tex_lower = _get_texture(path_lower)
	var tex_hand = _get_texture(path_hand)

	# Exact composed matrices from particle_arm.xml with 0.78125 bitmap scale and pivot centered:
	_draw_entries.clear()
	var center = Vector2(14.0, 24.0)
	if tex_lower:
		var xform_lower = Transform2D(Vector2(0.769722, 0.133713), Vector2(-0.133713, 0.769722), Vector2(15.1, -4.65) - center)
		_draw_entries.append([tex_lower, xform_lower])
	if tex_hand:
		var xform_hand = Transform2D(Vector2(0.754791, -0.201599), Vector2(0.201599, 0.754791), Vector2(-1.94, 32.21) - center)
		_draw_entries.append([tex_hand, xform_hand])
	queue_redraw()

func setup_cone(base_dir: String, p_ground_y: float, damage_stage: int = 2) -> void:
	particle_type = ParticleType.CONE
	ground_y = p_ground_y
	velocity = Vector2(randf_range(-60.0, 60.0), randf_range(-320.0, -230.0))
	angular_velocity = randf_range(-8.0, 8.0)

	var cone_file = "media/zombie_tutorial_82x82.png" if damage_stage == 2 else ("media/zombie_tutorial_80x83.png" if damage_stage == 1 else "media/zombie_tutorial_80x83_2.png")
	var path_cone = base_dir.path_join(cone_file)
	var tex_cone = _get_texture(path_cone)

	_draw_entries.clear()
	if tex_cone:
		var s = 0.78125
		var w = tex_cone.get_width() * s
		var h = tex_cone.get_height() * s
		var xform = Transform2D(Vector2(s, 0.0), Vector2(0.0, s), -Vector2(w * 0.5, h * 0.5))
		_draw_entries.append([tex_cone, xform])
	queue_redraw()

func setup_bucket(base_dir: String, p_ground_y: float, damage_stage: int = 2) -> void:
	particle_type = ParticleType.BUCKET
	ground_y = p_ground_y
	velocity = Vector2(randf_range(-70.0, 70.0), randf_range(-330.0, -240.0))
	angular_velocity = randf_range(-9.0, 9.0)

	var bucket_file = "media/zombie_tutorial_80x72.png" if damage_stage == 2 else ("media/zombie_tutorial_91x97.png" if damage_stage == 1 else "media/zombie_tutorial_96x97.png")
	var path_bucket = base_dir.path_join(bucket_file)
	var tex_bucket = _get_texture(path_bucket)

	_draw_entries.clear()
	if tex_bucket:
		var s = 0.78125
		var w = tex_bucket.get_width() * s
		var h = tex_bucket.get_height() * s
		var xform = Transform2D(Vector2(s, 0.0), Vector2(0.0, s), -Vector2(w * 0.5, h * 0.5))
		_draw_entries.append([tex_bucket, xform])
	queue_redraw()

func setup_brick(base_dir: String, p_ground_y: float, damage_stage: int = 2) -> void:
	particle_type = ParticleType.BRICK
	ground_y = p_ground_y
	velocity = Vector2(randf_range(-60.0, 60.0), randf_range(-290.0, -200.0))
	angular_velocity = randf_range(-6.0, 6.0)

	var brick_file = "media/zombie_tutorial_76x98.png" if damage_stage == 2 else ("media/zombie_tutorial_108x113.png" if damage_stage == 1 else "media/zombie_tutorial_115x115.png")
	var path_brick = base_dir.path_join(brick_file)
	var tex_brick = _get_texture(path_brick)

	_draw_entries.clear()
	if tex_brick:
		var s = 0.78125
		var w = tex_brick.get_width() * s
		var h = tex_brick.get_height() * s
		var xform = Transform2D(Vector2(s, 0.0), Vector2(0.0, s), -Vector2(w * 0.5, h * 0.5))
		_draw_entries.append([tex_brick, xform])
	queue_redraw()

func setup_head_from_sprite(render_data: Dictionary, p_ground_y: float) -> void:
	particle_type = ParticleType.HEAD
	ground_y = p_ground_y
	velocity = Vector2(randf_range(-90.0, 30.0), randf_range(-310.0, -220.0))
	angular_velocity = randf_range(-7.0, 7.0)

	_draw_entries.clear()
	var center = render_data.get("center", Vector2.ZERO)
	var loaded_tex = render_data.get("loaded_textures", [])
	var slices = render_data.get("slices", [])

	for s in slices:
		var tex_idx = int(s[0])
		if tex_idx < loaded_tex.size():
			var tex = loaded_tex[tex_idx]
			if tex:
				var a = float(s[1])
				var b = float(s[2])
				var c = float(s[3])
				var d = float(s[4])
				var tx = float(s[5]) - center.x
				var ty = float(s[6]) - center.y
				var xform = Transform2D(Vector2(a, b), Vector2(c, d), Vector2(tx, ty))
				_draw_entries.append([tex, xform])

	queue_redraw()

func setup_head(base_dir: String, p_ground_y: float, is_female: bool = false) -> void:
	particle_type = ParticleType.HEAD
	ground_y = p_ground_y
	velocity = Vector2(randf_range(-90.0, 30.0), randf_range(-310.0, -220.0))
	angular_velocity = randf_range(-7.0, 7.0)

	_draw_entries.clear()
	var center = Vector2(36.0, 40.0)

	# 1. Female rear hair if female
	if is_female:
		var tex_hair = _get_texture(base_dir.path_join("media/zombie_tutorial_fem_hair_E.png"))
		if tex_hair:
			var xf = Transform2D(Vector2(0.78125, 0.0), Vector2(0.0, 0.78125), Vector2(4.10, 0.55) - center)
			_draw_entries.append([tex_hair, xf])

	# 2. Skull (image scaled 0.78125)
	var tex_skull = _get_texture(base_dir.path_join("media/zombie_tutorial_82x69.png"))
	if tex_skull:
		var xf = Transform2D(Vector2(0.78125, 0.0), Vector2(0.0, 0.78125), Vector2(3.75, 1.1) - center)
		_draw_entries.append([tex_skull, xf])

	# 3. Pupils
	var tex_pupil = _get_texture(base_dir.path_join("media/zombie_tutorial_7x7.png"))
	if tex_pupil:
		var xf_left = Transform2D(Vector2(0.6328, 0.0), Vector2(0.0, 0.6328), Vector2(11.53, 43.53) - center)
		var xf_right = Transform2D(Vector2(0.8994, 0.0), Vector2(0.0, 0.8994), Vector2(49.20, 40.25) - center)
		_draw_entries.append([tex_pupil, xf_left])
		_draw_entries.append([tex_pupil, xf_right])

	# 4. Jaw (image scaled 0.78125)
	var tex_jaw = _get_texture(base_dir.path_join("media/zombie_tutorial_52x31.png"))
	if tex_jaw:
		var xf = Transform2D(Vector2(0.78125, 0.0), Vector2(0.0, 0.78125), Vector2(17.5, 55.05) - center)
		_draw_entries.append([tex_jaw, xf])

	# 5. Female front hair flap
	if is_female:
		var tex_flap = _get_texture(base_dir.path_join("media/zombie_tutorial_fem_hair_flap_E.png"))
		if tex_flap:
			var xf = Transform2D(Vector2(0.78125, 0.0), Vector2(0.0, 0.78125), Vector2(-5.47, 23.79) - center)
			_draw_entries.append([tex_flap, xf])

	queue_redraw()

static func _get_texture(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		if ResourceLoader.exists(path):
			_tex_cache[path] = load(path)
		else:
			_tex_cache[path] = null
	return _tex_cache[path]

func _process(delta: float) -> void:
	if settled:
		return

	velocity.y += gravity * delta
	global_position += velocity * delta
	rotation += angular_velocity * delta

	# Check ground collision
	if global_position.y >= ground_y:
		global_position.y = ground_y
		if abs(velocity.y) < 70.0:
			settled = true
			velocity = Vector2.ZERO
			angular_velocity = 0.0
			var tw = create_tween()
			tw.tween_interval(1.0)
			tw.tween_property(self, "modulate:a", 0.0, 0.8)
			tw.tween_callback(queue_free)
		else:
			# Bounce dissipation
			velocity.y = -velocity.y * 0.35
			velocity.x *= 0.6
			angular_velocity *= 0.5

func _draw() -> void:
	for entry in _draw_entries:
		var tex = entry[0] as Texture2D
		var xform = entry[1] as Transform2D
		if tex:
			draw_set_transform_matrix(xform)
			draw_texture(tex, Vector2.ZERO)
