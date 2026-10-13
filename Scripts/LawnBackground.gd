extends Node2D
class_name LawnBackground

# Scale factor from PvZ2 1536p source resolution to Godot 1080p target resolution
const SCALE_1536_TO_1080: float = 1080.0 / 1536.0 # 0.703125

@export var lawn_path: String = "res://Assets/Lawns/Modern Day"
@export var sod_lanes: int = 5 # 1, 3, or 5 lanes of sod (Modern Day uses Row 05 for 5-lane)

func _ready() -> void:
	scale = Vector2(SCALE_1536_TO_1080, SCALE_1536_TO_1080)
