extends Control
class_name SeedPacket

signal packet_clicked(packet: SeedPacket)

@export var plant_id: String = "peashooter"
@export var plant_name: String = "Peashooter"
@export var sun_cost: int = 100
@export var cooldown_duration: float = 5.0

var cooldown_remaining: float = 0.0
var is_selected: bool = false
var is_active: bool = false
var cached_sun: int = 50

@onready var card_texture: TextureRect = $CardTexture
@onready var cooldown_progress: TextureProgressBar = $CardTexture/CooldownProgress
@onready var cost_label: Label = $CostLabel
@onready var select_highlight: TextureRect = $SelectHighlight

func _ready() -> void:
	custom_minimum_size = Vector2(156, 112)
	size = Vector2(156, 112)
	mouse_filter = MOUSE_FILTER_STOP

	var icon_name = plant_id
	if plant_id == "peashooter_super":
		icon_name = "gatlingpea"
	elif plant_id == "sunflower_twin" or plant_id == "three_head_sunflower":
		icon_name = "twinsunflower"
	var packet_path = "res://SeedPackets/%s.png" % icon_name
	if ResourceLoader.exists(packet_path):
		card_texture.texture = load(packet_path)
	elif ResourceLoader.exists("res://SeedPackets/%s.png" % plant_id):
		card_texture.texture = load("res://SeedPackets/%s.png" % plant_id)

	if cost_label:
		cost_label.text = str(sun_cost)
	if select_highlight:
		select_highlight.visible = false
	if cooldown_progress:
		cooldown_progress.visible = false
		cooldown_progress.max_value = 100.0
		cooldown_progress.value = 0.0

func set_active(active: bool) -> void:
	is_active = active
	update_availability(cached_sun)

func _process(delta: float) -> void:
	if not is_active:
		return

	if cooldown_remaining > 0.0:
		cooldown_remaining = max(0.0, cooldown_remaining - delta)
		if cooldown_progress:
			cooldown_progress.visible = true
			cooldown_progress.value = (cooldown_remaining / cooldown_duration) * 100.0
		if cooldown_remaining <= 0.0:
			if cooldown_progress:
				cooldown_progress.visible = false
				cooldown_progress.value = 0.0
			# Instantly refresh brightness/greyness upon recharge completion
			update_availability(cached_sun)

func update_availability(current_sun: int) -> void:
	cached_sun = current_sun
	var can_afford = current_sun >= sun_cost

	if cost_label:
		if not is_active:
			cost_label.modulate = Color(0.65, 0.65, 0.65, 0.85)
		elif not can_afford:
			cost_label.modulate = Color(1.0, 0.2, 0.2, 1.0) # Red when cannot afford
		else:
			cost_label.modulate = Color(1.0, 1.0, 1.0, 1.0) # White when affordable

	if not is_active:
		card_texture.modulate = Color(0.48, 0.48, 0.48, 0.9)
	elif cooldown_remaining > 0.0:
		card_texture.modulate = Color(0.65, 0.65, 0.65, 1.0)
	elif not can_afford:
		card_texture.modulate = Color(0.48, 0.48, 0.48, 0.9)
	else:
		card_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)

func is_ready(current_sun: int) -> bool:
	return is_active and cooldown_remaining <= 0.0 and current_sun >= sun_cost

func start_cooldown() -> void:
	cooldown_remaining = cooldown_duration
	if cooldown_progress:
		cooldown_progress.visible = true
		cooldown_progress.value = 100.0
	update_availability(cached_sun)

func set_selected(val: bool) -> void:
	is_selected = val
	if select_highlight:
		select_highlight.visible = val

func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		packet_clicked.emit(self)
