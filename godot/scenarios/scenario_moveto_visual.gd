extends ScenarioManager


func _reload():
	print(get_parent())


func _on_touch_correct_platform(area: Area3D):
	track_success()


func _on_touch_wrong_platform(area: Area3D):
	track_failure()
