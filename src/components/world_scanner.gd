extends RefCounted

# WorldScanner - Scans the game world and provides LLM-friendly context
# Extracts spatial information, objects, NPCs, and tile data

const TILE_SIZE = 32
const DEFAULT_SCAN_RADIUS = 10  # tiles

var _tilemap: TileMapLayer
var _scene_root: Node

func initialize(scene_root: Node, tilemap: TileMapLayer = null):
	_scene_root = scene_root
	_tilemap = tilemap

# Scan the area around a character and return LLM-friendly context
func scan_around(character: Node2D, radius_tiles: int = DEFAULT_SCAN_RADIUS) -> Dictionary:
	var char_pos = character.global_position
	var char_tile = Vector2i(
		int(char_pos.x / TILE_SIZE),
		int(char_pos.y / TILE_SIZE)
	)
	
	var context = {
		"character_position": {
			"x": char_pos.x,
			"y": char_pos.y,
			"tile_x": char_tile.x,
			"tile_y": char_tile.y
		},
		"scan_radius_tiles": radius_tiles,
		"scan_radius_pixels": radius_tiles * TILE_SIZE,
		"walkable_tiles": [],
		"blocked_tiles": [],
		"nearby_entities": [],
		"nearby_objects": [],
		"known_locations": []
	}
	
	# Scan tiles in radius
	if _tilemap:
		context["walkable_tiles"] = _scan_walkable_tiles(char_tile, radius_tiles)
		context["blocked_tiles"] = _scan_blocked_tiles(char_tile, radius_tiles)
	
	# Scan for nearby entities (NPCs, player)
	context["nearby_entities"] = _scan_entities(char_pos, radius_tiles * TILE_SIZE)
	
	# Scan for nearby interactable objects
	context["nearby_objects"] = _scan_objects(char_pos, radius_tiles * TILE_SIZE)
	
	# Scan for known locations (buildings, landmarks)
	context["known_locations"] = _scan_known_locations(char_pos)
	
	return context

func _scan_walkable_tiles(center: Vector2i, radius: int) -> Array:
	var walkable = []
	
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var tile_pos = Vector2i(center.x + dx, center.y + dy)
			
			if _is_tile_walkable(tile_pos):
				walkable.append({
					"tile_x": tile_pos.x,
					"tile_y": tile_pos.y,
					"world_x": tile_pos.x * TILE_SIZE + TILE_SIZE / 2,
					"world_y": tile_pos.y * TILE_SIZE + TILE_SIZE / 2
				})
	
	return walkable

func _scan_blocked_tiles(center: Vector2i, radius: int) -> Array:
	var blocked = []
	
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var tile_pos = Vector2i(center.x + dx, center.y + dy)
			
			if not _is_tile_walkable(tile_pos):
				blocked.append({
					"tile_x": tile_pos.x,
					"tile_y": tile_pos.y
				})
	
	return blocked

func _is_tile_walkable(tile_pos: Vector2i) -> bool:
	if not _tilemap:
		return true
	
	var source_id = _tilemap.get_cell_source_id(tile_pos)
	if source_id == -1:
		return true  # Empty tiles are walkable
	
	# Check for custom walkable data if the tileset has it
	var tile_data = _tilemap.get_cell_tile_data(tile_pos)
	if tile_data:
		# Check if tileset has a "walkable" custom data layer
		var tileset = _tilemap.tile_set
		if tileset:
			var has_walkable_layer = false
			for i in range(tileset.get_custom_data_layers_count()):
				if tileset.get_custom_data_layer_name(i) == "walkable":
					has_walkable_layer = true
					break
			
			if has_walkable_layer:
				if tile_data.get_custom_data("walkable") == false:
					return false
	
	# Default: assume walkable if no custom data
	return true

func _scan_entities(center: Vector2, radius: float) -> Array:
	var entities = []
	
	if not _scene_root:
		return entities
	
	var npcs = _scene_root.get_tree().get_nodes_in_group("NPC")
	for npc in npcs:
		if not npc is Node2D:
			continue
		
		var dist = center.distance_to(npc.global_position)
		if dist <= radius:
			var entity_data = {
				"type": "npc",
				"name": npc.name,
				"x": npc.global_position.x,
				"y": npc.global_position.y,
				"distance": dist
			}
			
			if npc.has_method("get_display_name"):
				entity_data["display_name"] = npc.get_display_name()
			elif "display_name" in npc:
				entity_data["display_name"] = npc.display_name
			
			entities.append(entity_data)
	
	var players = _scene_root.get_tree().get_nodes_in_group("player")
	for player in players:
		if not player is Node2D:
			continue
		
		var dist = center.distance_to(player.global_position)
		if dist <= radius and dist > 0:
			entities.append({
				"type": "player",
				"name": "Player",
				"x": player.global_position.x,
				"y": player.global_position.y,
				"distance": dist
			})
	
	entities.sort_custom(func(a, b): return a.distance < b.distance)
	return entities

func _scan_objects(center: Vector2, radius: float) -> Array:
	var objects = []
	
	if not _scene_root:
		return objects
	
	var interactables = _scene_root.get_tree().get_nodes_in_group("interactable")
	for obj in interactables:
		if not obj is Node2D:
			continue
		if obj.is_in_group("NPC"):
			continue
		
		var dist = center.distance_to(obj.global_position)
		if dist <= radius:
			objects.append({
				"type": _get_object_type(obj),
				"name": obj.name,
				"x": obj.global_position.x,
				"y": obj.global_position.y,
				"distance": dist
			})
	
	objects.sort_custom(func(a, b): return a.distance < b.distance)
	return objects

