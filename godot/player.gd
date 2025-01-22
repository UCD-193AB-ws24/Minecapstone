class_name Player
extends CharacterBody3D


@onready var ai_controller: AIController = $AIController

# ======================= Movement and camera settings =======================
@export var _speed = 4.317
var _sprint_speed = _speed * 1.3
@export var _jump_velocity = 10.0
@export var _acceleration = 0.15
var current_acceleration = 0.15

# ============================ FOV and sprinting ============================
var _is_sprinting = false
@export var normal_fov = 70.0
var sprint_fov = normal_fov + 20
@export var fov_transition_speed = 10.0
var last_forward_press = 0.0 			# Make note and update the time for last "W" press
@export var double_tap_time = 0.3 		# Time in between "W" presses

# ============================= Alternate views ============================
enum ViewMode { THIRDPERSON, SPECTATOR, NORMAL }
@onready var view:ViewMode = ViewMode.NORMAL


# ========================= Block Breaking =================================
var _is_breaking : bool = false
var _break_timer : Timer
var _block_breaking
var _released : bool = true
@onready var block_progress : Label = $"../UI/Control/BlockProgress"


# ========================= Camera and player head =========================
@onready var head:Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var spawn_point: Marker3D = $"../SpawnPoint"	# TODO: replace with a proper spawn system
@export var _mouse_sensitivity = 0.1


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global_position = spawn_point.global_position


# Called on input event
func _input(event):
	if not ai_controller.ai_control_enabled:
		if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			var deltaX = -event.relative.y * _mouse_sensitivity
			var deltaY = -event.relative.x * _mouse_sensitivity
			if view == ViewMode.SPECTATOR:
				camera.global_rotation_degrees.x = clamp(camera.global_rotation_degrees.x + deltaX, -89.5, 89.5)
				camera.global_rotation_degrees.y += deltaY
				camera.global_rotation_degrees.z = 0
			else:
				rotate_y(deg_to_rad(deltaY))
				head.rotate_x(deg_to_rad(deltaX))
				head.rotation_degrees.x = clamp(head.rotation_degrees.x, -89.9, 89.9)
		elif event is InputEventKey and event.pressed and event.keycode == KEY_E:
			_throw_pearl()
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		match view:
			ViewMode.NORMAL:
				view = ViewMode.THIRDPERSON
				camera.global_position += camera.global_transform.basis.z * 3.5
			ViewMode.THIRDPERSON:
				view = ViewMode.SPECTATOR
				camera.global_position = global_position + Vector3(0, 1.66, 0)
			ViewMode.SPECTATOR:
				view = ViewMode.NORMAL
				camera.rotation_degrees = Vector3(0, 0, 0)
				camera.global_position = global_position + Vector3(0, 1.66, 0)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta):
	# Moves the player and child nodes
	# Called here instead to ensure smooth camera movement
	move_and_slide()

	if view == ViewMode.SPECTATOR: spectator_movement(_delta);

	# Highlight block player is looking at, and place or remove blocks
	if not ai_controller.ai_control_enabled:
		_handle_block_interaction()
	
	if _is_breaking:
		break_block()

func _handle_block_interaction():
	var block_highlight: CSGBox3D = $BlockHighlight
	var block_manager: Node = $"../BlockManager"
	var chunk_manager: Node = $"../ChunkManager"
	
	if not Input.is_action_pressed("mouse1"):
		_released = true
	
	if Input.is_action_just_pressed("mouse1"):
		_released = false
	
	if raycast.is_colliding() and raycast.get_collider().has_meta("is_chunk"):
		block_highlight.visible = true

		var block_position = raycast.get_collision_point() -0.5 * raycast.get_collision_normal()
		var int_block_position = Vector3(floor(block_position.x), floor(block_position.y), floor(block_position.z))

		block_highlight.global_position = int_block_position + Vector3(0.5, 0.5, 0.5)

		var chunk = raycast.get_collider()
		
		if not Input.is_action_pressed("mouse1"):
			_released = true
		
		if Input.is_action_just_pressed("mouse1") and not _is_breaking:
			begin_block_break((Vector3i)(int_block_position - chunk.global_position))
		
		if  not _released and not _is_breaking:
			begin_block_break((Vector3i)(int_block_position - chunk.global_position))
		
		if Input.is_action_just_pressed("mouse2"):
			# Prevent player from placing blocks if the block will intersect the player
			var new_block_position:Vector3 = int_block_position + raycast.get_collision_normal()
			
			if not block_position_intersect_player(new_block_position):
				chunk_manager.SetBlock(new_block_position, block_manager.Stone)
	else:
		block_highlight.visible = false
	# Lock the block highlight to the grid
	block_highlight.global_rotation = Vector3.ZERO


