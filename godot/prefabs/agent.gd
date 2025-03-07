class_name Agent extends NPC


# Config and export variables
@export var goal : String = "Move to (30,0)."
@export var max_memories: int = 20

@onready var hash_id : int = hash(self)
@onready var agent_controller = $AgentController
@onready var memories : Array[Dictionary] = []
@onready var _command_queue: Array[Command] = []

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


func prompt_llm():
	if _command_queue.size() > 0:
		print("Debug: [Agent %s] Skipping prompt - commands in queue" % hash_id)
		return
	
	# Build context about current state
	var context = _build_prompt_context()
	
	# set_goal(context)
	set_goal(goal)


func set_goal(new_goal: String) -> void:
	print("Debug: Agent received goal: ", new_goal)

	var command_info = {
		"agent": self,
		"type": Command.CommandType.GOAL,
		"command": new_goal
	}
	_add_command(command_info)


func _add_command(command_info: Dictionary) -> void:
	_command_queue.append(_command.new().create_with(command_info))


func _on_message_received(msg: String, from_id: int, to_id: int):
	# to_id == -1, the message is for all agents
	# to_id == hash_id, the message is for this agent
	# TODO: Curently does not remember messages sent by self, but probably should do that
	if (to_id == -1 or to_id == hash_id) and from_id != hash_id:
		print("Debug: [Agent %s] Received message from [Agent %s]: %s" % [hash_id, from_id, msg])

		# Included this message in the agent's memory
		memories.append({
			"type": "message",
			"msg": msg,
			"from_id": from_id,
			"to_id": to_id,
			"timestamp": Time.get_ticks_msec() / 1000.0
		})


# Record an action taken by the agent
func record_action(action_description: String):
	add_memory({
		"type": "action",
		"action": action_description
	})


func add_memory(memory: Dictionary) -> void:
	memory["timestamp"] = Time.get_ticks_msec() / 1000.0
	memories.append(memory)
	if memories.size() > max_memories:
		memories.pop_front()


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
	
	# # Add status of goal
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
			
	# if memories.size() > 0:
	# 	context += "- Recent events:\n"
	# 	var recent_memories = memories.slice(max(0, memories.size() -5), memories.size())
	# 	for memory in recent_memories:
	# 		if memory.type == "message":
	# 			context += "* Message from agent " + str(memory.from_id) + ": " + memory.msg + "\n"
	# 		elif memory.type == "goal_update":
	# 			context += "* Previous goal: " + memory.goal + "\n"
	# 		elif memory.type == "action":
	# 			context += "* Action performed: " + memory.action + "\n"
	return context


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
