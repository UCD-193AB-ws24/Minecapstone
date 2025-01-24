class_name NPC
extends Player


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var finished_setup = false

func _ready():
	actor_setup.call_deferred()
	_speed = 2.318
	ai_controller.ai_control_enabled = true
	# global_position = spawn_point.global_position


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	# finished_setup = true
	
	var player = get_node("/root/World/Player")
	set_movement_target(player.global_position)


func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)


func _physics_process(delta):
	var player = get_node("/root/World/Player")

	# Reduces the frequency of pathfinding updates
	var update_frequency = randi_range(60, 120)
	if get_tree().get_frame() % update_frequency == 0:
		set_movement_target(player.global_position)

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()

	# # Debug
	if not next_path_position.is_zero_approx():
		$Path3D.curve.clear_points()
		$Path3D.curve.add_point(Vector3(0.1,0.1,0.1))
		$Path3D.curve.add_point(next_path_position - global_position)

	var target_3d:Vector3 = current_agent_position.direction_to(next_path_position)
	var target_2d: Vector2 = Vector2(target_3d.x, target_3d.z).normalized() * target_3d.length()

	var player_position_2d: Vector2 = Vector2(player.global_position.x, player.global_position.z)
	var current_position_2d: Vector2 = Vector2(global_position.x, global_position.z)
	var emergency_direction_2d: Vector2 = current_position_2d.direction_to(player_position_2d)
	
	# Make a beeline for the player if the target is unreachable
	var target_reachable = navigation_agent.is_target_reachable()
	if target_reachable:
		# Determine angle of target position relative to NPC off the horizontal plane
		var target_flat:Vector3 = Vector3(target_3d.x, 0, target_3d.z)
		var angle:float = rad_to_deg(acos(target.dot(target_flat) / (target.length() * target_flat.length())))

		# print(angle)
		if (angle > 30 and target.y > 0) or velocity.length() < 0.1:
			# Jump if the target position is above the NPC
			move_player(target_2d, true, _speed, delta)
		else:
			move_player(target_2d, false, _speed, delta)
	else:
		move_player(emergency_direction_2d, true, _speed, delta)

	# Flatten the target_3d vector to a 2D vector
	raycast.target_position = Vector3(target_3d.x, target_3d.y, target_3d.z).normalized() * 2

	super(delta)


func _process(_delta):
	move_and_slide()


func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	return
