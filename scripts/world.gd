extends Node3D

const CHUNK = preload("res://scenes/TerrainChunk.tscn")

const LOAD_RADIUS = 6
const CHUNK_SIZE = 32

const SEED = 2

@onready var player = $Player
@onready var terrain = $Terrain
@onready var vegetation = $Vegetation

@export var day_speed : float = 0.02
@onready var sun: DirectionalLight3D = $DirectionalLight3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var loaded_faces: Dictionary = {}

var loaded_chunks: Dictionary = {}
var current_chunk := Vector2i(999999, 999999)

var chunks_to_load: Array[Vector2i] = []
var chunks_to_unload: Array[Vector2i] = []

func _ready():
	load_planet()

func load_planet():
	for face in range(6):
		load_face(face)
	
	load_vegetation()

func load_face(face: int):
	if loaded_faces.has(face):
		return
	
	var chunk = CHUNK.instantiate()
	
	terrain.add_child(chunk)
	$Vegetation.set_terrain_chunk(chunk)
	
	chunk.setup(SEED)

func load_vegetation():
	$Vegetation.generate_trees(SEED)
	

func _process(delta: float) -> void:
	var rotation_amount = day_speed * delta
	
	sun.rotate_x(rotation_amount)
	world_environment.environment.sky_rotation.x += rotation_amount

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_E:
			save_planet()

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
