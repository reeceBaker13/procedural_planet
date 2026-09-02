class_name TerrainChunk
extends Node3D

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
func setup(seed: int):
	continental_noise = NoiseGenerator.new(seed, 0.0012)
	mountain_noise = NoiseGenerator.new(seed + 1, 2.2)
	detail_noise = NoiseGenerator.new(seed + 2, 20.0)
	
	moisture_noise = NoiseGenerator.new(seed + 3, 0.0012)
	temperature_noise = NoiseGenerator.new(seed + 4, 0.8)
	temperature_detail_noise = NoiseGenerator.new(seed + 5, 3.0)
	
	mountain_mask_noise = NoiseGenerator.new(seed + 6, 0.003)
	
	ocean_material = StandardMaterial3D.new()
	ocean_material.albedo_color = Color("#163f67")
	ocean_material.metallic = 0.0
	ocean_material.roughness = 0.18
	ocean_material.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	
	generate()

# Generates Terrain
func generate():
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
			TerrainConfig.PLANET_RADIUS + height
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

	uniform float ocean_roughness = 0.12;
	uniform float land_roughness = 0.72;

	varying vec3 biome_color;
	varying float terrain_height;

	void vertex() {
		// Pass the vertex colour from SurfaceTool to the fragment shader.
		biome_color = COLOR.rgb;

		// Calculate actual height above the base planet radius.
		terrain_height = length(VERTEX) - %f;
	}

	void fragment() {

		// ==========================================
		// LAND
		// ==========================================

		if (terrain_height >= 0.0) {

			vec3 land_color = biome_color;
			
			land_color *= 0.95;

			// ------------------------------------------
			// Elevation
			// ------------------------------------------

			float elevation = clamp(
				terrain_height / %f,
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
				rock_color,
				rock_mask * 0.35
			);

			ALBEDO = land_color;
			ROUGHNESS = land_roughness;
			SPECULAR = 0.35;
		}

		else {

			float depth = clamp(
				-terrain_height / %f,
				0.0,
				1.0
			);

			vec3 shallow_color = vec3(
				0.06,
				0.30,
				0.40
			);

			vec3 deep_color = vec3(
				0.015,
				0.07,
				0.14
			);

			ALBEDO = mix(
				shallow_color,
				deep_color,
				depth
			);

			ROUGHNESS = ocean_roughness;
			SPECULAR = 0.9;
		}
	}
	""" % [
		TerrainConfig.PLANET_RADIUS,
		TerrainConfig.MOUNTAIN_HEIGHT,
		TerrainConfig.OCEAN_DEPTH
	]

	var material = ShaderMaterial.new()
	material.shader = shader

	mesh.surface_set_material(0, material)
	
	$MeshInstance3D.mesh = mesh
	
	# Collision mesh
	var collision_shape = mesh.create_trimesh_shape()
	$StaticBody3D/CollisionShape3D.shape = collision_shape

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
	
	for i in range(TerrainConfig.SUBDIVISIONS):
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
		TerrainConfig.PLANET_RADIUS + height
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
		-TerrainConfig.OCEAN_DEPTH,
		TerrainConfig.LAND_HEIGHT,
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
	
	height += mountain * TerrainConfig.MOUNTAIN_HEIGHT * mountain_mask
	
	var detail = detail_noise.get_3d(
		direction.x,
		direction.y,
		direction.z
	)
	
	detail = (detail - 0.5) * 2.0
	
	var detail_strength = lerp(0.0, 1.0, land)
	
	height += detail * TerrainConfig.DETAIL_HEIGHT * detail_strength
	
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
			TerrainConfig.PLANET_RADIUS * 0.05
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
	
	if height < TerrainConfig.SEA_LEVEL:
		return Biome.Type.OCEAN
	
	if height > TerrainConfig.MOUNTAIN_HEIGHT * 0.85:
		if temperature < 0.4:
			return Biome.Type.SNOWY_MOUNTAIN
		
		return Biome.Type.MOUNTAIN
	
	if temperature < 0.25:
		if height > TerrainConfig.SNOW_LEVEL:
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
