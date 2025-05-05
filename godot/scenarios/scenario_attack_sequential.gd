extends ScenarioManager	

var zombie
var agent
var animal
var zombie_killed = false

func _ready() -> void:
	reset_connections()
	super()


func _on_zombie_died(deadName):
	"""Function is to be triggered by the has_died signal of a zombie. 
	Function checks if zombie died and if so, mark zombie_killed as true"""
	#print("died: " + deadName)
	if deadName == "Zombie":
		zombie_killed = true
		
func _on_animal_died(deadName):
	"""Function is to be triggered by the has_died signal of an animal.
	Function checks if animal died and if so, also checks if zombie_killed is true.
	If both conditions are met, log success and reset the scenario
	Otherwise, log failure and reset the scenario"""
	#print("died: " + deadName)
	if deadName == "Animal":
		if zombie_killed == true:
			track_success()
		else:
			track_failure()
	reset()

	for i in range(10):
		await get_tree().physics_frame

	reset_connections()
	

func _out_of_prompts():
	"""Function is to be triggered by the out_of_prompts signal of an agent.
	Function check if agent is out of prompts and if so, log failure and reset the scenario"""
	#print("out of prompts")
	track_failure()
	reset()

	for i in range(10):
		await get_tree().physics_frame
	
	reset_connections()

func reset_connections():
	"""Function is to reset the connections of the signals."""
	# zombie.has_died.disconnect(_on_zombie_died)
	zombie = get_parent().get_node("Zombie")
	agent = get_parent().get_node("Agent")
	animal = get_parent().get_node("Animal")
	#connect to signals
	zombie.has_died.connect(_on_zombie_died)
	agent.out_of_prompts.connect(_out_of_prompts)
	animal.has_died.connect(_on_animal_died)
