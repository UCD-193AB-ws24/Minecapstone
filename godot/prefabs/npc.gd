class_name NPC
extends Player

signal attack_completed

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var navigation_ready = false
var agent_manager
var just_jumped = false
var cached_npc_pos

signal target_reached

#for navigating to a moving target
var cur_target:Node = null
var can_attack = true

var target_entity: Player = null
var detected_entities: Array = []
var targeting : bool = false
@onready var detection_area: Area3D = $DetectionSphere

@export var detection_range: float = 100.0
@export var attack_range: float = 2.0
@export var attack_damage: float = 25.0 # current 4 shots player
@export var attack_cooldown: float = 2.0 
@export var chase_speed: float = 2.0

func _ready():
	actor_setup.call_deferred()
	ai_controller.ai_control_enabled = true
	inventory_manager.AddItem(itemdict_instance.Get("Grass"), 64)
	agent_manager = $"../AgentManager"
	cached_npc_pos = self.global_position
	var collision_shape = detection_area.get_node("CollisionShape3D")
	collision_shape.shape.radius = detection_range
		
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true
	#set_movement_target(Vector3(-10,0,-10))


func set_movement_target(movement_target: Vector3):
	# TODO: replace this with a query to the closest point on the navmesh
	if movement_target.y == 0:
		# Sample the navigation map to find the closest point to the target
		var nav_map_rid = navigation_agent.get_navigation_map()
		var from = Vector3(movement_target.x, 1000, movement_target.y)  # Start high above target position
		var to = Vector3(movement_target.x, -1000, movement_target.y)    # End deep below target position
		movement_target = NavigationServer3D.map_get_closest_point_to_segment(nav_map_rid, from, to)
	
	navigation_agent.set_target_position(movement_target)

func set_moving_target(moving_target: Node):
	navigation_agent.target_desired_distance = 5.0
	cur_target = moving_target #set moving target to follow
	# print("setting cur_target to ", cur_target.name)
	

func _moving_target_process():
	var target_pos = cur_target.global_position
	if navigation_agent.target_position.distance_to(target_pos) > 1:
		# print("updating cur_target position")
		set_movement_target(target_pos)
		set_look_target(target_pos)
	if navigation_agent.is_target_reached():
		# print("target reached")
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
	# print(round(agent_ref.global_position.y - self.global_position.y))

func _physics_process(delta):
	if cur_target != null:
		_moving_target_process()
		_handle_movement(delta, 3)
	else:
		# specifically for agents, we need to constantly update the target position (using _set_chase_target_position) and then check if were within attack range
		if targeting:
			_set_chase_target_position()
			
		if target_entity and position.distance_to(target_entity.position) <= attack_range:
				targeting = false

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
	var height_diff = current_pos.y - next_path_position.y
	
	if height_diff > 0 and height_diff <= 3.0:
		move_to(path_direction_2d, false, _speed, delta)
	elif velocity.length() < 0.1 and is_on_floor() and next_path_position.y > current_pos.y + 0.5:
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


func _rotate_toward(movement_target: Vector3):
	var direction = (movement_target - global_position).normalized()
	rotation.y = atan2(direction.x, direction.z) + PI

func _handle_attacking(c : int = 1):
	navigation_agent.target_position = target_entity.global_position
	for i in range(0, c):
		if can_attack:
			_attack_entity()
			can_attack = false
			await get_tree().create_timer(attack_cooldown).timeout
			can_attack = true
	
	print("finished attack")
	attack_completed.emit()

func _attack_entity():
	print("attempting to attack 1")
	if target_entity and global_position.distance_to(target_entity.global_position) <= attack_range:
		print("attempting to attack 2")
		if raycast.is_colliding() and raycast.get_collider() == target_entity:
			print("targeting: " + raycast.get_collider().name)
			target_entity.damage(attack_damage)
			_apply_knockback(target_entity)

func _on_body_entered(body: Node):
	if body is Player or  body is NPC_Zombie: 
		# Since all current entities extend from Player, will detect all types of mobs
		detected_entities.push_back(body)
		
func _on_body_exited(body: Node):
	if body in detected_entities:
		detected_entities.erase(body)

func _select_nearest_target(target:String = "npc"):
	if detected_entities.is_empty():
		target_entity = null
		return
		
	var target_string = "NPC"
	if target != "npc":
		target_string += target

	var nearest_entity: Player = detected_entities[0]
	var nearest_distance: float = global_position.distance_to(detected_entities[0].global_position)
	
	for entity in detected_entities:
		print("checking entity: " + entity.name)
		var distance = global_position.distance_to(entity.global_position)
		if distance < nearest_distance and entity.name == target_string:
			nearest_distance = distance
			nearest_entity = entity
	
	target_entity = nearest_entity
	print("New target: ", target_entity.name, " at distance: ", nearest_distance)

func _set_chase_target_position():
	navigation_agent.target_position = target_entity.global_position
	_speed = chase_speed

func _on_player_death():
	# Want to despawn instead of respawning at spawn point
	# Drop loot
	inventory_manager.DropAllItems()
	# Don't actually queue free here anymore since want to let LLM agents respawn
	# queue_free()
