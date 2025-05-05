extends ScenarioManager

var food_name = "Meat"
var already_processed = false
var current_agent = null

func _ready() -> void:
	super()
	
	print("Meat eating scenario started")
	
	# Connect to node_added signal to detect new agents
	get_tree().connect("node_added", _on_node_added)
	
	# Start first test
	start_test()

func start_test():
	# Reset state for new test
	already_processed = false
	current_agent = null
	
	# Find the agent
	var agent = get_parent().get_node("Agent")
	if agent:
		setup_agent(agent)
	else:
		print("Agent not found, waiting...")
		# Try again after a delay
		get_tree().create_timer(0.5).timeout.connect(func(): start_test())

func setup_agent(agent):
	current_agent = agent
	print("Setting up agent for test iteration " + str(current_iteration + 1))
	
	# Add meat to inventory
	var inventory_manager = agent.get_node("InventoryManager")
	if inventory_manager:
		var meat_item = ItemDictionary.Get(food_name)
		if meat_item:
			var result = inventory_manager.AddItem(meat_item, 1)
			print("Added " + food_name + " to agent's inventory")
			
			# Connect to signals
			connect_agent_signals(agent)
			
			# Set a timeout as a backup
			get_tree().create_timer(10.0).timeout.connect(func(): _on_timeout())
		else:
			print("ERROR: Could not find " + food_name + " item in ItemDictionary")
			track_error()
	else:
		print("ERROR: Agent has no inventory_manager")
		track_error()

func connect_agent_signals(agent):
	# Connect to the food_eaten signal
	if agent.is_connected("food_eaten", _on_food_eaten):
		agent.disconnect("food_eaten", _on_food_eaten)
	agent.connect("food_eaten", _on_food_eaten)
	
	# Connect to script completion signal
	if agent.is_connected("script_execution_completed", _on_script_completed):
		agent.disconnect("script_execution_completed", _on_script_completed)
	agent.connect("script_execution_completed", _on_script_completed)

func _on_node_added(node):
	# If an Agent is added, set it up for the test
	if node is Player and node.name == "Agent" and current_agent == null:
		setup_agent(node)

func _on_food_eaten(eaten_food: String, agent_id: int) -> void:
	if already_processed:
		return
		
	print("Food eaten signal received: '" + eaten_food + "'")
	
	if eaten_food == food_name:
		already_processed = true
		track_success()
		print("Success! Agent ate " + food_name)
		proceed_to_next_iteration()

func _on_script_completed():
	# Wait a moment to make sure food_eaten wasn't called first
	get_tree().create_timer(0.2).timeout.connect(func():
		if not already_processed and current_agent != null:
			already_processed = true
			track_failure()
			print("Failure! Agent script completed without eating " + food_name)
			proceed_to_next_iteration()
	)

func _on_timeout():
	if not already_processed and current_agent != null:
		already_processed = true
		track_failure()
		print("Failure! Test timed out - agent didn't eat " + food_name)
		proceed_to_next_iteration()

func proceed_to_next_iteration():
	# Disconnect signals from current agent
	if current_agent:
		if current_agent.is_connected("food_eaten", _on_food_eaten):
			current_agent.disconnect("food_eaten", _on_food_eaten)
		if current_agent.is_connected("script_execution_completed", _on_script_completed):
			current_agent.disconnect("script_execution_completed", _on_script_completed)
	
	# Wait briefly then reset for next iteration
	get_tree().create_timer(1.0).timeout.connect(func():
		if current_iteration < MAX_ITERATIONS:
			reset()
			# Wait for reset to complete
			get_tree().create_timer(1.5).timeout.connect(func():
				start_test()
			)
		else:
			print("============== Scenario complete. ==============")
			print("Success count:", success_count)
			print("Failure count:", failure_count)
			print("Error count:", error_count)
	)
