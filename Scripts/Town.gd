extends Control

## PvZ2 Suburbia Town Map Scene
## Interactive hub providing access to Player House, Dave's Workshop, Taco Park,
## Zen Garden, The Arena, Devour Tower, and Zomboss Test Lab.

const FONT_PATH = "res://Fonts/PvZ2 Regular By Beast and MF.ttf"

var click_sfx: AudioStream = preload("res://Audio/SFX/click_buy_button.ogg")

const BUILDING_METADATA = {
	"Player_House": {
		"name": "Player's House",
		"desc": "Home sweet home! Inspect your collected plants, view player achievements, and manage your defensive lawn setups.",
		"icon": "res://Assets/Town/building_player_house.png"
	},
	"Dave_Workshop": {
		"name": "Crazy Dave's Workshop",
		"desc": "Upgrade tactical gadgets, unlock extra Plant Food slots, craft plant boosts, and tune up Penny for world expeditions!",
		"icon": "res://Assets/Town/building_dave_workshop.png"
	},
	"Taco_Park": {
		"name": "Taco Park",
		"desc": "The bustling heart of Suburbia! Enjoy gourmet hot sauce tacos with Dave to earn daily energy refills and special plant buffs.",
		"icon": "res://Assets/Town/building_taco_park.png"
	},
	"Zen_Garden": {
		"name": "Zen Garden",
		"desc": "Nurture rare sprouts, tend to flowering plants with your watering can, and harvest golden coins and permanent mastery boosts.",
		"icon": "res://Assets/Town/building_zen_garden.png"
	},
	"Arena": {
		"name": "The Arena",
		"desc": "Engage in competitive tournaments! Battle against zombie hordes, climb weekly leagues, and claim champion crowns and mint rewards.",
		"icon": "res://Assets/Town/building_arena.png"
	},
	"Devour_Tower": {
		"name": "Devour Tower",
		"desc": "Climb the perilous endless tower! Test your survival skills against increasingly ruthless waves of exotic zombie invaders.",
		"icon": "res://Assets/Town/building_devour_tower.png"
	},
	"Zomboss_Lab": {
		"name": "Zomboss Test Lab",
		"desc": "Infiltrate Dr. Zomboss' clandestine laboratory. Analyze classified mechanical prototypes and confront rogue robotic bosses!",
		"icon": "res://Assets/Town/building_zomboss_lab.png"
	}
}

var modal_overlay: Control = null
var modal_dialog: Control = null
var modal_title_lbl: Label = null
var modal_icon: TextureRect = null
var modal_desc_lbl: Label = null
var modal_enter_btn: TextureButton = null
var modal_close_btn: TextureButton = null

func _ready() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(AudioManager.title_music)

	_setup_top_hud()
	_setup_building_badges()
	_setup_battle_button()
	_setup_modal()
	_connect_building_buttons()

