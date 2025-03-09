class_name Agent extends NPC


# Config and export variables
@export var goal : String = "Move to (30,0)."
@export var max_memories: int = 20

@onready var hash_id : int = hash(self)
@onready var agent_controller = $AgentController
@onready var _command_queue: Array[Command] = []
@onready var _memory: Memory = Memory.new(max_memories)
@onready var _is_processing_commands: bool = false

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
		request_llm_action()


func _process_command_queue() -> void:
	if _is_processing_commands:
		return
		
	if len(_command_queue) > 0:
		_is_processing_commands = true
		
		var command_status = await _command_queue.front().execute(self)
		if command_status == Command.CommandStatus.DONE:
			_command_queue.pop_front()
			
			# If all are processed, make request to LLM
			if _command_queue.is_empty():
				request_llm_action()
		
		_is_processing_commands = false

# Request new action from LLM
func request_llm_action() -> void:
	if _command_queue.size() > 0:
		print("Debug: [Agent %s] Skipping LLM request")
		return
	
	print("Debug: [Agent %s] Requestion action from LLM" % hash_id)
	
	var command_info = {
		"agent": self,
		"type": Command.CommandType.LLM_REQUEST,
		"command": goal
	}
	
	add_command(command_info)

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
	if new_goal == goal:
		return
	
	print("Debug: [Agent %s] Setting goal: %s" % [hash_id, new_goal])
	
	var command_info = {
		"agent": self,
		"type": Command.CommandType.GOAL_UPDATE,
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
	print("Debug: [Agent %s] Script execution completed" % hash_id)



func _build_prompt_context() -> String:
	var context = "Current situation\n"
	context += "- Position: " + str(global_position) + "\n"
	context += "- Current goal: " + goal + "\n"
	
	context += _memory.format_recent_for_prompt(5)
	
	return context
	

# Get all memoris of a specific type
func get_memories_by_type(memory_type: String) -> Array[MemoryItem]:
	return _memory.get_by_type(memory_type)
