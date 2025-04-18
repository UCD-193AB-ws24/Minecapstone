class_name NPC
extends Player


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var navigation_ready = false
@onready var detection_area: Area3D = $DetectionSphere
var just_jumped = false
var current_target: Node = null
var detected_entities: Array = []
@export var detection_range: float = 10.0 # detecttion radius for the DetectionSphere area3d
@export var attack_damage: float = 25.0 # current 4 shots player
@export var attack_cooldown: float = 2.0
@export var chase_speed: float = 2.0


func _ready():
	actor_setup.call_deferred()
	ai_control_enabled = true
	inventory_manager.AddItem(ItemDictionary.Get("Grass"), 64)
	var collision_shape = detection_area.get_node("CollisionShape3D")
	collision_shape.shape.radius = detection_range

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true


func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	return


#NOTE: If you pass position of an entity, the look_pos will be at the feet. Use look_at_target instead
# TODO: in this case, can't you just use this look at the position of the head?
func set_look_position(look_pos: Vector3):
	#head.look_at(look_target, Vector3(0,1,0))
	var new_dir:Vector3 = head.global_position - look_pos
	new_dir = new_dir.normalized()
	head.look_at(look_pos)


func look_at_current_target():
	look_at_target(current_target)


# rotate body and head to look at look_target
func look_at_target(look_target:Node3D):
	#var new_dir:Vector3 = head.global_position - look_target.global_position
	if look_target == null:
		return 
	var direction = (look_target.global_position - global_position).normalized()
	
	# # for calculatinig the head rotation
	# var abs_z = abs(direction.z)
	# var hypotenuse = sqrt((direction.y ** 2) + (direction.z ** 2))
	# var y_normal = direction.y / hypotenuse
	# var z_normal = abs_z / hypotenuse
	# var hypo_normal = sqrt((y_normal ** 2) + (z_normal ** 2)) # equals 1

	# print("hypotenuse: ", hypo_normal)
	rotation.y = atan2(direction.x, direction.z) + PI
	# var head_rad = asin(y_normal / hypo_normal)

	# head.rotation.x = clamp(head_rad, -89.5 * (PI/180), 89.5 * (PI/180))
	var point_array = get_closest_point_target(look_target)
	
	if !point_array[0]:
		print("Can't get closest point of look_target")
		return
	var point:Vector3 = point_array[1]
	print("cur target position is", look_target.global_position)
	print("looking at ", point)
	head.look_at(point)

#gets the closest point of look_target's hurtbox. Target MUST have a BoxShape3D for their CollisionShape3D
#https://stackoverflow.com/questions/44824512/how-to-find-the-closest-point-on-a-right-rectangular-prism-3d-rectangle
#https://forum.godotengine.org/t/find-the-closest-point-inside-a-rotated-boxshape-towards-another-point-outside/3306/2
#includes logic to account for elevation differences
#TODO: get_closest_point_target crashes the game if it is called every physics frame (probably get_node is the root of the cause). 
#Figure out how to make function more efficient 
func get_closest_point_target(look_target:Node3D) -> Array:
	if look_target == null:
		return [false, Vector3.ZERO]
	var node = look_target.get_node("CollisionShape3D") # assumes the CollisionShape3D is a direct child of the current_target in the tree hierarchy
	if node.get_class() != "CollisionShape3D":
		print("node is not a CollisionShape3D. Returning")
		return [false, Vector3.ZERO] #No closest point due to no CollisionShape3D
	#print("node is ColiisonShape3D")
	var hurt_box:CollisionShape3D = node
	var hurt_box_shape:BoxShape3D = hurt_box.shape #assumes the shape is BoxShape3D
	# origin should be the bottom left corner of the target's hurtbox (the corner which is in the negative of all 3 axis)
	var origin:Vector3 = hurt_box.global_transform * Vector3(-hurt_box_shape.size.x/2, -hurt_box_shape.size.y/2, -hurt_box_shape.size.z/2)
	var px:Vector3 = hurt_box.global_transform * Vector3(hurt_box_shape.size.x/2, -hurt_box_shape.size.y/2, -hurt_box_shape.size.z/2) # x-positive corner of the box
	var py:Vector3 = hurt_box.global_transform * Vector3(-hurt_box_shape.size.x/2, hurt_box_shape.size.y/2, -hurt_box_shape.size.z/2)	# y-positive corner of the box
	var pz:Vector3 = hurt_box.global_transform * Vector3(-hurt_box_shape.size.x/2, -hurt_box_shape.size.y/2, hurt_box_shape.size.z/2)	# z_positive corner of the box
	var vx:Vector3 = (px - origin) # vector from origin to px
	var vy:Vector3 = (py - origin) # vector from origin to py
	var vz:Vector3 = (pz - origin) # vector from origin to pz

	var tx = vx.dot(head.global_position - origin) / vx.length_squared() # how far along the x axis the center point of agent's head lies
	var ty = vy.dot(head.global_position - origin) / vy.length_squared() # how far along the y axis the center point of agent's head lies
	var tz = vz.dot(head.global_position - origin) / vz.length_squared() # how far along the z axis the center point of agent's head lies

	#constrain tx ty and tz to [0, 1]
	if tx < 0:
		tx = 0
	elif tx > 1:
		tx = 1
	
	if ty < 0:
		ty = 0
	elif ty > 1:
		ty = 1

	if tz < 0:
		tz = 0
	elif tz > 1:
		tz = 1	 
	
	# scale the vs' with their respective ts', sum them up, and add the origin point to get the closest point on the box to the agent's head 
	var result_point:Vector3 = tx * vx + ty * vy + tz * vz + origin
	#account for elevation in point
	var elevation_diff:float = look_target.global_position.y - global_position.y
	var y_mod:float = 0 # modifier that will raise or lower the head to aim the raycast directly at look_target
	#1/4 is 1/4 of a block
	if elevation_diff > 0.01: # look_target is at a higher elevation
		y_mod = 0.25 * (elevation_diff / 2) ** 2 # (elevation_diff / 2) increases y_mod based on how big the difference in elevation is
	elif elevation_diff < 0.01: # look_target is at a lower elevation
		y_mod = 0.25 * (-elevation_diff / 2) ** 2
	result_point.y += y_mod

	return [true, result_point]


