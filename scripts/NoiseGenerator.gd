class_name NoiseGenerator
extends RefCounted

var noise: FastNoiseLite

func _init(planet_seed: int, frequency: float, radius: float):
    if not settings:
        push_error("NoiseGenerator: Missing planet settings.")
        return
    
    noise = FastNoiseLite.new()
    
    noise.seed = planet_seed
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    
    noise.frequency = frequency * radius
    

func get_2d(x: float, z: float) -> float:
    return (noise.get_noise_2d(x, z) + 1.0) * 0.5

func get_3d(x: float, y: float, z: float) -> float:
    return (noise.get_noise_3d(x, y, z) + 1.0) * 0.5
