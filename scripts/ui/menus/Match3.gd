extends Control

const GRID_SIZE = 8
const TILE_SIZE = 64
const COLORS = [
	Color.RED,
	Color.BLUE,
	Color.GREEN,
	Color.YELLOW,
	Color.PURPLE
]

var grid = []
var selected_tile = null
var score = 0

@onready var grid_container = $CenterContainer/VBoxContainer/GridContainer
@onready var score_label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var back_button = $CenterContainer/VBoxContainer/BackButton

func _ready():
	randomize()
	initialize_grid()
	update_display()

func initialize_grid():
	grid = []
	for x in range(GRID_SIZE):
		grid.append([])
		for y in range(GRID_SIZE):
			var color = COLORS[randi() % COLORS.size()]
			grid[x].append(color)
	# Ensure no initial matches
	while check_all_matches():
		remove_matches()
		drop_tiles()
		refill_grid()

func update_display():
	# Clear existing tiles
	for child in grid_container.get_children():
		child.queue_free()
	
	# Add new tiles
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			var button = Button.new()
			button.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			button.modulate = grid[x][y]
			button.connect("pressed", Callable(self, "_on_tile_pressed").bind(x, y))
			grid_container.add_child(button)
	
	score_label.text = "Score: " + str(score)

func _on_tile_pressed(x, y):
	if selected_tile == null:
		selected_tile = Vector2(x, y)
		# Highlight selected
		grid_container.get_child(x * GRID_SIZE + y).modulate *= 1.5
	else:
		var sx = selected_tile.x
		var sy = selected_tile.y
		if abs(sx - x) + abs(sy - y) == 1:  # Adjacent
			swap_tiles(sx, sy, x, y)
			if not check_all_matches():
				swap_tiles(sx, sy, x, y)  # Swap back if no match
			else:
				remove_matches()
				drop_tiles()
				refill_grid()
				update_display()
		# Deselect
		selected_tile = null
		update_display()

func swap_tiles(x1, y1, x2, y2):
	var temp = grid[x1][y1]
	grid[x1][y1] = grid[x2][y2]
	grid[x2][y2] = temp

func check_all_matches() -> bool:
	var matches = []
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if check_match_at(x, y):
				matches.append(Vector2(x, y))
	return matches.size() > 0

func check_match_at(x, y) -> bool:
	var color = grid[x][y]
	# Horizontal
	var count = 1
	for i in range(1, 3):
		if x + i < GRID_SIZE and grid[x + i][y] == color:
			count += 1
		else:
			break
	if count >= 3:
		return true
	# Vertical
	count = 1
	for i in range(1, 3):
		if y + i < GRID_SIZE and grid[x][y + i] == color:
			count += 1
		else:
			break
	if count >= 3:
		return true
	return false

func remove_matches():
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if check_match_at(x, y):
				grid[x][y] = null
				score += 10

func drop_tiles():
	for x in range(GRID_SIZE):
		var new_column = []
		for y in range(GRID_SIZE):
			if grid[x][y] != null:
				new_column.append(grid[x][y])
		while new_column.size() < GRID_SIZE:
			new_column.insert(0, null)
		grid[x] = new_column

func refill_grid():
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			if grid[x][y] == null:
				grid[x][y] = COLORS[randi() % COLORS.size()]

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menus/MainMenu.tscn")