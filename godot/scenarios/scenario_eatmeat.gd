extends ScenarioManager

var agent_name = "Agent"
var test_duration = 8.0
var initial_hunger: float = 0
var timer: Timer
var iteration_complete = false

func _ready() -> void:
	super()
	reload()

func reload():
	# Reset variables
	iteration_complete = false
	
	# Clean up previous timer if it exists
	if timer:
		timer.stop()
		timer.queue_free()
		timer = null
	
	var agent = get_parent().find_child(agent_name)
	if not agent:
		print("Agent not found in the scene.")
		await get_tree().create_timer(0.5).timeout
		reload()  # Try again after a short delay
		return
	
	var inventory_manager = agent.get_node("InventoryManager")
	
	# Add meat to the agent's inventory
	inventory_manager.AddItem(ItemDictionary.Get("Meat"), 1)
	print("Added Meat to agent's inventory")
	
	# Store initial hunger
	initial_hunger = agent.hunger
	print("Initial hunger: ", initial_hunger)
	
	# Set a timer to check the result
	timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = test_duration
	timer.timeout.connect(_on_timeout)
	add_child(timer)
	timer.start()

func _on_timeout():
	if iteration_complete:
		return
		
	iteration_complete = true
	
	var agent = get_parent().find_child(agent_name)
	if not agent:
		print("Agent not found at check time.")
		track_failure()
		if current_iteration <= MAX_ITERATIONS:
			reset()
			# Wait for physics frames to ensure proper reset
			await get_tree().physics_frame
			await get_tree().physics_frame
			reload()
		return
		
	var new_hunger = agent.hunger
	print("New hunger: ", new_hunger)
	
	# Check if inventory still has meat using the public GetInventoryData method
	var inventory_data = agent.inventory_manager.GetInventoryData()
	var still_has_meat = "Meat" in inventory_data
	
	# Check if hunger increased and meat was consumed
	if new_hunger > initial_hunger and not still_has_meat:
		print("Agent successfully ate meat.")
		track_success()
	else:
		print("Agent failed to eat meat. Still has meat: ", still_has_meat)
		track_failure()

	if timer:
		timer.queue_free()
		timer = null
		
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
