extends Node2D

@onready var flower: TileMapLayer = $Flower
@onready var hover: TileMapLayer = $Hover

var previous_hover_tile: Vector2i = Vector2i(-1, -1)  # Keeps track of last hovered tile

var current_hour: int = 0
var time_passed: float = 0.0
const SECONDS_PER_HOUR: float = 5.0
const TOTAL_HOURS: int = 8

# Flowers array now has 4 types
var flowers := [
	Vector2i(0, 0),  # Flower Type 1
	Vector2i(0, 0),  # Flower Type 1
	Vector2i(0, 1),  # Flower Type 2
	Vector2i(0, 1),  # Flower Type 2
	Vector2i(1, 1),  # Flower Type 3
	Vector2i(1, 1),  # Flower Type 3
	Vector2i(3, 0),   # Flower Type 4
	Vector2i(3, 0)   # Flower Type 4
]

func _process(delta: float) -> void:
	var mouse_pos = get_global_mouse_position()
	var current_hover_tile = hover.local_to_map(mouse_pos)
	var flower_current_tile = flower.get_cell_source_id(current_hover_tile)
	
	time_passed += delta
	if time_passed >= SECONDS_PER_HOUR:
		time_passed -= SECONDS_PER_HOUR
		# Change the hour every 2 hours instead of 1
		current_hour = (current_hour + 1) % TOTAL_HOURS
	
	# Only update if the tile under the mouse has changed
	if current_hover_tile != previous_hover_tile:
		hover.erase_cell(previous_hover_tile)
		# Set the new hover tile
		hover.set_cell(current_hover_tile, 0, Vector2i(9, 6))
		previous_hover_tile = current_hover_tile
	
	if Input.is_action_just_pressed("action") and flower_current_tile == -1:
		var flower_tile = flower.local_to_map(mouse_pos)
		place_flower(flower_tile)


func place_flower(flower_tile):
	if flower.get_cell_source_id(flower_tile) == -1:
		flower.set_cell(flower_tile, 0, flowers[current_hour])  # Use 4 flower types


		check_for_flower_chain(flower_tile, flowers[current_hour % 4])


# Function to check for flower chains
func check_for_flower_chain(origin: Vector2i, flower_tile: Vector2i):
	var directions = [
		Vector2i(1, 0),  # Right
		Vector2i(0, 1),  # Down
	]
	
	for dir in directions:
		# Store unique flower types in an array
		var chain_flowers = []
		# Add the planted flower to the chain
		chain_flowers.append(flower.get_cell_atlas_coords(origin))
		
		# Check in one direction
		var pos = origin + dir
		if flower.get_cell_source_id(pos) != -1:
			var atlas_coords = flower.get_cell_atlas_coords(pos)
			if not atlas_coords in chain_flowers:
				chain_flowers.append(atlas_coords)
		
		# Check in the opposite direction
		pos = origin - dir
		if flower.get_cell_source_id(pos) != -1:
			var atlas_coords = flower.get_cell_atlas_coords(pos)
			if not atlas_coords in chain_flowers:
				chain_flowers.append(atlas_coords)
		
		# If we found 3 different flower types
		if chain_flowers.size() >= 3:
			print("3 different flowers in a row found!")
			do_flower_chain_effect(origin)
			return  # Only trigger once

# Function to trigger the effect when a chain is detected
func do_flower_chain_effect(origin: Vector2i):
	# Example effect: Change the flower to a different type, or play an animation
	print("✨ Magic bloom triggered at ", origin)
	# Here, you could change the flower to a special type, animate it, etc.
