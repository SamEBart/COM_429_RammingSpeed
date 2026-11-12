extends Node

# Dependencies
@export var settings : GenerationSettings
@export_category("Dependencies")
@export var object_placer : ObjectPlacer
@export var tile_parent : Node3D

# Test-only!
@export var pfinder : Pathfinder
@export var proto_unit : PackedScene

@export_category("Ship Spawning")
## Off is the GDD rule: every team starts in its own corner of the map.
## On pulls the teams in toward the middle so testing is quicker.
@export var spawn_close_for_testing: bool = false
## Used only when spawn_close_for_testing is on. Tiles between each team and the teams beside it.
@export_range(4, 30, 1) var test_spawn_gap: int = 20
## The camera's parent node. At spawn it is turned and moved so the camera sits behind the local player's ships.
@export var camera_rig: Node3D

var allies = 2

## Different Terrain Tiles to Place (for now villages)
@export_category("Terrain Spawning")
@export var village : PackedScene
@export var village_02 : PackedScene

## What to create
var myShip = preload("res://scenes/Units/prototype_unit.tscn")
var myPlayer = preload("res://scenes/temp_player.tscn")
@onready var cameraScriptNode = $"../Interaction_tracker"

## Starting point: Generate a random seed, create the tiles, place POI's
func _ready() -> void:
	init_seed()
	generate_world()
	
	# Four players, one per corner. Each gets 3 Triremes and 1 Quadrireme in a V formation.
	var map_middle := _map_middle()
	var team_tiles: Array = []
	var tri_count := 0
	var quad_count := 0
	for i in SPAWN_PLAYERS.size():
		var info: Dictionary = SPAWN_PLAYERS[i]
		
		var isCPU = false
		if info["player_type"] == "CPU":
			isCPU = true
			
		var player = _inst_player(info["name"], i + 1, isCPU)
		var tiles: Array[Tile] = []
		if info.has("opposite_of"):
			tiles = _opposite_tiles(team_tiles[info["opposite_of"]], map_middle)
		else:
			var target := _map_corner(info["corner"])
			if spawn_close_for_testing:
				target = _close_spot(map_middle, target)
			tiles = _team_tiles(target, info["facing"])
		team_tiles.append(tiles)
		if tiles.is_empty():
			push_error("No room to spawn %s's ships." % info["name"])
			continue
		var quad_slot := randi_range(0, tiles.size() - 1)
		for slot in tiles.size():
			var tile := tiles[slot]
			var is_quad: bool = slot == quad_slot
			var ship_name := ""
			if is_quad:
				quad_count += 1
				ship_name = "Quad %02d" % quad_count
			else:
				tri_count += 1
				ship_name = "Tri %02d" % tri_count
			_inst_ship(player, ship_name, tile, info["facing"], is_quad, info["color"])
		if i + 1 == TurnController.local_player_id:
			_place_camera_behind(player, info["facing"])
	
#	create_starting_units(allies)  ## prototyping pathfinding and units


# Randomize if no seed has been set
func init_seed():
	if settings.map_seed == 0 or settings.map_seed == null:
		print("Randomizing seed")
		settings.biome_noise.seed = randi() #New map_seed for this generation
		settings.heightmap_noise.seed = randi()
		settings.ocean_noise.seed = randi()
	else:
		settings.biome_noise.seed = settings.map_seed
		settings.heightmap_noise.seed = settings.map_seed
		settings.ocean_noise.seed = settings.map_seed


## placeholder functionality for placing units onto the map
func create_starting_units(count : int):
	var safety_count = 0 #Add safety counter in case no valid tiles
	## Test pathfinder
	while count > 0 and safety_count < 50:
		var r_tile : Tile = WorldMap.map.pick_random()
		if r_tile.mesh_data.type != Tile.biome_type.Ocean or r_tile.occupier != null:
			safety_count += 1
			continue
		var unit : Unit = proto_unit.instantiate()
		add_child(unit)
		unit.place_unit(r_tile.position, r_tile)
##		unit.occupy_tile(r_tile)
		count -= 1

## Carter's Creating Player combined with Melia's create_starting_units
func _inst_player(name, id, isCPU=false):
	var playerInstance = myPlayer.instantiate()
	playerInstance.initiate(name, id, isCPU)
	add_child(playerInstance)
	playerInstance.add_to_group("players")
	return playerInstance

