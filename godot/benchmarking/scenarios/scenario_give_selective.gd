# GIVE SELECTIVE SCENARIO
extends ScenarioManager


var agent
var scenario_box
var scenario_box_inventory
var agent_inventory
@export var required_item: String = "Dirt"


func _ready() -> void:
	agent = get_parent().get_node("Agent")
	agent_inventory = agent.get_node("InventoryManager")
	agent_inventory.AddItem(ItemDictionary.Get("Wood Pickaxe"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Dirt"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Stone"), 1)

	scenario_box = get_parent().get_node("ScenarioBox")
	scenario_box_inventory = scenario_box.get_node("InventoryManager")

	# This scenario uniquely re-saves the state after some additional setup.
	_capture_initial_state()
	reset_connections()


func _on_item_added(item):
	"""function is triggered by the item_added signal of the scenario box inventory.
	Function checks if the item added is the required item and if so, log success. Otherwisem log failure. 
	Regardless, reset the scenario."""
	print("Item received: " + item.name)
	if item.name == required_item:
		await track_success()
	else:
		await track_failure()
	reset_connections()


func _out_of_prompts():
	"""Function is to be triggered by the out_of_prompts signal of an agent.
	Function check if agent is out of prompts and if so, log failure and reset the scenario"""
	#print("out of prompts")
	await track_failure()
	reset_connections()


func reset_connections():
	scenario_box_inventory.ItemAdded.connect(_on_item_added)
