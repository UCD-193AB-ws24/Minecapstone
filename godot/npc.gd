class_name NPC
extends Player

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
var finished_setup = false

func _ready():
	navigation_agent.path_desired_distance = 2
	navigation_agent.target_desired_distance = 2
	_speed = 2.28378822
	actor_setup.call_deferred()

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

	# This makes the NPC movement not that smooth/efficient, which is actually good
	if get_tree().get_frame() % 60 == 0:
		set_movement_target(player.global_position)

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var movement = current_agent_position.direction_to(next_path_position).normalized()

	if velocity.length() < 0.5:
		move_player(Vector2(movement.x, movement.z), true, _speed, delta)
	else:
		move_player(Vector2(movement.x, movement.z), false, _speed, delta)

	# if movement.length() > 0.1:
	# 	head.look_at(global_position + movement, Vector3.UP)

	raycast.target_position = Vector3(movement.x, movement.y, movement.z).normalized() * 2

	super(delta)


func _process(_delta):
	move_and_slide()


func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	return
