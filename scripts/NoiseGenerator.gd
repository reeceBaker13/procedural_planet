class_name NoiseGenerator
extends RefCounted

var noise: FastNoiseLite

func _init(seed: int, frequency: float):
	noise = FastNoiseLite.new()
	
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	noise.frequency = frequency * TerrainConfig.PLANET_RADIUS
	

func get_2d(x: float, z: float) -> float:
	return (noise.get_noise_2d(x, z) + 1.0) * 0.5

func get_3d(x: float, y: float, z: float) -> float:
	return (noise.get_noise_3d(x, y, z) + 1.0) * 0.5
