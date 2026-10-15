extends Control

## PvZ2 Suburbia Town Map Scene (Neighborville Hub)
## Interactive hub providing access to My House, Crazy Dave's Workshop,
## Zen Garden, Guildhall, Devour Tower, and Deck/Almanac/Guild/Friends.

const FONT_PATH = "res://Fonts/PvZ2 Regular By Beast and MF.ttf"

var click_sfx: AudioStream = preload("res://Audio/SFX/click_buy_button.ogg")

const BUILDING_METADATA = {
	"Player_House": {
		"name": "My House",
		"desc": "Home sweet home! Inspect your collected plants, view player achievements, and manage your defensive lawn setups.",
		"icon": "res://Assets/Town/building_player_house.png"
	},
	"Dave_Workshop": {
		"name": "Crazy Dave's Workshop",
		"desc": "Crazy Dave's tactical workshop! Upgrade plant food slots, tinker with Penny, and craft plant boosts for world expeditions.",
		"icon": "res://Assets/Town/building_dave_workshop.png"
	},
	"Zen_Garden": {
		"name": "Zen Garden",
		"desc": "Nurture rare sprouts, tend to flowering plants with your watering can, and harvest golden coins and permanent mastery boosts.",
		"icon": "res://Assets/Town/building_zen_garden.png"
	},
	"Guildhall": {
		"name": "Guildhall",
		"desc": "Gather with fellow plant defenders, coordinate alliance raids against Dr. Zomboss, and earn exclusive guild trophies.",
		"icon": "res://Assets/Town/building_arena.png"
	},
	"Devour_Tower": {
		"name": "Devour Tower",
		"desc": "Climb the perilous endless tower! Test your survival skills against increasingly ruthless waves of exotic zombie invaders.",
		"icon": "res://Assets/Town/building_devour_tower.png"
	}
}

var modal_overlay: Control = null
var modal_dialog: Control = null
var modal_title_lbl: Label = null
var modal_icon: TextureRect = null
var modal_desc_lbl: Label = null
var modal_enter_btn: TextureButton = null
var modal_close_btn: TextureButton = null

var energy_timer_seconds: int = 255
var timer_lbl: Label = null

var chat_current_tab: String = "WORLD"
var chat_labels_container: VBoxContainer = null
var chat_background: TextureRect = null

const CHAT_MESSAGES = {
	"WORLD": [
		"[color=#9fd944][World][/color] [color=#ffde42]ZombieSlayer_99:[/color] Anyone want to raid Devour Tower?",
		"[color=#9fd944][World][/color] [color=#61c7ff]PlantLover:[/color] Need a group for daily quests!",
		"[color=#9fd944][World][/color] [color=#ff94d2]GamerRose:[/color] Just unlocked Primal Peashooter!"
	],
	"GUILD": [
		"[color=#d974ff][Guild][/color] [color=#ffae42]Dave_Fan:[/color] Meet at the Guildhall for boss battle!",
		"[color=#d974ff][Guild][/color] [color=#9fd944]PeashooterPRO:[/color] Donated 500 guild coins to bank.",
		"[color=#d974ff][Guild][/color] [color=#ffde42]ZombieSlayer_99:[/color] Ready when you all are!"
	]
}

func _ready() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(AudioManager.title_music)

	_setup_concept_render_materials()
	_setup_top_hud()
	_setup_chat_box()
	_setup_bottom_shelf()
	_setup_battle_button()
	_setup_modal()
	_connect_building_buttons()
	_start_energy_timer()

func _setup_concept_render_materials() -> void:
	# Concept renders in Assets/Town/ are transparent PNGs with clean alpha defringing.
	# Any legacy JPGs can fallback to the cutout shader if needed.
	var white_bg_shader = load("res://Scripts/white_background_cutout.gdshader") as Shader
	if not white_bg_shader:
		return

	var building_names = ["Player_House", "Dave_Workshop", "Zen_Garden", "Guildhall", "Devour_Tower"]
	for building_name in building_names:
		var render = get_node_or_null("Buildings/" + building_name + "/Render") as TextureRect
		if render and render.texture and render.texture.resource_path.ends_with(".jpg"):
			var material = ShaderMaterial.new()
			material.shader = white_bg_shader
			material.set_shader_parameter("white_threshold", 0.94)
			material.set_shader_parameter("feather_width", 0.02)
			material.set_shader_parameter("neutral_tolerance", 0.10)
			render.material = material

