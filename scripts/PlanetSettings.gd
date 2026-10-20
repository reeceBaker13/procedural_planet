class_name PlanetSettings
extends Resource

# ======================================
# PLANET GEOMETRY
# ======================================

@export_group("01. Planet Geometry")

## Radius of the undeformed planet
@export_range(10.0, 1000.0, 1.0)
var radius: float = 800.0

## Subdivision level of the icosphere.
## Higher levels increase mesh and collision costs substantially.
@export_range(1, 7, 1)
var subdivisions: int = 6


# ======================================
# TERRAIN SHAPE
# ======================================

@export_group("02. Terrain Shape")

## Maximum depth of the generated seabed below the base radius.
@export_range(0.0, 200.0, 0.1)
var ocean_depth: float = 24.0

## Base elevation of land above the base radius.
@export_range(0.0, 300.0, 0.1)
var land_height: float = 40.0

## Maximum additional elevation contributed by mountains.
@export_range(0.0, 200.0, 0.1)
var mountain_height: float = 80.0

## Amplitude of small-scale displacement applied on terrain.
@export_range(0.0, 20.0, 0.1)
var detail_height: float = 2.4


# ======================================
# BIOME THRESHOLDS
# ======================================

@export_group("03. Biome Thresholds")

## Surface elevation of the ocean, measured
## relative to the undeformed planet radius.
@export_range(-100.0, 100.0, 0.1)
var sea_level: float = 0.0

## Elevation above which sufficiently cold terrain
## may be classified as snowy mountains.
@export_range(0.0, 200.0, 0.1)
var snow_level: float = 52.0

## Elevation above which land is classified as mountainous.
@export_range(0.0, 200.0, 0.1)
var mountain_level: float = 70.0


# ======================================
# TERRAIN NOISE
# ======================================

@export_group("04. Terrain Noise")

## Controls the scale of continental land/ocean variation.
@export_range(0.0, 0.02, 0.0001)
var continental_noise_frequency: float = 0.0012

## Controls the scale of mountain noise. Currently requires
## consistent frequency scaling in NoiseGenerator.gd
@export_range(0.0, 5.0, 0.01)
var mountain_noise_frequency: float = 2.2

## Controls the scale of fine terrain detail
@export_range(0.0, 100, 0.1)
var detail_noise_frequency: float = 20.0

## Controls the distribution of mountainous regions.
@export_range(0.0, 0.01, 0.0001)
var mountain_mask_noise: float = 0.003


# ======================================
# CLIMATE NOISE
# ======================================

@export_group("05. Climate Noise")

## Controls variation in moisture across the planet.
@export_range(0.0, 0.02, 0.0001)
var moisture_noise_frequency: float = 0.0012

## Controls large-scale temperature variation.
@export_range(0.0, 5.0, 0.01)
var temperature_noise_frequency: float = 0.8

## Controls finer temperature variation.
@export_range(0.0, 10.0, 0.1)
var temperature_detail_noise: float = 3.0


# ======================================
# LAND APPEARANCE
# ======================================

@export_group("06. Land Appearance")

## Material roughness of the generated terrain.
@export_range(0.0, 1.0, 0.01)
var land_roughness: float = 0.72

## Colour blended into steep terrain slopes.
@export var rock_color: Color = Color(0.30, 0.29, 0.27)

## Strength of the rock-colour blend. Zero disables the effect.
@export_range(0.0, 1.0, 0.01)
var rock_strength: float = 0.35

## Slope value at which rock colouring starts.
@export_range(0.0, 2.0, 0.01)
var rock_slope_start: float = 0.25

## Slope value at which rock colouring reaches full strength.
@export_range(0.01, 2.0, 0.01)
var rock_slope_end: float = 0.65

## Colour of shallow underwater terrain.
@export var shallow_seafloor_color: Color = Color(0.40, 0.31, 0.20)

## Colour of deeper underwater terrain.
@export var deep_seafloor_color: Color = Color(0.07, 0.09, 0.11)

## Material roughness of the seabed.
@export_range(0.0, 1.0, 0.01)
var seafloor_roughness: float = 0.9


# ======================================
# WATER APPEARANCE
# ======================================

@export_group("07. Ocean Appearance")

## Colour of the seperate water surface.
@export var water_color: Color = Color(0.08, 0.36, 0.52)

## Alpha opacity of the water surface: 1 is opaque, 0 is invisible.
@export_range(0.0, 1.0, 0.01)
var water_opacity: float = 0.9

## Roughness of the water material.
@export_range(0.0, 1.0, 0.01)
var water_roughness: float = 0.18

## Specular response of the water material.
@export_range(0.0, 1.0, 0.01)
var water_specular: float = 0.8
