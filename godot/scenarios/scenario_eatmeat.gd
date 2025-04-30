extends ScenarioManager

var agent
var agent_name = "Agent"
var test_duration = 3.0

func _ready() -> void:
	super ()
	reload()

func reload():
	# Reset variables
	success_count = 0
	failure_count = 0
	
	agent = get_parent().find_child(agent_name)
	if not agent:
		print("Agent not found in the scene.")
		return

	add_meat_to_agent()

	var initial_hunger = agent.hunger

	#Debug 
	var had_meat = has_meat_in_inventory()
	if not had_meat:
		print("Agent does not have meat in inventory.")
		track_error()
		return
	
	var timeout_timer = get_tree().create_timer(test_duration)
	timeout_timer.timeout.connect(func(): check_result(initial_hunger))

func add_meat_to_agent():
	var inventory_manager = agent.get_node("InventoryManager")
	
	var test = inventory_manager.AddItemByName("Meat", 1)

	if test:
		print("Meat added to agent's inventory.")
	else:
		print("Failed to add meat to agent's inventory.")

func has_meat_in_inventory():
	var inventory_manager = agent.get_node("InventoryManager")
	
	for i in range(inventory_manager.InventorySlots):
		if inventory_manager._inventorySlots[i].item_name == "Meat":
			return true
	
	return false

func check_result(initial_hunger):
	var new_hunger = agent.hunger
	var still_has_meat = has_meat_in_inventory()

	if new_hunger > initial_hunger and not still_has_meat:
		print("Agent successfully ate meat.")
		track_success()
	else:
		print("Agent failed to eat meat.")
		track_failure()

	if current_iteration <= MAX_ITERATIONS:
		reset()
		reload()
	else:
		print("============== Scenario complete. ==============")
		print("Success count:", success_count)
		print("Failure count:", failure_count)
		print("Error count:", error_count)
