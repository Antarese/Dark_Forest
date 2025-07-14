extends Node2D

var tile_storage = {} # Dictionary storing tile data in the scene (z_index and coordinates)
var debug_mode := true

func _ready():
	collect_all_tiles()
	remove_hidden_tiles()

# Converts tile z, x, y values into a string key for the dictionary
func generate_tile_key(z: int, x: int, y: int) -> String:
	return str(z) + "," + str(x) + "," + str(y)

func collect_all_tiles():
	tile_storage.clear()
	
	for child in get_children():
		if child is TileMapLayer:
			for cell in child.get_used_cells():
				var coords = Vector2i(cell.x, cell.y)
				var key = generate_tile_key(child.z_index, coords.x, coords.y)
				tile_storage[key] = {"z":child.z_index, "coords":coords}
	
	# Debug print
	if debug_mode:
		print("all tiles in the map: ")
		print(tile_storage.keys())

func remove_hidden_tiles():
	var hidden_tiles = []
	
	for key in tile_storage.keys():
		var parts = key.split(",")
		if parts.size() != 3:
			continue # Skip invalid keys
		var z = int(parts[0])
		var x = int(parts[1])
		var y = int(parts[2])
		var tile_above = generate_tile_key(z+2, x-1, y-1)
		if tile_storage.has(tile_above):
			hidden_tiles.append(key)
		
	# Debug print
	if debug_mode:
		print("hidden tiles: ") 
		print(hidden_tiles)
	
	for key in hidden_tiles:
		tile_storage.erase(key)
	
	# Debug Print
	if debug_mode:
		print("cleaned storage: ")
		print(tile_storage.keys())
