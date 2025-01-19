class_name Player
extends CharacterBody3D


@export var speed = 5
@export var sprint_speed = 10
@export var jump_velocity = 10.0
@export var mouse_sensitivity = 0.1
@export var acceleration = 0.15 

#Fov and sprinting
@export var normal_fov = 70.0 # Default Camera3D fov
@export var sprint_fov = 90.0 
@export var fov_transition_speed = 5.0
@export var double_tap_time = 0.3 # Time in between "W" presses

var is_sprinting = false
var last_forward_press = 0.0 # Make note and update the time for last "W" press

var current_acceleration = 0.15
var min_y: float

@onready var camera: Camera3D = $Camera3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var spawn_point: Marker3D = $"../SpawnPoint"			# TODO: replace with a proper spawn system
@onready var ai_controller: AIController = $AIController

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var start_y = global_position.y
	min_y = start_y - 2.0 	# arbritary just tp after walking off the ledge


# Called on input event
func _input(event):
	if not ai_controller.ai_control_enabled:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
			camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -89.9, 89.9)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_throw_pearl()
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta):
	# Moves the player and its children
	# Called here instead to ensure smooth camera movement
	move_and_slide()

func _physics_process(_delta):
	if not ai_controller.ai_control_enabled:
		_handle_player_input(_delta)
	
	_apply_gravity(_delta)
	_update_fov(_delta)
	
	if global_position.y < min_y:
		_on_out_of_bounds()


func _handle_player_input(_delta):
	
	# Sprinting
	
	# Double-tap W Sprint
	var current_time = Time.get_ticks_msec() / 1000.0 # Milliseconds to seconds
	if Input.is_action_just_pressed("move_forward"):
		if current_time - last_forward_press <= double_tap_time:
			is_sprinting = true
		last_forward_press = current_time
	
	# Shift sprint
	if Input.is_action_pressed("sprint"):
		is_sprinting = true
	
	# Stop sprinting if not moving forward or sprint is released
	if not Input.is_action_pressed("move_forward") and not Input.is_action_pressed("sprint"):
		is_sprinting = false
		
	
	# Speed if sprinting or not
	var current_speed = sprint_speed if is_sprinting else speed
	
	# Get input direction from player controls
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)

	# Transform movement direction to be relative to the camera
	var right_dir = Vector2(camera.global_transform.basis.x.x, camera.global_transform.basis.x.z)
	var forward_dir = Vector2(camera.global_transform.basis.z.x, camera.global_transform.basis.z.z)
	var relative_direction = right_dir * input_vector.x + forward_dir * input_vector.y
	relative_direction = relative_direction.normalized()
	
	_move_player(relative_direction, Input.is_action_pressed("jump"), current_speed, _delta)


func _move_player(direction: Vector2, jump: bool, current_speed: float, _delta):
	# Convert 2D direction to 3D movement
	var movement = Vector3(direction.x, 0, direction.y)
	
	# Apply movement
	if movement != Vector3.ZERO:
		velocity.x = lerp(velocity.x, movement.x * current_speed, acceleration)
		velocity.z = lerp(velocity.z, movement.z * current_speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration)
		velocity.z = lerp(velocity.z, 0.0, acceleration)
	
	# Handle jumping
	if is_on_floor() and jump:
		velocity.y = jump_velocity


func _apply_gravity(_delta):
	if not is_on_floor():
		velocity.y -= 35 * _delta
		current_acceleration = acceleration * 0.25
	else:
		current_acceleration = acceleration

func _update_fov(_delta):
	# Update fov based on sprinting or not
	if is_sprinting:
		camera.fov = lerp(camera.fov, sprint_fov, fov_transition_speed * _delta)
	else:
		camera.fov = lerp(camera.fov, normal_fov, fov_transition_speed * _delta)
	
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
