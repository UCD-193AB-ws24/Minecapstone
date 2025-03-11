class_name NPC
extends Player


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var navigation_ready = false
var just_jumped = false


func _ready():
	actor_setup.call_deferred()
	ai_controller.ai_control_enabled = true


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true


func set_movement_target(movement_target: Vector3):
	# TODO: replace this with a query to the closest point on the navmesh
	if movement_target.y == 0:
		# Sample the navigation map to find the closest point to the target
		var nav_map_rid = navigation_agent.get_navigation_map()
		var from = Vector3(movement_target.x, 1000, movement_target.y)  # Start high above target position
		var to = Vector3(movement_target.x, -1000, movement_target.y)    # End deep below target position
		movement_target = NavigationServer3D.map_get_closest_point_to_segment(nav_map_rid, from, to)
	
	navigation_agent.set_target_position(movement_target)


func _physics_process(delta):
	_handle_movement(delta)
	super(delta)


func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	return


func _handle_movement(delta):
	if not navigation_ready:
		return

	var current_pos = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var path_direction = current_pos.direction_to(next_path_position)
	var path_direction_2d = Vector2(path_direction.x, path_direction.z) * _speed
	# var height_diff = current_pos.y - next_path_position.y

	if velocity.length() < 0.4:
		if not just_jumped:
			move_to(path_direction_2d, true, _speed, delta)
			just_jumped = true
			navigation_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
			navigation_agent.path_desired_distance = randf_range(0.5, 3)
			navigation_agent.target_desired_distance = randf_range(0.5, 3)
			await get_tree().create_timer(randf_range(0.25, 2)).timeout
			navigation_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
			navigation_agent.path_desired_distance = 1
			navigation_agent.target_desired_distance = 1
			just_jumped = false
		else:
			move_to(path_direction_2d, false, _speed, delta)
	else:
		move_to(path_direction_2d, false, _speed, delta)

	# if height_diff > 0 and height_diff <= 3.0:
	# 	move_to(path_direction_2d, false, _speed, delta)
	# elif velocity.length() < 0.1 and is_on_floor(): # and next_path_position.y > current_pos.y + 0.5:
	# 	if not just_jumped:
	# 		move_to(path_direction_2d, true, _speed, delta)
	# 		just_jumped = true
	# 		var postprocessing_options = [
	# 			NavigationPathQueryParameters3D.PATH_POSTPROCESSING_NONE,
	# 			NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	# 		]
	# 		navigation_agent.path_postprocessing = postprocessing_options[randi() % postprocessing_options.size()]
	# 		navigation_agent.path_desired_distance = randf_range(1.3, 5)
	# 		await get_tree().create_timer(randf_range(1, 2)).timeout
	# 		navigation_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
	# 		navigation_agent.path_desired_distance = 1
	# 		just_jumped = false
	# 	else:
	# 		move_to(path_direction_2d, false, _speed, delta)
	# else:
	# 	move_to(path_direction_2d, false, _speed, delta)
