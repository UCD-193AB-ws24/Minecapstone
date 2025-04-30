# LOOK AT TARGET SCENARIO
extends ScenarioManager




func _ready() -> void:
	super()
	reload()

func reload():
	success_count = 0
	failure_count = 0


# currently broken, physics process does not continue after reset
func _physics_process(_delta):
	var raycast = get_parent().find_child("Agent").get_node("Head").get_node("Camera3D").get_node("RayCast3D")
	if raycast.is_colliding():
		print("Colliding")
		var collider = raycast.get_collider()
		if collider.name == "NPCZombie":
			track_success()
		elif collider.name == "NPCZombie":
			track_failure()
		if current_iteration <= MAX_ITERATIONS:
			reset()
		else:
			print("============== Scenario complete. ==============")
			print("Success count:", success_count)
			print("Failure count:", failure_count)
			print("Error count:", error_count)
