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
const HIGHLIGHT_SOURCE_ID_STEP: int = 200
const HIGHLIGHT_ATLAS_COORDS_STEP: Vector2i = Vector2i(0, 0)
const HIGHLIGHT_ALTERNATIVE_TILE_STEP: int = 0
const INVALID_SOURCE_ID = -1
const UNUSED_VECTOR2I = Vector2i(-999, -999)
const UNUSED_VECTOR3I = Vector3i(-999, -999, -999)


# Dictionary[Vector3i, Dictionary] - Maps 3D coordinates to tile data
var debug_mode := true
var all_tiles_dict: Dictionary = {} 
var current_z: int = MAX_Z
var current_layer: TileMapLayer
var level_max_z: int = MIN_Z
var child_count: int = 0
var last_highlighted_coords: Vector2i = UNUSED_VECTOR2I
var currently_highlighted_tile: Vector3i = UNUSED_VECTOR3I


func _ready() -> void:
	collect_all_tiles()
	collect_occluded_tiles()
	set_level_max_z()
	set_current_layer()
	apply_occluded_tiles_effect()


func _input(event: InputEvent) -> void:
	var old_z = current_z
	move_current_layer()
	if old_z != current_z:
		apply_unselected_layer_effect()
	if event is InputEventMouseMotion:
		handle_mouse_movement()


func handle_mouse_movement() -> void:
	var current_coords = get_mouse_coords()
	
	if current_coords != last_highlighted_coords:
		apply_highlighted_tile_effect()
		last_highlighted_coords = current_coords


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
				"layer_name": child,
				"source_id": child.get_cell_source_id(cell),
				"atlas_coords": child.get_cell_atlas_coords(cell)
				}
	
	if child_count == 0:
		print("Error: No children in the node")
	
	# Debug output
	if debug_mode:
		print("Total TileMapLayer children: ", child_count)
		print("total tiles: ", all_tiles_dict.size())
		print("all tiles in the map: ", all_tiles_dict)


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


func set_level_max_z() -> void:
	if all_tiles_dict.is_empty():
		level_max_z = MIN_Z
		current_z = MIN_Z
		print("Error: No tiles in the map")
		return
	
	level_max_z = MIN_Z
	var has_visible_tiles = false
	
	for coords in all_tiles_dict.keys():
		if all_tiles_dict[coords]["is_visible"]:
			has_visible_tiles = true
			if coords.z > level_max_z:
				level_max_z = coords.z
	
	if not has_visible_tiles:
		level_max_z = MIN_Z
		current_z = MIN_Z
		print("Error: No visible tiles in the map")
		return
	
	current_z = level_max_z
	
	# Debug Output
	if debug_mode:
		print("levelt_max_z: ", level_max_z)
		print(" ")


func set_current_layer():
	for coords in all_tiles_dict.keys():
		if not coords.z == current_z:
			continue
		current_layer = all_tiles_dict[coords]["layer_name"]
		if debug_mode:
			print("current layer: ", current_layer)
		return current_layer


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
		if  current_z < level_max_z:
			current_z = current_z + ENVIRONMENT_Z_STEP
			set_current_layer()
			# Debug Output
			print("current_z: ", current_z)
	
	if Input.is_action_just_pressed("ui_down"):
		if  current_z > MIN_Z:
			current_z = current_z - ENVIRONMENT_Z_STEP
			set_current_layer()
			# Debug Output
			print("current_z: ", current_z)


# Helper function to get all tiles on any given layer
# Can be called if all tiles on a layer are needed
# Might be redundant
func get_all_tiles_on_layer(layer_z: int) -> Array[Vector2i]: 
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
		if debug_mode:
			print("replace tile: ", coords3i)
			print("from atlas_coords: ", current_atlas_coords, ", source_id: ", current_source_id)
			print("to atlas_coords: ", replacement_atlas_coords, ", source_id: ", replacement_source_id)


func get_mouse_coords() -> Vector2i:
	var mouse_pos = get_global_mouse_position()
	var local_mouse_pos = current_layer.local_to_map(mouse_pos)
	print(local_mouse_pos.x, ", ", local_mouse_pos.y, " on layer: ", current_layer)
	return Vector2i(local_mouse_pos.x, local_mouse_pos.y)


func apply_highlighted_tile_effect() -> void:
	remove_highlighted_tile_effect()
	var map_coords = get_mouse_coords()
	for coords in all_tiles_dict.keys():
		if map_coords == Vector2i(coords.x, coords.y) and all_tiles_dict[coords]["is_visible"]:
			var current_source_id: int = current_layer.get_cell_source_id(map_coords)
			var current_atlas_coords: Vector2i = current_layer.get_cell_atlas_coords(map_coords)
			var current_alternative_tile = current_layer.get_cell_alternative_tile(map_coords)
			
			if current_source_id == all_tiles_dict[coords]["source_id"]:
				var replacement_source_id = current_source_id + HIGHLIGHT_SOURCE_ID_STEP
				var replacement_atlas_coords = current_atlas_coords + HIGHLIGHT_ATLAS_COORDS_STEP
				var replacement_alternative_tile = current_alternative_tile + HIGHLIGHT_ALTERNATIVE_TILE_STEP
			
				current_layer.set_cell(
					map_coords,
					replacement_source_id,
					replacement_atlas_coords,
					replacement_alternative_tile
					)
				
				currently_highlighted_tile = Vector3i(coords)
			# Debug Output
				if debug_mode:
					print("replace tile: ", map_coords)
					print("from atlas_coords: ", current_atlas_coords, ", source_id: ", current_source_id)
					print("to atlas_coords: ", replacement_atlas_coords, ", source_id: ", replacement_source_id)
				
				break


func remove_highlighted_tile_effect() -> void:
	if currently_highlighted_tile.x == -999:
		return
	
	#var map_coords = get_mouse_coords()
	if all_tiles_dict.has(currently_highlighted_tile):
		var tile_data = all_tiles_dict[currently_highlighted_tile]
		tile_data["layer_name"].set_cell(
			Vector2i(currently_highlighted_tile.x, currently_highlighted_tile.y),
			tile_data["source_id"],
			tile_data["atlas_coords"]
		)
	currently_highlighted_tile = Vector3i(-999, -999, -999)
