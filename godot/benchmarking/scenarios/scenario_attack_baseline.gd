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


func _restore_initial_state():
	await super()
	
	reset_connections()


func reset_connections():
	"""Function is to reset the connections of the signals."""

	zombie = get_parent().get_node("Zombie")
	agent = get_parent().get_node("Agent")
	if zombie:
		zombie.has_died.connect(_on_zombie_died)
	if agent:
		agent.out_of_prompts.connect(track_failure)