func _get_object_type(obj: Node) -> String:
	if obj.is_in_group("item"):
		return "item"
	if obj.is_in_group("container"):
		return "container"
	if obj.is_in_group("door"):
		return "door"
	if obj.is_in_group("building"):
		return "building"
	return "object"

func _scan_known_locations(char_pos: Vector2) -> Array:
	var locations = []
	
	# Get all buildings from the building repository
	var building_ids = DatabaseManager.buildings.get_building_ids()
	
	for building_id in building_ids:
		var building = DatabaseManager.buildings.get_building(building_id)
		if not building:
			continue
		
		var location_data = {
			"id": building_id,
			"name": building.get("name", building_id),
			"type": building.get("type", "building")
		}
		
		# Get entry point (door location) - entry_points is a Dictionary with named doors
		var entry_points = building.get("entry_points", {})
		if not entry_points.is_empty():
			# Use "default" or "main_door" as primary entrance
			var entry = entry_points.get("default", entry_points.get("main_door", {}))
			if entry.is_empty() and entry_points.size() > 0:
				# Fallback to first entry point
				entry = entry_points.values()[0]
			
			if not entry.is_empty():
				var entry_x = entry.get("x", 0)
				var entry_y = entry.get("y", 0)
				location_data["entrance_x"] = entry_x
				location_data["entrance_y"] = entry_y
				location_data["distance_to_entrance"] = char_pos.distance_to(Vector2(entry_x, entry_y))
		
		# Get building bounds if available
		var ext_pos = building.get("exterior_position", {})
		var ext_size = building.get("exterior_size", {})
		if not ext_pos.is_empty() and not ext_size.is_empty():
			location_data["bounds"] = {
				"x": ext_pos.get("x", 0),
				"y": ext_pos.get("y", 0),
				"width": ext_size.get("width", 0),
				"height": ext_size.get("height", 0)
			}
			# Calculate center of building
			var center_x = ext_pos.get("x", 0) + ext_size.get("width", 0) / 2
			var center_y = ext_pos.get("y", 0) + ext_size.get("height", 0) / 2
			location_data["center_x"] = center_x
			location_data["center_y"] = center_y
		
		# Include description if available (from building itself, not just env_state)
		if building.has("description"):
			location_data["description"] = building.get("description", "")
		
		locations.append(location_data)
	
	# Sort by distance to entrance
	locations.sort_custom(func(a, b): 
		var dist_a = a.get("distance_to_entrance", 999999)
		var dist_b = b.get("distance_to_entrance", 999999)
		return dist_a < dist_b
	)
	
	return locations

func get_context_for_prompt(character: Node2D, radius_tiles: int = DEFAULT_SCAN_RADIUS) -> String:
	var context = scan_around(character, radius_tiles)
	var lines = []
	
	lines.append("## Your Current Location")
	var pos = context.character_position
	lines.append("You are at position (%d, %d) in the world." % [pos.x, pos.y])
	
	# Known locations (buildings, landmarks)
	if context.known_locations.size() > 0:
		lines.append("")
		lines.append("## Known Locations")
		lines.append("These are places you know about in the world. Use the entrance coordinates when moving to a building.")
		for loc in context.known_locations:
			var name = loc.get("name", loc.get("id", "Unknown"))
			var loc_type = loc.get("type", "location")
			
			if loc.has("entrance_x") and loc.has("entrance_y"):
				var dist = loc.get("distance_to_entrance", 0)
				lines.append("- %s (%s): entrance at (%d, %d), %.0f pixels away" % [
					name, loc_type, loc.entrance_x, loc.entrance_y, dist
				])
			elif loc.has("center_x") and loc.has("center_y"):
				lines.append("- %s (%s): center at (%d, %d)" % [
					name, loc_type, loc.center_x, loc.center_y
				])
			else:
				lines.append("- %s (%s)" % [name, loc_type])
	
	if context.nearby_entities.size() > 0:
		lines.append("")
		lines.append("## Nearby Characters")
		for entity in context.nearby_entities:
			var display = entity.get("display_name", entity.name)
			lines.append("- %s (%s) at (%d, %d), %.0f pixels away" % [
				display, entity.type, entity.x, entity.y, entity.distance
			])
	
	if context.nearby_objects.size() > 0:
		lines.append("")
		lines.append("## Nearby Objects")
		for obj in context.nearby_objects:
			lines.append("- %s (%s) at (%d, %d), %.0f pixels away" % [
				obj.name, obj.type, obj.x, obj.y, obj.distance
			])
	
	lines.append("")
	lines.append("## Movement")
	lines.append("When asked to go somewhere, use the 'move' action with the coordinates of that location.")
	lines.append("For buildings, move to the entrance coordinates listed above.")
	lines.append("You can move anywhere in the world - there is no range limit for known locations.")
	
	return "\n".join(lines)

func get_context_json(character: Node2D, radius_tiles: int = DEFAULT_SCAN_RADIUS) -> String:
	var context = scan_around(character, radius_tiles)
	return JSON.stringify(context, "  ")

