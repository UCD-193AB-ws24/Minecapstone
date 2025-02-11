class_name NPC
extends Player


@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# NPC will wander around its spawn
@export var wander_range: float = 10.0
@export var wander_change_time: float = 5.0
var wander_timer: float = 0.0
var wander_target: Vector3 = Vector3.ZERO
var spawn_position: Vector3
var just_jumped = false

func _ready():
	actor_setup.call_deferred()
	_speed = 1.0
	ai_controller.ai_control_enabled = true
	spawn_position = global_position
	_generate_wander_target()

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

# Public function to handle wandering behavior that child classes can use without calling super
func handle_wandering(delta):
	_handle_wandering(delta)
	_handle_movement(delta)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 35 * delta
	
	handle_wandering(delta)
	_handle_movement(delta)
	
	move_and_slide()
	
func _handle_wandering(delta):
	wander_timer += delta
	
	if wander_timer >= wander_change_time or global_position.distance_to(wander_target) < 1.0:
		_generate_wander_target()
		wander_timer = 0.0
	
	navigation_agent.target_position = wander_target
	
func _generate_wander_target():
	
	# Select random angle within the wander_range and wander in that direction
	var random_angle = randf_range(0, PI * 2)
	var random_radius = randf_range(0, wander_range)
	var offset = Vector3(
		cos(random_angle) * random_radius,
		0,
		sin(random_angle) * random_radius
	)
	wander_target = Vector3(
		global_position.x + offset.x,
		global_position.y,
		global_position.z + offset.z
	
	)
	#print(wander_target)

func _handle_movement(delta):
	
	var current_pos = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var path_direction = current_pos.direction_to(next_path_position)
	var path_direction_2d = Vector2(path_direction.x, path_direction.z) * _speed

	# print(navigation_agent.path_postprocessing)
	if velocity.length() < 0.4:
		if not just_jumped:
			move_player(path_direction_2d, true, _speed, delta)
			just_jumped = true
			var postprocessing_options = [
				NavigationPathQueryParameters3D.PATH_POSTPROCESSING_NONE,
				NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
			]
			navigation_agent.path_postprocessing = postprocessing_options[randi() % postprocessing_options.size()]
			navigation_agent.path_desired_distance = randf_range(0.9, 3)
			await get_tree().create_timer(randf_range(0.5, 2)).timeout
			navigation_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
			navigation_agent.path_desired_distance = 1
			just_jumped = false
		else:
			move_player(path_direction_2d, false, _speed, delta)
	else:
		move_player(path_direction_2d, false, _speed, delta)

func _process(_delta):
	pass

func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	return
