extends CharacterBody3D

@export var speed = 5
@export var jump_velocity = 10.0
@export var mouse_sensitivity = 0.1
@export var acceleration = 0.15
var current_acceleration = 0.15

@onready var camera: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -89.9, 89.9)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta):
	move_and_slide()

func _physics_process(_delta):
	# Get input direction
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var direction = Vector3(input_vector.x, 0, input_vector.y)

	# Transform direction to be relative to the camera
	
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
	
	# Accelerate or decelerate
	if direction != Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * speed, current_acceleration)
		velocity.z = lerp(velocity.z, direction.z * speed, current_acceleration)
	else:
		velocity.x = lerp(velocity.x, 0.0, current_acceleration)
		velocity.z = lerp(velocity.z, 0.0, current_acceleration)

	# Move the player
