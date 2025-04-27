extends Node

var scenario_manager

var inventory_manager

func _ready() -> void:
	inventory_manager = get_node("InventoryManager")
	scenario_manager = get_parent().get_node("ScenarioManager") # ScenarioManager should be a sibling of the scriptholder

func check_box():
	var amount = inventory_manager.GetItemCount("Dirt")
	print("Dirt amount: ", amount)
	if amount > 0:
		scenario_manager.track_success()
		scenario_manager.reset()
