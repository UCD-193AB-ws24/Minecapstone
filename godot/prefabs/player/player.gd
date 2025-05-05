class_name Player
extends CharacterBody3D


@export var ai_control_enabled = false
""" ================================================ MOVEMENT ====================================================== """
@export var _speed = 4.317
var _sprint_speed = _speed * 1.3
@export var _jump_velocity = 10.0
@export var _acceleration = 0.15
var current_acceleration = 0.15
""" =========================================== FOV AND SPRINTING ================================================== """
@export var normal_fov = 70.0
@export var fov_transition_speed = 7.5
@export var double_tap_time = 0.3 # Time in between "W" presses
var sprint_fov = normal_fov + 20
var _is_sprinting = false
var last_forward_press = 0.0 # Make note and update the time for last "W" press
""" =========================================== ALTERNATVE VIEWS =================================================== """
enum ViewMode {THIRDPERSON, SPECTATOR, NORMAL}
@onready var view: ViewMode = ViewMode.NORMAL
""" ============================================ BLOCK BREAKING ==================================================== """
var _is_breaking: bool = false
var _break_timer: Timer
var _block_breaking # position of the block attempting to break or null (not attempted block)
var _released: bool = true
var _tool_breaking: Resource
@onready var block_progress: Label = $"../UI/Control/BlockProgress"
""" ================================================ NEEDS ========================================================= """
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
""" ============================================ BODY RELATED ====================================================== """
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var spawn_point: Marker3D = $"../SpawnPoint" # TODO: replace with a proper spawn system
@export var _mouse_sensitivity = 0.1
""" ============================================== INVENTORY ======================================================= """
@onready var inventory_manager: Node = $InventoryManager
@onready var block_highlight: CSGBox3D = $BlockHighlight
@onready var block_manager: Node = $"../NavigationMesher".find_child("BlockManager")
@onready var chunk_manager: Node = $"../NavigationMesher".find_child("ChunkManager")

""" =========================================== GODOT FUNCTIONS ==================================================== """
# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	global_position = spawn_point.global_position
	inventory_manager.AddItem(ItemDictionary.Get("Stone"), 64)
	inventory_manager.AddItem(ItemDictionary.Get("Wood Pickaxe"), 1)
	inventory_manager.AddItem(ItemDictionary.Get("Dirt"), 64)


# Called on input event
func _input(event):
	""" Handles the keyboard input of the player.
		Does nothing if the player is an AI.
	"""
	if ai_control_enabled:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_E: _throw_pearl()
			KEY_F5:
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
			KEY_ESCAPE:
				if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
					Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				else:
					Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var deltaX = - event.relative.y * _mouse_sensitivity
		var deltaY = - event.relative.x * _mouse_sensitivity
		if view == ViewMode.SPECTATOR:
			camera.global_rotation_degrees.x = clamp(camera.global_rotation_degrees.x + deltaX, -89.5, 89.5)
			camera.global_rotation_degrees.y += deltaY
			camera.global_rotation_degrees.z = 0
		else:
			rotate_y(deg_to_rad(deltaY))
			head.rotate_x(deg_to_rad(deltaX))
			head.rotation_degrees.x = clamp(head.rotation_degrees.x, -89.9, 89.9)

	if Input.is_action_just_released("inventory_up"):
		inventory_manager.CycleUp()
	if Input.is_action_just_released("inventory_down"):
		inventory_manager.CycleDown()
	if Input.is_action_just_pressed("drop_item"):
		inventory_manager.DropSelectedItem()


func _process(_delta):
	""" Called every frame. 'delta' is the elapsed time since the previous frame.
	"""
	# Moves the player and child nodes
	# Called here instead to ensure smooth camera movement
	move_and_slide()

	if not ai_control_enabled:
		if view == ViewMode.SPECTATOR: _spectator_movement(_delta);

		# Highlight block player is looking at, and place or remove blocks
		_handle_block_interaction()
		_handle_attacking()
		
	if _is_breaking:
		_break_block()


func _physics_process(_delta):
	""" Called every physics frame. 'delta' is the elapsed time since the previous frame.
	"""
	if not ai_control_enabled:
		_handle_player_input(_delta)

	_apply_gravity(_delta)
	_update_fov(_delta)
	_update_health_hunger_thirst(_delta)

	if global_position.y < 0:
		_on_out_of_bounds()


""" ============================================ MOVEMENT ========================================================== """


func _apply_gravity(delta):
	""" Applies gravity to the body every physics frame """

	if not is_on_floor():
		velocity.y -= 35 * delta
		current_acceleration = _acceleration * 0.25
	else:
		current_acceleration = _acceleration


func move_to(direction: Vector2, jump: bool, speed: float, _delta):
	""" Moves the player in the direction of the input vector
		- direction: Vector2 - The direction to move in
		- jump: bool - Whether or not to jump
		- speed: float - The speed to move at
	"""

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
	if is_on_floor() and jump and view != ViewMode.SPECTATOR:
		velocity.y = _jump_velocity

		# Apply horizontal impulse if jumping while sprinting
		if _is_sprinting:
			var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
			var impulse = horizontal_velocity.normalized() * 0 * horizontal_velocity.length()
			velocity += impulse

