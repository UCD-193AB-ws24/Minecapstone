extends ScenarioManager	

var zombie

func _ready() -> void:
	zombie = get_parent().get_node("Zombie")
	#connect to has_died signal
	zombie.has_died.connect(_on_zombie_died)
	super()


func _on_zombie_died(deadName):
		print("died: " + deadName)
		if deadName == "Zombie":
			track_success()
			reset()
			reset_zombie_connection()

func _out_of_prompts():
		print("out of prompts")
		track_failure()
		reset()
		reset_zombie_connection()

func reset_zombie_connection():
	zombie.has_died.disconnect(_on_zombie_died)
	zombie = get_parent().get_node("Zombie")
	#connect to has_died signal
	print(zombie.has_died.connect(_on_zombie_died))
	print("connection resetted")
