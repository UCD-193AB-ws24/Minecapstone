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
	If any other animal dies, log failre and reset the scenario. """
	print("this died: ", deadName)
	if deadName == conehead.name:
		print("conehead_dead flag set to true")
		conehead_dead = true
	else:
		track_failure()
		reset()

		for i in range(10):
			await get_tree().physics_frame

		reset_connections()
func _on_food_eaten(food_name: String, _id:int):
	"""Triggered by food_eaten signal. If meat eaten and conehead is dead, log success and reset the scenario."""
	timer.stop()
	print("scenarioo_attack_conehead: food eaten is ", food_name)
	if food_name == "Meat" and conehead_dead:
		track_success()
	else:
		track_failure()
	reset()

	for i in range(10):
		await get_tree().physics_frame

	reset_connections()

func _out_of_time():
	super()
	for i in range(10):
		await get_tree().physics_frame
	reset_connections()


func reset_connections():
	"""Function is to reset the connections of the signals."""
	conehead_dead = false
	conehead = get_parent().get_node("Animal3")
	animal1 = get_parent().get_node("Animal")
	animal2 = get_parent().get_node("Animal2")
	animal4 = get_parent().get_node("Animal4")
	agent = get_parent().get_node("Agent")
	var player = get_parent().get_node("Player")
	player.food_eaten.connect(_on_food_eaten)
	#connect to signals
	conehead.has_died.connect(_on_died)
	print(animal1.has_died.connect(_on_died))
	animal2.has_died.connect(_on_died)
	animal4.has_died.connect(_on_died)
	agent.food_eaten.connect(_on_food_eaten)
	
