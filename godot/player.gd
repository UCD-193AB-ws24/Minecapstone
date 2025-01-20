class_name Player
extends CharacterBody3D


@export var _speed = 5
@export var _sprint_speed = _speed * 1.5
@export var _jump_velocity = 10.0
@export var _mouse_sensitivity = 0.1
@export var _acceleration = 0.15

#Fov and sprinting
@export var normal_fov = 70.0 # Default Camera3D fov
@export var sprint_fov = 90.0 
@export var fov_transition_speed = 5.0
@export var double_tap_time = 0.3 # Time in between "W" presses

var _is_sprinting = false
var last_forward_press = 0.0 # Make note and update the time for last "W" press

var current_acceleration = 0.15

@onready var head:Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var block_highlight: CSGBox3D = $BlockHighlight
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var spawn_point: Marker3D = $"../SpawnPoint"	# TODO: replace with a proper spawn system
@onready var ai_controller: AIController = $AIController
@onready var block_manager: Node = $"../BlockManager"
@onready var chunk_manager: Node = $"../ChunkManager"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called on input event
func _input(event):
	if not ai_controller.ai_control_enabled:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			var deltaX = -event.relative.y * _mouse_sensitivity
			var deltaY = -event.relative.x * _mouse_sensitivity
			rotate_y(deg_to_rad(deltaY))
			head.rotate_x(deg_to_rad(deltaX))
			head.rotation_degrees.x = clamp(head.rotation_degrees.x, -89.9, 89.9)
		elif event is InputEventKey and event.pressed and event.keycode == KEY_E:
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

	# Highlight block player is looking at, and place or remove blocks
	if raycast.is_colliding() and raycast.get_collider().has_meta("is_chunk"):
		block_highlight.visible = true
		
		var block_position = raycast.get_collision_point() -0.5 * raycast.get_collision_normal()
		var int_block_position = Vector3(floor(block_position.x), floor(block_position.y), floor(block_position.z))

		block_highlight.global_position = int_block_position + Vector3(0.5, 0.5, 0.5)

		var chunk = raycast.get_collider()
		if Input.is_action_just_pressed("mouse1"):
			chunk.SetBlock((Vector3i)(int_block_position - chunk.global_position), block_manager.Air)
		if Input.is_action_just_pressed("mouse2"):
			# TODO: Prevent player from placing blocks if the block will intersect the player
			chunk_manager.SetBlock((Vector3i)(int_block_position + raycast.get_collision_normal()), block_manager.Stone)
	else:
		block_highlight.visible = false

	# Lock the block highlight to the grid
	block_highlight.global_rotation = Vector3.ZERO


func _physics_process(_delta):
	if not ai_controller.ai_control_enabled:
		_handle_player_input(_delta)
	
	_apply_gravity(_delta)
	_update_fov(_delta)
	
	if global_position.y < -64:
		_on_out_of_bounds()


func _handle_player_input(_delta):
	var current_speed = _handle_sprint()

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


func _handle_sprint():
	# Double-tap W Sprint
	var current_time = Time.get_ticks_msec() / 1000.0 # Milliseconds to seconds
	if Input.is_action_just_pressed("move_forward"):
		if current_time - last_forward_press <= double_tap_time:
			_is_sprinting = true
		last_forward_press = current_time
	
	if Input.is_action_pressed("sprint") and Input.is_action_pressed("move_forward"):
		_is_sprinting = true
	# Stop sprinting if not moving forward or sprint is released
	elif not Input.is_action_pressed("move_forward") and not Input.is_action_pressed("sprint"):
		_is_sprinting = false
		
	if _is_sprinting:
		return _sprint_speed
	else:
		return _speed


func _move_player(direction: Vector2, jump: bool, current_speed: float, _delta):
	# Convert 2D direction to 3D movement
	var movement = Vector3(direction.x, 0, direction.y)
	
	# Apply movement
	if movement != Vector3.ZERO:
		velocity.x = lerp(velocity.x, movement.x * current_speed, _acceleration)
		velocity.z = lerp(velocity.z, movement.z * current_speed, _acceleration)
	else:
		velocity.x = lerp(velocity.x, 0.0, _acceleration)
		velocity.z = lerp(velocity.z, 0.0, _acceleration)
	
	# Handle jumping
	if is_on_floor() and jump:
		velocity.y = _jump_velocity


func _apply_gravity(_delta):
	if not is_on_floor():
		velocity.y -= 35 * _delta
		current_acceleration = _acceleration * 0.25
	else:
		current_acceleration = _acceleration

func _update_fov(_delta):
	# Update fov based on sprinting or not
	if _is_sprinting:
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
	var facing_direction = -head.global_transform.basis.z 
	var throw_direction = facing_direction + ((facing_direction + velocity)/2)*0.1
	var spawn_position = head.global_transform.origin
	
	pearl_instance.throw_in_direction(self, spawn_position, throw_direction.normalized())
