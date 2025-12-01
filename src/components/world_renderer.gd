extends RefCounted

# World Renderer - Renders the game world (village, terrain, buildings) from loaded data
# Takes tile and building data from repositories and creates tilemap visuals

const TILE_SIZE = 48

# Village layout configuration
var village_center = Vector2i(0, 0)
var village_radius = 30  # tiles from center

func render_village(tilemap: TileMapLayer):
	"""Render the village tilemap from loaded data"""
	if not tilemap:
		push_error("WorldRenderer: No TileMapLayer provided")
		return
	
	print("WorldRenderer: Rendering village...")
	
	if not tilemap.tile_set:
		push_error("WorldRenderer: TileMapLayer has no TileSet!")
		return
	
	var catalog = DatabaseManager.tile_catalog
	if not catalog:
		push_error("WorldRenderer: No tile catalog available!")
		return
	
	# Clear existing tiles
	tilemap.clear()
	
	# Get tile data from catalog
	var grass = catalog.get_tile("ground", "grass")
	var dirt = catalog.get_tile("ground", "dirt")
	var stone = catalog.get_tile("stone", "cobblestone_gray")
	
	print("WorldRenderer: Using verified tiles")
	
	# Step 1: Fill entire area with grass
	print("  Rendering grass...")
	_fill_area_with_tile(tilemap, grass, -village_radius, -village_radius, village_radius * 2, village_radius * 2)
	
	# Step 2: Create main north-south dirt road
	print("  Rendering main road...")
	_fill_area_with_tile(tilemap, dirt, -2, -village_radius, 5, village_radius * 2)
	
	# Step 3: Create stone town square in center
	print("  Rendering town square...")
	_fill_area_with_tile(tilemap, stone, -5, -5, 11, 11)
	
	# Step 4: Get building positions from building data and draw paths
	print("  Rendering paths and buildings...")
	var building_positions = _get_building_tile_positions()
	
	print("  Found ", building_positions.size(), " buildings to render")
	
	for building_id in building_positions.keys():
		var tile_pos = building_positions[building_id]
		print("  Processing ", building_id, " at tile ", tile_pos)
		
		# Draw path from center to each building
		_draw_path(tilemap, stone, Vector2i(0, 0), tile_pos, 2)
		
		# Draw building exterior
		_render_building(tilemap, catalog, building_id, tile_pos)
	
	print("WorldRenderer: Village rendering complete!")
	print("WorldRenderer: Total tiles placed: ", tilemap.get_used_cells().size())

func _get_building_tile_positions() -> Dictionary:
	"""Convert building exterior positions from pixels to tile coordinates"""
	var positions = {}
	var building_repo = DatabaseManager.buildings
	
	for building_id in building_repo.get_building_ids():
		var building = building_repo.get_building(building_id)
		var ext_pos = building.get("exterior_position", {})
		
		var px = ext_pos.get("x", 0)
		var py = ext_pos.get("y", 0)
		var tile_x = int(px / TILE_SIZE)
		var tile_y = int(py / TILE_SIZE)
		
		positions[building_id] = Vector2i(tile_x, tile_y)
	
	return positions

func _render_building(tilemap: TileMapLayer, catalog, building_id: String, tile_pos: Vector2i):
	"""Render a building entrance marker at the specified tile position"""
	var building_repo = DatabaseManager.buildings
	var building = building_repo.get_building(building_id)
	var building_type = building.get("type", "house")
	var building_name = building.get("name", building_id)
	
	print("    Rendering building: ", building_name, " (", building_type, ")")
	
	# Get appropriate sign based on building type
	var sign_tile = {}
	match building_type:
		"tavern":
			sign_tile = catalog.get_tile("signs", "sign_inn")
		"shop":
			sign_tile = catalog.get_tile("signs", "sign_weapon")
		"church":
			sign_tile = catalog.get_tile("decorations", "gravestone")
		_:
			sign_tile = catalog.get_tile("decorations", "bench_wood")
	
	# Get door tile
	var door = catalog.get_tile("buildings", "door_wood")
	
	# Place a simple wood floor area for the building footprint
	var wood_floor = catalog.get_tile("floors", "wood_plank")
	var ext_size = building.get("exterior_size", {"width": 3, "height": 3})
	var width = ext_size.get("width", 3)
	var height = ext_size.get("height", 3)
	
	var start_x = tile_pos.x - width / 2
	var start_y = tile_pos.y - height / 2
	
	# Fill building footprint with wood floor
	for x in range(width):
		for y in range(height):
			_place_tile(tilemap, wood_floor, start_x + x, start_y + y)
	
	# Place door at front center (bottom)
	var door_tile_x = tile_pos.x
	var door_tile_y = start_y + height
	_place_tile(tilemap, door, door_tile_x, door_tile_y)
	
	# Place sign next to door
	if not sign_tile.is_empty():
		_place_tile(tilemap, sign_tile, tile_pos.x + 1, start_y + height)
	
	# Store the door position for entry detection (in pixels)
	var door_pixel_x = door_tile_x * TILE_SIZE + TILE_SIZE / 2
	var door_pixel_y = door_tile_y * TILE_SIZE + TILE_SIZE / 2
	_update_building_entry_point(building_id, door_pixel_x, door_pixel_y)

func _update_building_entry_point(building_id: String, px: int, py: int):
	"""Update the building's entry point to match the rendered door position"""
	var building_repo = DatabaseManager.buildings
	var building = building_repo.get_building(building_id)
	if building.is_empty():
		return
	
	if not building.has("entry_points"):
		building["entry_points"] = {}
	
	building["entry_points"]["main_door"] = {
		"x": px,
		"y": py,
		"facing": "up"
	}
	building["entry_points"]["default"] = building["entry_points"]["main_door"]
	
	print("  Building ", building_id, " door at pixel (", px, ", ", py, ")")

func _place_tile(tilemap: TileMapLayer, tile: Dictionary, x: int, y: int):
	if tile.is_empty():
		return
	
	var source_id = tile.get("source_id", 0)
	var coords = Vector2i(tile.get("x", 0), tile.get("y", 0))
	tilemap.set_cell(Vector2i(x, y), source_id, coords)

func _fill_area_with_tile(tilemap: TileMapLayer, tile: Dictionary, start_x: int, start_y: int, width: int, height: int):
	if tile.is_empty():
		return
	
	var source_id = tile.get("source_id", 0)
	var coords = Vector2i(tile.get("x", 0), tile.get("y", 0))
	
	for x in range(start_x, start_x + width):
		for y in range(start_y, start_y + height):
			tilemap.set_cell(Vector2i(x, y), source_id, coords)

func _draw_path(tilemap: TileMapLayer, tile: Dictionary, from: Vector2i, to: Vector2i, width: int):
	if tile.is_empty():
		return
	
	var source_id = tile.get("source_id", 0)
	var coords = Vector2i(tile.get("x", 0), tile.get("y", 0))
	var half_width = width / 2
	
	var min_x = mini(from.x, to.x)
	var max_x = maxi(from.x, to.x)
	for x in range(min_x - half_width, max_x + half_width + 1):
		for dy in range(-half_width, half_width + 1):
			tilemap.set_cell(Vector2i(x, from.y + dy), source_id, coords)
	
	var min_y = mini(from.y, to.y)
	var max_y = maxi(from.y, to.y)
	for y in range(min_y - half_width, max_y + half_width + 1):
		for dx in range(-half_width, half_width + 1):
			tilemap.set_cell(Vector2i(to.x + dx, y), source_id, coords)

