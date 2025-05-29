# ATTACK SELECTIVE SCENARIO
extends ScenarioManager	


var zombie
var animal


func _ready() -> void:
	reset_connections()
	super()


func _on_zombie_died(deadName):
	"""Function is to be triggered by the has_died signal of a zombie. 
	Function checks if zombie died and if so, log success and reset the scenario"""
	if deadName == "Zombie":
		await track_success()
		reset_connections()


func _on_animal_died(deadName):
	"""Function is to be triggered by the has_died signal of an animal.	
	Function checks if animal died and if so, log failure and reset the scenario"""
	if deadName == "Animal":
		await track_failure()
		reset_connections()


func _restore_initial_state():
	await super()

	reset_connections()


func reset_connections():
	"""Function is to reset the connections of the signals."""
	# zombie.has_died.disconnect(_on_zombie_died)
	zombie = get_parent().get_node("Zombie")
	animal = get_parent().get_node("Animal")
	#connect to signals
	zombie.has_died.connect(_on_zombie_died)
	animal.has_died.connect(_on_animal_died)
