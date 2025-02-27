class_name Agent extends NPC

signal movement_completed

@onready var goal : String = ""
@onready var hash_id : int = hash(self)
@onready var agent_controller = $AgentController
@onready var _prev_position: Vector3 = Vector3.ZERO
@onready var _was_navigating: bool = false
@onready var _movement_timeout: float = 5.0
@onready var _movement_start_time: float = 0.0
@onready var _is_waiting_for_movement: bool = false

@onready var _is_executing: bool = false
@onready var _task_queue: Array = []
@onready var _current_task = null

@export var initial_goal: String = ""

func _ready() -> void:
	super()
	API.connect("response", Callable(self, "_on_response"))
	
	# Register agent with message_broker
	var message_broker = get_node("/root/MessageHandler")
	if message_broker:
		message_broker.register_agent(self)
		message_broker.message_received.connect(_on_message_received)
	else:
		print("Warning: MessageHandler singleton not found")
	
	if initial_goal != "":
		set_goal(initial_goal)

# Gets call-deferred in _ready of npc
func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true

	# Wait for websocket connection
	if not API.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		await API.connected
		
		# No set goal in Insepctor then default
		if initial_goal == "":
			set_goal("Move to (30, 0)")
		else:
			set_goal(initial_goal)

# Prompts the LLM based on the agent's goal
func set_goal(new_goal:String):
	# Add to task queue
	var task = {
		"type": "goal",
		"content": new_goal
	}
	_enqueue_task(task)

# Add task to the queue
func _enqueue_task(task):
	_task_queue.append(task)
	
	# If not currently executing, start processing the queue
	if not _is_executing:
		_process_queue()

# Process the task queue
func _process_queue():
	if _is_executing or _task_queue.size() == 0:
		return
		
	_is_executing = true
	_current_task = _task_queue.pop_front()
	
	match _current_task.type:
		"goal":
			_execute_goal(_current_task.content)
		"script":
			_execute_script(_current_task.content)
		_:
			print("Unknown task")
			_task_completed()


func _execute_goal(new_goal: String):
	self.goal = new_goal
	print("Agent ", hash_id, " executing goal: ", new_goal)
	
	# Prompt LLM with the goal
	API.prompt_llm(new_goal, self.hash_id)
	# _task_completed() will be called when response is received

# Execute script from LLM
func _execute_script(script_content: String):
	run_script(script_content)

# Mark task as completed
func _task_completed():
	_is_executing = false
	_current_task = null
	
	# Continue processing
	_process_queue()

# Handles the response from the LLM
func _on_response(key, response: String):
	# Ensure the response is for this agent
	if key != self.hash_id: return

	var task = {
		"type": "script",
		"content": response
	}
	
	_enqueue_task(task)
	
	_task_completed()

# Do not modify this function, it is used to run the script created by the LLM
func run_script(input: String):
	var source = agent_controller.get_script().get_source_code().replace(
		"class_name AgentController\nextends Node", 
		"extends RefCounted").replace(
		"func eval(delta):\n\tdelta = delta\n\treturn true",
		""
		) + """
func eval(delta):
%s
	return true
""" % input

	# TODO: remove debug print
	print("Debug: Agent performing ", input)

	# Dangerously created script
	var script = GDScript.new()
	script.set_source_code(source)

	var err = script.reload()
	if err != OK:
		print("Script error: ", err)
		return false

	var instance = RefCounted.new()
	instance.set_script(script)
	var result = await instance.setup(self).eval(0)
	_task_completed()
	
	return result

# Use this function to emit signals
func _physics_process(delta):
	super(delta)
	
	if _is_waiting_for_movement:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - _movement_start_time > _movement_timeout:
			print("Movement timed out for agent ", hash_id)
			_is_waiting_for_movement = false
			movement_completed.emit()
			
	if navigation_agent:
		var is_finished = navigation_agent.is_navigation_finished()
		
		if _was_navigating and is_finished:
			print("Agent ", hash_id, " reached destination")
			_is_waiting_for_movement = false
			movement_completed.emit()
			
		_was_navigating = !is_finished
		
		
func start_movement_timeout():
	_is_waiting_for_movement = true
	_movement_start_time = Time.get_ticks_msec() / 1000.0

# Agent communication
func _on_message_received(from_id: int, to_id: int, content: String) -> void:
	if to_id == hash_id:
		print("Agent ", hash_id, " received message from ", from_id, ": ", content)
		
		var label = get_node_or_null("Label3D")
		if label:
			label.text = "Received " + content
	
		
		var new_goal = "Message received from agent " + str(from_id) + ": " + content + "\nRespond according to message content."
		self.goal = new_goal
		
		# Set goal but do not call API directly
		set_goal(new_goal)

		# Get current state and environment info
		#var context = {
			#"message_from": from_id,
			#"message_content": content,
			#"my_position": global_position,
			#"nearby_agents": agent_controller.get_nearby_agents()
		#}
