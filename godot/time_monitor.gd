extends Node

func _on_timer_timeout() -> void:
	print("You can pick me up!")
	queue_free()

func pick_up_cooldown() -> void:
	var area = get_parent(); # returns Area3D
	var timer = self
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.connect("timeout", _on_timer_timeout)
	timer.start()