func discard_item(item_name: String, amount: int):
	head.rotate_x(deg_to_rad(30)) #angles head to throw items away from body
	inventory_manager.DropItem(item_name, amount)
	head.rotate_x(deg_to_rad(-30)) #angles head back to original position


func give_to(agent_name: String, item_name:String, amount:int):
	var agent_ref = AgentManager.get_agent(agent_name)
	# set_moving_target(agent_ref)
	# await target_reached
	
	# Standard head angle for dropping item towards receiving agent who is [-1, 1] block level
	var look_pos = Vector3(agent_ref.global_position.x, agent_ref.global_position.y + 2, agent_ref.global_position.z)
	if (round(agent_ref.global_position.y - self.global_position.y)) >= 2:
		# Receiving agent is above this agent by 2+ blocks
		look_pos.y += 1
	elif (round(agent_ref.global_position.y - self.global_position.y)) <= -2:
		# Receiving agent is above this agent by 2- blocks
		look_pos.y += 1
	set_look_position(look_pos)
	inventory_manager.DropItem(item_name, amount)
	# print(round(agent_ref.global_position.y - self.global_position.y))


func set_target_position(movement_target: Vector3, distance_away:float = 1.0):
	navigation_agent.target_desired_distance = distance_away
	 # standard head angle for dropping item towards receiving agent who is [-1, 1] block level

	# Query to the closest point on the navmesh if 1000 given
	if movement_target.y == 1000:
		# Sample the navigation map to find the closest point to the target
		var nav_map_rid = navigation_agent.get_navigation_map()
		movement_target = NavigationServer3D.map_get_closest_point(nav_map_rid, movement_target)
	navigation_agent.set_target_position(movement_target)


func move_to_position(x: float, y: float, distance_away:float=1.0):
	set_target_position(Vector3(x,1000,y), distance_away)

	# TODO: replace with a loop that checks if the agent has reached the target, instead of waiting for a signal
	# Waiting for signal blocks the agent from doing anything else?... i had a better reason... it's 12 am..
	await navigation_agent.target_reached
	# return true


func move_to_current_target(distance_away:float=1.0):
	if current_target:
		var target_pos = current_target.global_position
		await move_to_position(target_pos.x, target_pos.z, distance_away)


func _moving_target_process():
	var target_pos = current_target.global_position
	if !navigation_agent.is_target_reached():
		#print("updating cur_target position")
		set_target_position(target_pos, navigation_agent.target_desired_distance)
		set_look_position(target_pos)
		#look_at_current_target()


func _physics_process(delta):
	if current_target != null and !navigation_agent.get_current_navigation_path().is_empty():
		_moving_target_process() # sets destination
	_handle_movement(delta) # actual moving
	super(delta)


func _handle_movement(delta):
	if not navigation_ready:
		return
	if navigation_agent.is_target_reached():
		move_to(Vector2(0,0), false,_speed, delta) #for early stopping
		return
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


func _attack_current_target(num_attacks : int = 1):
	if current_target == null: return

	var successful_attacks = 0
	while successful_attacks < num_attacks:
		await move_to_current_target()
		await look_at_current_target()
		var hit = await _attack()
		if hit: successful_attacks += 1
		
		# Wait for the cooldown before the next attack
		await get_tree().create_timer(attack_cooldown).timeout

	current_target = null


# Attacks specificaly the current target
func _attack():
	var hit = raycast.is_colliding() and raycast.get_collider() == current_target

	if hit:
		current_target.damage(attack_damage)
		_apply_knockback(current_target)
		
	return hit


func _on_body_entered(body: Node):
	if is_instance_of(body, Player):
		# Since all current entities extend from Player, will detect all types of mobs
		detected_entities.push_back(body)
		print("added entity: ", body.name)


func _on_body_exited(body: Node):
	if body in detected_entities:
		detected_entities.erase(body)
		print("removed entity: ", body.name)


# Sets target_entity to the nearest entity with the name that matches target_string
# RETURNs True if there is a valid target. False if no target
func select_nearest_target(target_name:String) -> bool:
	if detected_entities.is_empty():
		current_target = null
		return false

	# Find the nearest entity that matches the target name
	var nearest_entity: Player = null
	var nearest_distance: float = INF
	for entity in detected_entities:
		if entity != self and (target_name in entity.name or target_name == ""):
			var distance = global_position.distance_to(entity.global_position)
			if nearest_entity == null or distance < nearest_distance:
				nearest_distance = distance
				nearest_entity = entity

	current_target = nearest_entity
	print("current target: ", current_target)
	if current_target != null:
		return true
	else:
		return false


func _set_chase_target_position():
	navigation_agent.target_position = current_target.global_position
	_speed = chase_speed


func _on_player_death():
	# Want to despawn instead of respawning at spawn point
	# Drop loot
	inventory_manager.DropAllItems()
	# Don't actually queue free here anymore since want to let LLM agents respawn
	# queue_free()
