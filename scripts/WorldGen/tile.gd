extends Node3D
class_name Tile

enum biome_type {Grassland, Forest, Desert, Ocean, Tundra, Beach, Island, Mountain, Village}
var biome : String
var mesh_data : TileMeshData
var pos_data : PositionData

var neighbors = []
var placeable = true

var occupier = []
var debug_label : Label3D
var range : int
