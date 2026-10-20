class_name TerrainChunk
extends Node3D

# Settings
@export var settings: PlanetSettings

# Noise
var continental_noise: NoiseGenerator
var mountain_noise: NoiseGenerator
var detail_noise: NoiseGenerator

var moisture_noise: NoiseGenerator
var temperature_noise: NoiseGenerator
var temperature_detail_noise: NoiseGenerator

var mountain_mask_noise: NoiseGenerator

# Icosphere data
var sphere_vertices: Array[Vector3] = []
var sphere_triangles: Array = []
var midpoint_cache: Dictionary = {}

# Materials
var ocean_material: StandardMaterial3D

# Constructor
func setup(planet_seed: int, p_settings: PlanetSettings) -> float:
    if p_settings:
        settings = p_settings
    else:
        push_error("TerrainChunk: No PlanetSettings provided and could not find default planet settings.")
        return 0.0
    
    continental_noise = NoiseGenerator.new(planet_seed, settings.continental_noise_frequency, settings.radius)
    mountain_noise = NoiseGenerator.new(planet_seed + 1, settings.moisture_noise_frequency, settings.radius)
    detail_noise = NoiseGenerator.new(planet_seed + 2, settings.detail_noise_frequency, settings.radius)
    
    moisture_noise = NoiseGenerator.new(planet_seed + 3, settings.moisture_noise_frequency, settings.radius)
    temperature_noise = NoiseGenerator.new(planet_seed + 4, settings.temperature_noise_frequency, settings.radius)
    temperature_detail_noise = NoiseGenerator.new(planet_seed + 5, settings.temperature_detail_noise, settings.radius)
    
    mountain_mask_noise = NoiseGenerator.new(planet_seed + 6, settings.mountain_mask_noise, settings.radius)
    
    return generate()

# Generates Terrain
func generate() -> float:
    var start_time = Time.get_ticks_usec()
    sphere_vertices.clear()
    sphere_triangles.clear()
    midpoint_cache.clear()
    
    generate_icosphere()
    
    var st = SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    
    # Add displaced vertices with their biome colours.
    for direction in sphere_vertices:
        var height = get_height(direction)
        
        var vertex = direction * (
            settings.radius + height
        )
        
        var biome = get_biome_from_direction(direction, height)
        
        st.set_color(Biome.get_color(biome))
        st.add_vertex(vertex)
    
    # Add triangle indices.
    for triangle in sphere_triangles:
        st.add_index(triangle[0])
        st.add_index(triangle[1])
        st.add_index(triangle[2])
    
    # Calculate normals
    st.generate_normals()
    
    var mesh = st.commit()
    
    # Terrain material
    var shader = Shader.new()

    shader.code = """
	shader_type spatial;

    uniform float planet_radius;
    uniform float sea_level;
    uniform float max_mountain_height;
    uniform float ocean_vertical_range;

    uniform float land_roughness;
    uniform float seafloor_roughness;
    uniform float rock_strength;

    uniform vec4 rock_color;
    uniform vec4 shallow_seafloor_color;
    uniform vec4 deep_seafloor_color;

    varying vec3 biome_color;
    varying float terrain_height;

	varying vec3 biome_color;
	varying float terrain_height;

	void vertex() {
		// Pass the vertex colour from SurfaceTool to the fragment shader.
		biome_color = COLOR.rgb;

		// Calculate actual height above the base planet radius.
		terrain_height = length(VERTEX) - planet_radius;
	}

	void fragment() {

		// ==========================================
		// LAND
		// ==========================================

		if (terrain_height >= sea_level) {

			vec3 land_color = biome_color;
			
			land_color *= 0.95;

			// ------------------------------------------
			// Elevation
			// ------------------------------------------

			float elevation = clamp(
				terrain_height / max(max_mountain_height, 0.001),
				0.0,
				1.0
			);

			// Slight variation with elevation.
			land_color *= mix(
				0.90,
				1.05,
				elevation
			);

			// ------------------------------------------
			// Slope / Rock
			// ------------------------------------------

			vec3 radial = normalize(VERTEX);

			float slope = 1.0 - dot(
				NORMAL,
				radial
			);

			float rock_mask = smoothstep(
				0.25,
				0.65,
				slope
			);

			vec3 rock_color = vec3(
				0.30,
				0.29,
				0.27
			);

			land_color = mix(
				land_color,
				rock_color.rgb,
				rock_mask * rock_strength
			);

			ALBEDO = land_color;
			ROUGHNESS = land_roughness;
			SPECULAR = 0.35;
		}

		else {

			float depth = clamp(
				(sea_level - terrain_height) / max(ocean_vertical_range, 0.001),
				0.0,
				1.0
			);

			ALBEDO = mix(
				shallow_seafloor_color.rgb,
				deep_seafloor_color.rgb,
				depth
			);

			ROUGHNESS = seafloor_roughness;
			SPECULAR = 0.15;
		}
	}
    """ % [
        settings.radius,
        settings.mountain_height,
        settings.ocean_depth
    ]

    var material = ShaderMaterial.new()
    material.shader = shader

    material.set_shader_parameter(
        "planet_radius", settings.radius
    )
    material.set_shader_parameter(
        "sea_level", settings.sea_level
    )
    material.set_shader_parameter(
        "max_mountain_height", settings.mountain_height
    )
    material.set_shader_parameter(
        "ocean_vertical_range",
        maxf(settings.ocean_depth + settings.sea_level, 0.001)
    )

    material.set_shader_parameter(
        "land_roughness", settings.land_roughness
    )
    material.set_shader_parameter(
        "seafloor_roughness", settings.seafloor_roughness
    )
    material.set_shader_parameter(
        "rock_strength", settings.rock_strength
    )

    material.set_shader_parameter(
        "rock_color", settings.rock_color
    )
    material.set_shader_parameter(
        "shallow_seafloor_color", settings.shallow_seafloor_color
    )
    material.set_shader_parameter(
        "deep_seafloor_color", settings.deep_seafloor_color
    )

    mesh.surface_set_material(0, material)
    
    $MeshInstance3D.mesh = mesh

    update_water_surface()
    
    # Collision mesh
    var collision_shape := (
        $StaticBody3D/CollisionShape3D
        as CollisionShape3D
    )
    collision_shape.shape = mesh.create_trimesh_shape()
    
    var elapsed_time = Time.get_ticks_usec() - start_time
    return elapsed_time / 1000.0