""" ==================================== BLOCK BREAKING ======================================== """


func _handle_block_interaction():
	""" Handles block breaking and placing
	"""
	# Allows for multiple blocks to be broken while mouse1 is held down
	if not Input.is_action_pressed("mouse1"): _released = true
	if Input.is_action_just_pressed("mouse1"): _released = false

	# Lock the block highlight rotation to prevent it from rotating with the player
	block_highlight.global_rotation = Vector3.ZERO
	
	# if raycast.is_colliding() and raycast.get_collider().has_meta("is_chunk"):
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if raycast.is_colliding() and collider and collider.has_meta("is_chunk"):
			var chunk = raycast.get_collider()

			var block_position = raycast.get_collision_point() - 0.5 * raycast.get_collision_normal()
			var int_block_position = Vector3(floor(block_position.x), floor(block_position.y), floor(block_position.z))
			
			block_highlight.visible = true
			block_highlight.global_position = int_block_position + Vector3(0.5, 0.5, 0.5)

			# Handles the mouse1 event for breaking blocks
			_handle_block_breaking(block_position, chunk.global_position)
			
			if Input.is_action_just_pressed("mouse2"):
				var new_block_position: Vector3 = int_block_position + raycast.get_collision_normal()
				
				# Prevent player from placing blocks if the block will intersect the player
				if not _block_position_intersect_player(new_block_position):
					#replace block_manager.ItemDict.Get with selected block to place from inventory
					if inventory_manager.GetSelectedItem() != null and inventory_manager.GetSelectedItem().has_meta("is_block"):
						chunk_manager.SetBlock(new_block_position, inventory_manager.GetSelectedItem())
						inventory_manager.ConsumeSelectedItem()
						_update_navmesh()
	else:
		block_highlight.visible = false


func _block_position_intersect_player(new_block_position: Vector3) -> bool:
	""" Checks if the new block position intersects with the player
		- new_block_position: Vector3 - The position of the new block
	"""
	# Creates a collision box in the location of the new block
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


func _handle_block_breaking(block_position: Vector3, chunk_offset: Vector3):
	""" Checks if the player toggled breaking
	"""
	if not Input.is_action_pressed("mouse1"): _released = true

	# if pressed left mouse prepare for block breaking
	if Input.is_action_just_pressed("mouse1") and not _is_breaking:
		_begin_block_break((Vector3i)(block_position - chunk_offset))
	# if holding down left mouse prepare for breaking
	if not _released and not _is_breaking:
		_begin_block_break((Vector3i)(block_position - chunk_offset))


func _begin_block_break(pos: Vector3i):
	""" Begins the target block breaking process,
		Prepares a timer for block breaking
	"""
	_is_breaking = true
	_block_breaking = pos
	# get block data, time to break
	var chunk = raycast.get_collider()
	var block = chunk.GetBlock(_block_breaking)
	var time = block_manager.GetTime(block)

	_tool_breaking = inventory_manager.GetSelectedItem()
	
	if _tool_breaking != null and _tool_breaking.has_meta("is_tool") and _tool_breaking.GetProficency() == block.GetProficency():
		time = time / float(_tool_breaking.GetHarvestLevel() + 1)

	# setup timer to calculate block breaking
	_break_timer = Timer.new()
	_break_timer.one_shot = true
	add_child(_break_timer)
	_break_timer.start(time)

	# setup progress label for block breaking
	block_progress.text = "0%"
	block_progress.visible = true


func _break_block():
	""" Determines if the player is looking at the right block and breaks it after timeout
	"""

	# Get initial raycast data from player
	var chunk = raycast.get_collider()
	var block_position = raycast.get_collision_point() - 0.5 * raycast.get_collision_normal()
	var int_block_position = Vector3(floor(block_position.x), floor(block_position.y), floor(block_position.z))

	# if player isn't looking at a block, cancel the block breaking
	if not raycast.is_colliding() or not chunk.has_meta("is_chunk") or _tool_breaking != inventory_manager.GetSelectedItem():
		_block_breaking = null
		_is_breaking = false
		block_progress.visible = false
		return
	
	# get block time and update progress label
	var block = chunk.GetBlock(_block_breaking)
	
	var time = block_manager.GetTime(block)
	var percentage: float = (time - _break_timer.time_left) / time * 100
	var percent_string: String = str(round(percentage * 10) / 10, "%")
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
		chunk.SetBlock(_block_breaking, ItemDictionary.Get("Air"))
		
		# TODO: Fix this
		if (_tool_breaking != null and _tool_breaking.has_meta("is_tool") and _tool_breaking.GetHarvestLevel() >= block.GetHarvestLevel() and _tool_breaking.GetProficency() == block.GetProficency()) or block.GetHarvestLevel() == 0:
			var drop_pos: Vector3 = chunk.global_position + Vector3(_block_breaking.x, _block_breaking.y, _block_breaking.z)
			var block_node = block.GenerateItem()
			get_parent().add_child(block_node)
			block_node.global_position = drop_pos + Vector3(0.5, 0.5, 0.5)
		
		_block_breaking = null
		_is_breaking = false
		_break_timer.queue_free()
		_update_navmesh()


