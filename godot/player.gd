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
@export var normal_fov = 70.0
@export var fov_transition_speed = 7.5
@export var double_tap_time = 0.3 		# Time in between "W" presses
var sprint_fov = normal_fov + 20
var _is_sprinting = false
var last_forward_press = 0.0 			# Make note and update the time for last "W" press

# ============================= Alternate views ============================
enum ViewMode { THIRDPERSON, SPECTATOR, NORMAL }
@onready var view:ViewMode = ViewMode.NORMAL

# ========================= Block Breaking =================================
var _is_breaking : bool = false
var _break_timer : Timer
var _block_breaking						# position of the block attempting to break or null (not attempted block)
var _released : bool = true
@onready var block_progress : Label = $"../UI/Control/BlockProgress"

# ============================ Health, Hunger, Thirst =====================
@export var max_health = 100
@export var max_hunger = 100
@export var max_thirst = 100
var health = max_health
var hunger = max_hunger
var thirst = max_thirst

@export var hunger_decrease_rate = 0.01 # Default hunger decrease
@export var thirst_decrease_rate = 0.015 # Default thirst decrease
@export var sprint_hunger = 0.09 # Additional hunger decrease when sprinting
@export var sprint_thirst = 0.035 # Additional thirst decrease when sprinting
@export var health_decrease_rate = 2.5 # Lose 1 health per second if hunger/thirst is 0
@export var natural_healing_rate = 5.0 # Health regeneration when hunger and thirst are full

# TODO: investigate using an actual timer rather than delta time (framerate dependent)
var hunger_timer = 0.0
var thirst_timer = 0.0

# ============================ Important stuff ============================
@onready var head:Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var spawn_point: Marker3D = $"../SpawnPoint"	# TODO: replace with a proper spawn system
@export var _mouse_sensitivity = 0.1

# ======================= Inventory =========================
@onready var inventory_manager: Node = $InventoryManager
@onready var block_highlight: CSGBox3D = $BlockHighlight
@onready var block_manager: Node = $"../NavigationMesher/BlockManager"
@onready var chunk_manager: Node = $"../NavigationMesher/ChunkManager"


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global_position = spawn_point.global_position
	inventory_manager.AddItem(block_manager.ItemDict.Get("Stone"), 64)


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
	if Input.is_action_just_released("inventory_up"):
		print("scroll up")
		inventory_manager.CycleUp()
		inventory_manager.PrintSelected()
	if Input.is_action_just_released("inventory_down"):
		print("scroll down")
		inventory_manager.CycleDown()
		inventory_manager.PrintSelected()


func _process(_delta):
	# Moves the player and child nodes
	# Called here instead to ensure smooth camera movement
	move_and_slide()

	if view == ViewMode.SPECTATOR: _spectator_movement(_delta);

	# Highlight block player is looking at, and place or remove blocks
	if not ai_controller.ai_control_enabled:
		_handle_block_interaction()
	
	if _is_breaking:
		_break_block()


func _physics_process(_delta):
	if not ai_controller.ai_control_enabled:
		_handle_player_input(_delta)

	_apply_gravity(_delta)
	_update_fov(_delta)
	_update_health_hunger_thirst(_delta)

	if global_position.y < -64:
		_on_out_of_bounds()

func move_player(direction: Vector2, jump: bool, speed: float, _delta):
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


func _handle_block_interaction():
	# Allows for multiple blocks to be broken while mouse1 is held down
	if not Input.is_action_pressed("mouse1"): _released = true
	if Input.is_action_just_pressed("mouse1"): _released = false

	# Lock the block highlight rotation to prevent it from rotating with the player
	block_highlight.global_rotation = Vector3.ZERO
	
	if raycast.is_colliding() and raycast.get_collider().has_meta("is_chunk"):
		var chunk = raycast.get_collider()

		var block_position = raycast.get_collision_point() -0.5 * raycast.get_collision_normal()
		var int_block_position = Vector3(floor(block_position.x), floor(block_position.y), floor(block_position.z))
		
		block_highlight.visible = true
		block_highlight.global_position = int_block_position + Vector3(0.5, 0.5, 0.5)

		# Handles the mouse1 event for breaking blocks
		_handle_block_breaking(block_position, chunk.global_position)
		
		if Input.is_action_just_pressed("mouse2"):
			var new_block_position:Vector3 = int_block_position + raycast.get_collision_normal()
			
			# Prevent player from placing blocks if the block will intersect the player
			if not _block_position_intersect_player(new_block_position):
				#replace block_manager.ItemDict.Get with selected block to place from inventory
				if inventory_manager.GetSelectedItem() != null and inventory_manager.GetSelectedItem().has_meta("is_block"):
					chunk_manager.SetBlock(new_block_position, inventory_manager.GetSelectedItem())
					inventory_manager.ConsumeSelectedItem()
					_update_navmesh()
	else:
		block_highlight.visible = false


func _block_position_intersect_player(new_block_position:Vector3) -> bool:
	# Creates a collision box to check if the new block position would intersects the player
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


func _update_navmesh():
	var nav_mesher = $"../NavigationMesher"
	nav_mesher.call_deferred("GenerateNavmesh")


