extends RefCounted

# Interior Renderer - Renders building interior scenes from loaded data
# Takes building data from building_repository and creates visual representation

const TILE_SIZE = 48
const NPC_SCENE = preload("res://src/entities/npc/npc.tscn")

var _tilemap: TileMapLayer = null
var _interior_root: Node2D = null
var _width: int = 8
var _height: int = 6

func render_interior(building_id: String, parent_node: Node2D) -> Node2D:
	"""Render a complete interior scene for a building from loaded data"""
	var building_repo = DatabaseManager.buildings
	var building = building_repo.get_building(building_id)
	
	if building.is_empty():
		push_error("InteriorRenderer: Building not found: " + building_id)
		return null
	
	var interior_data = building.get("interior", {})
	if interior_data.is_empty():
		push_error("InteriorRenderer: No interior data for building: " + building_id)
		return null
	
	_width = interior_data.get("width", 8)
	_height = interior_data.get("height", 6)
	
	print("InteriorRenderer: Rendering interior for ", building.get("name", building_id))
	
	# Create root node for interior
	_interior_root = Node2D.new()
	_interior_root.name = "Interior_" + building_id
	parent_node.add_child(_interior_root)
	
	# Create background (dark area outside the room)
	_render_background()
	
	# Create tilemap for floor (z_index -1 so player renders on top)
	_render_floor(interior_data)
	
	# Create walls around the room
	_render_walls(interior_data)
	
	# Place furniture
	_render_furniture(interior_data.get("furniture", []))
	
	# Create exit door visual
	_render_exit_door()
	
	# Spawn NPCs for this building
	_spawn_npcs(building_id, interior_data)
	
	return _interior_root

func _render_background():
	"""Render a dark background outside the room bounds"""
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.1, 0.1, 0.15, 1.0)
	bg.size = Vector2(2000, 2000)
	bg.position = Vector2(-1000, -1000)
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interior_root.add_child(bg)

func _render_floor(interior_data: Dictionary):
	"""Render the floor tilemap from interior layout data"""
	var floor_tile_name = interior_data.get("floor_tile", "wood_plank")
	
	_tilemap = TileMapLayer.new()
	_tilemap.name = "FloorTileMap"
	_tilemap.z_index = -2
	
	var tileset = load("res://src/assets/sprites/tilesets/village_tileset.tres")
	if tileset:
		_tilemap.tile_set = tileset
	else:
		push_error("InteriorRenderer: Could not load tileset")
		return
	
	_interior_root.add_child(_tilemap)
	
	var catalog = DatabaseManager.tile_catalog
	var floor_tile = catalog.get_tile("floors", floor_tile_name)
	if floor_tile.is_empty():
		floor_tile = catalog.get_tile("floors", "wood_plank")
	
	var source_id = floor_tile.get("source_id", 0)
	var coords = Vector2i(floor_tile.get("x", 0), floor_tile.get("y", 0))
	
	for x in range(_width):
		for y in range(_height):
			_tilemap.set_cell(Vector2i(x, y), source_id, coords)
	
	_tilemap.position = Vector2(-_width * TILE_SIZE / 2.0, -_height * TILE_SIZE / 2.0)
	print("  Rendered floor: ", _width, "x", _height, " tiles")

func _render_walls(_interior_data: Dictionary):
	"""Render walls around the room perimeter with collision"""
	var wall_color = Color(0.3, 0.25, 0.2, 1.0)
	var wall_thickness = 24
	
	var room_width = _width * TILE_SIZE
	var room_height = _height * TILE_SIZE
	var offset = Vector2(-room_width / 2.0, -room_height / 2.0)
	
	_render_wall_with_collision("WallTop", wall_color,
		Vector2(room_width + wall_thickness * 2, wall_thickness),
		offset + Vector2(-wall_thickness, -wall_thickness))
	
	_render_wall_with_collision("WallLeft", wall_color,
		Vector2(wall_thickness, room_height + wall_thickness * 2),
		offset + Vector2(-wall_thickness, -wall_thickness))
	
	_render_wall_with_collision("WallRight", wall_color,
		Vector2(wall_thickness, room_height + wall_thickness * 2),
		offset + Vector2(room_width, -wall_thickness))
	
	var door_width = TILE_SIZE * 1.5
	var door_x = room_width / 2 - door_width / 2
	
	_render_wall_with_collision("WallBottomLeft", wall_color,
		Vector2(door_x + wall_thickness, wall_thickness),
		offset + Vector2(-wall_thickness, room_height))
	
	_render_wall_with_collision("WallBottomRight", wall_color,
		Vector2(room_width - door_x - door_width + wall_thickness, wall_thickness),
		offset + Vector2(door_x + door_width, room_height))

func _render_wall_with_collision(wall_name: String, color: Color, size: Vector2, pos: Vector2):
	"""Render a wall with both visual and collision"""
	var wall_visual = ColorRect.new()
	wall_visual.name = wall_name
	wall_visual.color = color
	wall_visual.size = size
	wall_visual.position = pos
	wall_visual.z_index = 1
	wall_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interior_root.add_child(wall_visual)
	
	var wall_body = StaticBody2D.new()
	wall_body.name = wall_name + "_Collision"
	wall_body.position = pos + size / 2
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	
	wall_body.add_child(collision)
	_interior_root.add_child(wall_body)

