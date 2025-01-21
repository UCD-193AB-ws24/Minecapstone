class_name NPC
extends Player

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var finished_setup = false

func _ready():
	navigation_agent.path_desired_distance = 2
	navigation_agent.target_desired_distance = 2
	_speed = 1.28
	actor_setup.call_deferred()

	ai_controller.ai_control_enabled = true
	# global_position = spawn_point.global_position

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	# finished_setup = true
	
	var player = get_node("/root/World/Player")
	set_movement_target(player.global_position)
	# Now that the navigation map is no longer empty, set the movement target.
	

func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
	

func _physics_process(delta):
	var player = get_node("/root/World/Player")

	# This makes the NPC movement not that smooth/efficient, which is actually good
	if get_tree().get_frame() % 60 == 0:
		set_movement_target(player.global_position)
	
	

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	var movement = current_agent_position.direction_to(next_path_position).normalized()

	if velocity.length() < 0.5:
		_move_player(Vector2(movement.x, movement.z), true, _speed, delta)
	else:
		_move_player(Vector2(movement.x, movement.z), false, _speed, delta)

	# if movement.length() > 0.1:
	# 	head.look_at(global_position + movement, Vector3.UP)

	raycast.target_position = Vector3(movement.x, movement.y, movement.z).normalized() * 2

	move_and_slide()
	super(delta)


# func _physics_process(delta: float):
# 	if finished_setup: 
# 		var player = get_node("/root/World/Player")
# 		navigation_agent.set_target_position(player.global_position)

# 		var current_agent_position: Vector3 = global_position
# 		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
# 		var movement = current_agent_position.direction_to(next_path_position).normalized()

		# velocity = Vector3(movement.x, velocity.y, movement.z)
		# raycast.target_position = Vector3(movement.x, 0, movement.z) * 10

	# super(delta)

func _process(_delta):
	move_and_slide()

# func _physics_process(delta: float):
# 	var player = get_node("/root/World/Player")
# 	if player:
# 		go_to(player.global_position)
		
# 		if navigation_agent.is_navigation_finished():
# 			return
		
# 		var current_agent_position: Vector3 = global_position
# 		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
# 		var movement = current_agent_position.direction_to(next_path_position)
# 		movement = Vector2(movement.x, movement.y)

# 		print(movement, " ", next_path_position)

# 		_move_player(movement, false, _speed, delta)

# 	move_and_slide()
	
# 	super(delta)

func _input(_event):
	return
