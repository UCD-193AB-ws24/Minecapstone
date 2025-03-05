class_name Agent extends NPC

# Config and export variables
@export var goal : String = "Move to (30,0)."
@export var max_memories: int = 20
@export var min_time_between_prompts: float = 5.0

# Internal variables
@onready var hash_id : int = hash(self)
@onready var agent_controller = $AgentController
@onready var _command_queue: Array[Command] = []
@onready var memories : Array[Dictionary] = []
@onready var _last_prompt_time: float = 0.0
@onready var _is_waiting_for_script: bool = false
@onready var _prompt_timer: SceneTreeTimer = null

# State tracking
enum GoalStatus { IN_PROGRESS, COMPLETED, FAILED }
@onready var _goal_status: GoalStatus = GoalStatus.IN_PROGRESS

# Command preload
static var _command = preload("command.gd")

func _ready() -> void:
	super()
	_initialize()

func _initialize() -> void:
	# Register with message_broker
	if MessageBroker:
		MessageBroker.register_agent(self)
		MessageBroker.message.connect(_on_message_received)
	else:
		push_error("MessageBroker not available")
	
	# Connect to API
	if API:
		if not API.is_connected("response", Callable(self, "_on_response")):
			API.connect("response", Callable(self, "_on_response"))
	else:
		push_error("API not available")
		
	_last_prompt_time = Time.get_ticks_msec() / 1000.0
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
	_goal_status = GoalStatus.IN_PROGRESS
	
	await get_tree().create_timer(1.0).timeout
	_schedule_prompt()

func add_memory(memory: Dictionary) -> void:
	memory["timestamp"] = Time.get_ticks_msec() / 1000.0
	memories.append(memory)
	if memories.size() > max_memories:
		memories.pop_front()
		
func _add_command(command_info: Dictionary) -> void:
	if _command:
		_command_queue.append(_command.new().create_with(command_info))
	else:
		push_error("Command script not available")
		
func _process_command_queue() -> void:
	if len(_command_queue) > 0:
		var command_status = _command_queue.front().execute(self)
		if command_status == Command.CommandStatus.DONE:
			_command_queue.pop_front()
			
			
func prompt_llm():
	# Check if we should prompt
	if not _should_prompt():
		_schedule_prompt()
		return
		
	_last_prompt_time = Time.get_ticks_msec() / 1000.0
	
	# Build context about current state
	var context = _build_prompt_context()
	
	var command_info = {
		"agent": self,
		"type": Command.CommandType.GOAL,
		"command": context
	}
	
	print("Debug: Agent prompting LLM with context")
	_is_waiting_for_script = true
	
	_add_command(command_info)

func _build_prompt_context() -> String:
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
		GoalStatus.IN_PROGRESS:
			context += "- Goal status: IN_PROGRESS\n"
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
	return context


func _should_prompt() -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0
	return (
		_command_queue.size() == 0 and
		not _is_waiting_for_script and
		current_time - _last_prompt_time >= min_time_between_prompts
	)

func set_goal(new_goal: String) -> void:
	var command_info = {
		"agent": self,
		"type": Command.CommandType.GOAL,
		"command": new_goal
	}
	
	print("Debug: Agent received goal: ", new_goal)
	_add_command(command_info)


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
	if status != GoalStatus.IN_PROGRESS:
		_is_waiting_for_script = false
	
# Record an action taken by the agent
func record_action(action_description: String):
	add_memory({
		"type": "action",
		"action": action_description
	})
	
func _on_response(key, response: String):
	if key != self.hash_id:
		return
		
	print("Debug: Received script from LLM")
	_is_waiting_for_script = false
	
func run_script(input: String):
	var script_command = _command.new().create_with({
		"agent": self,
		"type": Command.CommandType.SCRIPT,
		"command": input
	})
	
	return await script_command.run_script(input)
	
func script_execution_completed():
	print("Debug: Script execution completed")
	
	var timer = get_tree().create_timer(min_time_between_prompts)
	timer.timeout.connect(func():
		if _command_queue.size() == 0 and not _is_waiting_for_script:
			_schedule_prompt()
	)
	


func _schedule_prompt():
	# Cancel existing prompts
	if _prompt_timer != null and _prompt_timer.time_left > 0:
		pass
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last = current_time - _last_prompt_time
	var wait_time = max(0.1, min_time_between_prompts - time_since_last)
	
	_prompt_timer = get_tree().create_timer(wait_time)
	_prompt_timer.timeout.connect(func():
		if _command_queue.size() == 0 and not _is_waiting_for_script:
			print("Debug: Retry prompting")
			prompt_llm()
	)

# Use this function to emit signals
func _physics_process(delta):
	super(delta)
	_process_command_queue()
