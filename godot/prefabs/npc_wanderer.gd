class_name NPC_Wanderer
extends NPC

@export var wander_range: float = 10.0
@export var wander_change_time: float = 5.0
var wander_timer: float = 0.0
var wander_target: Vector3 = Vector3.ZERO
var spawn_position: Vector3

func _ready():
	super()
	_speed = 1.0
	spawn_position = global_position
	_generate_wander_target()

func _physics_process(delta):
	super(delta)
	_set_wander_target_position(delta)

func _set_wander_target_position(delta):
	wander_timer += delta
	
	if wander_timer >= wander_change_time or global_position.distance_to(wander_target) < 1.0:
		_generate_wander_target()
		wander_timer = 0.0
	
	navigation_agent.target_position = wander_target
	
func _generate_wander_target() -> Vector3:
	var random_angle = randf_range(0, PI * 2)
	var random_radius = randf_range(0, wander_range)
	var offset = Vector3(
		cos(random_angle) * random_radius,
		0,
		sin(random_angle) * random_radius
	)
	
	wander_target = Vector3(
		spawn_position.x + offset.x,
		spawn_position.y,
		spawn_position.z + offset.z
	)
	
	return wander_target
