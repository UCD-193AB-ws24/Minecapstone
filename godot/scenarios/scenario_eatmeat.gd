extends ScenarioManager

var food_name = "Meat"
var already_processed = false
var meat_added = false
var agent

func _ready() -> void:
	super ()
	
	# Connect to node events to track agent creation/removal
	get_tree().connect("node_added", _on_node_added)
	get_tree().connect("node_removed", _on_node_removed)
	
	print("Scenario started: Testing if agent eats " + food_name)
	
	# Start checking for agents immediately
	await get_tree().create_timer(0.5).timeout
	find_and_setup_agent()

func find_and_setup_agent():
	# Find agent in the scene
	agent = get_parent().find_child("Agent")
	if agent:
		setup_agent_for_test()
	else:
		print("Agent not found in scene. Waiting...")
		await get_tree().create_timer(0.5).timeout
		find_and_setup_agent()

func setup_agent_for_test():
	print("Setting up agent for test iteration: " + str(current_iteration + 1))
	meat_added = false
	already_processed = false
	
	# First verify inventory is clear of meat
	var inventory_manager = agent.get_node("InventoryManager")
	if inventory_manager:
		# Try to remove any existing meat first to avoid duplicates
		inventory_manager.DropItem(food_name, 99)
		
		# Add fresh meat
		var meat_item = ItemDictionary.Get(food_name)
		if meat_item:
			var result = inventory_manager.AddItem(meat_item, 1)
			if result:
				print("Added " + food_name + " to agent's inventory")
				meat_added = true
			else:
				print("ERROR: Failed to add meat to inventory")
				track_error()
				return
		else:
			print("ERROR: Could not find " + food_name + " item in ItemDictionary")
			track_error()
			return
			
		# Connect to signals
		_connect_signals()
		
		# Add timeout as backup to catch cases where script doesn't complete
		get_tree().create_timer(10.0).timeout.connect(_on_timeout)
	else:
		print("ERROR: Agent has no inventory_manager")
		track_error()

func _connect_signals():
	# Connect to food eaten signal
	if agent.is_connected("food_eaten", _on_food_eaten):
		agent.disconnect("food_eaten", _on_food_eaten)
	agent.connect("food_eaten", _on_food_eaten)
	
	# Connect to script execution completed to detect if the agent didn't eat
	if agent.is_connected("script_execution_completed", _on_script_completed):
		agent.disconnect("script_execution_completed", _on_script_completed)
	agent.connect("script_execution_completed", _on_script_completed)

func _on_node_added(node):
	# If an Agent is added, try to setup test
	if node is Player and node.name == "Agent":
		agent = node
		setup_agent_for_test()

func _on_node_removed(node):
	# Clear references when agent is removed
	if node is Player and node.name == "Agent":
		meat_added = false
		already_processed = false
		agent = null

func _on_script_completed():
	# If script completed but agent hasn't eaten, mark as failure
	if !already_processed and meat_added:
		already_processed = true
		track_failure()
		print("Failure! Agent script completed without eating " + food_name)
		proceed_to_next_iteration()

func _on_timeout():
	# Backup timeout in case other signals fail
	if !already_processed and meat_added:
		already_processed = true
		track_failure()
		print("Failure! Test timed out - agent didn't eat " + food_name)
		proceed_to_next_iteration()

func _on_food_eaten(eaten_food: String, agent_id: int) -> void:
	if already_processed:
		return
	
	print("Food eaten signal received: '" + eaten_food + "'")
	
	# Only count it if it's our test agent
	if agent and agent.get_instance_id() == agent_id:
		if eaten_food == food_name:
			already_processed = true
			track_success()
			print("Success! Agent ate " + food_name)
			proceed_to_next_iteration()

func proceed_to_next_iteration():
	# Wait briefly then reset for next iteration
	get_tree().create_timer(1.0).timeout.connect(func():
		if current_iteration < MAX_ITERATIONS:
			# Properly disconnect signals before reset
			if agent:
				if agent.is_connected("food_eaten", _on_food_eaten):
					agent.disconnect("food_eaten", _on_food_eaten)
				if agent.is_connected("script_execution_completed", _on_script_completed):
					agent.disconnect("script_execution_completed", _on_script_completed)
			
			reset()
			
			# Setup for next iteration with delay to ensure reset is complete
			get_tree().create_timer(0.5).timeout.connect(func():
				find_and_setup_agent()
			)
		else:
			print("============== Scenario complete. ==============")
			print("Success count:", success_count)
			print("Failure count:", failure_count)
			print("Error count:", error_count)
	)
