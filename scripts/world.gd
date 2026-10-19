extends Node3D

const CHUNK = preload("res://scenes/TerrainChunk.tscn")
const PLANET_SEED = 2

@export var settings : PlanetSettings = load("res://Assets/default_planet.tres")

@onready var player = $Player
@onready var terrain = $Terrain
@onready var vegetation = $Vegetation

@export var day_speed : float = 0.02
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment

func _ready():
    load_planet()

func load_planet():
    var chunk = CHUNK.instantiate()
    
    terrain.add_child(chunk)
    $Vegetation.set_terrain_chunk(chunk)
    
    chunk.setup(PLANET_SEED, settings)
    
    $Vegetation.generate_trees(PLANET_SEED, settings)

func _process(delta: float) -> void:
    var rotation_amount = day_speed * delta
    
    sun.rotate_x(rotation_amount)
    world_environment.environment.sky_rotation.x += rotation_amount

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        if event.pressed and event.keycode == KEY_E:
            take_screenshot()

func take_screenshot() -> void:
    var viewport = get_viewport()
    var texture = viewport.get_texture()
    var image = texture.get_image()
    image.save_png("res://high_quality_screenshot.png")

func save_planet():
    var save_root = Node3D.new()
    save_root.name = "GeneratedPlanet"

    for chunk in terrain.get_children():
        var mesh_instance = chunk.get_node_or_null("MeshInstance3D")

        if mesh_instance == null or mesh_instance.mesh == null:
            continue

        var saved_mesh = MeshInstance3D.new()
        saved_mesh.name = "TerrainChunk"
        saved_mesh.mesh = mesh_instance.mesh
        saved_mesh.transform = mesh_instance.global_transform

        save_root.add_child(saved_mesh)
        saved_mesh.owner = save_root

    var vegetation_root = Node3D.new()
    vegetation_root.name = "Vegetation"

    save_root.add_child(vegetation_root)
    vegetation_root.owner = save_root

    for child in vegetation.get_children():
        if child is MultiMeshInstance3D:
            var saved_vegetation = child.duplicate()

            saved_vegetation.name = child.name
            saved_vegetation.transform = child.transform

            vegetation_root.add_child(saved_vegetation)
            saved_vegetation.owner = save_root

    print("Saving terrain chunks: ", terrain.get_child_count())
    print("Saving vegetation instances: ", vegetation.get_child_count())

    for child in vegetation_root.get_children():
        if child is MultiMeshInstance3D:
            print(
                "Vegetation: ",
                child.name,
                " | instances: ",
                child.multimesh.instance_count,
                " | visible: ",
                child.multimesh.visible_instance_count
            )

    var packed_scene = PackedScene.new()
    var result = packed_scene.pack(save_root)

    if result != OK:
        print("Failed to pack planet: ", result)
        save_root.queue_free()
        return

    var path = "res://GeneratedPlanet.tscn"
    var save_result = ResourceSaver.save(packed_scene, path)

    if save_result == OK:
        print("Planet saved successfully to: ", path)
    else:
        print("Failed to save planet: ", save_result)

    save_root.queue_free()
