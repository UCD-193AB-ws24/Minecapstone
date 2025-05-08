# MOVE TO VISUAL SCENARIO
extends ScenarioManager


func _ready() -> void:
	super()
	reload()


func reload():
	var red_platform = get_parent().find_child("RedPlatform").get_node("Area3D")
	var blue_platform = get_parent().find_child("BluePlatform").get_node("Area3D")
	
	success_count = 0
	failure_count = 0
	red_platform.connect("body_entered", _on_touch_platform.bind("RedPlatform"))
	blue_platform.connect("body_entered", _on_touch_platform.bind("BluePlatform"))


func _on_touch_platform(_body: Node3D, platform_name: String) -> void:
	if platform_name == "RedPlatform":
		track_success()
	else:
		track_failure()

	if current_iteration <= MAX_ITERATIONS:
		reset()
	else:
		get_results(true)