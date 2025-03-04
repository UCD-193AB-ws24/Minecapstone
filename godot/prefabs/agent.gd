class_name Agent extends NPC


@export var goal : String = "Move to (30,0)."
@onready var hash_id : int = hash(self)
@onready var agent_controller = $AgentController
@onready var _command_queue: Array[Command] = []
@onready var memories : Array[Dictionary] = []

# State tracking
enum GoalStatus { PENDING, COMPLETED, FAILED }
@onready var _goal_status: GoalStatus = GoalStatus.PENDING
@export var max_memories: int = 20

func _ready() -> void:
	super()
	# Register agent with message_broker
	var message_broker = MessageBroker
	message_broker.register_agent(self)
	message_broker.message.connect(_on_message_received)
	API.connect("response", Callable(self, "_on_response"))


# Gets call-deferred in _ready of npc
func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true

	# Wait for websocket connection
	if not API.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		await API.connected
		set_initial_goal(goal)

func set_initial_goal(new_goal:String):
	goal = new_goal
	_goal_status = GoalStatus.PENDING
	prompt_llm()
	
func prompt_llm():
	# Build context about current state
	var context = "Current situation\n"
	context += "- Position: " + str(global_position) + "\n"
	context += "- Current goal: " + goal + "\n"
	
	# Add status of goal
	match _goal_status:
		GoalStatus.COMPLETED:
			context += "- Goal status: COMPLETED\n"
			context += "- You need to set a new goal for yourself \n"
		GoalStatus.FAILED:
			context += "- Goal status: FAILED\n"
			context += "- Consider why the goal failed and what you want to do next \n"
		GoalStatus.PENDING:
			context += "- Goal status: PENDING\n"
			context += "- Continue working on your goal \n"
			
	if memories.size() > 0:
		context += "- Recent events:\n"
		var recent_memories = memories.slice(max(0, memories.size() -5), memories.size())
		for memory in recent_memories:
			if memory.type == "message":
				context += "* Message from agent " + str(memory.from_id) + ": " + memory.msg + "\n"
			elif memory.type == "goal_update":
				context += "* Previous goal: " + memory.goal + "\n"
			elif memory.type == "action":
				context += "* Action performed: " + memory.action + "\n"
	
	var command_info = {
		"agent": self,
		"type": Command.CommandType.GOAL,
		"command": context
	}
	
	print("Debug: Agent prompting LLM with context")
	_command_queue.append(_command.new().create_with(command_info))

func add_memory(memory: Dictionary):
	memories.append(memory)
	if memories.size() > max_memories:
		memories.pop_front()

# Queues a prompt to the LLM based on the agent's goal

func set_goal(new_goal:String):
	# Add to task queue

	var command_info = {
		"agent": self,
		"type": Command.CommandType.GOAL,
		"command": new_goal
	}

	print("Debug: Agent received goal: ", new_goal)

	_command_queue.append(_command.new().create_with(command_info))

func _on_message_received(msg: String, from_id: int, to_id: int):
	# If to_id is -1, the message is for all agents
	# If to_id is the same as this agent's hash_id, the message is for this agent
	# and do not process messages sent by self
	if (to_id == -1 or to_id == hash_id) and from_id != hash_id:
		print("Debug: Agent received message: ", msg)
		print("Debug: From agent id: ", from_id)
		print("Debug: To agent id: ", to_id)

		memories.append({
			"type": "message",
			"msg": msg,
			"from_id": from_id,
			"to_id": to_id,
			"timestamp": Time.get_ticks_msec() / 1000.0
		})
		
		
		# TODO: prompt llm to determine if the agent should respond, for now do it anyways
		if _command_queue.size() == 0:
			prompt_llm()
		#set_goal(msg)

		# Get current state and environment info
		#var context = {
			#"message_from": from_id,
			#"message_content": content,
			#"my_position": global_position,
			#"nearby_agents": agent_controller.get_nearby_agents()
		#}

# Update goal status - call from agent_controller when goal is completed/failed
func set_goal_status(status: GoalStatus, new_goal: String = ""):
	_goal_status = status
	
	if new_goal != "":
		goal = new_goal
		add_memory({
			"type": "goal_update",
			"goal": new_goal,
			"timestamp": Time.get_ticks_msec() / 1000.0
		})
		
	# If completed a goal or failed, prompt llm
	if status != GoalStatus.PENDING and _command_queue.size() == 0:
		prompt_llm()

# Record an action taken by the agent
func record_action(action_description: String):
	add_memory({
		"type": "action",
		"action": action_description,
		"timestamp": Time.get_ticks_msec() / 1000.0
	})

static var _command = preload("command.gd")
# Use this function to emit signals
func _physics_process(delta):
	super(delta)

	if len(_command_queue) > 0:
		var command_status = _command_queue.front().execute(self)
		if command_status == Command.CommandStatus.DONE:
			_command_queue.pop_front()
			
		# If we completed the script and have no more commands prompt LLM again
		if len(_command_queue) == 0:
			prompt_llm()
