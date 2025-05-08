extends ScenarioManager

var agent
var scenario_box
var scenario_box_adapter
var agent_inventory
var timer: Timer
@export var required_item: String = "Dirt"
@export var scenario_duration_seconds: int = 315

func _ready() -> void:
	agent = get_parent().get_node("Agent")
	agent_inventory = agent.get_node("InventoryManager")
	agent_inventory.AddItem(ItemDictionary.Get("Wood Pickaxe"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Dirt"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Stone"), 1)
	scenario_box = get_parent().get_node("ScenarioBox")
	scenario_box_adapter = scenario_box.get_node("SignalAdapter")
	scenario_box_adapter.transit_signal.connect(_receive_transit_signal)
	timer = get_node("ScenarioTimer")
	timer.timeout.connect(_out_of_time)
	super()
	reset_timer()

func _on_item_added(item):
	"""Function checks if the item added is the required item and if so, log success. Otherwisem log failure. 
	Regardless, reset the scenario."""
	print("Item received: " + item.Name)
	#stop timer
	timer.stop()
	#check if the item is the required item
	if item.Name == required_item:
		track_success()
	else:
		track_failure()
	reset()
	# wait for 10 frames to give time for the scenario to reset
	for i in range(10):
		await get_tree().physics_frame
	#reset inventory
	reset_inventory()
	#reset timer
	reset_timer()

# func _out_of_prompts():
# 	"""Function is to be triggered by the out_of_prompts signal of an agent.
# 	Function check if agent is out of prompts and if so, log failure and reset the scenario"""
# 	#print("out of prompts")

# 	#It takes some time for the item to be picked up by the scenario box. Wait a few seconds and check the success flag. If the flag is true, don't log fail.
# 	# If the flag is false, log fail.
# 	await get_tree().create_timer(4.0).timeout
# 	if !success_flag:

# 		track_failure()
# 		reset()

# 		for i in range(10):
# 			await get_tree().physics_frame
	
# 		reset_connections()
func _out_of_time():
	"""Function is to be triggered by the out_of_time signal of an agent.
	Function check if agent is out of time and if so, log failure and reset the scenario"""
	print("out of time")
	track_failure()
	reset()

	for i in range(10):
		await get_tree().physics_frame
	
	#reset inventory
	reset_inventory()
	#reset timer
	reset_timer()

func _receive_transit_signal(signal_name:String, args: Array):
	"""Function is to be triggered by the transit_signal signal of the scenario box adapter.
	Function checks if the signal name is ItemAdded and if so, call _on_item_added function."""
	print("transit signal received: " + signal_name)
	if signal_name == "ItemAdded":
		print(args)
		_on_item_added(args[0])

func reset():
	super()

func reset_inventory():
	agent = get_parent().get_node("Agent")
	agent_inventory = agent.get_node("InventoryManager")
	agent_inventory.AddItem(ItemDictionary.Get("Wood Pickaxe"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Dirt"), 1)
	agent_inventory.AddItem(ItemDictionary.Get("Stone"), 1)
	

	#connect to signals
	#agent.out_of_prompts.connect(_out_of_prompts)

func reset_timer():
	"""Function is to be triggered by the reset_timer signal of the scenario box adapter.
	Function resets the timer."""
	print("reset timer")
	timer.start(scenario_duration_seconds)
