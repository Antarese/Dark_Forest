extends Node2D


const TILE_PARTS_COUNT: int = 3
const OCCLUSION_Z_OFFSET: int = 2
const OCCLUSION_X_OFFSET: int = 1
const OCCLUSION_Y_OFFSET: int = 1
const MIN_Z: int = 0
const MAX_Z: int = 6
const ENVIRONMENT_Z_STEP: int = 2
const SELECTED_LAYER_OPACITY: float = 1
const UNSELECTED_LAYER_OPACITY: float = 0.35


var all_tiles_dict: Dictionary = {} # Dictionary[Vector3i, Dictionary] - Maps 3D coordinates to tile data
var visible_tiles_dict: Dictionary = {}
var hidden_tiles_dict: Dictionary = {}
var debug_mode := true
var current_z: int = MAX_Z
var current_max_z: int = MIN_Z


func _ready() -> void:
	collect_all_tiles()
	check_for_hidden_tiles()
	collect_visible_tiles()
	set_current_max_z()


func _input(_event):
	move_current_layer()
	dim_other_layer()

func collect_all_tiles() -> void:
	all_tiles_dict.clear()
	
	for child in get_children():
		if not child is TileMapLayer:
			continue
		for cell in child.get_used_cells():
			var coords = Vector3i(cell.x, cell.y, child.z_index)
			all_tiles_dict[coords] = {"coords":coords}
	
	# Debug output
	if debug_mode:
		print("number of tiles in the map: ")
		print(all_tiles_dict.size())
		print("all tiles in the map: ")
		print(all_tiles_dict.keys())
		print(" ")


func check_for_hidden_tiles() -> void:
	for coords in all_tiles_dict.keys():
		# Checking for possible tiles sitting right above current tile.
		# The math is the next layer, and go directly up so minus 1 in both x and y direction
		var occluding_tile = Vector3i(
			coords.x - OCCLUSION_X_OFFSET,
			coords.y - OCCLUSION_Y_OFFSET,
			coords.z + OCCLUSION_Z_OFFSET
			)
		if all_tiles_dict.has(occluding_tile):
			hidden_tiles_dict[coords] = {"coords":coords}
	
	# Debug output
	if debug_mode:
		print("number of hidden tiles: ")
		print(hidden_tiles_dict.size())
		print("hidden tiles: ") 
		print(hidden_tiles_dict.keys())
		print(" ")


func collect_visible_tiles() -> void:
	if all_tiles_dict.is_empty(): # For debugging, in case something is wrong with tile_storage
		if debug_mode:
			print("No tiles to process for hidden tile removal")
		return
	
	for coords in all_tiles_dict.keys():
		if not hidden_tiles_dict.has(coords):
			visible_tiles_dict[coords] = {"coords": coords}
	
	# Debug output
	if debug_mode:
		print("number of visible tiles: ")
		print(visible_tiles_dict.size())
		print("cleaned storage: ")
		print(visible_tiles_dict.keys())
		print(" ")


func set_current_max_z() -> void:
	if visible_tiles_dict.is_empty():
		current_max_z = MIN_Z
		current_z = MIN_Z
		return
	
	for coords in visible_tiles_dict.keys():
		if coords.z > current_max_z:
			current_max_z = coords.z
	current_z = current_max_z
	
	# Debug Output
	print("current_max_z: ", current_max_z)


func dim_other_layer() -> void:
	for child in get_children():
		if not child is TileMapLayer:
			continue
		if child.z_index <= current_z:
			child.modulate = Color(1, 1, 1, SELECTED_LAYER_OPACITY)
		else:
			child.modulate = Color(1, 1, 1, UNSELECTED_LAYER_OPACITY)


func move_current_layer() -> void:
	if Input.is_action_just_pressed("ui_up"):
		if  current_z < current_max_z:
			current_z = current_z + ENVIRONMENT_Z_STEP
			# Debug Output
			print("current_z: ", current_z)
	
	if Input.is_action_just_pressed("ui_down"):
		if  current_z > MIN_Z:
			current_z = current_z - ENVIRONMENT_Z_STEP
			# Debug Output
			print("current_z: ", current_z)
