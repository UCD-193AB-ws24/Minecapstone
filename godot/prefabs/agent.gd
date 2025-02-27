class_name Agent extends NPC


@export var goal : String = "Move to (30,0)."
@onready var hash_id : int = hash(self)
@onready var agent_controller = $AgentController


@onready var _command_queue: Array[Command] = []
@onready var memories : Array[Dictionary] = []


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
		set_goal(goal)

# Queues a prompt to the LLM based on the agent's goal
static var _command = preload("command.gd")
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
			"msg": msg,
			"from_id": from_id,
			"to_id": to_id
		})

		# TODO: prompt llm to determine if the agent should respond, for now do it anyways
		set_goal(msg)

		# Get current state and environment info
		#var context = {
			#"message_from": from_id,
			#"message_content": content,
			#"my_position": global_position,
			#"nearby_agents": agent_controller.get_nearby_agents()
		#}

# Use this function to emit signals
func _physics_process(delta):
	super(delta)

	if len(_command_queue) > 0:
		var command_status = _command_queue.front().execute(self)
		if command_status == Command.CommandStatus.DONE:
			_command_queue.pop_front()
