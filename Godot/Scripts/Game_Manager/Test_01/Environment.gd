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
const OCCLUDED_SOURCE_ID_STEP: int = 100
const OCCLUDED_ATLAS_COORDS_STEP: Vector2i = Vector2i(0, 0)
const OCCLUDED_ALTERNATIVE_TILE_STEP: int = 0
const INVALID_SOURCE_ID = -1


# Dictionary[Vector3i, Dictionary] - Maps 3D coordinates to tile data
var debug_mode := true
var all_tiles_dict: Dictionary = {} 
var current_z: int = MAX_Z
var current_max_z: int = MIN_Z
var child_count: int = 0


func _ready() -> void:
	collect_all_tiles()
	collect_occluded_tiles()
	set_current_max_z()
	apply_occluded_tiles_effect()


func _input(_event):
	var old_z = current_z
	move_current_layer()
	if old_z != current_z:
		apply_unselected_layer_effect()


func collect_all_tiles() -> void:
	all_tiles_dict.clear()
	child_count = 0
	
	for child in get_children():
		if not child is TileMapLayer:
			continue
		
		# Debug Output to count children
		child_count += 1
		
		for cell in child.get_used_cells():
			var coords = Vector3i(cell.x, cell.y, child.z_index)
			all_tiles_dict[coords] = {
				"is_occluded": false,
				"is_visible": true,
				"layer_name": child
				}
	
	if child_count == 0:
		print("Error: No children in the node")
	
	# Debug output
	if debug_mode:
		print("Total TileMapLayer children: ", child_count)
		print("total tiles: ", all_tiles_dict.size())
		print("all tiles in the map: ", all_tiles_dict.keys())


func collect_occluded_tiles() -> void:
	if all_tiles_dict.is_empty():
		print("Error: No environmental tile in the map")
		return
	
	for coords in all_tiles_dict.keys():
		# Checking for possible tiles sitting right above current tile.
		# The math is the next layer, and go directly up so minus 1 in both x and y direction
		var occluding_tile = Vector3i(
			coords.x - OCCLUSION_X_OFFSET,
			coords.y - OCCLUSION_Y_OFFSET,
			coords.z + OCCLUSION_Z_OFFSET
			)
		if all_tiles_dict.has(occluding_tile):
			all_tiles_dict[coords]["is_occluded"] = true
			all_tiles_dict[coords]["is_visible"] = false

	# Debug output
	if debug_mode:
		var occluded_tiles: Array[Vector3i] = []
		for coords in all_tiles_dict.keys():
			if all_tiles_dict[coords]["is_occluded"]:
				occluded_tiles.append(coords)
		print("number of occluded tiles: ", occluded_tiles.size())
		print("occluded tiles: ", occluded_tiles) 
		print(" ")


func set_current_max_z() -> void:
	if all_tiles_dict.is_empty():
		current_max_z = MIN_Z
		current_z = MIN_Z
		print("Error: No tiles in the map")
		return
	
	current_max_z = MIN_Z
	var has_visible_tiles = false
	
	for coords in all_tiles_dict.keys():
		if all_tiles_dict[coords]["is_visible"]:
			has_visible_tiles = true
			if coords.z > current_max_z:
				current_max_z = coords.z
	
	if not has_visible_tiles:
		current_max_z = MIN_Z
		current_z = MIN_Z
		print("Error: No visible tiles in the map")
		return
	
	current_z = current_max_z
	
	# Debug Output
	if debug_mode:
		print("current_max_z: ", current_max_z)
		print(" ")


func apply_unselected_layer_effect() -> void:
	if child_count == 0:
		print("Error: No children in the node")
		return
	
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


func get_all_tiles_on_layer(layer_z: int) -> Array[Vector2i]: # Currently not in use but might be useful
	var all_tiles_on_layer: Array[Vector2i] = []
	
	if all_tiles_dict.is_empty():
		print("Error: No environmental tile in the map")
		return all_tiles_on_layer
	
	for coords_3i in all_tiles_dict.keys():
		if coords_3i.z == layer_z:
			var coords2i = Vector2i(coords_3i.x, coords_3i.y)
			all_tiles_on_layer.append(coords2i)
	return all_tiles_on_layer


func apply_occluded_tiles_effect() -> void:
	if child_count == 0:
		print("Error : No children in the node")
		return
	
	for coords3i in all_tiles_dict.keys():
		if not all_tiles_dict[coords3i]["is_occluded"]:
			continue
		
		var tile_layer = all_tiles_dict[coords3i]["layer_name"]
		var coords2i = Vector2i(coords3i.x, coords3i.y)
		var current_source_id: int = tile_layer.get_cell_source_id(coords2i)
		var current_atlas_coords: Vector2i = tile_layer.get_cell_atlas_coords(coords2i)
		var current_alternative_tile = tile_layer.get_cell_alternative_tile(coords2i)
		
		if current_source_id == INVALID_SOURCE_ID:
			continue
		
		var replacement_source_id = current_source_id + OCCLUDED_SOURCE_ID_STEP
		var replacement_atlas_coords = current_atlas_coords + OCCLUDED_ATLAS_COORDS_STEP
		var replacement_alternative_tile = current_alternative_tile + OCCLUDED_ALTERNATIVE_TILE_STEP
		
		tile_layer.set_cell(
			coords2i,
			replacement_source_id,
			replacement_atlas_coords,
			replacement_alternative_tile
			)
		
		# Debug Output
		if debug_mode == true:
			print("replace tile: ", coords3i)
			print("from atlas_coords: ", current_atlas_coords, ", source_id: ", current_source_id)
			print("to atlas_coords: ", replacement_atlas_coords, ", source_id: ", replacement_source_id)



"""To do:
	1. Unify debug statements into a helper function (maybe)
	2. Add source ID validation before tile replacement - done
	3. Add error handling for edge cases - somewhat done
	4. Consider splitting the script and node into smaller nodes to handle separate function:
		- Tile Collection Node
		- Setting up the level graphically node
	5. Validate z_index steps
	6. Check for type safety consistency
	7. Rename functions more consistently
	8. Recheck repeated operations to see if combinable: all dicitonaries and children are 
	being iterated multiple times by multiple functions. - done: 1 dictionary"""
