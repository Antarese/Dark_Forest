extends Node2D


const TILE_PARTS_COUNT: int = 3
const OCCLUSION_Z_OFFSET: int = 2
const OCCLUSION_X_OFFSET: int = 1
const OCCLUSION_Y_OFFSET: int = 1

var tile_storage = {} # Dictionary[Vector3i, Dictionary] - Maps 3D coordinates to tile data
var debug_mode := true


func _ready() -> void:
	collect_all_tiles()
	remove_hidden_tiles()


func collect_all_tiles() -> void:
	tile_storage.clear()
	
	for child in get_children():
		if not child is TileMapLayer:
			continue
		for cell in child.get_used_cells():
			var coords = Vector3i(child.z_index, cell.x, cell.y)
			tile_storage[coords] = {"coords":coords}
	
	# Debug output
	if debug_mode:
		print("all tiles in the map: ")
		print(tile_storage.keys())


func remove_hidden_tiles() -> void:
	if tile_storage.is_empty(): # For debugging, in case something is wrong with tile_storage
		if debug_mode:
			print("No tiles to process for hidden tile removal")
		return
	
	var hidden_tiles = []
	
	for coords in tile_storage.keys():
		# Checking for possible tiles sitting right above current tile.
		# The math is the next layer, and go directly up so minus 1 in both x and y direction
		var tile_above = Vector3i(
			coords.x + OCCLUSION_Z_OFFSET,
			coords.y - OCCLUSION_X_OFFSET,
			coords.z - OCCLUSION_Y_OFFSET
			)
		if tile_storage.has(tile_above):
			hidden_tiles.append(coords)
		
	# Debug output
	if debug_mode:
		print("hidden tiles: ") 
		print(hidden_tiles)
	
	for key in hidden_tiles:
		tile_storage.erase(key)
	
	# Debug output
	if debug_mode:
		print("cleaned storage: ")
		print(tile_storage.keys())
