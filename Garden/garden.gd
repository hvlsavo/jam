extends Node2D

@onready var flower: TileMapLayer = $Flower
@onready var hover: TileMapLayer = $Hover
var previous_hover_tile: Vector2i = Vector2i(-1, -1)  # Keeps track of last hovered tile
var current_hour: int = 0
var time_passed: float = 0.0
const SECONDS_PER_HOUR: float = 5.0
const TOTAL_HOURS: int = 8

# Flowers array now has 4 types (2 of each, total 8 hours)
var flowers := [
	Vector2i(0, 0),  # Flower Type 1
	Vector2i(0, 0),  # Flower Type 1
	Vector2i(0, 1),  # Flower Type 2
	Vector2i(0, 1),  # Flower Type 2
	Vector2i(1, 1),  # Flower Type 3
	Vector2i(1, 1),  # Flower Type 3
	Vector2i(3, 0),  # Flower Type 4
	Vector2i(3, 0)   # Flower Type 4
]

func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var current_hover_tile = hover.local_to_map(mouse_pos)
	var flower_current_tile = flower.get_cell_source_id(current_hover_tile)

	time_passed += delta
	if time_passed >= SECONDS_PER_HOUR:
		time_passed -= SECONDS_PER_HOUR
		current_hour = (current_hour + 1) % TOTAL_HOURS

	if current_hover_tile != previous_hover_tile:
		hover.erase_cell(previous_hover_tile)
		hover.set_cell(current_hover_tile, 0, Vector2i(9, 6))
		previous_hover_tile = current_hover_tile

	if Input.is_action_just_pressed("action") and flower_current_tile == -1:
		var flower_tile = flower.local_to_map(mouse_pos)
		place_flower(flower_tile)

func place_flower(flower_tile):
	if flower.get_cell_source_id(flower_tile) == -1:
		flower.set_cell(flower_tile, 0, flowers[current_hour])
		print("Planted flower type ", current_hour, " at ", flower_tile)
		check_for_flower_chain(flower_tile, flowers[current_hour])

# Modified to check for a specific 2x2 pattern of different flower types
func check_for_flower_chain(origin: Vector2i, flower_tile: Vector2i):
	var pattern := [
		Vector2i(0, 0),  # Top-left
		Vector2i(1, 0),  # Top-right
		Vector2i(0, 1),  # Bottom-left
		Vector2i(1, 1)   # Bottom-right
	]

	var expected_types := [
		Vector2i(0, 0),  # First flower type
		Vector2i(1, 1),  # Third flower type
		Vector2i(0, 1),  # Second flower type
		Vector2i(3, 0)   # Fourth flower type
	]

	# Try all possible 2x2 top-left corners around the placed tile
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
		var base = origin + offset
		var matches = true

		for i in pattern.size():
			var check_pos = base + pattern[i]
			if flower.get_cell_source_id(check_pos) == -1:
				matches = false
				break
			var cell_type = flower.get_cell_atlas_coords(check_pos)
			if cell_type != expected_types[i]:
				matches = false
				break

		if matches:
			print("2x2 flower pattern found starting at ", base)
			do_flower_chain_effect(base)
			return

func do_flower_chain_effect(origin: Vector2i):
	# Example effect: Log it or trigger animation
	print("🌸 Magic bloom triggered at ", origin)
