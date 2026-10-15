extends CanvasLayer
class_name AnimationViewer

## In-Game XFL Animation Viewer (Debug Tool)
## Opened via 'A' key when debug mode ('G') is active.
## Allows browsing and inspecting all plant, zombie, projectile, and VFX animations in-engine.

signal closed

var entity_catalog: Array[Dictionary] = []

var cur_entity_idx: int = 0
var cur_anim_idx: int = 0
var anim_list: Array[String] = []
var is_paused: bool = false
var loop_enabled: bool = true

# UI References
var panel: Panel
var preview_sprite: XFLSprite2D
var entity_label: Label
var anim_label: Label
var frame_label: Label
var play_pause_btn: Button
var loop_btn: Button

func _ready() -> void:
	layer = 120
	_scan_and_build_catalog()
	_build_ui()
	_load_entity(0)

func _format_entity_name(raw: String) -> String:
	var clean = raw.replace("_", " ").replace("-", " ")
	var words = clean.split(" ", false)
	var capitalized: Array[String] = []
	for w in words:
		capitalized.append(w.capitalize())
	return " ".join(capitalized)

func _scan_and_build_catalog() -> void:
	entity_catalog.clear()
	var search_dirs = [
		"res://Assets/Plants",
		"res://Assets/Zombies",
		"res://Assets/Mowers",
		"res://Assets/Projectiles",
		"res://Assets/Misc",
		"res://Assets/GridItems",
		"res://Assets/UI"
	]
	for s_dir in search_dirs:
		_scan_dir_recursive(s_dir)
	print("[AnimationViewer] Auto-detected %d entity animations!" % entity_catalog.size())