func _render_exit_door():
	"""Render a visual door at the bottom center with collision"""
	var room_height = _height * TILE_SIZE
	var room_width = _width * TILE_SIZE
	var door_width = TILE_SIZE * 1.5
	
	# Visual door
	var door = ColorRect.new()
	door.name = "ExitDoor"
	door.color = Color(0.5, 0.35, 0.2, 1.0)
	door.size = Vector2(door_width, 24)
	door.position = Vector2(-door_width / 2, room_height / 2 - 8)
	door.z_index = 0
	door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_interior_root.add_child(door)
	
	var label = Label.new()
	label.text = "EXIT"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(door_width / 2 - 16, 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	door.add_child(label)
	
	# Door collision - blocks player from walking out the door gap
	var door_body = StaticBody2D.new()
	door_body.name = "ExitDoor_Collision"
	door_body.position = Vector2(0, room_height / 2 + 12)  # At the door threshold
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(door_width, 16)  # Thin barrier at the exit
	collision.shape = shape
	
	door_body.add_child(collision)
	_interior_root.add_child(door_body)

func _render_furniture(furniture_list: Array):
	"""Render furniture sprites based on furniture data"""
	for furniture in furniture_list:
		var furniture_node = _render_furniture_piece(furniture)
		if furniture_node:
			_interior_root.add_child(furniture_node)

func _render_furniture_piece(furniture_data: Dictionary) -> Control:
	"""Render a visual node for a piece of furniture"""
	var furniture_type = furniture_data.get("type", "unknown")
	var x = furniture_data.get("x", 0)
	var y = furniture_data.get("y", 0)
	var fwidth = furniture_data.get("width", 1)
	var fheight = furniture_data.get("height", 1)
	
	var furniture = ColorRect.new()
	furniture.name = furniture_type
	furniture.size = Vector2(fwidth * TILE_SIZE, fheight * TILE_SIZE)
	furniture.z_index = 0
	
	var room_offset = Vector2(-_width * TILE_SIZE / 2.0, -_height * TILE_SIZE / 2.0)
	furniture.position = room_offset + Vector2(x * TILE_SIZE, y * TILE_SIZE)
	
	match furniture_type:
		"bar_counter", "counter":
			furniture.color = Color(0.4, 0.25, 0.1, 0.9)
		"fireplace", "forge":
			furniture.color = Color(0.8, 0.3, 0.1, 0.9)
		"table":
			furniture.color = Color(0.5, 0.35, 0.15, 0.9)
		"bed":
			furniture.color = Color(0.6, 0.4, 0.5, 0.9)
		"shelves", "bookshelf", "weapon_rack", "armor_stand", "herb_drying_rack":
			furniture.color = Color(0.35, 0.25, 0.1, 0.9)
		"altar":
			furniture.color = Color(0.7, 0.7, 0.7, 0.9)
		"pew":
			furniture.color = Color(0.4, 0.3, 0.15, 0.9)
		"desk":
			furniture.color = Color(0.45, 0.32, 0.18, 0.9)
		"anvil":
			furniture.color = Color(0.3, 0.3, 0.35, 0.9)
		"cauldron":
			furniture.color = Color(0.2, 0.2, 0.25, 0.9)
		"crate", "barrel":
			furniture.color = Color(0.5, 0.35, 0.2, 0.9)
		_:
			furniture.color = Color(0.4, 0.3, 0.2, 0.9)
	
	furniture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var label = Label.new()
	label.text = furniture_type
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(2, 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	furniture.add_child(label)
	
	return furniture

func _spawn_npcs(building_id: String, interior_data: Dictionary):
	"""Spawn NPCs that belong in this building"""
	var npc_positions = interior_data.get("npc_positions", {})
	
	if npc_positions.is_empty():
		print("  No NPCs defined for this interior")
		return
	
	print("  Spawning ", npc_positions.size(), " NPCs")
	
	for npc_id in npc_positions.keys():
		var pos_data = npc_positions[npc_id]
		var tile_x = pos_data.get("x", 0)
		var tile_y = pos_data.get("y", 0)
		
		var room_offset = Vector2(-_width * TILE_SIZE / 2.0, -_height * TILE_SIZE / 2.0)
		var world_pos = room_offset + Vector2(tile_x * TILE_SIZE + TILE_SIZE / 2, tile_y * TILE_SIZE + TILE_SIZE / 2)
		
		var npc_instance = NPC_SCENE.instantiate()
		npc_instance.name = "Interior_" + npc_id
		npc_instance.npc_id = npc_id
		npc_instance.position = world_pos
		_interior_root.add_child(npc_instance)
		
		if not npc_instance.is_in_group("interactable"):
			npc_instance.add_to_group("interactable")
		if not npc_instance.is_in_group("NPC"):
			npc_instance.add_to_group("NPC")
		
		print("    Spawned ", npc_id, " at ", world_pos)

func get_entry_position(building_id: String, _entry_name: String = "default") -> Vector2:
	"""Get the world position of the entry point in the interior (near the door)"""
	var building_repo = DatabaseManager.buildings
	var building = building_repo.get_building(building_id)
	var interior = building.get("interior", {})
	var height = interior.get("height", 6)
	
	return Vector2(0, (height / 2.0 - 1.5) * TILE_SIZE)

