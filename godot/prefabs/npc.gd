class_name NPC
extends Player

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var just_jumped = false

func _ready():
	actor_setup.call_deferred()
	ai_controller.ai_control_enabled = true

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame

func _handle_movement(delta):
	var current_pos = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var path_direction = current_pos.direction_to(next_path_position)
	var path_direction_2d = Vector2(path_direction.x, path_direction.z) * _speed
	
	var height_diff = current_pos.y - next_path_position.y
	
	if height_diff > 0 and height_diff <= 3.0:
		move_player(path_direction_2d, false, _speed, delta)
	elif velocity.length() < 0.1 and is_on_floor() and next_path_position.y > current_pos.y + 0.5:
		if not just_jumped:
			move_player(path_direction_2d, true, _speed, delta)
			just_jumped = true
			var postprocessing_options = [
				NavigationPathQueryParameters3D.PATH_POSTPROCESSING_NONE,
				NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
			]
			navigation_agent.path_postprocessing = postprocessing_options[randi() % postprocessing_options.size()]
			navigation_agent.path_desired_distance = randf_range(0.9, 3)
			await get_tree().create_timer(1.0).timeout
			navigation_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_CORRIDORFUNNEL
			navigation_agent.path_desired_distance = 1
			just_jumped = false
		else:
			move_player(path_direction_2d, false, _speed, delta)
	else:
		move_player(path_direction_2d, false, _speed, delta)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= 35 * delta

	_handle_movement(delta)
	move_and_slide()

	if global_position.y < 15:
		_on_out_of_bounds()


func _process(_delta):
	pass

func _input(_event):
	return
