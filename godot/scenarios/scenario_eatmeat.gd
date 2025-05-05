extends ScenarioManager

var food_name = "Meat"
var already_processed = false
var meat_added = false

func _ready() -> void:
	super()
	
	# Connect to node events to track agent creation/removal
	get_tree().connect("node_added", _on_node_added)
	get_tree().connect("node_removed", _on_node_removed)
	
	print("Scenario started: Testing if agent eats " + food_name)
	
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
			
			# Connect to the food_eaten signal
			if !agent.is_connected("food_eaten", _on_food_eaten):
				agent.connect("food_eaten", _on_food_eaten)
				
			# Also connect to script execution completed to detect if the agent didn't eat
			if !agent.is_connected("script_execution_completed", _on_script_completed):
				agent.connect("script_execution_completed", _on_script_completed)
		else:
			print("Could not find " + food_name + " item in ItemDictionary")

func _on_node_removed(node):
	# Reset meat_added flag when the agent is removed
	if node is Player and node.name == "Agent":
		meat_added = false

func _on_script_completed():
	# If script completed but agent hasn't eaten, mark as failure
	if !already_processed and meat_added:
		already_processed = true
		track_failure()
		print("Failure! Agent script completed without eating " + food_name)
		proceed_to_next_iteration()

func _on_food_eaten(eaten_food: String, agent_id: int) -> void:
	if already_processed:
		return
	
	print("Food eaten signal received: '" + eaten_food + "'")
	
	if eaten_food == food_name:
		already_processed = true
		track_success()
		print("Success! Agent ate " + food_name)
		proceed_to_next_iteration()

func proceed_to_next_iteration():
	# Wait briefly then reset for next iteration
	get_tree().create_timer(1.0).timeout.connect(func():
		if current_iteration < MAX_ITERATIONS:
			reset()
			# Reset state for next iteration
			already_processed = false
			meat_added = false
		else:
			print("============== Scenario complete. ==============")
			print("Success count:", success_count)
			print("Failure count:", failure_count)
			print("Error count:", error_count)
	)
