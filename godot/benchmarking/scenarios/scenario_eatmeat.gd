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
	
	# Ensure we have a clean slate for this test
	already_processed = false
	
	# Add meat to inventory
	var inventory_manager = agent.get_node("InventoryManager")
	if inventory_manager:
		var meat_item = ItemDictionary.Get(food_name)
		if meat_item:
			inventory_manager.AddItem(meat_item, 1)
			print("Added " + food_name + " to agent's inventory - inventory now: " + inventory_manager.GetInventoryData())
			
			# Connect to signals
			connect_agent_signals(agent)
			
			# Set a timeout as a backup
			get_tree().create_timer(10.0).timeout.connect(func(): 
				if current_agent == agent: # Only proceed if this is still the active agent
					_on_timeout()
			)
		else:
			print("ERROR: Could not find " + food_name + " item in ItemDictionary")
			track_error()
	else:
		print("ERROR: Agent has no inventory_manager")
		track_error()

func connect_agent_signals(agent):
	# Store the agent's instance ID for verification in signal callbacks
	var agent_instance_id = agent.get_instance_id()
	
	# Disconnect any previous signal connections to avoid duplicates
	if agent.is_connected("food_eaten", _on_food_eaten):
		agent.disconnect("food_eaten", _on_food_eaten)
	if agent.is_connected("script_execution_completed", _on_script_completed):
		agent.disconnect("script_execution_completed", _on_script_completed)
	
	# Connect signals with clean connections
	agent.connect("food_eaten", _on_food_eaten)
	agent.connect("script_execution_completed", _on_script_completed)
	
	print("Connected signals to agent (instance ID: " + str(agent_instance_id) + ")")

func _on_node_added(node):
	# If an Agent is added and we're not already testing one, set it up
	if node is Agent and node.name == "Agent" and current_agent == null:
		setup_agent(node)

func _on_food_eaten(eaten_food: String, agent_id: int) -> void:
	# Verify signal is from our current test agent
	if current_agent == null or agent_id != current_agent.get_instance_id():
		print("Ignoring food_eaten signal from different agent instance")
		return
		
	if already_processed:
		print("Test already processed, ignoring food_eaten signal")
		return
		
	print("Food eaten signal received: '" + eaten_food + "' from agent ID: " + str(agent_id))
	
	if eaten_food == food_name:
		already_processed = true
		track_success()
		print("Success! Agent ate " + food_name)
		proceed_to_next_iteration()

func _on_script_completed():
	# Verify we have a current agent being tested
	if current_agent == null:
		return
		
	# Don't process if the test has already been marked as success/failure
	if already_processed:
		return
		
	# Wait a short moment to ensure we didn't miss a food_eaten signal
	get_tree().create_timer(0.2).timeout.connect(func():
		if not already_processed and current_agent != null:
			already_processed = true
			track_failure()
			print("Failure! Agent script completed without eating " + food_name)
			proceed_to_next_iteration()
	)

func _on_timeout():
	if already_processed or current_agent == null:
		return
		
	already_processed = true
	track_failure()
	print("Failure! Test timed out - agent didn't eat " + food_name)
	proceed_to_next_iteration()

func proceed_to_next_iteration():
	# Store the agent we're disconnecting from
	var agent_to_disconnect = current_agent
	
	# Clear current agent reference before timer to avoid race conditions
	current_agent = null
	
	# Disconnect signals from the agent
	if agent_to_disconnect:
		if agent_to_disconnect.is_connected("food_eaten", _on_food_eaten):
			agent_to_disconnect.disconnect("food_eaten", _on_food_eaten)
		if agent_to_disconnect.is_connected("script_execution_completed", _on_script_completed):
			agent_to_disconnect.disconnect("script_execution_completed", _on_script_completed)
		
		print("Disconnected signals from agent")
	
	next_iteration()

	await get_tree().create_timer(0.5).timeout
	start_test()