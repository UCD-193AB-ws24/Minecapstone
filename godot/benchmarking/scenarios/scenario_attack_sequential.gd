# ATTACK SEQUENTIAL SCENARIO
extends ScenarioManager	


var zombie
var animal
var zombie_killed = false


func _ready() -> void:
	reset_connections()
	super()


func _on_zombie_died(deadName):
	"""Function is to be triggered by the has_died signal of a zombie. 
	Function checks if zombie died and if so, mark zombie_killed as true"""
	if deadName == "Zombie":
		zombie_killed = true


func _on_animal_died(deadName):
	"""Function is to be triggered by the has_died signal of an animal.
	Function checks if animal died and if so, also checks if zombie_killed is true.
	If both conditions are met, log success and reset the scenario
	Otherwise, log failure and reset the scenario"""
	if deadName == "Animal":
		if zombie_killed == true:
			await track_success()
		else:
			await track_failure()


func reset():
	#Clear data from global classes
	await super()
	zombie_killed = false
	reset_connections()


func reset_connections():
	"""Function is to reset the connections of the signals."""
	# zombie.has_died.disconnect(_on_zombie_died)
	zombie = get_parent().get_node("Zombie")
	animal = get_parent().get_node("Animal")
	#connect to signals
	zombie.has_died.connect(_on_zombie_died)
	animal.has_died.connect(_on_animal_died)
