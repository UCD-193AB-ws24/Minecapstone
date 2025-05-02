# MOVE TO VISUAL SCENARIO
extends ScenarioManager


func _ready() -> void:
	super()
	reload()


func reload():
	var agent_goal = get_parent().get_node("Agent2").get_node("Area3D")
	
	agent_goal.connect("body_entered", _on_target_reached)
	success_count = 0
	failure_count = 0


func _on_target_reached(_body: Node3D) -> void:
	#if get_parent().get_node("Agent") in agent.detected_entities:
	track_success()
	#else:
		#track_failure()

	if current_iteration <= MAX_ITERATIONS:
		reset()
	else:
		print("============== Scenario complete. ==============")
		print("Success count:", success_count)
		print("Failure count:", failure_count)
		print("Error count:", error_count)
