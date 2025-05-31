# LOOK AT TARGET SCENARIO
extends ScenarioManager


var agent
var raycast


func _ready() -> void:
	super()
	_find_agent()


func _restore_initial_state():
	await super()
	_find_agent()
	

func _find_agent():
	agent = get_parent().get_node("Agent")
	if agent:
		raycast = agent.get_node("Head/Camera3D/RayCast3D")


# currently broken, still trying to figure out how to get raycast after a reset
func _physics_process(_delta):
	# if raycast == null:
	# 	_find_agent()
	
	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.name == "NPCZombie":
			await track_success()
		elif collider.name == "Animal":
			await track_failure()
