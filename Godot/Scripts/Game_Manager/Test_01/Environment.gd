extends Node2D


const TILE_PARTS_COUNT: int = 3
const OCCLUSION_Z_OFFSET: int = 2
const OCCLUSION_X_OFFSET: int = 1
const OCCLUSION_Y_OFFSET: int = 1
const MIN_Z: int = 0
const MAX_Z: int = 6
# Environment z_indexes are 0,2,4,6 while characters' z_indexes are 1,3,5,7
const ENVIRONMENT_Z_STEP: int = 2
const SELECTED_LAYER_OPACITY: float = 1
const UNSELECTED_LAYER_OPACITY: float = 0.25
# Atlas organization structure is original atlas: n. occluded atlas: n+100. highlight atlas: n+200
const occluded_atlas_step: int = 100


# Dictionary[Vector3i, Dictionary] - Maps 3D coordinates to tile data
var all_tiles_dict: Dictionary = {} 
var visible_tiles_dict: Dictionary = {}
var occluded_tiles_dict: Dictionary = {}
var debug_mode := true
var current_z: int = MAX_Z
var current_max_z: int = MIN_Z


func _ready() -> void:
	collect_all_tiles()
	check_for_occluded_tiles()
	collect_visible_tiles()
	set_current_max_z()
	apply_occluded_tiles_effect()


func _input(_event):
	move_current_layer()
	apply_unselected_layer_effect()


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


func check_for_occluded_tiles() -> void:
	for coords in all_tiles_dict.keys():
		# Checking for possible tiles sitting right above current tile.
		# The math is the next layer, and go directly up so minus 1 in both x and y direction
		var occluding_tile = Vector3i(
			coords.x - OCCLUSION_X_OFFSET,
			coords.y - OCCLUSION_Y_OFFSET,
			coords.z + OCCLUSION_Z_OFFSET
			)
		if all_tiles_dict.has(occluding_tile):
			occluded_tiles_dict[coords] = {"coords":coords}
	
	# Debug output
	if debug_mode:
		print("number of occluded tiles: ")
		print(occluded_tiles_dict.size())
		print("occluded tiles: ") 
		print(occluded_tiles_dict.keys())
		print(" ")


func collect_visible_tiles() -> void:
	if all_tiles_dict.is_empty(): # For debugging, in case something is wrong with tile_storage
		if debug_mode:
			print("No tiles to process for occluded tile removal")
		return
	
	for coords in all_tiles_dict.keys():
		if not occluded_tiles_dict.has(coords):
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


func apply_unselected_layer_effect() -> void:
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


func get_all_tiles_on_layer(layer_z: int):
	var all_tiles_on_layer: Array[Vector2i] = []
	for coords_3i in all_tiles_dict.keys():
		if coords_3i.z == layer_z:
			var coords2i = Vector2i(coords_3i.x, coords_3i.y)
			all_tiles_on_layer.append(coords2i)
	return all_tiles_on_layer


func get_all_occluded_tiles_on_layer(layer_z: int):
	var all_occluded_tiles_on_layer: Array[Vector2i] = []
	for coords_3i in occluded_tiles_dict.keys():
		if coords_3i.z == layer_z:
			var coords2i = Vector2i(coords_3i.x, coords_3i.y)
			all_occluded_tiles_on_layer.append(coords2i)
	return all_occluded_tiles_on_layer 


func apply_occluded_tiles_effect() -> void:
	for child in get_children():
		if not child is TileMapLayer:
			continue
		
		var occluded_tiles_on_layer: Array[Vector2i] = get_all_occluded_tiles_on_layer(child.z_index)
		
		# Debug Output
		if debug_mode == true:
			print("occluded tiles on layer: ", child.z_index, " are: ", occluded_tiles_on_layer)
		
		for coords2i in occluded_tiles_on_layer:
			var current_source_id: int = child.get_cell_source_id(coords2i)
			var current_atlas_coords: Vector2i = child.get_cell_atlas_coords(coords2i)
			var current_alternative_tile = child.get_cell_alternative_tile(coords2i)
			
			if current_source_id == -1:
				continue
			
			var replacement_source_id = current_source_id + occluded_atlas_step
			
			# Debug Output
			if debug_mode == true:
				print("replacement tile: ")
				print("	replacement source id: ", replacement_source_id)
				print("	replacement atlas coords: ", current_atlas_coords)
				print("	replacement alternative tile: ", current_alternative_tile)
			
			child.set_cell(
				coords2i,
				replacement_source_id,
				current_atlas_coords,
				current_alternative_tile
			)

"""To do:
	1. Unify debug statements into a helper function (maybe)
	2. Add source ID validation before tile replacement
	3. Add error handling for edge cases
	4. Consider splitting the script and node into smaller nodes to handle separate function:
		- Tile Collection Node
		- Setting up the level graphically node
	5. Validate z_index steps
	6. Check for type safety consistency
	7. Rename functions more consistently
	8. Recheck repeated operations to see if combinable: all dicitonaries and children are 
	being iterated multiple times by multiple functions."""
