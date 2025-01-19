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

#AI Variables
var ai_control_enabled: bool = false
var ai_movement: Vector2 = Vector2.ZERO
var ai_jump: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var start_y = global_position.y
	min_y = start_y - 2.0 # arbritary just tp after walking off the ledge
	max_y = start_y + 15.0 # no point for now but added anyways
	

func _input(event):
	if not ai_control_enabled:
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
	
	if ai_control_enabled:
		_handle_ai_control(_delta)
	else:
		_handle_player_input(_delta)
		
	if global_position.y < min_y:
		_on_out_of_bounds()

func _handle_player_input(_delta):

	#Get input direction from player controls
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	
	#Transform input to world-relative movement
	var right_dir = Vector2(camera.global_transform.basis.x.x, camera.global_transform.basis.x.z)
	var forward_dir = Vector2(camera.global_transform.basis.z.x, camera.global_transform.basis.z.z)
	var relative_direction = right_dir * input_vector.x + forward_dir * input_vector.y
	relative_direction = relative_direction.normalized()
	
	_apply_gravity(_delta)
	_move_player(relative_direction, Input.is_action_pressed("jump"), _delta)

func _handle_ai_control(_delta):
	# Use AI movement inputs directly
	var relative_direction = ai_movement.normalized()
	_apply_gravity(_delta)
	_move_player(relative_direction, ai_jump, _delta)

func _move_player(direction: Vector2, jump: bool, _delta):
	# Convert 2D direction to 3D movement
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
	
	move_and_slide()

func _apply_gravity(_delta):
	if not is_on_floor():
		velocity.y -= 35 * _delta

func _on_out_of_bounds():
	global_position = spawn_point.global_position
	velocity = Vector3.ZERO
	
func _set_ai_movement(direction: Vector2):
	ai_movement = direction
	
func _set_ai_jump(jump: bool):
	ai_jump = jump
