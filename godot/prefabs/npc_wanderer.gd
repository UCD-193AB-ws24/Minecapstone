class_name NPC_Wanderer
extends NPC


@export var wander_range: float = 10.0
@export var wander_change_time: float = 10.0 # Don't make this too fast otherwise it changes too quickly and basically stays in place
var wander_timer: float = 0.0
var wander_target: Vector3 = Vector3.ZERO
var wander_center: Vector3


func _ready():
	super()
	wander_center = global_position


func _physics_process(delta):
	_set_wander_target_position(delta)
	super(delta)


func _set_wander_target_position(delta):
	if navigation_ready:
		wander_timer += delta
		
		if wander_timer >= wander_change_time or navigation_agent.is_navigation_finished():
			set_movement_target(_generate_wander_target())
			wander_timer = 0.0


func _generate_wander_target() -> Vector3:
	var random_angle = randf_range(0, PI * 2)
	var random_radius = randf_range(0, wander_range)
	var offset = Vector3(
		cos(random_angle) * random_radius,
		0,
		sin(random_angle) * random_radius
	)
	
	wander_target = Vector3(
		wander_center.x + offset.x,
		wander_center.y,
		wander_center.z + offset.z
	)
	
	return wander_target

func _on_player_death():
	super()
	queue_free()
