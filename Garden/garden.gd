extends Node2D

@onready var flower: TileMapLayer = $Flower
@onready var hover: TileMapLayer = $Hover
@onready var label: Label = $Label
@onready var bee: Node2D = $Bee
@onready var loading: ColorRect = $Loading
@onready var daylabel: Label = $Loading/daylabel
@onready var patternlabel: Label = $Loading/patternlabel

var bee_target: Vector2 = Vector2.ZERO
var bee_speed: float = 100.0
var bee_moving: bool = false
var previous_hover_tile: Vector2i = Vector2i(-1, -1)
var current_hour: int = 0
var time_passed: float = 0.0
var current_day = 1
const TOTAL_DAYS = 3
const SECONDS_PER_HOUR: float = 2.0
const TOTAL_HOURS: int = 8
var total_patterns = 0
var game_lost = false
var game_won = false
var flowers := [
	Vector2i(0, 0),
	Vector2i(0, 0),
	Vector2i(0, 1),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(1, 1),
	Vector2i(3, 0),
	Vector2i(3, 0)
]

var flower_pattern := [
	1324,
	4321,
	1122,
	3344
]

var day_start_timer := 0.0
var loading_duration := 1.5
var loading_active := true

var current_pattern: int = -1

func _ready():
	show_loading_screen()
	pick_new_pattern()

func _process(delta: float) -> void:
	if loading_active:
		day_start_timer += delta
		if day_start_timer >= loading_duration:
			hide_loading_screen()
		return

	var mouse_pos = get_global_mouse_position()
	var current_hover_tile = hover.local_to_map(mouse_pos)
	var flower_current_tile = flower.get_cell_source_id(current_hover_tile)

	if bee_moving:
		var direction = (bee_target - bee.position).normalized()
		var distance = bee_speed * delta
		if bee.position.distance_to(bee_target) <= distance:
			bee.position = bee_target
			bee_moving = false
		else:
			bee.position += direction * distance

	time_passed += delta
	if time_passed >= SECONDS_PER_HOUR:
		time_passed -= SECONDS_PER_HOUR
		current_hour += 1

	if current_hour >= TOTAL_HOURS:
		current_hour = 0
		current_day += 1
		if current_day <= TOTAL_DAYS:
			pick_new_pattern()
			show_loading_screen()
			print("🌅 A new day begins! Day:", current_day)
		elif current_day > TOTAL_DAYS and total_patterns < 3:
			game_lost = true
			show_loading_screen()
			print("💀 Game lost at day", current_day)

	label.text = "Day: " + str(current_day) + "  Time: " + str(current_hour + 1) + "PM"

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

func pick_new_pattern():
	if current_day <= TOTAL_DAYS:
		current_pattern = randi() % flower_pattern.size()
		patternlabel.text = "Pattern: " + str(flower_pattern[current_pattern])
		print("Selected flower pattern: ", flower_pattern[current_pattern])

func check_for_flower_chain(origin: Vector2i, flower_tile: Vector2i):
	var pattern := [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1)
	]

	var selected_pattern = flower_pattern[current_pattern]
	var expected_types := []

	match selected_pattern:
		1324:
			expected_types = [Vector2i(0, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(1, 1)]
		4321:
			expected_types = [Vector2i(1, 1), Vector2i(3, 0), Vector2i(0, 0), Vector2i(0, 1)]
		1122:
			expected_types = [Vector2i(0, 0), Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 1)]
		3344:
			expected_types = [Vector2i(1, 1), Vector2i(1, 1), Vector2i(3, 0), Vector2i(3, 0)]

	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
		var base = origin + offset
		var matches = true

		for i in range(pattern.size()):
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
	total_patterns += 1
	print("🌸 Magic bloom triggered at ", origin)

	var start_pos = flower.to_global(flower.map_to_local(origin))
	var end_pos = start_pos + Vector2(500, 0)

	bee.position = start_pos
	bee_target = end_pos
	bee_moving = true

	print("Bee moving from", bee.position, "to", bee_target)
	if total_patterns == 3:
		game_won = true

func show_loading_screen():
	loading.visible = true
	loading_active = true
	day_start_timer = 0.0

	if game_lost:
		daylabel.text = "You have lost but you can continue making your garden!"
		patternlabel.visible = false
	elif game_won:
		daylabel.text = "You have won! Continue making your garden!"
		patternlabel.visible = true
	else:
		daylabel.text = "Today is the " + str(current_day) + ". day."
		patternlabel.visible = true

	print("🕒 Showing loading screen...")

func hide_loading_screen():
	loading.visible = false
	loading_active = false
	print("✅ Loading finished")
