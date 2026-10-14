extends Control

@onready var modal_overlay: ColorRect = $ComingSoonModal
@onready var modal_title: Label = $ComingSoonModal/Panel/VBox/TitleLabel
@onready var modal_message: Label = $ComingSoonModal/Panel/VBox/MessageLabel
@onready var modal_close_btn: Button = $ComingSoonModal/Panel/VBox/CloseButton

var click_sfx: AudioStream = preload("res://Audio/SFX/click_buy_button.ogg")

func _ready() -> void:
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(AudioManager.title_music)

	if modal_overlay:
		modal_overlay.visible = false

	if modal_close_btn:
		modal_close_btn.pressed.connect(_close_modal)

	_connect_building_buttons()

func _connect_building_buttons() -> void:
	var buildings_container = get_node_or_null("Buildings")
	if not buildings_container:
		return

	for child in buildings_container.get_children():
		if child is Control or child is BaseButton:
			var btn: BaseButton = child if child is BaseButton else child.get_node_or_null("Button")
			if btn:
				var b_name = child.name
				btn.pressed.connect(func(): _on_building_clicked(b_name))

func _on_building_clicked(building_name: String) -> void:
	_play_click_sfx()
	var formatted_name = building_name.replace("_", " ")
	_show_modal(formatted_name, "This feature is coming soon!\nStay tuned for future updates.")

func _show_modal(title_text: String, msg_text: String) -> void:
	if modal_title:
		modal_title.text = title_text
	if modal_message:
		modal_message.text = msg_text
	if modal_overlay:
		modal_overlay.visible = true

func _close_modal() -> void:
	_play_click_sfx()
	if modal_overlay:
		modal_overlay.visible = false

func _on_battle_button_pressed() -> void:
	_play_click_sfx()
	print("[Town] Battle button pressed! Loading Lawn.tscn...")
	get_tree().change_scene_to_file("res://Scenes/Lawn.tscn")

func _on_settings_button_pressed() -> void:
	_play_click_sfx()
	_show_modal("Settings", "Game Options & Settings\nAudio and Graphics settings coming soon!")

func _play_click_sfx() -> void:
	if get_node_or_null("/root/AudioManager") and click_sfx:
		AudioManager.play_sfx(click_sfx)
