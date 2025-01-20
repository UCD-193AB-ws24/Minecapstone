class_name Player
extends CharacterBody3D


@export var speed = 5
@export var jump_velocity = 10.0
@export var mouse_sensitivity = 0.1
@export var acceleration = 0.15

var current_acceleration = 0.15
var min_y: float
var spectator_view = false;
var god_view = false;

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
			if spectator_view:
				camera.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
				camera.rotation_degrees.x = clamp(camera.rotation_degrees.x - event.relative.y * mouse_sensitivity, -89.9, 89.9)
			elif god_view:
				camera.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			else:
				rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
				camera.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
				camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -89.9, 89.9)
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_throw_pearl()
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		spectator_view = !spectator_view
		god_view = false
		if not spectator_view:
			camera.global_position = global_position + Vector3(0, 1.66, 0)
			camera.rotation_degrees = Vector3(0, 0, 0)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ALT:
		god_view = !god_view
		spectator_view = false
		if god_view:
			camera.global_position = global_position + Vector3(0, 10, 0)
			camera.rotation_degrees = Vector3(-90, 0, 0)
		else:
			camera.global_position = global_position + Vector3(0, 1.66, 0)
			camera.rotation_degrees = Vector3(0, 0, 0)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			


func _process(_delta):
	# Moves the player and its children
	# Called here instead to ensure smooth camera movement
	if spectator_view:
		spectator_movement(_delta);
	move_and_slide()

func spectator_movement(_delta):
	var cameraSpeed = 10;
	var move_dir = Vector3(
	Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
	Input.get_action_strength("move_up") - Input.get_action_strength("move_down"),
	Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	# we are the camera now so just move the camera
	var move_vector = camera.global_transform.basis.x * move_dir.x + camera.global_transform.basis.y * move_dir.y + camera.global_transform.basis.z * move_dir.z
	if Input.is_key_pressed(KEY_SPACE):
		move_vector.y += 1
	if Input.is_key_pressed(KEY_CTRL):
		move_vector.y -= 1
	camera.global_position += move_vector * cameraSpeed * _delta


func _physics_process(_delta):
	if not ai_controller.ai_control_enabled:
		_handle_player_input(_delta)
	
	_apply_gravity(_delta)
	
	if global_position.y < min_y:
		_on_out_of_bounds()


func _handle_player_input(_delta):
	# Get input direction from player controls
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)

	# Transform movement direction to be relative to the camera
	var right_dir = Vector2(camera.global_transform.basis.x.x, camera.global_transform.basis.x.z)
	var forward_dir = Vector2(camera.global_transform.basis.z.x, camera.global_transform.basis.z.z)
	if god_view:
		forward_dir = -forward_dir
	var relative_direction = right_dir * input_vector.x + forward_dir * input_vector.y
	relative_direction = relative_direction.normalized()
	
	_move_player(relative_direction, Input.is_action_pressed("jump"), _delta)


func _move_player(direction: Vector2, jump: bool, _delta):
	# Convert 2D direction to 3D movement
	if spectator_view:
		# still want model to keep moving if midair so do this
		velocity.x = lerp(velocity.x, 0.0, acceleration)
		velocity.z = lerp(velocity.z, 0.0, acceleration)
		return
	
	var movement = Vector3(direction.x, 0, direction.y)
	
	# Apply movement
	if movement != Vector3.ZERO:
		velocity.x = lerp(velocity.x, movement.x * speed, acceleration)
		velocity.z = lerp(velocity.z, movement.z * speed, acceleration)
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
