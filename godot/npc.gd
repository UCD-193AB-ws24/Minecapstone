class_name NPC
extends Player


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D


func _ready():
	actor_setup.call_deferred()
	_speed = 2.318
	ai_controller.ai_control_enabled = true
	# global_position = spawn_point.global_position


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

	var player = $"../Player"
	set_movement_target(player.global_position)


func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)


var is_queued_for_jump = false
func _physics_process(delta):
	var player = $"../Player"
	set_movement_target(player.global_position)
	_speed = 2


	var current_agent_position: Vector3 = self.global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var path_direction = current_agent_position.direction_to(next_path_position)
	# var path_direction_flat = Vector3(path_direction.x, 0, path_direction.z)
	var path_direction_2d = Vector2(path_direction.x, path_direction.z) * _speed
	velocity = path_direction

	# print(path_direction_2d.length())
	# if velocity.length() < 0.2:
	# 	if not is_queued_for_jump:
	# 		is_queued_for_jump = true
	# 		move_player(path_direction_2d, true, _speed, delta)
	# 		# await get_tree().create_timer(1.0).timeout
	# 		is_queued_for_jump = false
	# else:
	# 	move_player(path_direction_2d, false, _speed, delta)

	# # var angle = acos(path_direction.dot(path_direction_flat) / path_direction.length() * path_direction_flat.length())
	# var dir = current_agent_position - next_path_position
	# var angle = dir.angle_to(Vector3(dir.x, 0, dir.z))
	# angle = rad_to_deg(angle)
	# print(angle)

	# var angle = acos(next_path_position.dot(next_path_position_flat.normalized())/next_path_position.length()*next_path_position_flat.length())
	# angle = rad_to_deg(angle)

	# var temp = current_agent_position - next_path_position
	# var angle2 = acos(temp.dot(Vector3(temp.x, 0, temp.z).normalized()) / temp.length() * Vector3(temp.x, 0, temp.z).length())
	# angle2 = rad_to_deg(angle2)
	# if get_tree().get_frame() % 15 == 0:
	# 	print(angle, " ", angle2)

	# Reduces the frequency of pathfinding updates
	# var player_position = player.global_position
	# if navigation_agent.target_position.distance_to(player_position) > 0.01:
	# 	var update_frequency = randi_range(30, 60)
	# 	if get_tree().get_frame() % update_frequency == 0:


	super(delta)


func _process(_delta):
	move_and_slide()


func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	return
