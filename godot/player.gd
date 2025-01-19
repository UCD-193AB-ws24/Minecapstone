class_name Player
extends CharacterBody3D


@export var speed = 5
@export var jump_velocity = 10.0
@export var mouse_sensitivity = 0.1
@export var acceleration = 0.15
var current_acceleration = 0.15
var min_y: float
var max_y: float


@onready var camera: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var spawn_point: Marker3D = $"../SpawnPoint"


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var start_y = global_position.y
	min_y = start_y - 2.0 # arbritary just tp after walking off the ledge
	max_y = start_y + 15.0 # no point for now but added anyways


# Called on input event
func _input(event):
	# Rotate the player and the camera
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -89.9, 89.9)
	# Toggle mouse capture with escape
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_throw_pearl()


func _process(_delta):
	# Moves the player and its children
	# Called here instead to ensure smooth camera movement
	move_and_slide()


func _physics_process(_delta):
	# Get input direction
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var direction = Vector3(input_vector.x, 0, input_vector.y)

	# Movement direction as relative to the camera
	var camera_transform = camera.global_transform
	direction = camera_transform.basis * direction
	direction.y = 0
	direction = direction.normalized()
	collision.global_rotation.y = 0

	# Handle jumping
	if is_on_floor() and Input.is_action_pressed("jump"):
		velocity.y = jump_velocity

	# Apply gravity
	if not is_on_floor():
		velocity.y -= 35 * _delta
		current_acceleration = acceleration * 0.25
	else:
		current_acceleration = acceleration
	
	# Ramp movement speed
	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * speed, current_acceleration)
		velocity.z = lerp(velocity.z, direction.z * speed, current_acceleration)
	else:
		velocity.x = lerp(velocity.x, 0.0, current_acceleration)
		velocity.z = lerp(velocity.z, 0.0, current_acceleration)
	
	# Teleport the player back to the spawn point if they fall off the map
	if global_position.y < min_y:
		_on_out_of_bounds()


func _on_out_of_bounds():
	global_position = spawn_point.global_position
	velocity = Vector3.ZERO


var pearl_scene = preload("res://pearl.tscn")
func _throw_pearl():
	var pearl_instance = pearl_scene.instantiate()
	pearl_instance.global_transform = global_transform
	get_parent().add_child(pearl_instance)
	
	# Launch the pearl in the direction the camera is facing
	var spawn_position = camera.global_transform.origin
	var throw_direction = -camera.global_transform.basis.z
	pearl_instance.throw_in_direction(self, spawn_position, throw_direction)