func _scan_dir_recursive(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path = dir_path + "/" + file_name
		if dir.current_is_dir():
			if not "research purposes" in file_name.to_lower():
				_scan_dir_recursive(full_path)
		elif file_name.ends_with(".anim.json"):
			var base_name = file_name.replace(".anim.json", "")
			var xfl_name = base_name + ".xfl"
			var tex_dir = dir_path + "/" + xfl_name + "/library/"
			if not DirAccess.dir_exists_absolute(tex_dir):
				tex_dir = dir_path + "/" + xfl_name + "/LIBRARY/"
			if not DirAccess.dir_exists_absolute(tex_dir):
				tex_dir = dir_path + "/library/"

			var disp_name = _format_entity_name(base_name)
			var ent_scale = 1.2
			if "zombie" in base_name.to_lower():
				ent_scale = 1.0
			elif "projectile" in base_name.to_lower() or "splat" in base_name.to_lower() or "bullet" in base_name.to_lower():
				ent_scale = 1.5
			elif "mower" in base_name.to_lower():
				ent_scale = 0.9

			entity_catalog.append({
				"name": disp_name,
				"json": full_path,
				"tex": tex_dir,
				"scale": ent_scale,
				"armor": "none"
			})

			if base_name == "zombie_tutorial":
				for arm in ["cone", "bucket", "brick"]:
					entity_catalog.append({
						"name": "%s Zombie" % arm.capitalize(),
						"json": full_path,
						"tex": tex_dir,
						"scale": 1.0,
						"armor": arm
					})
			elif base_name == "wallnut":
				entity_catalog.append({
					"name": "Wall-nut (PF Armor)",
					"json": full_path,
					"tex": tex_dir,
					"scale": 1.2,
					"armor": "wallnut_pf"
				})

		file_name = dir.get_next()
	dir.list_dir_end()

func _build_ui() -> void:
	# Main container panel
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Dark semi-transparent background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.12, 0.88)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Title Banner
	var title = Label.new()
	title.text = "★ IN-GAME XFL ANIMATION VIEWER ★  (Press 'A' or 'ESC' to close)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 20)
	title.size = Vector2(1920, 40)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	panel.add_child(title)

	# Close Button
	var close_btn = Button.new()
	close_btn.text = "✖ Close (A)"
	close_btn.position = Vector2(1740, 20)
	close_btn.size = Vector2(150, 44)
	close_btn.pressed.connect(close_viewer)
	panel.add_child(close_btn)

	# Preview Center Sprite Container
	var center_node = Node2D.new()
	center_node.position = Vector2(960, 520)
	panel.add_child(center_node)

	# Ground reference line
	var ground_marker = Line2D.new()
	ground_marker.points = PackedVector2Array([Vector2(-250, 0), Vector2(250, 0)])
	ground_marker.default_color = Color(0.3, 0.8, 0.3, 0.4)
	ground_marker.width = 3.0
	center_node.add_child(ground_marker)

	preview_sprite = XFLSprite2D.new()
	preview_sprite.autoplay = false
	center_node.add_child(preview_sprite)

	# Bottom Controls Bar
	var bottom_bar = HBoxContainer.new()
	bottom_bar.position = Vector2(160, 920)
	bottom_bar.size = Vector2(1600, 70)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_bar.add_theme_constant_override("separation", 15)
	panel.add_child(bottom_bar)

	# Entity Switcher
	var prev_ent_btn = Button.new()
	prev_ent_btn.text = "◀ Prev Entity"
	prev_ent_btn.custom_minimum_size = Vector2(140, 50)
	prev_ent_btn.pressed.connect(_on_prev_entity)
	bottom_bar.add_child(prev_ent_btn)

	entity_label = Label.new()
	entity_label.custom_minimum_size = Vector2(240, 50)
	entity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	entity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	entity_label.add_theme_font_size_override("font_size", 22)
	entity_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	bottom_bar.add_child(entity_label)

	var next_ent_btn = Button.new()
	next_ent_btn.text = "Next Entity ▶"
	next_ent_btn.custom_minimum_size = Vector2(140, 50)
	next_ent_btn.pressed.connect(_on_next_entity)
	bottom_bar.add_child(next_ent_btn)

	var sep1 = VSeparator.new()
	bottom_bar.add_child(sep1)

	# Animation Switcher
	var prev_anim_btn = Button.new()
	prev_anim_btn.text = "◀ Prev Anim"
	prev_anim_btn.custom_minimum_size = Vector2(130, 50)
	prev_anim_btn.pressed.connect(_on_prev_anim)
	bottom_bar.add_child(prev_anim_btn)

	anim_label = Label.new()
	anim_label.custom_minimum_size = Vector2(220, 50)
	anim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anim_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	anim_label.add_theme_font_size_override("font_size", 22)
	anim_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	bottom_bar.add_child(anim_label)

	var next_anim_btn = Button.new()
	next_anim_btn.text = "Next Anim ▶"
	next_anim_btn.custom_minimum_size = Vector2(130, 50)
	next_anim_btn.pressed.connect(_on_next_anim)
	bottom_bar.add_child(next_anim_btn)

	var sep2 = VSeparator.new()
	bottom_bar.add_child(sep2)

	# Playback Controls
	play_pause_btn = Button.new()
	play_pause_btn.text = "❚❚ Pause"
	play_pause_btn.custom_minimum_size = Vector2(110, 50)
	play_pause_btn.pressed.connect(_on_toggle_play_pause)
	bottom_bar.add_child(play_pause_btn)

	var step_prev_btn = Button.new()
	step_prev_btn.text = "⏮ -1"
	step_prev_btn.custom_minimum_size = Vector2(70, 50)
	step_prev_btn.pressed.connect(func(): _step_frame(-1))
	bottom_bar.add_child(step_prev_btn)

	var step_next_btn = Button.new()
	step_next_btn.text = "+1 ⏭"
	step_next_btn.custom_minimum_size = Vector2(70, 50)
	step_next_btn.pressed.connect(func(): _step_frame(1))
	bottom_bar.add_child(step_next_btn)

	loop_btn = Button.new()
	loop_btn.text = "Loop: ON"
	loop_btn.custom_minimum_size = Vector2(110, 50)
	loop_btn.pressed.connect(_on_toggle_loop)
	bottom_bar.add_child(loop_btn)

	# Frame status display
	frame_label = Label.new()
	frame_label.position = Vector2(0, 840)
	frame_label.size = Vector2(1920, 40)
	frame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame_label.add_theme_font_size_override("font_size", 20)
	frame_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	panel.add_child(frame_label)