func _setup_top_hud() -> void:
	var hud = get_node_or_null("TopHUD")
	if not hud:
		return

	# 1. Player Profile Button
	var profile_btn = hud.get_node_or_null("PlayerProfile/ProfileButton")
	if profile_btn:
		profile_btn.pressed.connect(func():
			_play_click_sfx()
			_show_modal("Player Profile", "Level 19 Suburbia Champion • 14 Plants Unlocked • 82 Levels Mastered", "res://Assets/Town/UI/ui_player_profile.png")
		)

	# 2. Energy Bar (Lightning + Bar + Timer)
	var energy_container = hud.get_node_or_null("EnergyBarContainer")
	if energy_container:
		var energy_bg = ColorRect.new()
		energy_bg.size = Vector2(280.0, 48.0)
		energy_bg.position = Vector2(35.0, 10.0)
		energy_bg.color = Color(0.12, 0.08, 0.04, 0.85)
		energy_container.add_child(energy_bg)

		var energy_fill = ColorRect.new()
		energy_fill.size = Vector2(250.0, 40.0)
		energy_fill.position = Vector2(39.0, 14.0)
		energy_fill.color = Color(0.98, 0.78, 0.12, 1.0)
		energy_container.add_child(energy_fill)

		var energy_icon = TextureRect.new()
		energy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		energy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		energy_icon.custom_minimum_size = Vector2(24.0, 35.0)
		energy_icon.size = Vector2(24.0, 35.0)
		energy_icon.position = Vector2(24.0, 16.0)
		energy_icon.texture = load("res://Assets/Town/UI/energy_icon.png")
		energy_container.add_child(energy_icon)
		energy_icon.size = Vector2(24.0, 35.0)
		energy_icon.position = Vector2(24.0, 16.0)

		var energy_lbl = Label.new()
		energy_lbl.text = "45/50"
		energy_lbl.position = Vector2(70.0, 12.0)
		energy_lbl.size = Vector2(160.0, 42.0)
		energy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		energy_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_apply_font(energy_lbl, 26, Color(1.0, 1.0, 1.0, 1.0), 5)
		energy_container.add_child(energy_lbl)

		timer_lbl = Label.new()
		timer_lbl.text = "04:15"
		timer_lbl.position = Vector2(230.0, 60.0)
		timer_lbl.size = Vector2(90.0, 30.0)
		_apply_font(timer_lbl, 20, Color(1.0, 0.95, 0.75, 1.0), 4)
		energy_container.add_child(timer_lbl)

	# 3. Currencies (Coins, Gems, Gear Settings) using authentic PvZ2 assets
	var curr_container = hud.get_node_or_null("CurrenciesContainer")
	if curr_container:
		var hbox = HBoxContainer.new()
		hbox.position = Vector2(0.0, 10.0)
		hbox.size = Vector2(680.0, 65.0)
		hbox.alignment = BoxContainer.ALIGNMENT_END
		hbox.add_theme_constant_override("separation", 24)

		# Coins (white text)
		_add_currency_entry(hbox, "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/coin.png", "11,000", Color(1.0, 1.0, 1.0, 1.0), "Coins Shop", "Purchase lawn plant seeds and fertilizers with your golden coins.")

		# Gems (white text)
		_add_currency_entry(hbox, "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/gem.png", "15", Color(1.0, 1.0, 1.0, 1.0), "Gem Vault", "Collect precious gems to unlock premium costumes and rare plant pinatas.")

		# Settings Gear
		var gear_btn = TextureButton.new()
		gear_btn.custom_minimum_size = Vector2(60.0, 60.0)
		gear_btn.size = Vector2(60.0, 60.0)
		gear_btn.texture_normal = load("res://Assets/UI/UI_SettingsButton/resource/images/initial/UI/hud_settingsbutton/buttons_hud_settings_normal.png")
		var gear_selected_path = "res://Assets/UI/UI_SettingsButton/resource/images/initial/UI/hud_settingsbutton/buttons_hud_settings_selected.png"
		if ResourceLoader.exists(gear_selected_path):
			gear_btn.texture_pressed = load(gear_selected_path)
		gear_btn.ignore_texture_size = true
		gear_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		gear_btn.focus_mode = Control.FOCUS_NONE
		gear_btn.pressed.connect(_on_settings_button_pressed)
		hbox.add_child(gear_btn)

		curr_container.add_child(hbox)

