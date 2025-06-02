extends Node


func _on_timer_timeout() -> void:
	var area = get_parent() # returns Area3D
	area.monitoring = true
	queue_free()


func pick_up_cooldown() -> void:
	var area = get_parent() # returns Area3D
	area.monitoring = false
	var timer = self;
	#timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	timer.start(0.5)
