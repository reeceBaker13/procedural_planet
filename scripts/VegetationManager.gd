class_name VegetationManager
extends Node3D

# Settings
var settings: PlanetSettings

# Terrain Chunk
var terrain_chunk: TerrainChunk

# Tree Parameters
@export var tree_count: int = 2000
@export var tree_seed: int = 12345
@export var tree_min_scale: float = 0.75
@export var tree_max_scale: float = 1.25

# Initialise terrain chunk
func set_terrain_chunk(terrain_chunk_: TerrainChunk):
    self.terrain_chunk = terrain_chunk_

# Generates Trees
func generate_trees(planet_seed: int, p_settings: PlanetSettings):
    if terrain_chunk == null:
        push_error("Terrain Chunk not yet set")
        return
        
    if not p_settings:
        push_error("VegetationManager: Missing PlanetSettings resource!")
        return
    
    settings = p_settings
    
    var vegetation_root = self
    
    for child in vegetation_root.get_children():
        child.queue_free()
    
    var rng = RandomNumberGenerator.new()
    rng.seed = planet_seed
    
    var multimeshes: Dictionary = {}
    
    for biome_type in Biome.vegetation_by_biome:
        for species in Biome.vegetation_by_biome[biome_type]:
            if multimeshes.has(species):
                continue
            
            var mesh = get_tree_mesh(species.packed_scene)
            
            if mesh == null:
                push_warning("Could not find tree mesh.")
                continue
            
            var multi_mesh = MultiMesh.new()
            multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
            multi_mesh.mesh = mesh
            multi_mesh.instance_count = tree_count
            multi_mesh.visible_instance_count = 0
            
            var instance = MultiMeshInstance3D.new()
            instance.name = species.packed_scene.resource_path.get_file()
            instance.multimesh = multi_mesh
            
            var extent = (settings.radius + settings.mountain_height + mesh.get_aabb().size.length())
            
            multi_mesh.custom_aabb = AABB(
                Vector3(-extent, -extent, -extent),
                Vector3(extent * 2.0, extent * 2.0, extent * 2.0)
            )
            
            vegetation_root.add_child(instance)
            
            multimeshes[species] = {
                "multimesh": multi_mesh,
                "species": species,
                "count": 0
            }
    print("Vegetation entries: ", Biome.vegetation_by_biome.size())
    print("MultiMesh entries: ", multimeshes.size())
    
    var placed : int = 0
    var attempts : int = 0
    var max_attempts: int = tree_count * 10
    
    while placed < tree_count and attempts < max_attempts:
        attempts += 1
        
        var y = rng.randf_range(-1.0, 1.0)
        var angle = rng.randf_range(0.0, TAU)
        
        var radius = sqrt(max(0.0, 1.0 - y * y))
        
        var direction = Vector3(
            cos(angle) * radius,
            y,
            sin(angle) * radius
        )
        
        var height = terrain_chunk.get_height(direction)
        var biome = terrain_chunk.get_biome_from_direction(direction, height)
        
        if not Biome.vegetation_by_biome.has(biome):
            continue
        
        var density = get_tree_density(direction, height, biome)
        
        if rng.randf() > density:
            continue
        
        var species_list = Biome.vegetation_by_biome[biome]
        var species = choose_species(species_list, rng)
        
        if species == null:
            continue
        
        if not multimeshes.has(species):
            continue
        
        var data: Dictionary = multimeshes[species]
        
        var multi_mesh: MultiMesh = data["multimesh"]
        var instance_index: int = data["count"]
        
        if instance_index >= multi_mesh.instance_count:
            continue
            
        var position_ = terrain_chunk.get_planet_position(direction)
        
        var transform_ = create_tree_transform(
            direction,
            position_,
            rng,
            species
        )
        
        multi_mesh.set_instance_transform(
            instance_index,
            transform_
        )
        
        data["count"] = instance_index + 1
        
        multimeshes[species] = data
        
        placed += 1
    
    for species in multimeshes:
        var data: Dictionary = multimeshes[species]
        var multi_mesh: MultiMesh = data["multimesh"]
        multi_mesh.visible_instance_count = (data["count"])
    
    print("Generated ", placed, " trees.")

func choose_species(species_list: Array, rng: RandomNumberGenerator) -> Biome.VegetationSpecies:
    var total_weight = 0.0
    
    for species in species_list:
        total_weight += species.weight
    
    if total_weight <= 0.0:
        return null
    
    var roll = rng.randf() * total_weight
    
    for species in species_list:
        roll -= species.weight
        
        if roll <= 0.0:
            return species
    
    return species_list.back()

func get_tree_mesh(tree_scene: PackedScene) -> Mesh:
    if tree_scene == null:
        return null
    
    var instance = tree_scene.instantiate()
    
    var mesh_nodes = instance.find_children(
        "*",
        "MeshInstance3D",
        true,
        false
    )
    
    for node in mesh_nodes:
        if node.mesh != null:
            var mesh = node.mesh
            instance.free()
            return mesh
    
    instance.free()
    return null

func get_tree_density(direction: Vector3, height: float, biome: Biome.Type) -> float:
    var density : float = 0.0
    
    match biome:
        Biome.Type.FOREST:
            density = 1.0
        Biome.Type.JUNGLE:
            density = 1.0
        Biome.Type.SAVANNA:
            density = 0.25
        Biome.Type.PLAINS:
            density = 0.08
        _:
            return 0.0
    
    var moisture = terrain_chunk.get_moisture(direction)
    
    density *= lerp(0.25, 1.0, moisture)
    
    var elevation = clamp(max(height, 0.0) / settings.mountain_height, 0.0, 1.0)
    
    density *= 1.0 - smoothstep(0.35, 0.9, elevation)
    
    return clamp(density, 0.0, 1.0)

func create_tree_transform(direction: Vector3, position_: Vector3, rng: RandomNumberGenerator, species: Biome.VegetationSpecies) -> Transform3D:
    var up = direction.normalized()
    
    var reference = Vector3.UP
    
    if abs(up.dot(reference)) > 0.95:
        reference = Vector3.RIGHT
    
    var tangent = up.cross(reference).normalized()
    var forward = tangent.cross(up).normalized()
    
    var basis_ = Basis(tangent, up, forward)
    
    var yaw = rng.randf_range(0.0, TAU)
    
    basis_ = basis_.rotated(up, yaw)
    
    var scale_ = rng.randf_range(species.min_scale, species.max_scale) * settings.radius / 50.0
    
    basis_ = basis_.scaled(Vector3.ONE * scale_)
    
    return Transform3D(basis_, position_)