func generate_icosphere():
    var phi = (1.0 + sqrt(5.0)) / 2.0
    
    var base_vertices = [
        Vector3(-1, phi, 0),
        Vector3(1, phi, 0),
        Vector3(-1, -phi, 0),
        Vector3(1, -phi, 0),
        
        Vector3(0, -1, phi),
        Vector3(0, 1, phi),
        Vector3(0, -1, -phi),
        Vector3(0, 1, -phi),
        
        Vector3(phi, 0, -1),
        Vector3(phi, 0, 1),
        Vector3(-phi, 0, -1),
        Vector3(-phi, 0, 1),
    ]
    
    for vertex in base_vertices:
        sphere_vertices.append(
            vertex.normalized()
        )
    
    sphere_triangles = [
        [0, 11, 5],
        [0, 5, 1],
        [0, 1, 7],
        [0, 7, 10],
        [0, 10, 11],
        
        [1, 5, 9],
        [5, 11, 4],
        [11, 10, 2],
        [10, 7, 6],
        [7, 1, 8],
        
        [3, 9, 4],
        [3, 4, 2],
        [3, 2, 6],
        [3, 6, 8],
        [3, 8, 9],
        
        [4, 9, 5],
        [2, 4, 11],
        [6, 2, 10],
        [8, 6, 7],
        [9, 8, 1]
    ]
    
    for i in range(settings.subdivisions):
        subdivide_icosphere()
    
    for triangle in sphere_triangles:
        var a = sphere_vertices[triangle[0]]
        var b = sphere_vertices[triangle[1]]
        var c = sphere_vertices[triangle[2]]
        
        var normal = (
            b - a
        ).cross(
            c - a
        ).normalized()
        
        var centre = (
            a + b + c
        ) / 3.0
        
        if normal.dot(centre) > 0.0:
            var temp = triangle[1]
            triangle[1] = triangle[2]
            triangle[2] = temp

func subdivide_icosphere():
    var new_triangles: Array = []
    
    midpoint_cache.clear()
    
    for triangle in sphere_triangles:
        var a = triangle[0]
        var b = triangle[1]
        var c = triangle[2]
        
        var ab = get_midpoint(a, b)
        var bc = get_midpoint(b, c)
        var ca = get_midpoint(c, a)
        
        new_triangles.append([
            a,
            ab,
            ca
        ])
    
        new_triangles.append([
            b,
            bc,
            ab
        ])
    
        new_triangles.append([
            c,
            ca,
            bc
        ])
    
        new_triangles.append([
            ab,
            bc,
            ca
        ])
    
    sphere_triangles = new_triangles

func get_midpoint(a: int, b: int) -> int:
    var min_index = min(a, b)
    var max_index = max(a, b)
    
    var key = Vector2i(
        min_index,
        max_index
    )
    
    if midpoint_cache.has(key):
        return midpoint_cache[key]
    
    var midpoint = (
        sphere_vertices[a]
        +
        sphere_vertices[b]
    ) * 0.5
    
    var direction = midpoint.normalized()
    var index = sphere_vertices.size()
    
    sphere_vertices.append(
        direction
    )
    
    midpoint_cache[key] = index
    
    return index

func get_planet_position(direction: Vector3) -> Vector3:
    var height = get_height(direction)
    
    return direction * (
        settings.radius + height
    )

