extends ScenarioManager	

var zombie
var agent
var animal

func _ready() -> void:
	reset_connections()
	super()


func _on_zombie_died(deadName):
		print("died: " + deadName)
		if deadName == "Zombie":
			track_success()
			reset()

			for i in range(10):
				await get_tree().physics_frame

			reset_connections()
func _on_animal_died(deadName):
		print("died: " + deadName)
		if deadName == "Animal":
			track_failure()
			reset()

			for i in range(10):
				await get_tree().physics_frame

			reset_connections()
	

func _out_of_prompts():
		print("out of prompts")
		track_failure()
		reset()

		for i in range(10):
			await get_tree().physics_frame
		
		reset_connections()

func reset_connections():
	# zombie.has_died.disconnect(_on_zombie_died)
	zombie = get_parent().get_node("Zombie")
	agent = get_parent().get_node("Agent")
	animal = get_parent().get_node("Animal")
	#connect to signals
	zombie.has_died.connect(_on_zombie_died)
	agent.out_of_prompts.connect(_out_of_prompts)
	animal.has_died.connect(_on_animal_died)
