# GIVE SELECTIVE SCENARIO
extends ScenarioManager


var agent
var scenario_box
var scenario_box_inventory
var agent_inventory
@export var required_item: String = "Dirt"


func _ready() -> void:
	reset_inventory()
	scenario_box = get_parent().get_node("ScenarioBox")
	scenario_box_inventory = scenario_box.get_node("InventoryManager")
	scenario_box_inventory.ItemAdded.connect(_on_item_added)
	super()


func _on_item_added(item):
	"""Function checks if the item added is the required item and if so, log success. Otherwisem log failure. 
	Regardless, reset the scenario."""
	
	#check if the item is the required item
	if item.Name == required_item:
		track_success()
	else:
		track_failure()


func _restore_initial_state():
	await super()


	
	reset_inventory()


func reset_inventory():
	agent = get_parent().get_node("Agent")
	agent_inventory = agent.get_node("InventoryManager")
	agent_inventory.AddItem(ItemDictionary.Get("Wood Pickaxe"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Dirt"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Stone"), 1)