func get_cube_position(face: int, u: float, v: float) -> Vector3:
    var x = u * 2.0 - 1.0
    var y = v * 2.0 - 1.0
    
    match face:
        0:
            return Vector3(1.0, y, -x)
        1:
            return Vector3(-1.0, y, x)
        2:
            return Vector3(x, 1.0, y)
        3:
            return Vector3(x, -1.0, -y)
        4:
            return Vector3(x, y, 1.0)
        5:
            return Vector3(-x, y, -1.0)
    
    return Vector3.ZERO

func get_height(direction: Vector3) -> float:
    var continental = continental_noise.get_3d(
        direction.x,
        direction.y,
        direction.z
    )
    
    var land = smoothstep(
        0.42, #ocean
        0.58, #mountains
        continental
    )
    
    var height = lerp(
        -settings.ocean_depth,
        settings.land_height,
        land
    )
    
    var mountain_mask = mountain_mask_noise.get_3d(
        direction.x,
        direction.y,
        direction.z
    )
    
    mountain_mask = smoothstep(
        0.40,
        0.72,
        mountain_mask
    )
    
    mountain_mask *= land
    
    var mountain = mountain_noise.get_3d(
        direction.x,
        direction.y,
        direction.z
    )
    
    mountain = smoothstep(
        0.18,
        0.68,
        mountain
    )
    
    mountain = pow(mountain, 1.8)
    
    height += mountain * settings.mountain_height * mountain_mask
    
    var detail = detail_noise.get_3d(
        direction.x,
        direction.y,
        direction.z
    )
    
    detail = (detail - 0.5) * 2.0
    
    var detail_strength = lerp(0.0, 1.0, land)
    
    height += detail * settings.detail_height * detail_strength
    
    return height

func get_moisture(direction: Vector3) -> float:
    return moisture_noise.get_3d(direction.x, direction.y, direction.z)

func get_temperature(direction: Vector3, height: float) -> float:
    var latitude = abs(direction.y)
    
    var latitude_temperature = 1.0 - pow(latitude, 1.5)
    
    var climate = temperature_noise.get_3d(
        direction.x * 2.0,
        direction.y * 2.0,
        direction.z * 2.0
    )
    
    climate = clamp(climate, 0.0, 1.0)
    
    var detail = temperature_detail_noise.get_3d(
        direction.x,
        direction.y,
        direction.z
    )
    
    detail = clamp(detail, 0.0, 1.0)
    
    var temperature = (latitude_temperature * 0.65 + climate * 0.25 + detail * 0.1)
    
    if height > 0.0:
        var elevation_factor = height / (
            settings.radius * 0.05
        )
        
        temperature -= elevation_factor * 0.2
    
    return clamp(temperature, 0.0, 1.0)

func get_biome_from_direction(direction: Vector3, height: float) -> Biome.Type:
    var temperature = get_temperature(direction, height)
    
    var moisture = moisture_noise.get_3d(
        direction.x * 2.0,
        direction.y * 2.0,
        direction.z * 2.0
    )
    
    moisture = clamp(moisture, 0.0, 1.0)
    
    if height < settings.sea_level:
        return Biome.Type.OCEAN
    
    if height > settings.mountain_level:
        if temperature < 0.4:
            return Biome.Type.SNOWY_MOUNTAIN
        
        return Biome.Type.MOUNTAIN
    
    if temperature < 0.25:
        if height > settings.snow_level:
            return Biome.Type.SNOWY_MOUNTAIN
        
        if moisture > 0.35:
            return Biome.Type.TUNDRA
        
        return Biome.Type.ARCTIC
    
    if temperature > 0.65:
        if moisture > 0.65:
            return Biome.Type.JUNGLE
        
        if moisture > 0.3:
            return Biome.Type.SAVANNA
        
        return Biome.Type.DESERT
    
    if moisture > 0.6:
        return Biome.Type.FOREST
    
    return Biome.Type.PLAINS

func update_water_surface() -> void:
    var water_surface := get_node_or_null(
        "WaterSurface"
    ) as MeshInstance3D

    if water_surface == null:
        water_surface = MeshInstance3D.new()
        water_surface.name = "WaterSurface"
        add_child(water_surface)

    # The waterline is measured from the planet's base radius.
    var water_radius: float = settings.radius + settings.sea_level
    water_radius = maxf(water_radius, 0.1)

    var sphere := SphereMesh.new()
    sphere.radius = water_radius
    sphere.height = water_radius * 2.0
    sphere.radial_segments = 128
    sphere.rings = 64

    water_surface.mesh = sphere

    var water_material := StandardMaterial3D.new()

    water_material.albedo_color = Color(
        settings.water_color.r,
        settings.water_color.g,
        settings.water_color.b,
        settings.water_opacity
    )

    water_material.roughness = settings.water_roughness
    water_material.specular = settings.water_specular
    water_material.metallic = 0.0

    if settings.water_opacity < 0.999:
        water_material.transparency = (
            BaseMaterial3D.TRANSPARENCY_ALPHA
        )
    else:
        water_material.transparency = (
            BaseMaterial3D.TRANSPARENCY_DISABLED
        )

    water_surface.material_override = water_material
    water_surface.cast_shadow = (
        GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    )