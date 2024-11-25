"""extends TileMap

# Constants
const MAX_LAYERS = 5
const max_z = 6

# Variables
var tile_storage = {} #Dictionary storing tile data in the scene (z_index and coordinates)
var hovered_tile = null #Store the current hovered tile coordinates (Vector2i)

func _ready():
	# Prepare the tile storage by precomputing and cleaning the data
	precompute_tile()
	clean_tile_storage()

func precompute_tile():
	#Clear previous data in tile storage
	tile_storage.clear()
	#Loop through all layers and tiles in the tilemap
	for z in range(0, max_z): #Iterate through all z-index layers
		for cell in get_used_cells(z): #Get all used cells in the current layer
			var coords = Vector2i(cell.x, cell.y) # Convert cell to integer coordinates
			#Add to tile_storage if the tile is not already there or has a lower z-index
			if not tile_storage.has(coords) or tile_storage[coords].z < z:
				tile_storage[coords] = {"z":z, "coords":coords} #Store z-index and coordinates

func clean_tile_storage():
	#Removes tiles that are fully occluded by higher z-index tiles
	var keys_to_delete = [] #List to store keys of tiles to remove
	for coords in tile_storage:
		var data = tile_storage[coords]
		var z = data["z"]
		var next_coords = Vector2i(coords.x - 1, coords.y - 1) #Coordinates of a potentially occluding tile
		var next_z = z + 1 #Higher z-index of the occluding tile
		#If there's a tile above this one that occludes it, mark it for deletion
		if tile_storage.has(next_coords) and tile_storage[next_coords]["z"] == next_z:
			keys_to_delete.append(coords)
	#Remove all occluded tiles from tile_storage
	for key in keys_to_delete:
		tile_storage.erase(key)
	print(tile_storage) #Debug: print the final cleaned tile_storage

func get_mouse_coords() -> Vector2i:
	#Convert the global mouse position to local TileMap coordinates
	var mouse_pos = get_global_mouse_position() #Get the mouse position in global space
	var local_mouse_pos = local_to_map(mouse_pos) #Convert to TileMap coordinates
	return Vector2i(local_mouse_pos.x, local_mouse_pos.y) #Return as integer coordinates

func tile_storage_check(coords: Vector2i) -> Dictionary:
	#Check if the given coordinates exist in tile_storage
	if tile_storage.has(coords):
		return tile_storage[coords] #Return the stored tile data if it exists
	return {} #Return an empty dictionary if no data exists for the coordinates

func _process(delta):
	#Called every frame to update the tile highlighting based on the mouse position
	var map_coords = get_mouse_coords() #Get the current mouse position in TileMap coordinates
	var tile_data = tile_storage_check(map_coords)  #Check for tile data at the current coordinates
	if tile_data.has("z"): #If valid tile data exists
		remove_highlight() #Remove highlight from the previously hovered tile
		print(tile_data) #Debug: Print the current tile data
		highlight_tile_under_mouse(tile_data["z"], map_coords) #Highlight the current tile
		hovered_tile = map_coords #Update hovered_tile to the current coordinates
	else: #If no valid tile is under the mouse
		remove_highlight()
		print("no") #Debug: Indicate no tile is under the mouse
		#remove_highlight() #Remove highlight from the previously hovered tile
		hovered_tile = null #Reset hovered_tile

func highlight_tile_under_mouse(highlight_z:int, coords:Vector2i):
	#Highlights a tile by setting a special tile ID at a higher z-index layer
	#Highlight_z ensures the highlight appears above the tile
	# 7 is the current ID of the highligh tile in the TileSet
	set_cell(highlight_z + 1, coords, 5, Vector2i(0, 0), 0)

func remove_highlight():
	# Removes the highlight from the currently hovered tile
	if hovered_tile != null: #Ensure there is a previously hovered tile
		var previous_tile_data = tile_storage_check(hovered_tile) #Get data of the previously hovered tile
		if previous_tile_data.has("z"): #Ensure the data is valid
			#Remove the highlight by setting the tile ID to -1 at the highlight layer
			set_cell(previous_tile_data["z"] + 1, hovered_tile, -1)
		hovered_tile = null  #Reset hovered_tile to indicate no tile is currently highlighted"""

extends TileMap

#Constants
const MAX_LAYERS = 5
const MAX_Z_INDEX = 5
const HIGHLIGHT_TILE_ID = 5 #The id of the sprite tile used as highlight

#Variables
var tile_data = {} #Stores tile data (z_index and coordinates)
var hovered_tile = null #Current hovered tile coordinates (Vector2i)

func _ready():
	prepare_tile_data()

func prepare_tile_data():
	#Initialize and clean storage
	compute_tile_data()
	remove_occluded_tile()

func compute_tile_data():
	tile_data.clear()
	for z in range(MAX_Z_INDEX):
		for cell in get_used_cells(z):
			var coords = Vector2i(cell.x, cell.y)
			#Store only the highest z_index at each coordinates
			if not tile_data.has(coords) or tile_data[coords].z < z:
				tile_data[coords] = {"z":z, "coords":coords}

func remove_occluded_tile():
	#Remove tiles occluded by higher tiles in the tile column
	var to_remove = []
	for coords in tile_data.keys():
		var z = tile_data[coords].z
		var occluding_coords = coords + Vector2i(-1,-1)
		if tile_data.has(occluding_coords) and tile_data[occluding_coords].z > z:
			to_remove.append(coords)
	for coords in to_remove:
		tile_data.erase(coords)

func get_tile_coords_under_mouse() -> Vector2i:
	#Convert global mouse position to Tilemap coordinates
	return local_to_map(get_global_mouse_position())

func get_tile_data(coords: Vector2i) -> Dictionary:
	#Retrieve tile data for the given coordinates
	var current_tile_data = tile_data.get(coords)
	if current_tile_data:
		return current_tile_data
	else:
		return {}

func apply_highlight(z:int, coords: Vector2i):
	#Add highlight at mouse coordinates but at a higher z index
	set_cell(z+1, coords, HIGHLIGHT_TILE_ID)

func clear_highlight():
	#Remove the highligh when the mouse no longer hovers over it
	if hovered_tile:
		var prev_tile_info = tile_data[hovered_tile].z
		if prev_tile_info:
			set_cell(prev_tile_info + 1, hovered_tile, -1)
		hovered_tile = null

func _process(delta):
	#Highlight tile under mouse
	var mouse_coords = get_tile_coords_under_mouse()
	var tile_info = get_tile_data(mouse_coords)
	if tile_info:
		if mouse_coords != hovered_tile:
			clear_highlight()
			apply_highlight(tile_info["z"], mouse_coords)
			hovered_tile = mouse_coords
	else:
		clear_highlight()

