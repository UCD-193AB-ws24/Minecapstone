extends Node


@export var giver:String = "Agent"

#sets up the scene by giving Agent a specified amount of meat
func _ready() -> void:
    var giver_ref = AgentManager.get_agent(giver)
    #check if giver is an agent
    if giver_ref.get_meta("Name") != "agent":
        print("meat_scenario.gd: ", giver, " is not an agent")
        return
    giver_ref.inventory_manager.AddItem(ItemDictionary.get("Meat"), 5)