## Carter's Creating and Placing Trimeme Ships combined with Melia's create_starting_units
func _inst_tri(owner, name):
	var safety_count = 0 #Add safety counter in case no valid tiles
	var done = false
	## Test pathfinder
	while !done and safety_count < 50:
		var r_tile : Tile = WorldMap.map.pick_random()
		if r_tile.mesh_data.type != Tile.biome_type.Ocean or r_tile.occupier.size() > 0:
			safety_count += 1
			continue
		var unit = myShip.instantiate()
		unit.set_script(Ship.Trireme)
		unit._setup(owner)
		unit.name = name
		owner.appendShip(unit)
		add_child(unit)
		unit.place_unit(r_tile.position, r_tile)
		done = true

## Hex directions are indexes into Ship.HEX_DIR: 0 SE, 1 NE, 2 N, 3 NW, 4 SW, 5 S. Screen up is north (-Z).
##
## Each team spawns in a V around an empty middle tile:
##     outer           outer
##          inner  .  inner        <- "." is the middle tile, which stays empty
##
## "corner" is the corner the team starts in. x: -1 west, 1 east. y: -1 north, 1 south.
## "facing" is the diagonal that points toward the middle of the map.
## "opposite_of" copies another team's spots spun half a turn around the middle of the map.
## On this hex grid that is the only mirror that lands exactly on tiles, so the two teams start in matching spots.
const SPAWN_PLAYERS := [
	{"name": "Chris", "corner": Vector2(-1, -1), "facing": 0, "color": Color(1.0, 0.45, 0.4), "player_type": "Human"},
	{"name": "Bobby", "corner": Vector2(1, -1), "facing": 4, "color": Color(0.45, 0.7, 1.0), "player_type": "Human"},
	{"name": "Grimm", "opposite_of": 0, "facing": 3, "color": Color(0.5, 0.95, 0.5), "player_type": "Human"},
	{"name": "Robot", "opposite_of": 1, "facing": 1, "color": Color(1.0, 0.85, 0.35), "player_type": "CPU"},
]


## The exact middle of the map, seen from above. x is world x, y is world z.
func _map_middle() -> Vector2:
	return (_map_corner(Vector2(-1, -1)) + _map_corner(Vector2(1, 1))) / 2.0


## The outermost tile position in the given corner. x: -1 west, 1 east. y: -1 north, 1 south.
func _map_corner(corner: Vector2) -> Vector2:
	var far := Vector2(-INF, -INF)
	for tile: Tile in WorldMap.map:
		far = far.max(Vector2(tile.position.x * corner.x, tile.position.z * corner.y))
	return far * corner


## The spot on the way from the map's middle to corner that leaves test_spawn_gap tiles between neighboring teams.
## Corner to corner the map is map_width - 1 tiles across and map_length - 1 tiles top to bottom.
func _close_spot(map_middle: Vector2, corner: Vector2) -> Vector2:
	var across := minf(1.0, float(test_spawn_gap) / (settings.map_width - 1))
	var down := minf(1.0, float(test_spawn_gap) / (settings.map_length - 1))
	return map_middle + (corner - map_middle) * Vector2(across, down)


## Picks the free ocean tile closest to target that has room for the whole V, and returns the 4 ship tiles.
## Returns an empty list when nothing fits.
func _team_tiles(target: Vector2, facing: int) -> Array[Tile]:
	var best: Array[Tile] = []
	var best_distance := INF
	for middle: Tile in WorldMap.map:
		var distance := Vector2(middle.position.x, middle.position.z).distance_to(target)
		if distance >= best_distance:
			continue
		var ships := _v_formation(middle, facing)
		if ships.is_empty():
			continue
		best_distance = distance
		best = ships
	return best


## Each tile's twin on the other side of the map's middle, as if the board were spun half a turn.
## Returns an empty list when a twin is missing, land, or taken.
func _opposite_tiles(tiles: Array[Tile], map_middle: Vector2) -> Array[Tile]:
	var opposites: Array[Tile] = []
	for tile in tiles:
		var spot := map_middle * 2.0 - Vector2(tile.position.x, tile.position.z)
		var opposite := _tile_at(spot)
		if not _is_free_ocean(opposite):
			return []
		opposites.append(opposite)
	return opposites


## The tile sitting on spot, or null when no tile is there.
func _tile_at(spot: Vector2) -> Tile:
	for tile: Tile in WorldMap.map:
		if Vector2(tile.position.x, tile.position.z).distance_to(spot) < 0.1:
			return tile
	return null


func _is_free_ocean(tile: Tile) -> bool:
	return tile != null and tile.mesh_data.type == Tile.biome_type.Ocean and tile.occupier.size() == 0


