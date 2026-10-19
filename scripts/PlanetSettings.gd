class_name PlanetSettings
extends Resource

@export_group("Planet Geometry")
@export_range(10.0, 1000.0, 1.0, "or_greater")
var radius: float = 800.0

@export_range(1, 8, 1)
var subdivisions: int = 6

@export_group("Terrain Heights")
@export_range(0.0, 200.0, 0.1)
var ocean_depth: float = 24.0

@export_range(0.0, 300.0, 0.1)
var land_height: float = 40.0

@export_range(0.0, 500.0, 0.1)
var mountain_height: float = 80.0

@export_range(0.0, 50.0, 0.1)
var detail_height: float = 2.4

@export_group("World Biome Levels")
@export var sea_level: float = 0.0

@export_range(0.0, 500.0, 0.1)
var snow_level: float = 52.0

@export_range(0.0, 500.0, 0.1)
var mountain_level: float = 425.0

@export_group("Noise Frequencies")
@export_range(0.0, 0.02, 0.0001)
var continental_noise_frequency: float = 0.0012

@export_range(0.0, 5.0, 0.01)
var mountain_noise_frequency: float = 2.2

@export_range(0.0, 100, 0.1)
var detail_noise_frequency: float = 20.0

@export_range(0.0, 0.02, 0.0001)
var moisture_noise_frequency: float = 0.0012

@export_range(0.0, 5.0, 0.01)
var temperature_noise_frequency: float = 0.8

@export_range(0.0, 10.0, 0.1)
var temperature_detail_noise: float = 3.0

@export_range(0.0, 0.01, 0.0001)
var mountain_mask_noise: float = 0.003

@export_group("Land Visuals")
@export_range(0.0, 1.0, 0.01)
var land_roughness: float = 0.72

@export var rock_color: Color = Color(0.30, 0.29, 0.27)

@export_range(0.0, 1.0, 0.01)
var rock_strength: float = 0.35

@export var shallow_seafloor_color: Color = Color(0.40, 0.31, 0.20)
@export var deep_seafloor_color: Color = Color(0.07, 0.09, 0.11)

@export_range(0.0, 1.0, 0.01)
var seafloor_roughness: float = 0.9


@export_group("Ocean Visuals")

@export var water_color: Color = Color(0.08, 0.36, 0.52)

@export_range(0.0, 1.0, 0.01)
var water_opacity: float = 0.9

@export_range(0.0, 1.0, 0.01)
var water_roughness: float = 0.18

@export_range(0.0, 1.0, 0.01)
var water_specular: float = 0.8