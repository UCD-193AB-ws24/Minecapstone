extends ScenarioManager

var test_message = "Hello, I am excited to play Minecapstone"

func _ready() -> void:
	super()
	
	# Connect to the message broker signal once
	MessageBroker.connect("message", _on_message_received)

func _on_message_received(msg: String, _from_id: int, _to_id: int) -> void:
	# Check for our test message
	if msg == test_message:
		track_success()
		next_iteration()