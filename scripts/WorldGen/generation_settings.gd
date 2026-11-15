extends Resource
class_name GenerationSettings

enum shape {HEXAGONAL, RECTANGULAR, DIAMOND, CIRCLE}

@export_category("Tiles")
@export var tiles : Array[TileMeshData]
@export var biome_weights : Array[float]
@export var tile_size : float = 1 #Scalar for different size tiles, leave at 1 if not using your own mesh
@export var debug = false

@export_category("Generation")
@export var map_seed : int
@export var map_shape : shape = shape.HEXAGONAL
@export_range(0, 99, 1) var radius: int = 5
## Rectangular maps only. Hexes across (columns) and hexes top to bottom (rows). The GDD's normal map is 30 x 40.
@export_range(1, 200, 1) var map_width: int = 30
@export_range(1, 200, 1) var map_length: int = 40
@export var biome_noise : FastNoiseLite

@export_category("Hills")
@export var modify_height = true
@export_range(0.1, 1.0) var hill_height = 0.5
@export_range(0.0, 1.0) var heightmap_treshold = 0.6
@export var heightmap_noise : FastNoiseLite

@export_category("Water/Ocean")
@export var create_water = true
@export var ocean_tile : TileMeshData
@export var ocean_noise : FastNoiseLite
@export_range(-1.0, -0.1) var ocean_height = -0.4
@export_range(0.0, 1.0) var ocean_treshold : float

@export_category("Villages")
@export var spawn_villages = true
@export var map_edge_buffer = 2
@export_range(1, 99) var spacing = 6

@export_category("Beaches")
@export var spawn_beaches = true
@export var map_edge_buffer_beach = 2
@export_range(1, 99) var spacing_beaches = 5

@export_category("Islands")
@export var spawn_islands = true
@export var map_edge_buffer_island = 2
@export_range(1, 99) var spacing_islands = 13

@export_category("Big Rock")
@export var spawn_big_rocks = true
@export var map_edge_buffer_big_rocks = 2
@export_range(1, 99) var spacing_big_rocks = 15

@export_category("Rocks")
@export var spawn_rocks = true
@export var map_edge_buffer_rocks = 2
@export_range(1, 99) var spacing_rocks = 10
