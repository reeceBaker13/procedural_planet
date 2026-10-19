extends CharacterBody3D

@export var settings : PlanetSettings = load("res://Assets/default_planet.tres")

@export var speed := 0.6 * settings.radius / 50
@export var jump_velocity := 30.0
@export var gravity := 25.0
@export var mouse_sensitivity := 0.002
@export var planet_center := Vector3.ZERO

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var pitch := 0.0
var spawn_timer := 0.5 # Small grace period for chunks to finish generating collision


func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    respawn_player()


func respawn_player() -> void:
    # Spawn safely high above the planet surface
    var spawn_dir := Vector3(0, 1, 1).normalized()
    global_position = planet_center + spawn_dir * (settings.radius + settings.land_height + 20.0)
    velocity = Vector3.ZERO
    spawn_timer = 0.5 # Reset grace period
    align_to_planet()


func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var up := (global_position - planet_center).normalized()
        # Rotate yaw locally around the planet's surface normal
        global_transform.basis = global_transform.basis.rotated(up, event.relative.x * mouse_sensitivity)
        
        # Pitch (look up/down) with your original camera pivot offset restored
        pitch -= event.relative.y * mouse_sensitivity
        pitch = clamp(pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
        camera_pivot.rotation.x = pitch - TAU/4
    
    if event is InputEventKey:
        if event.pressed and event.keycode == KEY_ESCAPE:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        if event.pressed and event.keycode == KEY_Q:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
    var dist_from_center = global_position.distance_to(planet_center)
    
    # Void safeguard
    if dist_from_center < settings.radius * 0.9 or dist_from_center > settings.radius * 3.0:
        respawn_player()
        return

    var up := (global_position - planet_center).normalized()
    up_direction = up
    
    # Wait out the spawn grace period so terrain collision has time to register before gravity pulls you down
    if spawn_timer > 0:
        spawn_timer -= delta
        velocity = Vector3.ZERO
        return

    # Apply radial gravity towards the planet center when airborne
    if not is_on_floor():
        velocity -= up * gravity * delta
    else:
        var radial_vel = velocity.dot(up)
        if radial_vel < 0:
            velocity -= up * radial_vel

    # Handle Jump
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity += up * jump_velocity

    # Get camera-relative movement vectors projected onto the planet tangent plane
    var forward := -global_transform.basis.z
    var right := global_transform.basis.x
    
    forward = (forward - up * forward.dot(up)).normalized()
    right = (right - up * right.dot(up)).normalized()
    
    var input_dir := Vector3.ZERO
    if Input.is_action_pressed("move_forward"):
        input_dir += forward
    if Input.is_action_pressed("move_backward"):
        input_dir -= forward
    if Input.is_action_pressed("move_left"):
        input_dir -= right
    if Input.is_action_pressed("move_right"):
        input_dir += right
        
    var sprint_mult := 5.0 if Input.is_action_pressed("camera_sprint") else 1.0
    
    if input_dir.length_squared() > 0.0:
        input_dir = input_dir.normalized()
        var vertical_vel = up * velocity.dot(up)
        velocity = (input_dir * speed * sprint_mult) + vertical_vel
    else:
        var vertical_vel = up * velocity.dot(up)
        var horiz_vel = velocity - vertical_vel
        horiz_vel = horiz_vel.move_toward(Vector3.ZERO, speed * delta * 10.0)
        velocity = horiz_vel + vertical_vel

    move_and_slide()
    
    # Smoothly curve the character's orientation to match the sphere curvature
    align_to_planet_smooth(up)


func align_to_planet() -> void:
    var up := (global_position - planet_center).normalized()
    var ref := Vector3.FORWARD
    if abs(up.dot(Vector3.FORWARD)) > 0.99:
        ref = Vector3.RIGHT
    var right := up.cross(ref).normalized()
    var forward := right.cross(up).normalized()
    global_transform.basis = Basis(right, up, -forward).orthonormalized()
    
    pitch = 0.0
    camera_pivot.rotation.x = pitch - TAU/4


func align_to_planet_smooth(target_up: Vector3) -> void:
    var current_up := global_transform.basis.y
    if current_up.length_squared() > 0.0 and target_up.length_squared() > 0.0:
        var rot_quat := Quaternion(current_up, target_up)
        global_transform.basis = Basis(rot_quat) * global_transform.basis
        global_transform.basis = global_transform.basis.orthonormalized()
