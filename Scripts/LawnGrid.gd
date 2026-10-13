extends Node2D
class_name LawnGrid

## Flexible Lawn Grid System for PvZ Godot
## Supports arbitrary row/col counts (e.g. 6-lane, 10-column), 
## slants/skews, and roof lawns (sloped peak).

enum GridType {
	STANDARD,
	SLANTED,
	ROOF
}

@export_group("Grid Dimensions")
@export var columns: int = 9
@export var rows: int = 5

@export_group("PvZ2 1536p Coordinates")
## Scale factor from PvZ2 1536p reference resolution to 1080p target
const S: float = 1080.0 / 1536.0 # 0.703125
## Calibrated origin in 1536p space (matching PopCap GRID_LEFT = 200 + texture offset 556 = 1068)
@export var origin_1536: Vector2 = Vector2(1068.0, 395.0)
@export var cell_size_1536: Vector2 = Vector2(164.0, 195.0)

@export_group("Custom Lawn Shapes")
@export var grid_type: GridType = GridType.STANDARD
## Vertical slope per column (for slanted lawns like Kongfu World or custom ramps)
@export var slant_y_per_col: float = 0.0
## Peak column for roof lawns (columns 0..peak slope up, peak..N slope down)
@export var roof_peak_col: int = 4
## Vertical slope in pixels per column towards the roof peak
@export var roof_slope_y: float = 0.0

@export_group("Visuals")
@export var debug_draw_grid: bool = true

# Scaled coordinates in 1080p world space
var origin: Vector2:
	get: return origin_1536 * S

var cell_size: Vector2:
	get: return cell_size_1536 * S

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

## Get the vertical height offset for a specific column (handles roof peak & slants)
func get_column_y_offset(col: int) -> float:
	match grid_type:
		GridType.SLANTED:
			return col * (slant_y_per_col * S)
		GridType.ROOF:
			var dist_from_peak = abs(col - roof_peak_col)
			# Peak is highest (lowest Y value), sloping downward away from peak
			return dist_from_peak * (roof_slope_y * S)
		_:
			return 0.0

## Convert (col, row) to world space center position for plant placement
func cell_to_world(col: int, row: int) -> Vector2:
	var x = origin.x + (col + 0.5) * cell_size.x
	var col_y_offset = get_column_y_offset(col)
	# Planting anchor is slightly lower in the cell (0.65) so roots/stem rest on grass
	var y = origin.y + col_y_offset + (row + 0.65) * cell_size.y
	return Vector2(x, y)

## Convert world space position to (col, row) grid coordinate
func world_to_cell(pos: Vector2) -> Vector2i:
	var local_x = pos.x - origin.x
	if local_x < 0.0:
		return Vector2i(-1, -1)
	
	var col = int(local_x / cell_size.x)
	if col < 0 or col >= columns:
		return Vector2i(-1, -1)
	
	var col_y_offset = get_column_y_offset(col)
	var local_y = pos.y - (origin.y + col_y_offset)
	if local_y < 0.0:
		return Vector2i(-1, -1)
	
	var row = int(local_y / cell_size.y)
	if row >= 0 and row < rows:
		return Vector2i(col, row)
	
	return Vector2i(-1, -1)

## Check if (col, row) is within the active lawn bounds
func is_valid_cell(col: int, row: int) -> bool:
	return col >= 0 and col < columns and row >= 0 and row < rows

## PopCap perspective Z-order: rows are ordered back-to-front (row * 10 + layer_offset)
func get_row_z_index(row: int, layer_offset: int = 2) -> int:
	return row * 10 + layer_offset

## Get the 4 corner points of a cell in world space
func get_cell_polygon(col: int, row: int) -> PackedVector2Array:
	var x0 = origin.x + col * cell_size.x
	var x1 = x0 + cell_size.x
	var y_offset0 = get_column_y_offset(col)
	var y_offset1 = get_column_y_offset(col + 1) if grid_type != GridType.STANDARD else y_offset0
	
	var p0 = Vector2(x0, origin.y + y_offset0 + row * cell_size.y)
	var p1 = Vector2(x1, origin.y + y_offset1 + row * cell_size.y)
	var p2 = Vector2(x1, origin.y + y_offset1 + (row + 1) * cell_size.y)
	var p3 = Vector2(x0, origin.y + y_offset0 + (row + 1) * cell_size.y)
	return PackedVector2Array([p0, p1, p2, p3])

func _draw() -> void:
	if not debug_draw_grid:
		return

	var line_color = Color(1.0, 1.0, 1.0, 0.4)
	
	# Draw all cell outlines
	for c in range(columns):
		for r in range(rows):
			var poly = get_cell_polygon(c, r)
			draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), line_color, 1.5)

	# Highlight hovered cell
	if is_valid_cell(hovered_cell.x, hovered_cell.y):
		var poly = get_cell_polygon(hovered_cell.x, hovered_cell.y)
		draw_colored_polygon(poly, Color(0.2, 0.9, 0.2, 0.3))
		draw_polyline(PackedVector2Array([poly[0], poly[1], poly[2], poly[3], poly[0]]), Color(0.3, 1.0, 0.3, 0.8), 2.5)
