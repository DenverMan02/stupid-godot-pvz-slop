extends Node2D
class_name ZombieParticle

## Lightweight physics particle for zombie body parts and armor (arm, cone, head)
## Matches PvZ2 ZombieParticle bounce physics and fade-out behavior without extra node bloat.

enum ParticleType {
	ARM,
	CONE
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

	# Accurate matrices from particle_arm.xml with pivot centered:
	# Lower arm: a=0.9852, b=0.1712, c=-0.1712, d=0.9852, tx=0.75, ty=-18.75
	# Hand: a=0.9661, b=-0.2580, c=0.2580, d=0.9661, tx=-13.15, ty=15.55
	_draw_entries.clear()
	if tex_lower:
		var xform_lower = Transform2D(Vector2(0.9852, 0.1712), Vector2(-0.1712, 0.9852), Vector2(0.75, -18.75))
		_draw_entries.append([tex_lower, xform_lower])
	if tex_hand:
		var xform_hand = Transform2D(Vector2(0.9661, -0.2580), Vector2(0.2580, 0.9661), Vector2(-13.15, 15.55))
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
		var xform = Transform2D(0.0, -Vector2(tex_cone.get_width() * 0.5, tex_cone.get_height() * 0.5))
		_draw_entries.append([tex_cone, xform])
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
