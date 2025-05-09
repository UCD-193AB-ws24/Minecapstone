extends ScenarioManager	

var zombie
var agent

func _ready() -> void:
	super()
	reset_connections()


func _on_zombie_died(deadName):
	"""Function is to be triggered by the has_died signal of a zombie. 
	Function checks if zombie died and if so, log success and reset the scenario"""
	if deadName == "Zombie":
		await track_success()
		reset_connections()


func _out_of_prompts():
	"""Function is to be triggered by the out_of_prompts signal of an agent.
	Function check if agent is out of prompts and if so, log failure and reset the scenario"""
	await track_failure()	
	reset_connections()


func reset_connections():
	"""Function is to reset the connections of the signals."""

	zombie = get_parent().get_node("Zombie")
	agent = get_parent().get_node("Agent")
	print(zombie, agent)
	if zombie:
		zombie.has_died.connect(_on_zombie_died)
	if agent:
		agent.out_of_prompts.connect(_out_of_prompts)