func _handle_attacking():
	if raycast.is_colliding() and raycast.get_collider() is Player:
		var target = raycast.get_collider()
		if Input.is_action_just_pressed("mouse1"):
			target.damage(10)
			print("Entity has been attacked -- health is now: ", target.health)
			_apply_knockback(target)


func _apply_knockback(target):
	var knockback_direction = (target.global_position - global_position).normalized()
	var knockback_strength = 10.0
	target.velocity += knockback_direction * knockback_strength
	target.velocity.y += 3.5


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

	move_to(relative_direction, Input.is_action_pressed("jump"), current_speed, _delta)


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


func _update_fov(_delta):
	# Update fov based on sprinting or not
	if _is_sprinting:
		camera.fov = lerp(camera.fov, sprint_fov, fov_transition_speed * _delta)
	else:
		camera.fov = lerp(camera.fov, normal_fov, fov_transition_speed * _delta)


func _on_out_of_bounds():
	global_position = spawn_point.global_position
	velocity = Vector3.ZERO


var pearl_scene = preload("res://prefabs/pearl.tscn")
func _throw_pearl():
	var pearl_instance = pearl_scene.instantiate()
	pearl_instance.global_transform = global_transform
	get_parent().add_child(pearl_instance)

	# Launch the pearl in the direction the camera is facing
	var facing_direction = - head.global_transform.basis.z
	var throw_direction = facing_direction + ((facing_direction + velocity) / 2) * 0.05
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

signal food_eaten(food_name: String, agent_hash_id: int)

func eat_food(food_name: String = "") -> bool:
	if food_name == "":
		hunger = min(hunger + 10, max_hunger)
		return true

	# Get inventory data as a string
	var inventory_data = inventory_manager.GetInventoryData()

	# Check if the food is in inventory
	if inventory_data.contains(food_name):
		# Find food item in dictionary to get satiety value
		var food_item = ItemDictionary.Get(food_name)
		if food_item and food_item.IsConsumable:
			var satiety = 10  # Default
			
			if food_item.has_method("get_satiety"):
				satiety = food_item.get_satiety()

			# Increase hunger
			hunger = min(hunger + satiety, max_hunger)

			# Remove one of the food items from inventory
			inventory_manager.DropItem(food_name, 1)
			print("Ate " + food_name)
			
			emit_signal("food_eaten", food_name, get_instance_id())
			return true

	return false


func drink_water(amount):
	thirst = min(thirst + amount, max_thirst)


func heal(amount):
	health = min(health + amount, max_health)


func damage(damage_amount: float):
	health = max(health - damage_amount, 0)
	if health <= 0:
		_on_player_death()


func _on_player_death():
	print(str(self) + " has died!")

	health = max_health
	hunger = max_hunger
	thirst = max_thirst
	global_position = spawn_point.global_position


func save():
	var save_dict = {
		"filename": get_scene_file_path(),
		"name": name,
		"parent": get_parent().get_path(),
		"pos_x": position.x,
		"pos_y": position.y,
		"pos_z": position.z,
		"ai_control_enabled": ai_control_enabled,
		"_speed": _speed,
		"_sprint_speed": _sprint_speed,
		"_jump_velocity": _jump_velocity,
		"_acceleration": _acceleration,
		"current_acceleration": current_acceleration,
		"normal_fov": normal_fov,
		"fov_transition_speed": fov_transition_speed,
		"double_tap_time": double_tap_time,
		"sprint_fov": sprint_fov,
		"_is_sprinting": false, # Reset sprint state
		"last_forward_press": 0.0, # Reset to prevent accidental sprint activation
		"view": ViewMode.NORMAL, # Reset to normal view
		"_is_breaking": false, # Not breaking blocks when loaded
		"_released": true, # Mouse button is released
		"health": health,
		"hunger": hunger,
		"thirst": thirst,
		"max_health": max_health,
		"max_hunger": max_hunger,
		"max_thirst": max_thirst,
		"hunger_decrease_rate": hunger_decrease_rate,
		"thirst_decrease_rate": thirst_decrease_rate,
		"sprint_hunger": sprint_hunger,
		"sprint_thirst": sprint_thirst,
		"health_decrease_rate": health_decrease_rate,
		"natural_healing_rate": natural_healing_rate,
		"hunger_timer": 0.0, # Reset timers
		"thirst_timer": 0.0, # Reset timers
		"_mouse_sensitivity": _mouse_sensitivity,
		"velocity": Vector3.ZERO, # Stop any movement
		"_block_breaking": null, # Not targeting any block
		"_tool_breaking": null, # Not using any tool
	}
	return save_dict
