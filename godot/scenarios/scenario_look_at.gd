# LOOK AT TARGET SCENARIO
extends ScenarioManager

var agent
var raycast

func _ready() -> void:
	super()
	reload()


func _find_agent():
	agent = get_parent().get_node("Agent")
	if not agent:
		return
	else:
		raycast = agent.get_node("Head").get_node("Camera3D").get_node("RayCast3D")

func reload():
	_find_agent()

	success_count = 0
	failure_count = 0

func _physics_process(_delta):
	if raycast == null:
		_find_agent()
		return
	
	if raycast.is_colliding():
		# don't want raycast hitting player as a result
		var collider = raycast.get_collider()
		if collider.name == "NPCZombie":
			track_success()
			if current_iteration <= MAX_ITERATIONS:
				reset()
		elif collider.name == "Animal":
			track_failure()
			if current_iteration <= MAX_ITERATIONS:
				reset()

	# print results upon finishing iterations 
	if !(current_iteration <= MAX_ITERATIONS):
		print("============== Scenario complete. ==============")
		print("Success count:", success_count)
		print("Failure count:", failure_count)
		print("Error count:", error_count)
