class_name NPC
extends Player


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var navigation_ready = false
var agent_manager
var just_jumped = false
var cached_npc_pos

signal target_reached

#for navigating to a moving target
var cur_target:Node = null


func _ready():
	actor_setup.call_deferred()
	ai_controller.ai_control_enabled = true
	inventory_manager.AddItem(itemdict_instance.Get("Grass"), 64)
	agent_manager = $"../AgentManager"
	cached_npc_pos = self.global_position

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true


func set_movement_target(movement_target: Vector3):
	# TODO: replace this with a query to the closest point on the navmesh
	if movement_target.y == 0: movement_target.y = global_position.y
	navigation_agent.set_target_position(movement_target)

func set_moving_target(moving_target: Node):
	navigation_agent.target_desired_distance = 5.0
	cur_target = moving_target #set moving target to follow
	print("setting cur_target to ", cur_target.name)
	

func _moving_target_process():
	var target_pos = cur_target.global_position
	if navigation_agent.target_position.distance_to(target_pos) > 1:
		print("updating cur_target position")
		set_movement_target(target_pos)
		set_look_target(target_pos)
	if navigation_agent.is_target_reached():
		print("target reached")
		cur_target = null # stop following target
		navigation_agent.target_desired_distance = 1.0
		target_reached.emit()

func set_look_target(look_target: Vector3):
	#head.look_at(look_target, Vector3(0,1,0))
	var new_dir:Vector3 = head.global_position - look_target
	new_dir = new_dir.normalized()
	head.look_at(look_target)

func discard_item(item_name: String, amount: int):
	head.rotate_x(deg_to_rad(30)) #angles head to throw items away from body
	inventory_manager.DropItem(item_name, amount)
	head.rotate_x(deg_to_rad(-30)) #angles head back to original position

func give_to(agent_name: String, item_name:String, amount:int):
	var agent_ref = agent_manager.get_agent(agent_name)
	set_moving_target(agent_ref)
	await target_reached
	 # standard head angle for dropping item towards receiving agent who is [-1, 1] block level
	var look_pos = Vector3(agent_ref.global_position.x, agent_ref.global_position.y + 2, agent_ref.global_position.z)
	if (round(agent_ref.global_position.y - self.global_position.y)) >= 2:
		# receiving agent is above this agent by 2+ blocks
		look_pos.y += 1
	elif (round(agent_ref.global_position.y - self.global_position.y)) <= -2:
		# receiving agent is above this agent by 2- blocks
		look_pos.y += 1
	set_look_target(look_pos)
	inventory_manager.DropItem(item_name, amount)
	print(round(agent_ref.global_position.y - self.global_position.y))

func _physics_process(delta):
	if cur_target != null:
		_moving_target_process()
		_handle_movement(delta, 3)
	else:
		_handle_movement(delta)
	super(delta)



func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	#You can delete the commented out code below
	# if _event is InputEventKey and _event.pressed and _event.keycode == KEY_Z:
	# 	set_look_target(Vector3(-10,99,-20))
	# if _event is InputEventKey and _event.pressed and _event.keycode == KEY_X:
	# 	set_look_target(Vector3(26, 24, 0))
	if _event is InputEventKey and _event.pressed and _event.keycode == KEY_C:		
		give_to("Player", "Grass", 1)
	return


func _handle_movement(delta, desired_dist:float = 1):
	if not navigation_ready:
		return
	if navigation_agent.is_target_reached():
		move_to(Vector2(0,0), false,_speed, delta)
		return
	navigation_agent.path_desired_distance = desired_dist
	navigation_agent.target_desired_distance = desired_dist
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
