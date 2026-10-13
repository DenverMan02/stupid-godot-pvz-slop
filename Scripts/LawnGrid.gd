extends Node2D
class_name LawnGrid

# 9 columns x 5 rows standard PvZ2 lawn grid
const COLS: int = 9
const ROWS: int = 5

# Scale factor from 1536p to 1080p
const S: float = 1080.0 / 1536.0 # 0.703125

# 1536p anchor coordinates from data.json & BoardConstants
# Sod / Row 5 begins at X = 1017, Y = 395 in 1536 space
const GRID_ORIGIN_1536: Vector2 = Vector2(1017.0, 395.0)
const CELL_SIZE_1536: Vector2 = Vector2(164.0, 195.0)

# Scaled coordinates in 1080p world space
var origin: Vector2 = GRID_ORIGIN_1536 * S
var cell_size: Vector2 = CELL_SIZE_1536 * S

@export var debug_draw_grid: bool = true
var hovered_cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var cell = world_to_cell(get_global_mouse_position())
		if cell != hovered_cell:
			hovered_cell = cell
			queue_redraw()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_G:
			debug_draw_grid = !debug_draw_grid
			queue_redraw()

# Convert (col, row) to world space center position for planting
func cell_to_world(col: int, row: int) -> Vector2:
	var x = origin.x + (col + 0.5) * cell_size.x
	# Offset Y slightly downward so plant base/roots rest on the grass tile
	var y = origin.y + (row + 0.65) * cell_size.y
	return Vector2(x, y)

# Convert world space position to (col, row)
func world_to_cell(pos: Vector2) -> Vector2i:
	var local_x = pos.x - origin.x
	var local_y = pos.y - origin.y
	if local_x < 0.0 or local_y < 0.0:
		return Vector2i(-1, -1)
	var col = int(local_x / cell_size.x)
	var row = int(local_y / cell_size.y)
	if is_valid_cell(col, row):
		return Vector2i(col, row)
	return Vector2i(-1, -1)

func is_valid_cell(col: int, row: int) -> bool:
	return col >= 0 and col < COLS and row >= 0 and row < ROWS

# PopCap perspective Z-order: rows are ordered from back (row 0) to front (row 4)
func get_row_z_index(row: int, layer_offset: int = 2) -> int:
	return row * 10 + layer_offset

func _draw() -> void:
	if not debug_draw_grid:
		return

	# Draw grid tile borders
	var line_color = Color(1.0, 1.0, 1.0, 0.2)
	for r in range(ROWS + 1):
		var y = origin.y + r * cell_size.y
		draw_line(Vector2(origin.x, y), Vector2(origin.x + COLS * cell_size.x, y), line_color, 1.5)
	for c in range(COLS + 1):
		var x = origin.x + c * cell_size.x
		draw_line(Vector2(x, origin.y), Vector2(x, origin.y + ROWS * cell_size.y), line_color, 1.5)

	# Highlight hovered cell
	if is_valid_cell(hovered_cell.x, hovered_cell.y):
		var rect = Rect2(
			origin.x + hovered_cell.x * cell_size.x,
			origin.y + hovered_cell.y * cell_size.y,
			cell_size.x,
			cell_size.y
		)
		draw_rect(rect, Color(0.2, 0.9, 0.2, 0.25), true)
		draw_rect(rect, Color(0.3, 1.0, 0.3, 0.7), false, 2.0)