func _load_entity(idx: int) -> void:
	if entity_catalog.is_empty():
		return
	cur_entity_idx = posmod(idx, entity_catalog.size())
	var info = entity_catalog[cur_entity_idx]
	entity_label.text = "[%d/%d] %s" % [cur_entity_idx + 1, entity_catalog.size(), info["name"]]

	preview_sprite.scale = Vector2(info["scale"], info["scale"])
	preview_sprite.set_animation_source(info["json"], info["tex"])

	# Apply armor setup if applicable
	var armor = info.get("armor", "none")
	if armor == "wallnut_pf":
		preview_sprite.set_plantfood_armor(true, 0)
	elif armor in ["cone", "bucket", "brick"]:
		preview_sprite.set_armor(armor, 0)
	else:
		preview_sprite.set_plantfood_armor(false, 0)
		preview_sprite.set_armor("none", 0)

	anim_list = preview_sprite.get_animation_names()
	cur_anim_idx = 0
	_play_anim(0)

func _play_anim(idx: int) -> void:
	if anim_list.is_empty():
		anim_label.text = "No Animations"
		return
	cur_anim_idx = posmod(idx, anim_list.size())
	var a_name = anim_list[cur_anim_idx]
	anim_label.text = "[%d/%d] %s" % [cur_anim_idx + 1, anim_list.size(), a_name]
	preview_sprite.play(a_name, loop_enabled)
	is_paused = false
	play_pause_btn.text = "❚❚ Pause"

func _process(_delta: float) -> void:
	if not visible:
		return
	if is_instance_valid(preview_sprite) and preview_sprite.has_animation(preview_sprite.current_animation):
		var anims = preview_sprite._anim_data.get("animations", {})
		var anim_info = anims.get(preview_sprite.current_animation, {})
		var total_f = int(anim_info.get("frame_count", 1))
		frame_label.text = "Frame: %d / %d  |  FPS: %.1f  |  Status: %s" % [
			preview_sprite.current_frame + 1,
			total_f,
			preview_sprite._frame_rate,
			("PAUSED" if is_paused else "PLAYING")
		]

func _on_prev_entity() -> void:
	_load_entity(cur_entity_idx - 1)

func _on_next_entity() -> void:
	_load_entity(cur_entity_idx + 1)

func _on_prev_anim() -> void:
	_play_anim(cur_anim_idx - 1)

func _on_next_anim() -> void:
	_play_anim(cur_anim_idx + 1)

func _on_toggle_play_pause() -> void:
	is_paused = !is_paused
	if is_paused:
		preview_sprite.stop()
		play_pause_btn.text = "▶ Play"
	else:
		preview_sprite.is_playing = true
		play_pause_btn.text = "❚❚ Pause"

func _step_frame(dir: int) -> void:
	is_paused = true
	preview_sprite.stop()
	play_pause_btn.text = "▶ Play"
	var anims = preview_sprite._anim_data.get("animations", {})
	var anim_info = anims.get(preview_sprite.current_animation, {})
	var total_f = int(anim_info.get("frame_count", 1))
	if total_f <= 0:
		return
	preview_sprite.current_frame = posmod(preview_sprite.current_frame + dir, total_f)
	preview_sprite.queue_redraw()

func _on_toggle_loop() -> void:
	loop_enabled = !loop_enabled
	preview_sprite.loop = loop_enabled
	loop_btn.text = "Loop: ON" if loop_enabled else "Loop: OFF"

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A or event.keycode == KEY_ESCAPE:
			close_viewer()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE:
			_on_toggle_play_pause()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT:
			_on_prev_anim()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			_on_next_anim()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP:
			_on_prev_entity()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			_on_next_entity()
			get_viewport().set_input_as_handled()

func close_viewer() -> void:
	visible = false
	closed.emit()
	queue_free()