func _add_currency_entry(parent: BoxContainer, icon_path: String, amount: String, col: Color, shop_title: String, shop_desc: String) -> void:
	var box = HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)

	if ResourceLoader.exists(icon_path):
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(48.0, 48.0)
		icon.texture = load(icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(icon)

	var lbl = Label.new()
	lbl.text = amount
	_apply_font(lbl, 26, col, 5)
	box.add_child(lbl)

	var plus_path = "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/coin_buy.png"
	var plus_pressed_path = "res://Assets/UI/UI_AlwaysLoaded/hud_ingame/coin_buy_down.png"
	if ResourceLoader.exists(plus_path):
		var plus_btn = TextureButton.new()
		plus_btn.custom_minimum_size = Vector2(36.0, 36.0)
		plus_btn.texture_normal = load(plus_path)
		if ResourceLoader.exists(plus_pressed_path):
			plus_btn.texture_pressed = load(plus_pressed_path)
		plus_btn.ignore_texture_size = true
		plus_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		plus_btn.focus_mode = Control.FOCUS_NONE
		plus_btn.pressed.connect(func():
			_play_click_sfx()
			_show_modal(shop_title, shop_desc, icon_path)
		)
		box.add_child(plus_btn)

	parent.add_child(box)

func _setup_chat_box() -> void:
	var chat_root = get_node_or_null("ChatBox")
	if not chat_root:
		return

	# Background TextureRect
	var bg = TextureRect.new()
	chat_background = bg
	bg.texture = load("res://Assets/Town/UI/ui_chat_box_shell.svg")
	bg.size = Vector2(440.0, 390.0)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	chat_root.add_child(bg)

	# Tabs Container at top
	var world_tab_btn = Button.new()
	world_tab_btn.text = "WORLD"
	world_tab_btn.position = Vector2(10.0, 10.0)
	world_tab_btn.size = Vector2(130.0, 48.0)
	world_tab_btn.focus_mode = Control.FOCUS_NONE
	world_tab_btn.flat = true
	world_tab_btn.add_theme_font_override("font", load(FONT_PATH))
	world_tab_btn.add_theme_font_size_override("font_size", 22)
	world_tab_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	world_tab_btn.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	world_tab_btn.add_theme_constant_override("outline_size", 4)
	world_tab_btn.pressed.connect(func(): _switch_chat_tab("WORLD"))
	chat_root.add_child(world_tab_btn)

	var guild_tab_btn = Button.new()
	guild_tab_btn.text = "GUILD"
	guild_tab_btn.position = Vector2(150.0, 10.0)
	guild_tab_btn.size = Vector2(130.0, 48.0)
	guild_tab_btn.focus_mode = Control.FOCUS_NONE
	guild_tab_btn.flat = true
	guild_tab_btn.add_theme_font_override("font", load(FONT_PATH))
	guild_tab_btn.add_theme_font_size_override("font_size", 22)
	guild_tab_btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	guild_tab_btn.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04, 1.0))
	guild_tab_btn.add_theme_constant_override("outline_size", 4)
	guild_tab_btn.pressed.connect(func(): _switch_chat_tab("GUILD"))
	chat_root.add_child(guild_tab_btn)

	chat_labels_container = VBoxContainer.new()
	chat_labels_container.position = Vector2(24.0, 75.0)
	chat_labels_container.size = Vector2(390.0, 290.0)
	chat_labels_container.add_theme_constant_override("separation", 10)
	chat_root.add_child(chat_labels_container)

	_update_chat_display()

func _switch_chat_tab(tab_name: String) -> void:
	_play_click_sfx()
	chat_current_tab = tab_name
	if chat_background:
		var shell_path = "res://Assets/Town/UI/ui_chat_box_shell_guild.svg" if tab_name == "GUILD" else "res://Assets/Town/UI/ui_chat_box_shell.svg"
		chat_background.texture = load(shell_path)
	_update_chat_display()

func _update_chat_display() -> void:
	if not chat_labels_container:
		return
	for c in chat_labels_container.get_children():
		c.queue_free()

	var msgs = CHAT_MESSAGES.get(chat_current_tab, [])
	for m in msgs:
		var rtl = RichTextLabel.new()
		rtl.bbcode_enabled = true
		rtl.text = m
		rtl.fit_content = true
		rtl.scroll_active = false
		rtl.custom_minimum_size = Vector2(380.0, 50.0)
		rtl.add_theme_font_override("normal_font", load(FONT_PATH))
		rtl.add_theme_font_size_override("normal_font_size", 18)
		chat_labels_container.add_child(rtl)

