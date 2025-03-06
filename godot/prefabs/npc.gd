class_name NPC
extends Player


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var navigation_ready = false
var just_jumped = false
var can_attack = true

var target_entity: Player = null
var detected_entities: Array = []
@onready var detection_area: Area3D = $DetectionSphere

@export var detection_range: float = 10.0
@export var attack_range: float = 2.0
@export var attack_damage: float = 25.0 # current 4 shots player
@export var attack_cooldown: float = 2.0 
@export var chase_speed: float = 2.0

func _ready():
	actor_setup.call_deferred()
	ai_controller.ai_control_enabled = true
	
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
	if movement_target.y == 0: movement_target.y = global_position.y
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
			navigation_agent.path_desired_distance = 1
			navigation_agent.target_desired_distance = 1
			just_jumped = false
		else:
			move_to(path_direction_2d, false, _speed, delta)
	else:
		move_to(path_direction_2d, false, _speed, delta)


func _rotate_toward(movement_target: Vector3):
	var direction = (movement_target - global_position).normalized()
	rotation.y = atan2(direction.x, direction.z) + PI

func _handle_attacking():
	navigation_agent.target_position = target_entity.global_position
	if can_attack:
		_attack_entity()
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func _attack_entity():
	if target_entity and global_position.distance_to(target_entity.global_position) <= attack_range:
		if raycast.is_colliding() and raycast.get_collider() == target_entity:
			target_entity.damage(attack_damage)
			_apply_knockback(target_entity)

func _on_body_entered(body: Node):
	if body is Player: 
		# Since all current entities extend from Player, will detect all types of mobs
		detected_entities.push_back(body)
		
func _on_body_exited(body: Node):
	if body in detected_entities:
		detected_entities.erase(body)

func _target_nearest_entity():
	if detected_entities.is_empty():
		target_entity = null
		return
	
	var nearest_entity: Player = detected_entities[0]
	var nearest_distance: float = global_position.distance_to(detected_entities[0].global_position)
	
	for entity in detected_entities:
		var distance = global_position.distance_to(entity.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_entity = entity
	
	target_entity = nearest_entity
	print("New target: ", target_entity.name, " at distance: ", nearest_distance)

func _on_player_death():
	# Want to despawn instead of respawning at spawn point
	# Drop loot
	inventory_manager.DropAllItems()
	# Don't actually queue free here anymore since want to let LLM agents respawn
	# queue_free()
