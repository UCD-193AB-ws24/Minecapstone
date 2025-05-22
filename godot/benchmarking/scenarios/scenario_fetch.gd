extends ScenarioManager

var agent1:Agent
var agent1_inventory
var agent2:Agent
var zombie1:NPC_Zombie
var zombie2:NPC_Zombie
var zombie2_inventory
var animal:NPC_Animal
var correct_zombie_dead: bool = false

func _ready() -> void:
	reset_connections()
	super()

func _on_item_added(item):
	"""function is triggered by the item_added signal of the scenario box inventory.
	Checks if the item added is the required item and if so, log success. Otherwise, log failure.
	Then reset the scenario."""
	timeout_timer.stop()
	print("Item received: " + item.Name)
	if item.Name == "Wood Pickaxe" and correct_zombie_dead:
		track_success()
	else:
		track_failure()

	for i in range(10):
		await get_tree().physics_frame

	reset_connections()


func _on_died(deadName: String):
	"""Triggered by has_died signal. If Zombie2 dies, set correct_zombie_dead flag true. 
	If anything else dies, log failure and reset the scenario. """
	print("this died: ", deadName)
	if deadName == zombie2.name:
		correct_zombie_dead = true
	else:
		track_failure()


func _restore_initial_state():
	await super()

	reset_connections()


func reset_connections():
	correct_zombie_dead = false
	agent1 = get_parent().get_node("Agent1")
	agent1.has_died.connect(_on_died)
	agent1_inventory = agent1.get_node("InventoryManager")
	agent1_inventory.ItemAdded.connect(_on_item_added)

	agent2 = get_parent().get_node("Agent2")
	agent2.has_died.connect(_on_died)

	zombie1 = get_parent().get_node("Zombie1")
	zombie1.has_died.connect(_on_died)

	zombie2 = get_parent().get_node("Zombie2")
	zombie2.has_died.connect(_on_died)
	zombie2_inventory = zombie2.get_node("InventoryManager")
	zombie2_inventory.AddItem(ItemDictionary.Get("Wood Pickaxe"), 1)

	animal = get_parent().get_node("Animal")
	animal.has_died.connect(_on_died)