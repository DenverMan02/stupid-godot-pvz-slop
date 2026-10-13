extends Plant
class_name Peashooter

func _init() -> void:
	plant_type = "peashooter"
	display_name = "Peashooter"
	anim_data_path = "res://Assets/Plants/peashooter.anim.json"
	textures_base_dir = "res://Assets/Plants/peashooter.xfl/library/"

func shoot() -> void:
	play_attack()
