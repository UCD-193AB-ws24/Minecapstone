extends ScenarioManager

var agent_name = "Agent"
var test_message = "Hello, I am excited to play Minecapstone"
var timer: Timer
var iteration_complete = false

func _ready() -> void:
	super()
	reload()

func reload():
	# Reset variables
	iteration_complete = false
	
	var agent = get_parent().find_child(agent_name)
	if not agent:
		print("Agent not found in the scene.")
		await get_tree().create_timer(0.5).timeout
		reload()  # Try again after a short delay
		return
		
	print("Tracking agent with hash_id: ", agent.hash_id)
	
	# Clean up previous timer if it exists
	if timer:
		timer.stop()
		timer.queue_free()
		
	# Connect to message signal
	if MessageBroker.is_connected("message", _on_message_received):
		MessageBroker.disconnect("message", _on_message_received)
	MessageBroker.connect("message", _on_message_received)
	
	# Set a timeout
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = 10.0
	timer.timeout.connect(_on_timeout)
	add_child(timer)
	timer.start()

func _on_message_received(msg: String, from_id: int, to_id: int) -> void:
	# First check if we already completed this iteration
	if iteration_complete:
		return
		
	var agent = get_parent().find_child(agent_name)
	if not agent:
		return
		
	# Check if the message matches and is from our tracked agent
	if msg == test_message and from_id == agent.hash_id:
		iteration_complete = true
		
		if timer:
			timer.stop()
			timer.queue_free()
			timer = null
			
		track_success()
		print("Agent successfully sent the message!")

		# Disconnect signal before resetting
		if MessageBroker.is_connected("message", _on_message_received):
			MessageBroker.disconnect("message", _on_message_received)
			
		if current_iteration <= MAX_ITERATIONS:
			reset()
			# Wait for physics frames to ensure proper reset
			await get_tree().physics_frame
			await get_tree().physics_frame
			reload()
		else:
			print("============== Scenario complete. ==============")
			print("Success count:", success_count)
			print("Failure count:", failure_count)
			print("Error count:", error_count)

func _on_timeout():
	if iteration_complete:
		return
		
	iteration_complete = true
	print("Timeout: Agent did not send the message in time.")
	track_failure()
	
	if timer:
		timer.queue_free()
		timer = null
	
	# Disconnect signal before resetting
	if MessageBroker.is_connected("message", _on_message_received):
		MessageBroker.disconnect("message", _on_message_received)
		
	if current_iteration <= MAX_ITERATIONS:
		reset()
		# Wait for physics frames to ensure proper reset
		await get_tree().physics_frame
		await get_tree().physics_frame
		reload()
	else:
		print("============== Scenario complete. ==============")
		print("Success count:", success_count)
		print("Failure count:", failure_count)
		print("Error count:", error_count)
