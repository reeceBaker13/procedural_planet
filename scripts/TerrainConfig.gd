class_name TerrainConfig
extends RefCounted

const PLANET_RADIUS = 800.0
const SUBDIVISIONS = 6
const SIZE = 32

const OCEAN_DEPTH = 0.03 * TerrainConfig.PLANET_RADIUS
const BEACH_HEIGHT = 0.02 * TerrainConfig.PLANET_RADIUS
const LAND_HEIGHT = 0.05 * TerrainConfig.PLANET_RADIUS
const MOUNTAIN_HEIGHT = 0.1 * TerrainConfig.PLANET_RADIUS 
const DETAIL_HEIGHT = 0.003 * TerrainConfig.PLANET_RADIUS

# World parameters
const SEA_LEVEL = 0.0
const SNOW_LEVEL = 0.065 * PLANET_RADIUS
const MOUNTAIN_LEVEL = 0.025 * PLANET_RADIUS
