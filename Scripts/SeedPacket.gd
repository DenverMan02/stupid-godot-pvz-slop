extends Control
class_name SeedPacket

signal packet_clicked(packet: SeedPacket)

@export var plant_id: String = "peashooter"
@export var plant_name: String = "Peashooter"
@export var sun_cost: int = 100
@export var cooldown_duration: float = 5.0

var cooldown_remaining: float = 0.0
var is_selected: bool = false

@onready var card_texture: TextureRect = $CardTexture
@onready var cooldown_progress: TextureProgressBar = $CooldownProgress
@onready var select_highlight: TextureRect = $SelectHighlight

func _ready() -> void:
	custom_minimum_size = Vector2(156, 112)
	size = Vector2(156, 112)
	mouse_filter = MOUSE_FILTER_STOP

	var packet_path = "res://SeedPackets/%s.png" % plant_id
	if ResourceLoader.exists(packet_path):
		card_texture.texture = load(packet_path)

	if select_highlight:
		select_highlight.visible = false
	if cooldown_progress:
		cooldown_progress.visible = false
		cooldown_progress.max_value = 100.0
		cooldown_progress.value = 0.0

func _process(delta: float) -> void:
	if cooldown_remaining > 0.0:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)
		if cooldown_progress:
			cooldown_progress.visible = true
			cooldown_progress.value = (cooldown_remaining / cooldown_duration) * 100.0
	else:
		if cooldown_progress and cooldown_progress.visible:
			cooldown_progress.visible = false
			cooldown_progress.value = 0.0

func update_availability(current_sun: int) -> void:
	if cooldown_remaining > 0.0:
		card_texture.modulate = Color(0.65, 0.65, 0.65, 1.0)
	elif current_sun < sun_cost:
		card_texture.modulate = Color(0.48, 0.48, 0.48, 0.9)
	else:
		card_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)

func is_ready(current_sun: int) -> bool:
	return cooldown_remaining <= 0.0 and current_sun >= sun_cost

func start_cooldown() -> void:
	cooldown_remaining = cooldown_duration
	if cooldown_progress:
		cooldown_progress.visible = true
		cooldown_progress.value = 100.0

func set_selected(val: bool) -> void:
	is_selected = val
	if select_highlight:
		select_highlight.visible = val

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		packet_clicked.emit(self)
