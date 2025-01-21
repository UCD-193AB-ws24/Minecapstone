class_name NPC
extends Player

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
	navigation_agent.path_desired_distance = 0.5
	navigation_agent.target_desired_distance = 0.5

	actor_setup.call_deferred()

	ai_controller.ai_control_enabled = true
	global_position = spawn_point.global_position

func actor_setup():
	await get_tree().physics_frame

func _physics_process(delta: float):
	var player = get_node("/root/World/Player")
	if player:
		go_to(player.global_position)
		
		if navigation_agent.is_navigation_finished():
			return
		
		var current_agent_position: Vector3 = global_position
		var next_path_position: Vector3 = navigation_agent.get_next_path_position()
		var movement = current_agent_position.direction_to(next_path_position)
		movement = Vector2(movement.x, movement.y)

		print(movement, " ", player.global_position, " ", global_position)

		_move_player(movement, false, _speed, delta)

	move_and_slide()
	
	super(delta)

func _input(_event):
	return

func go_to(location: Vector3):
	navigation_agent.set_target_position(location)