func _setup_bottom_shelf() -> void:
	var shelf = get_node_or_null("BottomShelf")
	if not shelf:
		return

	# This artwork already contains the four icons and labels. Keep it as the
	# single visual source with correct aspect ratio and place transparent hit targets over each item.
	var shelf_bg = TextureRect.new()
	shelf_bg.texture = load("res://Assets/Town/UI/ui_bottom_shelf.png")
	shelf_bg.position = Vector2(0.0, 0.0)
	shelf_bg.size = Vector2(650.0, 188.0)
	shelf_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shelf_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	shelf_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shelf.add_child(shelf_bg)

	var btn_configs = [
		{"x": 55.0, "title": "Seed Deck", "desc": "Choose your plant line-up for future lawn battles and world levels.", "tex": "res://Assets/Town/UI/btn_deck.png"},
		{"x": 197.0, "title": "Suburban Almanac", "desc": "Study official stats, weaknesses, and plant food powers for every plant and zombie.", "tex": "res://Assets/Town/UI/btn_almanac.png"},
		{"x": 339.0, "title": "Guild Headquarters", "desc": "Join an alliance of defenders to tackle weekly Boss raids and earn mints.", "tex": "res://Assets/Town/UI/btn_guild.png"},
		{"x": 481.0, "title": "Friend List", "desc": "Send daily sun gifts to neighbors and challenge buddies in friendly lawn duels.", "tex": "res://Assets/Town/UI/btn_friends.png"}
	]

	for cfg in btn_configs:
		var btn = Button.new()
		btn.text = ""
		btn.position = Vector2(cfg["x"], 4.0)
		btn.size = Vector2(118.0, 180.0)
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE

		var transparent_style = StyleBoxFlat.new()
		transparent_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
		btn.add_theme_stylebox_override("normal", transparent_style)
		btn.add_theme_stylebox_override("hover", transparent_style)
		btn.add_theme_stylebox_override("pressed", transparent_style)
		btn.add_theme_stylebox_override("focus", transparent_style)

		btn.pressed.connect(func():
			_play_click_sfx()
			_show_modal(cfg["title"], cfg["desc"], cfg["tex"])
		)
		shelf.add_child(btn)

func _setup_battle_button() -> void:
	var btn = get_node_or_null("BattleButton")
	if not btn:
		return
	btn.pivot_offset = btn.size / 2.0
	btn.pressed.connect(_on_battle_button_pressed)

	btn.mouse_entered.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.2)
	)
	btn.mouse_exited.connect(func():
		var tw = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.18)
	)

	# Gentle breathing animation
	var tw = create_tween().set_loops()
	tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _connect_building_buttons() -> void:
	var buildings_container = get_node_or_null("Buildings")
	if not buildings_container:
		return

	for child in buildings_container.get_children():
		var btn = child.get_node_or_null("Button")
		if btn and btn is BaseButton:
			var b_name = child.name
			btn.pressed.connect(func(): _on_building_clicked(b_name))
			btn.mouse_entered.connect(func():
				Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
			)
			btn.mouse_exited.connect(func():
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			)

func _on_building_clicked(building_name: String) -> void:
	_play_click_sfx()
	var data = BUILDING_METADATA.get(building_name, {
		"name": building_name.replace("_", " "),
		"desc": "This suburban establishment will unlock in an upcoming update!",
		"icon": ""
	})
	_show_modal(data["name"], data["desc"], data.get("icon", ""))

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
		modal_desc_lbl.text = "Crazy Dave says:\n'Wabby wabbo! Welcome inside, neighbor! Construction is still underway, but exciting surprises are coming!'"

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
	_show_modal("Game Settings", "Audio, graphics preferences, and community controls will be available here.", "res://Assets/Town/UI/settings_gear.png")

func _start_energy_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(func():
		if energy_timer_seconds > 0:
			energy_timer_seconds -= 1
		else:
			energy_timer_seconds = 300
		var mins = energy_timer_seconds / 60
		var secs = energy_timer_seconds % 60
		if timer_lbl:
			timer_lbl.text = "%02d:%02d" % [mins, secs]
	)
	add_child(timer)

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
