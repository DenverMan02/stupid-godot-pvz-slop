extends Control

@onready var prompt_label: Label = 
var starting: bool = false

func _ready() -> void:
	# Ensure title music is playing via AudioManager
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_music(AudioManager.title_music)

	# Gentle pulsing animation for the "Click to Start" prompt
	if prompt_label:
		var tween = create_tween().set_loops()
		tween.tween_property(prompt_label, "modulate:a", 0.35, 0.75).set_trans(Tween.TRANS_SINE)
		tween.tween_property(prompt_label, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_SINE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_start()

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo):
		_on_start()

func _on_start() -> void:
	if starting:
		return
	starting = true

	var click_sfx = preload("res://Audio/SFX/click_buy_button.ogg")
	if get_node_or_null("/root/AudioManager"):
		AudioManager.play_sfx(click_sfx)

	print("[TitleScreen] Clicked! Starting game...")
	get_tree().change_scene_to_file("res://Scenes/Lawn.tscn")
