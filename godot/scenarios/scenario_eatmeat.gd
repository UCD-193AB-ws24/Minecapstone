extends ScenarioManager

var food_name = "Meat"
var already_processed = false
var meat_added = false

func _ready() -> void:
	super()
	
	# Connect to any food_eaten signals in the scene
	get_tree().connect("node_added", _on_node_added)
	get_tree().connect("node_removed", _on_node_removed)
	
	# Also connect to the message broker to detect when an agent says something
	MessageBroker.connect("message", _on_message_received)
	
	print("Listening for any agent that eats " + food_name)
	
	# Start checking for agents immediately
	add_meat_to_agent()

func _on_node_added(node):
	# If an Agent is added, try to add meat
	if node is Player and node.name == "Agent":
		add_meat_to_agent()

func add_meat_to_agent():
	var agent = get_parent().find_child("Agent")
	if agent and !meat_added:
		# Add meat to inventory
		var meat_item = ItemDictionary.Get(food_name)
		if meat_item:
			agent.inventory_manager.AddItem(meat_item, 1)
			print("Added " + food_name + " to agent's inventory")
			meat_added = true
			
			# Connect to the signal
			if !agent.is_connected("food_eaten", _on_food_eaten):
				agent.connect("food_eaten", _on_food_eaten)
		else:
			print("Could not find " + food_name + " item in ItemDictionary")

func _on_node_removed(node):
	# Reset meat_added flag when the agent is removed
	if node is Player and node.name == "Agent":
		meat_added = false

func _on_message_received(msg: String, from_id: int, to_id: int) -> void:
	# If the agent is talking about finding meat, it probably doesn't have any
	if "find" in msg.to_lower() and "meat" in msg.to_lower() and !already_processed:
		already_processed = true
		track_failure()
		print("Failure! Agent said it needs to find meat, which means it doesn't have any.")
		
		# Wait briefly then reset for next iteration
		get_tree().create_timer(1.0).timeout.connect(func():
			if current_iteration < MAX_ITERATIONS:
				reset()
				meat_added = false
			else:
				print("============== Scenario complete. ==============")
				print("Success count:", success_count)
				print("Failure count:", failure_count)
				print("Error count:", error_count)
		)

func _on_food_eaten(eaten_food: String, agent_id: int) -> void:
	if already_processed:
		return
	
	print("Food eaten signal received: '" + eaten_food + "'")
	
	if eaten_food == food_name:
		already_processed = true
		track_success()
		print("Success! Agent ate " + food_name)
		
		# Wait briefly then reset for next iteration
		get_tree().create_timer(1.0).timeout.connect(func():
			if current_iteration < MAX_ITERATIONS:
				reset()
				meat_added = false
			else:
				print("============== Scenario complete. ==============")
				print("Success count:", success_count)
				print("Failure count:", failure_count)
				print("Error count:", error_count)
		)
