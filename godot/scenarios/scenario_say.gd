extends ScenarioManager

var agent
var agent_name = "Agent"
var test_message = "Hello, I am excited to play Minecapstone"
var message_received = false

func _ready() -> void:
    super ()
    reload()

func reload():
    success_count = 0
    failure_count = 0

    message_received = false

    MessageBroker.connect("message_sent", _on_message_sent)

func _on_message_sent(message: String, sender_id: int, receiver_id: int) -> void:
    if message == test_message and receiver_id == agent.hash_id:
        message_received = true

        track_success()

        if current_iteration <= MAX_ITERATIONS:
            MessageBroker.disconnect("message_sent", _on_message_sent)
            reset()
        else:
            print("============== Scenario complete. ==============")
            print("Success count:", success_count)
            print("Failure count:", failure_count)
            print("Error count:", error_count)
