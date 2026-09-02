class_name Biome
extends RefCounted

enum Type {
	PLAINS,
	DESERT,
	SAVANNA,
	JUNGLE,
	FOREST,
	MOUNTAIN,
	SNOWY_MOUNTAIN,
	TUNDRA,
	ARCTIC,
	OCEAN,
	NA
}

static func get_color(type: Type) -> Color:
	match type:
		Type.ARCTIC:
			return Color(0.68, 0.75, 0.76)
			
		Type.DESERT:
			return Color(0.68, 0.56, 0.34)
			
		Type.FOREST:
			return Color(0.18, 0.38, 0.20)
			
		Type.JUNGLE:
			return Color(0.12, 0.32, 0.14)
			
		Type.MOUNTAIN:
			return Color(0.34, 0.32, 0.29)
			
		Type.OCEAN:
			return Color(0.035, 0.16, 0.28)
			
		Type.PLAINS:
			return Color(0.42, 0.52, 0.28)
			
		Type.SAVANNA:
			return Color(0.55, 0.55, 0.29)
			
		Type.SNOWY_MOUNTAIN:
			return Color(0.78, 0.82, 0.82)
			
		Type.TUNDRA:
			return Color(0.4, 0.46, 0.4)
	
	return Color.BLACK

class VegetationSpecies:
	var packed_scene: PackedScene
	var min_scale: float
	var max_scale: float
	var weight: float
	
	func _init(packed_scene: PackedScene, min_scale: float, max_scale: float, weight: float):
		self.packed_scene = packed_scene
		self.min_scale = min_scale
		self.max_scale = max_scale
		self.weight = weight

# Defining the species
static var oak_species = VegetationSpecies.new(
	preload("res://Assets/Vegetation/TreeBell.fbx"),
	0.8,
	1.3,
	0.5
)

static var fir_species = VegetationSpecies.new(
	preload("res://Assets/Vegetation/TreeDiamond.fbx"),
	0.8,
	1.3,
	0.5
)

static var pine_species = VegetationSpecies.new(
	preload("res://Assets/Vegetation/TreePine.fbx"),
	0.8,
	1.3,
	0.5
)

static var cherry_species = VegetationSpecies.new(
	preload("res://Assets/Vegetation/TreePink.fbx"),
	0.8,
	1.3,
	0.5
)

static var elm_species = VegetationSpecies.new(
	preload("res://Assets/Vegetation/TreeRound.fbx"),
	0.8,
	1.3,
	0.5
)

static var juniper_species = VegetationSpecies.new(
	preload("res://Assets/Vegetation/TreeStack.fbx"),
	0.8,
	1.3,
	0.5
)

static var trees = [oak_species, fir_species, pine_species, cherry_species, elm_species, juniper_species]

static var vegetation_by_biome = {
	Biome.Type.FOREST: [
		oak_species,
		fir_species,
		pine_species
	],
	
	Biome.Type.JUNGLE: [
		elm_species,
		juniper_species,
		pine_species
	],
	
	Biome.Type.SAVANNA: [
		juniper_species
	],
	
	Biome.Type.PLAINS: [
		oak_species,
		cherry_species,
		elm_species
	]
}