func _setup_top_hud() -> void:
	var hud = get_node_or_null("TopHUD")
	if not hud:
		return

	# Dark translucent wood banner strip
	var bar_bg = ColorRect.new()
	bar_bg.size = Vector2(1920.0, 90.0)
	bar_bg.color = Color(0.12, 0.08, 0.05, 0.85)
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bar_bg)

	# Left: Player Profile Card
	var profile = HBoxContainer.new()
	profile.position = Vector2(30.0, 10.0)
	profile.size = Vector2(400.0, 70.0)
	profile.add_theme_constant_override("separation", 16)

	var avatar = TextureRect.new()
	avatar.custom_minimum_size = Vector2(70.0, 70.0)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.texture = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/plantfood_button.png")
	profile.add_child(avatar)

	var p_vbox = VBoxContainer.new()
	p_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	p_vbox.add_theme_constant_override("separation", 2)

	var name_lbl = Label.new()
	name_lbl.text = "Crazy Dave"
	_apply_font(name_lbl, 28, Color(1.0, 0.9, 0.2, 1.0), 6)
	p_vbox.add_child(name_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Level 12 • Suburbia Hub"
	_apply_font(sub_lbl, 18, Color(0.85, 0.9, 0.85, 0.9), 4)
	p_vbox.add_child(sub_lbl)

	profile.add_child(p_vbox)
	hud.add_child(profile)

	# Right: Currencies (Coins, Gems, Mints)
	var curr_container = HBoxContainer.new()
	curr_container.position = Vector2(1050.0, 15.0)
	curr_container.size = Vector2(740.0, 60.0)
	curr_container.alignment = BoxContainer.ALIGNMENT_END
	curr_container.add_theme_constant_override("separation", 35)

	_create_currency_badge(curr_container, "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/coin.png", "12,500", Color(1.0, 0.88, 0.2, 1.0))
	_create_currency_badge(curr_container, "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/gem.png", "350", Color(0.3, 0.85, 1.0, 1.0))
	_create_currency_badge(curr_container, "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/mint.png", "85", Color(0.4, 1.0, 0.5, 1.0))

	hud.add_child(curr_container)

	# Top right pause/settings button
	var settings_btn = TextureButton.new()
	settings_btn.name = "SettingsButton"
	settings_btn.position = Vector2(1825.0, 12.0)
	settings_btn.custom_minimum_size = Vector2(65.0, 65.0)
	settings_btn.size = Vector2(65.0, 65.0)
	settings_btn.ignore_texture_size = true
	settings_btn.stretch_mode = TextureButton.STRETCH_SCALE
	settings_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/pause_button.png")
	settings_btn.texture_pressed = load("res://Assets/UI/UI_AlwaysLoaded/hud_ingame/pause_button_down.png")
	settings_btn.focus_mode = Control.FOCUS_NONE
	settings_btn.pressed.connect(_on_settings_button_pressed)
	hud.add_child(settings_btn)

func _create_currency_badge(parent: Control, icon_path: String, amount_text: String, col: Color) -> void:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	if ResourceLoader.exists(icon_path):
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(40.0, 40.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.texture = load(icon_path)
		box.add_child(icon)

	var lbl = Label.new()
	lbl.text = amount_text
	_apply_font(lbl, 24, col, 5)
	box.add_child(lbl)

	parent.add_child(box)

func _setup_building_badges() -> void:
	var buildings_container = get_node_or_null("Buildings")
	if not buildings_container:
		return

	for child in buildings_container.get_children():
		var b_name = child.name
		var data = BUILDING_METADATA.get(b_name, { "name": b_name.replace("_", " ") })
		var display_name = data["name"]

		# Wooden nameplate badge at bottom of building
		var badge = NinePatchRect.new()
		badge.name = "NameBadge"
		badge.texture = load("res://Assets/UI/UI_AlwaysLoaded/Generic/BrownButton.png")
		var w = child.size.x
		badge.size = Vector2(max(w, 220.0), 48.0)
		badge.position = Vector2((child.size.x - badge.size.x) / 2.0, child.size.y - 40.0)
		badge.patch_margin_left = 18
		badge.patch_margin_right = 18
		badge.patch_margin_top = 14
		badge.patch_margin_bottom = 14
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var lbl = Label.new()
		lbl.text = display_name
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		lbl.size = badge.size
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(lbl, 20, Color(1.0, 0.95, 0.75, 1.0), 5)
		badge.add_child(lbl)

		child.add_child(badge)

		# Add hover animations to building button
		var btn = child.get_node_or_null("Button")
		if btn and btn is TextureButton:
			btn.pivot_offset = btn.size / 2.0
			btn.mouse_entered.connect(func():
				var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.22)
			)
			btn.mouse_exited.connect(func():
				var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				tw.tween_property(btn, "scale", Vector2.ONE, 0.18)
			)

func _setup_battle_button() -> void:
	var btn = get_node_or_null("BattleButton")
	if not btn:
		return
	btn.position = Vector2(1540.0, 890.0)
	btn.size = Vector2(330.0, 120.0)
	btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/Generic/PurpleButton.png")
	btn.texture_pressed = load("res://Assets/UI/UI_AlwaysLoaded/Generic/PurpleButton_Down.png")
	btn.pressed.connect(_on_battle_button_pressed)

	var lbl = Label.new()
	lbl.text = "⚔️ BATTLE!"
	lbl.anchors_preset = Control.PRESET_FULL_RECT
	lbl.size = btn.size
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(lbl, 36, Color(1.0, 0.95, 0.2, 1.0), 8)
	btn.add_child(lbl)

	# Gentle pulsing animation for the battle button
	var tw = create_tween().set_loops()
	tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _setup_modal() -> void:
	modal_overlay = get_node_or_null("ComingSoonModal")
	if not modal_overlay:
		modal_overlay = ColorRect.new()
		modal_overlay.name = "ComingSoonModal"
		modal_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		modal_overlay.size = Vector2(1920.0, 1080.0)
		modal_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
		modal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(modal_overlay)

	modal_overlay.visible = false
	modal_overlay.z_index = 200

	# Modal Dialog Box (PvZ2 Dialog asset style)
	modal_dialog = Control.new()
	modal_dialog.name = "Dialog"
	var d_w = 780.0
	var d_h = 490.0
	modal_dialog.size = Vector2(d_w, d_h)
	modal_dialog.position = Vector2((1920.0 - d_w) / 2.0, (1080.0 - d_h) / 2.0)
	modal_dialog.mouse_filter = Control.MOUSE_FILTER_PASS

	var bg_wood = NinePatchRect.new()
	bg_wood.texture = load("res://Assets/UI/UI_AlwaysLoaded_Uncompressed/Dialog_Asset/dialogtexture.png")
	bg_wood.size = Vector2(d_w, d_h)
	bg_wood.patch_margin_left = 60
	bg_wood.patch_margin_right = 60
	bg_wood.patch_margin_top = 60
	bg_wood.patch_margin_bottom = 60
	bg_wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_dialog.add_child(bg_wood)

	var border = NinePatchRect.new()
	border.texture = load("res://Assets/UI/UI_AlwaysLoaded_Uncompressed/Dialog_Asset/dialogborder.png")
	border.size = Vector2(d_w, d_h)
	border.patch_margin_left = 60
	border.patch_margin_right = 60
	border.patch_margin_top = 60
	border.patch_margin_bottom = 60
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_dialog.add_child(border)

	modal_title_lbl = Label.new()
	modal_title_lbl.position = Vector2(30.0, 24.0)
	modal_title_lbl.size = Vector2(d_w - 60.0, 48.0)
	modal_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(modal_title_lbl, 36, Color(1.0, 0.9, 0.2, 1.0), 8)
	modal_dialog.add_child(modal_title_lbl)

	# Building preview icon
	modal_icon = TextureRect.new()
	modal_icon.position = Vector2(60.0, 95.0)
	modal_icon.size = Vector2(260.0, 220.0)
	modal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	modal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	modal_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_dialog.add_child(modal_icon)

	# Building Description text
	modal_desc_lbl = Label.new()
	modal_desc_lbl.position = Vector2(340.0, 95.0)
	modal_desc_lbl.size = Vector2(380.0, 220.0)
	modal_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(modal_desc_lbl, 22, Color(1.0, 1.0, 1.0, 0.95), 5)
	modal_dialog.add_child(modal_desc_lbl)

	# Action Buttons (ENTER & CLOSE)
	var btn_size = Vector2(200.0, 68.0)
	var btn_y = d_h - 90.0

	modal_enter_btn = TextureButton.new()
	modal_enter_btn.size = btn_size
	modal_enter_btn.position = Vector2(160.0, btn_y)
	modal_enter_btn.ignore_texture_size = true
	modal_enter_btn.stretch_mode = TextureButton.STRETCH_SCALE
	modal_enter_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/Generic/PurpleButton.png")
	modal_enter_btn.texture_pressed = load("res://Assets/UI/UI_AlwaysLoaded/Generic/PurpleButton_Down.png")
	modal_enter_btn.focus_mode = Control.FOCUS_NONE
	modal_enter_btn.pressed.connect(_on_enter_building_pressed)
	var enter_lbl = Label.new()
	enter_lbl.text = "ENTER"
	enter_lbl.anchors_preset = Control.PRESET_FULL_RECT
	enter_lbl.size = btn_size
	enter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enter_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(enter_lbl, 26, Color(1.0, 1.0, 1.0, 1.0), 6)
	modal_enter_btn.add_child(enter_lbl)
	modal_dialog.add_child(modal_enter_btn)

	modal_close_btn = TextureButton.new()
	modal_close_btn.size = btn_size
	modal_close_btn.position = Vector2(420.0, btn_y)
	modal_close_btn.ignore_texture_size = true
	modal_close_btn.stretch_mode = TextureButton.STRETCH_SCALE
	modal_close_btn.texture_normal = load("res://Assets/UI/UI_AlwaysLoaded/Generic/BrownButton.png")
	modal_close_btn.texture_pressed = load("res://Assets/UI/UI_AlwaysLoaded/Generic/BrownButton_Down.png")
	modal_close_btn.focus_mode = Control.FOCUS_NONE
	modal_close_btn.pressed.connect(_close_modal)
	var close_lbl = Label.new()
	close_lbl.text = "CLOSE"
	close_lbl.anchors_preset = Control.PRESET_FULL_RECT
	close_lbl.size = btn_size
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_apply_font(close_lbl, 26, Color(1.0, 1.0, 1.0, 1.0), 6)
	modal_close_btn.add_child(close_lbl)
	modal_dialog.add_child(modal_close_btn)

	modal_overlay.add_child(modal_dialog)

func _connect_building_buttons() -> void:
	var buildings_container = get_node_or_null("Buildings")
	if not buildings_container:
		return

	for child in buildings_container.get_children():
		var btn = child.get_node_or_null("Button")
		if btn and btn is BaseButton:
			var b_name = child.name
			btn.pressed.connect(func(): _on_building_clicked(b_name))

func _on_building_clicked(building_name: String) -> void:
	_play_click_sfx()
	var data = BUILDING_METADATA.get(building_name, {
		"name": building_name.replace("_", " "),
		"desc": "This suburban feature will unlock in an upcoming update!",
		"icon": ""
	})
	_show_modal(data["name"], data["desc"], data.get("icon", ""))

func _show_modal(title_text: String, msg_text: String, icon_path: String = "") -> void:
	if modal_title_lbl:
		modal_title_lbl.text = title_text
	if modal_desc_lbl:
		modal_desc_lbl.text = msg_text
	if modal_icon:
		if icon_path != "" and ResourceLoader.exists(icon_path):
			modal_icon.texture = load(icon_path)
			modal_icon.visible = true
		else:
			modal_icon.visible = false
	if modal_overlay:
		modal_overlay.visible = true
		modal_dialog.scale = Vector2(0.85, 0.85)
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(modal_dialog, "scale", Vector2.ONE, 0.22)

func _on_enter_building_pressed() -> void:
	_play_click_sfx()
	if modal_desc_lbl:
		modal_desc_lbl.text = "Dave says:\n'Wabby wabbo! Construction is still underway here, but the blueprints are looking magnificent!'"

func _close_modal() -> void:
	_play_click_sfx()
	if modal_overlay:
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(modal_dialog, "scale", Vector2(0.85, 0.85), 0.15)
		tw.tween_callback(func(): modal_overlay.visible = false)

func _on_battle_button_pressed() -> void:
	_play_click_sfx()
	print("[Town] Battle button pressed! Loading Lawn.tscn...")
	get_tree().change_scene_to_file("res://Scenes/Lawn.tscn")

func _on_settings_button_pressed() -> void:
	_play_click_sfx()
	_show_modal("Game Settings", "Audio, graphics preferences, and community controls will be available here.", "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/pause_button.png")

func _play_click_sfx() -> void:
	if get_node_or_null("/root/AudioManager") and click_sfx:
		AudioManager.play_sfx(click_sfx)

func _apply_font(lbl: Label, font_sz: int, col: Color, outline_sz: int) -> void:
	if ResourceLoader.exists(FONT_PATH):
		lbl.add_theme_font_override("font", load(FONT_PATH))
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	lbl.add_theme_constant_override("outline_size", outline_sz)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and modal_overlay and modal_overlay.visible:
			_close_modal()
