extends ScenarioManager

var animal1: NPC_Animal
var animal2: NPC_Animal
var conehead: NPC_Animal # this is animal3
var animal4: NPC_Animal
var animal5: NPC_Animal
var agent:Agent
var conehead_dead: bool


func _ready() -> void:
	reset_connections()
	super()


func _on_died(deadName: String):
	"""Triggered by has_died signal. If the conehead animal dies, set conehead died flag true. 
	If any other animal dies, log failure and reset the scenario. """
	if deadName == conehead.name:
		conehead_dead = true
	else:
		track_failure()


func _on_food_eaten(food_name: String, _id:int):
	"""Triggered by food_eaten signal. If meat eaten and conehead is dead, log success and reset the scenario."""
	if food_name == "Meat" and conehead_dead:
		track_success()
	else:
		track_failure()


func reset():
	await super()
	reset_connections()


func reset_connections():
	"""Function is to reset the connections of the signals."""
	conehead_dead = false
	animal1 = get_parent().get_node("Animal")
	animal1.has_died.connect(_on_died)
	animal2 = get_parent().get_node("Animal2")
	animal2.has_died.connect(_on_died)
	conehead = get_parent().get_node("Animal3")
	conehead.has_died.connect(_on_died)
	animal4 = get_parent().get_node("Animal4")
	animal4.has_died.connect(_on_died)
	
	agent = get_parent().get_node("Agent")
	agent.food_eaten.connect(_on_food_eaten)
