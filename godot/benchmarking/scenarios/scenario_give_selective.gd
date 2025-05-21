# GIVE SELECTIVE SCENARIO
extends ScenarioManager


var agent
var scenario_box
var scenario_box_adapter
var agent_inventory
@export var required_item: String = "Dirt"


func _ready() -> void:
	agent = get_parent().get_node("Agent")
	agent_inventory = agent.get_node("InventoryManager")
	agent_inventory.AddItem(ItemDictionary.Get("Wood Pickaxe"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Dirt"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Stone"), 1)
	scenario_box = get_parent().get_node("ScenarioBox")
	scenario_box_adapter = scenario_box.get_node("SignalAdapter")
	scenario_box_adapter.transit_signal.connect(_receive_transit_signal)
	super()


func _on_item_added(item):
	"""Function checks if the item added is the required item and if so, log success. Otherwisem log failure. 
	Regardless, reset the scenario."""
	print("Item received: " + item.Name)
	
	#check if the item is the required item
	if item.Name == required_item:
		track_success()
	else:
		track_failure()


func _receive_transit_signal(signal_name:String, args: Array):
	"""Function is to be triggered by the transit_signal signal of the scenario box adapter.
	Function checks if the signal name is ItemAdded and if so, call _on_item_added function."""
	print("transit signal received: " + signal_name)
	if signal_name == "ItemAdded":
		_on_item_added(args[0])


func _restore_initial_state():
	await super()
	reset_inventory()


func reset_inventory():
	agent = get_parent().get_node("Agent")
	agent_inventory = agent.get_node("InventoryManager")
	agent_inventory.AddItem(ItemDictionary.Get("Wood Pickaxe"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Dirt"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Stone"), 1)