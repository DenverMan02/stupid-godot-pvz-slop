extends Control
class_name SeedBank

signal packet_selected(packet: SeedPacket)
signal selection_cleared()

@onready var sun_label: Label = $VBoxContainer/SunBank/SunCountLabel
@onready var packets_container: VBoxContainer = $VBoxContainer/PacketsContainer

var selected_packet: SeedPacket = null
var current_sun: int = 50

const ALL_PLANT_PACKETS: Dictionary = {
	"sunflower": {"name": "Sunflower", "cost": 50, "cooldown": 5.0},
	"peashooter": {"name": "Peashooter", "cost": 100, "cooldown": 5.0},
	"repeater": {"name": "Repeater", "cost": 200, "cooldown": 7.5},
	"wallnut": {"name": "Wall-nut", "cost": 50, "cooldown": 20.0},
	"potatomine": {"name": "Potato Mine", "cost": 25, "cooldown": 20.0},
	"cabbagepult": {"name": "Cabbage-pult", "cost": 100, "cooldown": 5.0},
	"sunflower_twin": {"name": "Twin Sunflower", "cost": 125, "cooldown": 7.5},
	"threepeater": {"name": "Threepeater", "cost": 300, "cooldown": 7.5},
	"peashooter_super": {"name": "Gatling Pea", "cost": 400, "cooldown": 10.0},
	"three_head_sunflower": {"name": "Triplet Sunflower", "cost": 200, "cooldown": 10.0},
}

const PACKET_DATA: Array[Dictionary] = [
	{
		"id": "sunflower",
		"name": "Sunflower",
		"cost": 50,
		"cooldown": 5.0
	},
	{
		"id": "peashooter",
		"name": "Peashooter",
		"cost": 100,
		"cooldown": 5.0
	},
	{
		"id": "cabbagepult",
		"name": "Cabbage-pult",
		"cost": 100,
		"cooldown": 5.0
	},
	{
		"id": "wallnut",
		"name": "Wall-nut",
		"cost": 50,
		"cooldown": 20.0
	},
	{
		"id": "potatomine",
		"name": "Potato Mine",
		"cost": 25,
		"cooldown": 20.0
	}
]

var packet_nodes: Array[SeedPacket] = []
var packet_scene: PackedScene = preload("res://Scenes/SeedPacket.tscn")

func _ready() -> void:
	_init_packets()
	update_sun_display(current_sun)

func _init_packets() -> void:
	# Clear any existing placeholder children
	for child in packets_container.get_children():
		child.queue_free()
	packet_nodes.clear()

	for info in PACKET_DATA:
		var pkt: SeedPacket = packet_scene.instantiate()
		pkt.plant_id = info["id"]
		pkt.plant_name = info["name"]
		pkt.sun_cost = info["cost"]
		pkt.cooldown_duration = info["cooldown"]
		pkt.packet_clicked.connect(_on_packet_clicked)
		packets_container.add_child(pkt)
		packet_nodes.append(pkt)

func set_active(active: bool) -> void:
	for pkt in packet_nodes:
		if pkt:
			pkt.set_active(active)

func _on_packet_clicked(pkt: SeedPacket) -> void:
	if selected_packet == pkt:
		deselect_all()
		selection_cleared.emit()
		return

	if pkt.is_ready(current_sun):
		deselect_all()
		selected_packet = pkt
		pkt.set_selected(true)
		if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/select_plant.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/select_plant.ogg"))
		packet_selected.emit(pkt)
	else:
		if get_node_or_null("/root/AudioManager") and ResourceLoader.exists("res://Audio/SFX/failure.ogg"):
			AudioManager.play_sfx(load("res://Audio/SFX/failure.ogg"))

func update_sun_display(amount: int) -> void:
	current_sun = amount
	if sun_label:
		sun_label.text = str(current_sun)
	for pkt in packet_nodes:
		if pkt:
			pkt.update_availability(current_sun)

func deselect_all() -> void:
	selected_packet = null
	for pkt in packet_nodes:
		if pkt:
			pkt.set_selected(false)

func on_plant_placed() -> void:
	if selected_packet:
		selected_packet.start_cooldown()
		deselect_all()
		selection_cleared.emit()

func get_sun_icon_global_pos() -> Vector2:
	var sun_icon = $VBoxContainer/SunBank/SunIcon
	if sun_icon:
		return sun_icon.global_position + (sun_icon.size * 0.5)
	return Vector2(90.0, 60.0)
