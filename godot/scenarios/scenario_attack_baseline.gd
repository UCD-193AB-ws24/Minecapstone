extends ScenarioManager

func _ready() -> void:
	_capture_initial_state()
	var zombie = get_parent().get_node("Zombie")
	#connect to has_died signal
	zombie.has_died.connect(_on_zombie_died)

func _on_zombie_died(deadName):
		print("died: " + deadName)
		if deadName == "Zombie":
			track_success()
			reset()

func _out_of_prompts():
		print("out of prompts")
		track_failure()
		reset()
