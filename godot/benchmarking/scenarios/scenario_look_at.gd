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
		#print("Agent not found")
		return
	else:
		raycast = agent.get_node("Head").get_node("Camera3D").get_node("RayCast3D")
		#print("Agent: ", agent)
		#print("Raycast: ", raycast)

func reset():
	super()

	#print("FINDING THE AGENT NOW")
	_find_agent()

func reload():
	_find_agent()

	success_count = 0
	failure_count = 0

# currently broken, still trying to figure out how to get raycast after a reset
func _physics_process(_delta):
	# raycast = get_parent().get_node("Agent").get_node("Head").get_node("Camera3D").get_node("RayCast3D")
	# print("Finding raycast")
	if raycast == null:
		#print("Raycast not found")
		_find_agent()
	
	# print("Raycast found")

	if raycast and raycast.is_colliding():
		#print("Colliding")
		var collider = raycast.get_collider()
		if collider.name == "NPCZombie":
			track_success()
		elif collider.name == "Animal":
			track_failure()
		if current_iteration <= MAX_ITERATIONS:
			reset()
		else:
			get_results(true)
