extends CharacterBody3D

@export var speed := 20.0 * TerrainConfig.PLANET_RADIUS / 50
@export var mouse_sensitivity := 0.002
@export var planet_center := Vector3.ZERO

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var yaw := 0.0
var pitch := 0.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	position.y = TerrainConfig.PLANET_RADIUS * 1.1
	position.z = TerrainConfig.PLANET_RADIUS * 1.1
	
	update_gravity_orientation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch -= event.relative.y * mouse_sensitivity
		
		pitch = clamp(
			pitch,
			deg_to_rad(-89.0),
			deg_to_rad(89.0)
		)
		
		camera_pivot.rotation.x = pitch - TAU/4
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_Q:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	update_gravity_orientation()
	
	var direction := Vector3.ZERO
	
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	
	var sprint_mult := 1.0

	if Input.is_action_pressed("camera_sprint"):
		sprint_mult = 5.0
	
	if Input.is_action_pressed("move_forward"):
		direction += forward
	
	if Input.is_action_pressed("move_backward"):
		direction -= forward
	
	if Input.is_action_pressed("move_left"):
		direction -= right
	
	if Input.is_action_pressed("move_right"):
		direction += right
	
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
		
		var motion := direction * speed * delta * sprint_mult
		
		move_and_collide(motion)
		
		#update_pos_text()

func update_gravity_orientation() -> void:
	var up := (global_position - planet_center).normalized()
	var forward := -global_transform.basis.z
	
	forward = forward - up * forward.dot(up)
	
	if forward.length_squared() < 0.001:
		return
	
	forward = forward.normalized()
	
	var right := forward.cross(up).normalized()
	
	forward = up.cross(right).normalized()
	
	global_transform.basis = Basis(right, up, -forward).orthonormalized()

func update_pos_text():
	$"../HUD/CoordLabel".text = str(
		"x: ", global_position.x,
		"\ny: ", global_position.y,
		"\nz: ", global_position.z
	)