## The two arms of the V go out from the middle tile, two hex sides away from the facing on each side,
## which points sideways and a little back. Each arm has an inner ship one step out
## and an outer ship two steps further.
## Returns an empty list when any tile walked over is off the map, land, or taken.
func _v_formation(middle: Tile, facing: int) -> Array[Tile]:
	var ships: Array[Tile] = []
	if not _is_free_ocean(middle):
		return ships
	for arm_direction in [facing + 2, facing - 2]:
		var tile := middle
		for steps in [1, 2]:
			for _step in steps:
				tile = PhaseMovement._neighbor_tile(tile, posmod(arm_direction, Ship.HEX_DIR.size()))
				if not _is_free_ocean(tile):
					return []
			ships.append(tile)
	return ships


## Turns the camera rig to look the way the player's ships face, then slides it back
## so the camera looks at the middle of the ships from behind.
## The camera's height and tilt are left alone.
func _place_camera_behind(player: Player, facing: int) -> void:
	if camera_rig == null:
		return
	var ships_middle := Vector3.ZERO
	for ship in player._ships:
		ships_middle += ship.occupied_tile.position
	ships_middle /= player._ships.size()
	ships_middle.y = 0.0
	
	# How far ahead of the rig the camera looks, measured on the water.
	var camera := camera_rig.get_viewport().get_camera_3d()
	var look_direction := -camera.global_basis.z
	var look_point := camera.global_position + look_direction * (camera.global_position.y / -look_direction.y)
	var look_ahead := Vector2(look_point.x - camera_rig.position.x, look_point.z - camera_rig.position.z).length()
	
	var forward := PhaseMovement.facing_world_delta(player._ships[0].occupied_tile, facing).normalized()
	camera_rig.rotation.y = atan2(-forward.x, -forward.z)
	camera_rig.position = Vector3(ships_middle.x - forward.x * look_ahead, camera_rig.position.y, ships_middle.z - forward.z * look_ahead)


## Creates one ship on tile with the given facing and a floating "Name (Owner)" tag.
func _inst_ship(owner: Player, ship_name: String, tile: Tile, facing: int, is_quad: bool, tint: Color) -> void:
	var unit = myShip.instantiate()
	if is_quad:
		unit.set_script(Ship.Quadrireme)
	else:
		unit.set_script(Ship.Trireme)
	unit._setup(owner)
	unit.name = ship_name
	owner.appendShip(unit)
	add_child(unit)
	unit._facing = facing
	unit.place_unit(tile.position, tile)
	var tag := Label3D.new()
	tag.name = "OwnerTag"
	tag.text = "%s (%s)" % [ship_name, owner.getName()]
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.pixel_size = 0.004
	tag.font_size = 100
	tag.outline_size = 8
	tag.modulate = tint
	tag.position = Vector3(0, 1.2, 0)
	unit.add_child(tag)


## Start of world_generation, time each step
func generate_world():
	var starttime = Time.get_ticks_msec()
	var interval = {"Start of Generation!" : starttime}
	
	## Get all positions through the gridmapper
	var mapper = GridMapper.new()
	var positions = mapper.calculate_map_positions(settings)
	interval["Calculate Map Positions -- "] = Time.get_ticks_msec()
	
	## Create the tiles
	var factory = TileFactory.new()
	factory.init_factory(settings, tile_parent)
	var map = factory.create_map(positions)
	WorldMap.set_map(map)
	interval["Create Map -- "] = Time.get_ticks_msec()

	## Fill all gaps
	if settings.modify_height:
		factory.modify_terrain()
		interval["Modify terrain and fill Gaps -- "] = Time.get_ticks_msec()
	
	## Spawn villages
	if settings.spawn_villages:
		var placeable = get_placeable_tiles()
		object_placer.place_villages(placeable, settings.spacing, village)
		interval["Spawn Villages -- "] = Time.get_ticks_msec()
		
		placeable = get_placeable_tiles()
		object_placer.place_villages(placeable, settings.spacing, village_02)
		interval["Spawn Villages -- "] = Time.get_ticks_msec()
	
	print_generation_results(starttime, interval)


## This mess of a function loops through the timing results of generate_world and prints them
func print_generation_results(start : float, dict : Dictionary):
	print("\n")
	var last_val = start
	var total = 0
	for key in dict:
		var val = dict[key]
		if val == start:
			print(key)
			continue
		var passed = val - last_val
		print(key, str(passed) + "ms")
		last_val = val
		total += passed
	var s = "ms"
	if total > 999: 
		s = "s"
		total *= 0.001
	print("Total completion time: ", total, s)


## Ignore buffer and ocean to return for object placer
func get_placeable_tiles() -> Array[Tile]:
	var placeable_tiles : Array[Tile] = []
	for tile : Tile in WorldMap.map:
		if tile.pos_data.buffer or not tile.placeable:
			continue
		placeable_tiles.append(tile)
	print(str(placeable_tiles.size()) + " placeable tiles")
	return placeable_tiles