# Checks if inputted to break block
func _handle_block_breaking(block_position:Vector3, chunk_offset:Vector3):
	if not Input.is_action_pressed("mouse1"): _released = true

	# if pressed left mouse prepare for block breaking
	if Input.is_action_just_pressed("mouse1") and not _is_breaking:
		_begin_block_break((Vector3i)(block_position - chunk_offset))
	# if holding down left mouse prepare for breaking
	if not _released and not _is_breaking:
		_begin_block_break((Vector3i)(block_position - chunk_offset))


# Prepares timer for block breaking
func _begin_block_break(pos:Vector3i):
	_is_breaking = true
	_block_breaking = pos 
	# get block data, time to break
	var chunk = raycast.get_collider()
	var block = chunk.GetBlock(_block_breaking)
	var time = block_manager.GetTime(block)

	# setup timer to calculate block breaking
	_break_timer = Timer.new()
	_break_timer.one_shot = true
	add_child(_break_timer)
	_break_timer.start(time)

	# setup progress label for block breaking
	block_progress.text = "0%"
	block_progress.visible = true


# Determines if looking at the right block and breaks it after timeout
func _break_block():
	# Get initial raycast data from player
	var chunk = raycast.get_collider()
	var block_position = raycast.get_collision_point() -0.5 * raycast.get_collision_normal()
	var int_block_position = Vector3(floor(block_position.x), floor(block_position.y), floor(block_position.z))

	# if player isn't looking at a block, cancel the block breaking
	if not raycast.is_colliding() or not chunk.has_meta("is_chunk"):
		_block_breaking = null
		_is_breaking = false
		block_progress.visible = false
		return
	
	# get block time and update progress label
	var block = chunk.GetBlock(_block_breaking)
	
	var time = block_manager.GetTime(block)
	var percentage : float = (time - _break_timer.time_left) / time * 100
	var percent_string : String = str(round(percentage * 10)/10, "%")
	block_progress.text = percent_string
	
	# if player stops looking at the block cancel the block breaking
	if (Vector3i)(int_block_position - chunk.global_position) != _block_breaking:
		_block_breaking = null
		_is_breaking = false
		block_progress.visible = false
		_break_timer.queue_free()
	
	# if not looking at a valid block stop block breaking
	if _block_breaking == null:
		_is_breaking = false
		block_progress.visible = false
		_break_timer.queue_free()
		return
	
	# if released mouse button cancel block breaking
	if Input.is_action_just_released("mouse1"):
		_block_breaking = null
		_is_breaking = false
		block_progress.visible = false
		_break_timer.queue_free()
		return
		
	# when timer stops break the block (set it to air)
	if _break_timer.is_stopped():
		block_progress.visible = false
		chunk.SetBlock(_block_breaking, block_manager.ItemDict.Get("Air"))
		
		var drop_pos:Vector3 = chunk.global_position + Vector3(_block_breaking.x, _block_breaking.y, _block_breaking.z)
		var block_node = block.GenerateItem()
		get_parent().add_child(block_node)
		block_node.global_position = drop_pos + Vector3(0.5, 0.5, 0.5)
		
		inventory_manager.PrintInventory()
		
		_block_breaking = null
		_is_breaking = false
		_break_timer.queue_free()
		_update_navmesh()
	

func _spectator_movement(_delta):
	var cameraSpeed = 10;
	var move_dir = Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("jump") - Input.get_action_strength("crouch"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)

	# Move the camera in the direction it's facing
	var move_vector = camera.global_transform.basis.x * move_dir.x + camera.global_transform.basis.y * move_dir.y + camera.global_transform.basis.z * move_dir.z
	camera.global_position += move_vector * cameraSpeed * _delta


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

	move_player(relative_direction, Input.is_action_pressed("jump"), current_speed, _delta)


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
	var throw_direction = facing_direction + ((facing_direction + velocity)/2)*0.05
	var spawn_position = head.global_transform.origin

	pearl_instance.throw_in_direction(self, spawn_position, throw_direction.normalized())


func _update_health_hunger_thirst(_delta):
	# Decrease health and thirst over time
	hunger_timer += _delta
	thirst_timer += _delta
	
	# Calculate current decrease rate
	var current_hunger_rate = hunger_decrease_rate
	var current_thirst_rate = thirst_decrease_rate
	
	if _is_sprinting:
		current_hunger_rate += sprint_hunger
		current_thirst_rate += sprint_thirst
		
	# Apply a regular decrease per second 
	if hunger_timer >= 1.0:
		hunger = max(hunger - current_hunger_rate, 0)
		hunger_timer = 0.0
	if thirst_timer >= 1.0:
		thirst = max(thirst - current_thirst_rate, 0)
		thirst_timer = 0.0
		
	# Lose health if hunger or thirst reaches 0
	if hunger == 0 or thirst == 0:
		health = max(health - health_decrease_rate * _delta, 0)
	
	if hunger == max_hunger and thirst == max_thirst:
		health = min(health + natural_healing_rate * _delta, max_health)
	
	if health <= 0:
		_on_player_death()
		
func eat_food(amount):
	hunger = min(hunger + amount, max_hunger)

func drink_water(amount):
	thirst = min(thirst + amount, max_thirst)
	
func healh(amount):
	health = min(health + amount, max_health)

func _on_player_death():
	print("Player has died")
	health = max_health
	hunger = max_hunger
	thirst = max_thirst
	global_position = spawn_point.global_position
