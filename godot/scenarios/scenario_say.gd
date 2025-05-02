extends ScenarioManager

var test_message = "Hello, I am excited to play Minecapstone"
var already_processed = false

func _ready() -> void:
	super()
	
	# Connect to the message broker signal once and never disconnect
	if MessageBroker.is_connected("message", _on_message_received):
		MessageBroker.disconnect("message", _on_message_received)
	MessageBroker.connect("message", _on_message_received)
	
	print("Scenario started. Waiting for message: '" + test_message + "'")

func _on_message_received(msg: String, from_id: int, to_id: int) -> void:
	# Only process each message once per test iteration
	if already_processed:
		return
		
	print("Message received: '" + msg + "' from " + str(from_id))
	
	# Check for our test message
	if msg == test_message:
		already_processed = true
		track_success()
		print("Success! Agent sent the message.")
		
		# Wait briefly then reset for next iteration
		get_tree().create_timer(1.0).timeout.connect(func():
			if current_iteration < MAX_ITERATIONS:
				reset()
				already_processed = false
				print("Ready for next message: '" + test_message + "'")
			else:
				print("============== Scenario complete. ==============")
				print("Success count:", success_count)
				print("Failure count:", failure_count)
				print("Error count:", error_count)
		)
