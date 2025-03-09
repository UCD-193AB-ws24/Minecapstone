class_name Agent extends NPC


# Config and export variables
@export var goal : String = "Move to (30,0)."
@export var max_memories: int = 20

@onready var hash_id : int = hash(self)
@onready var agent_controller = $AgentController
@onready var _command_queue: Array[Command] = []
@onready var _memory: Memory = Memory.new(max_memories)

# Command preload
static var _command = preload("command.gd")

# Initialize the agent
func _ready() -> void:
	super()

	# Register with message_broker
	MessageBroker.register_agent(self)
	MessageBroker.message.connect(_on_message_received)
	
	# Connect to API
	API.connect("response", Callable(self, "_on_response"))


func _physics_process(delta):
	super(delta)
	_process_command_queue()

	# Print debug information about commands in the queue
	# if not _command_queue.is_empty():
	# 	print("Debug: [Agent %s] Command Queue Status:" % hash_id)
	# 	for i in range(_command_queue.size()):
	# 		var cmd = _command_queue[i]
	# 		var status_text = "WAITING"
	# 		if cmd.command_status == Command.CommandStatus.EXECUTING:
	# 			status_text = "EXECUTING"
	# 		elif cmd.command_status == Command.CommandStatus.DONE:
	# 			status_text = "DONE"
				
	# 		var type_text = "GOAL" if cmd.command_type == Command.CommandType.GOAL else "SCRIPT"
			
	# 		print("  [%d] Type: %s | Status: %s | Command: %s" % [
	# 			i, type_text, status_text, cmd.command.substr(0, 50) + (
	# 				"..." if cmd.command.length() > 50 else ""
	# 			)
	# 		])


# Gets call-deferred in _ready of npc
func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true

	# Wait for websocket connection
	if not API.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		await API.connected
		set_goal(goal)


func _process_command_queue() -> void:
	if len(_command_queue) > 0:
		var command_status = await _command_queue.front().execute(self)
		match command_status:
			Command.CommandStatus.EXECUTING:
				pass
			Command.CommandStatus.WAITING:
				pass
			Command.CommandStatus.DONE:
				_command_queue.pop_front()
				# if _command_queue.is_empty():
				# 	generate_new_goal()


func generate_new_goal():
	if _command_queue.size() > 0:
		print("Debug: [Agent %s] Skipping prompt - commands in queue" % hash_id)
		return
	else:
		print("Debug: [Agent %s] Prompting LLM" % hash_id)
	
	# Build context about current state, this will inform the LLM ab the agent's current situation
	# var context = _build_prompt_context()
	print("goal generated cuz i went hre")
	set_goal(goal)


func set_goal(new_goal: String) -> void:
	print("Debug: [Agent %s] Setting goal: %s" % [hash_id, new_goal])
	
	if goal != new_goal:
		_memory.add_goal_update(new_goal)
		goal = new_goal
	
	var command_info = {
		"agent": self,
		"type": Command.CommandType.GOAL,
		"command": new_goal
	}
	add_command(command_info)


func add_command(command_info: Dictionary) -> void:
	_command_queue.push_back(_command.new().create_with(command_info))


func _on_message_received(msg: String, from_id: int, to_id: int):
	# to_id == -1, the message is for all agents
	# to_id == hash_id, the message is for this agent
	# TODO: Curently does not remember messages sent by self, but probably should do that
	if (to_id == -1 or to_id == hash_id) and from_id != hash_id:
		print("Debug: [Agent %s] Received message from [Agent %s]: %s" % [hash_id, from_id, msg])

		# Included this message in the agent's memory
		_memory.add_message(msg, from_id, to_id)


# Record an action taken by the agent

# Recording individual actions might be excessive
#func record_action(action_description: String):

func _on_response(key, _response: String):
	if key == self.hash_id:
		print("Debug: [Agent %s] Received script from LLM" % hash_id)


func script_execution_completed():
	print("Debug: Script execution completed")
	
	await get_tree().create_timer(0.5).timeout


func _build_prompt_context() -> String:
	var context = "Current situation\n"
	context += "- Position: " + str(global_position) + "\n"
	context += "- Current goal: " + goal + "\n"
	
	context += _memory.format_recent_for_prompt(5)
	
	return context
	# Add status of goal
	# match _goal_status:
	# 	GoalStatus.COMPLETED:
	# 		context += "- Goal status: COMPLETED\n"
	# 		context += "- IMPORTANT: The previous goal '" + goal + "' is already COMPLETED. \n"
	# 		context += "- You MUST set a new goal using the set_goal() function\n"
	# 		context += "- DO NOT attempt to complete the previous goal again \n"
	# 	GoalStatus.FAILED:
	# 		context += "- Goal status: FAILED\n"
	# 		context += "- Consider why the goal failed and what you want to do next \n"
	# 	GoalStatus.IN_PROGRESS:
	# 		context += "- Goal status: IN_PROGRESS\n"
	# 		context += "- Continue working on your goal \n"
			

# Get all memoris of a specific type
func get_memories_by_type(memory_type: String) -> Array[MemoryItem]:
	return _memory.get_by_type(memory_type)

# # Update goal status - call from agent_controller when goal is completed/failed
# func set_goal_status(status: GoalStatus, new_goal: String = ""):
# 	_goal_status = status
	
# 	if new_goal != "":
# 		goal = new_goal
# 		add_memory({
# 			"type": "goal_update",
# 			"goal": new_goal,
# 		})
		
# 	# If completed a goal or failed, prompt llm
# 	if status != GoalStatus.IN_PROGRESS:
# 		print("Debug: [Agent %s] Goal status changed to %s" % [_debug_id, GoalStatus.keys()[status]])
# 		_is_waiting_for_script = false
		
# 		await get_tree().create_timer(1.0).timeout
# 		prompt_llm()