func block_position_intersect_player(new_block_position:Vector3) -> bool:
	var collision_box = BoxShape3D.new()
	collision_box.extents = Vector3(0.5, 0.5, 0.5)

	var collision_box_transform = Transform3D()
	collision_box_transform.origin = new_block_position + Vector3(0.5, 0.5, 0.5)

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = collision_box
	query.transform = collision_box_transform

	var result = space_state.intersect_shape(query)

	return result.size() > 0

func begin_block_break(pos:Vector3i):
	print(block_progress.text)
	_is_breaking = true
	_block_breaking = pos
	var block_manager: Node = $"../BlockManager"
	var chunk = raycast.get_collider()
	var block = chunk.GetBlock(_block_breaking)
	var time = block_manager.GetTime(block)
	_break_timer = Timer.new()
	_break_timer.one_shot = true
	add_child(_break_timer)
	_break_timer.start(time)
	block_progress.text = "0%"
	block_progress.visible = true

func break_block():
	
	var block_manager: Node = $"../BlockManager"
	var chunk = raycast.get_collider()
	var block_position = raycast.get_collision_point() -0.5 * raycast.get_collision_normal()
	var int_block_position = Vector3(floor(block_position.x), floor(block_position.y), floor(block_position.z))
	
	
	
	if not raycast.is_colliding() or not chunk.has_method("GetBlock"):
		_block_breaking = null
		_is_breaking = false
		block_progress.visible = false
		return
	
	var block = chunk.GetBlock(_block_breaking)
	var time = block_manager.GetTime(block)
	var percentage : float = (time - _break_timer.time_left) / time * 100
	var percent_string : String = str(round(percentage * 10)/10, "%")
	block_progress.text = percent_string
	
	if (Vector3i)(int_block_position - chunk.global_position) != _block_breaking:
		_block_breaking = null
		_is_breaking = false
		block_progress.visible = false

	
	if _block_breaking == null:
		_is_breaking = false
		block_progress.visible = false
		return
	
	if Input.is_action_just_released("mouse1"):
		_block_breaking = null
		_is_breaking = false
		block_progress.visible = false
		
	
	if _break_timer.is_stopped():
		block_progress.visible = false
		chunk.SetBlock(_block_breaking, block_manager.Air)
		_block_breaking = null
		_is_breaking = false
		
	

# TODO: Spectator mode should unchild the camera from the player
func spectator_movement(_delta):
	var cameraSpeed = 10;
	var move_dir = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("jump") - Input.get_action_strength("crouch"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)

	# Move the camera in the direction it's facing
	var move_vector = camera.global_transform.basis.x * move_dir.x + camera.global_transform.basis.y * move_dir.y + camera.global_transform.basis.z * move_dir.z
	camera.global_position += move_vector * cameraSpeed * _delta


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
	# Double-tap to sprint
	var current_time = Time.get_ticks_msec() / 1000.0
	if Input.is_action_just_pressed("move_forward"):
		if current_time - last_forward_press <= double_tap_time:
			_is_sprinting = true
		last_forward_press = current_time

	# Shift to sprint
	if Input.is_action_pressed("sprint") and Input.is_action_pressed("move_forward"):
		_is_sprinting = true
	elif not Input.is_action_pressed("move_forward") or Vector2(velocity.x, velocity.z).length() < 0.1:
		# Stop sprinting if not moving forward or sprint is released
		_is_sprinting = false

	if _is_sprinting:
		return _sprint_speed
	else:
		return _speed


func _move_player(direction: Vector2, jump: bool, speed: float, _delta):
	# Disable movement if spectator mode
	if view == ViewMode.SPECTATOR: direction = Vector2.ZERO

	# Convert 2D direction to 3D movement
	var movement = Vector3(direction.x, 0, direction.y)

	# Apply movement
	if movement != Vector3.ZERO:
		velocity.x = lerp(velocity.x, movement.x * speed, _acceleration)
		velocity.z = lerp(velocity.z, movement.z * speed, _acceleration)
	else:
		velocity.x = lerp(velocity.x, 0.0, _acceleration)
		velocity.z = lerp(velocity.z, 0.0, _acceleration)

	# Handle jumping
	if is_on_floor() and jump:
		velocity.y = _jump_velocity

		# Apply horizontal impulse if jumping while sprinting
		if _is_sprinting:
			var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
			var impulse = horizontal_velocity.normalized() * 0 * horizontal_velocity.length()
			velocity += impulse


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
