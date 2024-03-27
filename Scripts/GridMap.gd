extends GridMap

#grid consts
const ROWS := 20
const COLS := 10

const SPAWN = Vector3i(-1, 8, 0)

#game piece vars
var piece_type
var next_piece_type
var next_piece_color
var rotation_index : int = 0
var active_piece : Array
var current_loc

#grid vars
var cube_id : int = 0
var piece_color : int
var current_shown = []

#movement variables
const directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]
var steps : Array
const steps_req : int = 50
var speed : float
const ACCEL : float = 0.25

var bag = SRS.shapes.duplicate()

func convert_vec2_vec3(vec2 : Vector2i) -> Vector3i:
	return Vector3i(vec2.x, -vec2.y, 0)

func _ready():
	new_game()
	
func _physics_process(_delta):
	if Input.is_action_pressed("left"):
		steps[0] += 10
	if Input.is_action_pressed("right"):
		steps[1] += 10
	if Input.is_action_pressed("soft"):
		steps[2] += 10
	if Input.is_action_just_pressed("rot_left"):
		rotate_piece("left")
	if Input.is_action_just_pressed("rot_right"):
		rotate_piece("right")
		
	
	steps[2] += speed
	for i in range(steps.size()):
		if steps[i] > steps_req:
			move_piece(directions[i])
			steps[i] = 0
		
func new_game():
	speed = 1.0
	steps = [0, 0, 0]
	next_piece_type = pick_piece()
	next_piece_color = SRS.shapes.find(next_piece_type)
	create_piece()
	
func pick_piece():
	var piece
	if not bag.is_empty():
		bag.shuffle()
		piece = bag.pop_front()
	else:
		bag = SRS.shapes.duplicate()
		bag.shuffle()
		piece = bag.pop_front()
	return piece

func create_piece():
	steps = [0, 0, 0]
	current_loc = SPAWN
	rotation_index = 0
	
	piece_type = next_piece_type
	piece_color = next_piece_color
	next_piece_type = pick_piece()
	next_piece_color = SRS.shapes.find(next_piece_type)
	active_piece = piece_type[rotation_index]
	draw_piece(active_piece, SPAWN)
	show_piece(next_piece_type[0], next_piece_color)

func clear_piece():
	for i in active_piece:
		set_cell_item(convert_vec2_vec3(i) + current_loc, -1)

func draw_piece(piece, pos):
	for i in piece:
		set_cell_item(convert_vec2_vec3(i) + pos, piece_color)

func rotate_piece(dir):
	if can_rotate(dir):
		clear_piece()
		match dir:
			"left":
				rotation_index = (rotation_index - 1) % 4
			"right":
				rotation_index = (rotation_index + 1) % 4
		active_piece = piece_type[rotation_index]
		draw_piece(active_piece, current_loc)

func can_rotate(dir):
	var current_positions = []
	for square in active_piece:
		current_positions.append(convert_vec2_vec3(square) + current_loc)

	var cr = true
	var temp_rotation_index
	match dir:
		"left":
			temp_rotation_index = (rotation_index - 1) % 4
		"right":
			temp_rotation_index = (rotation_index + 1) % 4
	for i in piece_type[temp_rotation_index]:
		var next_pos = convert_vec2_vec3(i) + current_loc
		if not is_free(next_pos) and next_pos not in current_positions:
			cr = false
			break
	return cr

func move_piece(dir):
	if can_move(dir):
		clear_piece()
		current_loc += convert_vec2_vec3(dir)
		draw_piece(active_piece, current_loc)
	elif dir == Vector2i.DOWN:
		land_piece()
		create_piece()

	
func can_move(dir):

	# Collect current positions of the active piece
	var current_positions = []
	for square in active_piece:
		current_positions.append(convert_vec2_vec3(square) + current_loc)
	
	# Check if the entire piece can move in the specified direction
	var cm = true
	for square in active_piece:
		var next_pos = convert_vec2_vec3(square) + current_loc + convert_vec2_vec3(dir)
		if not is_free(next_pos) and next_pos not in current_positions:
			cm = false
			break
	return cm
	
func land_piece():
	#remove each segment from the active layer and move to board layer

	for i in active_piece:
		set_cell_item(convert_vec2_vec3(i) + current_loc, -1)
		set_cell_item(convert_vec2_vec3(i) + current_loc, piece_color)	

func is_free(pos):
	return get_cell_item(pos) == -1

func show_piece(piece, color):
	
	for i in current_shown:
		set_cell_item(convert_vec2_vec3(i) + Vector3i(8, 4, 0), -1)

	current_shown = []
	for i in piece:
		set_cell_item(convert_vec2_vec3(i) + Vector3i(8, 4, 0), color)
		current_shown.append(i)
