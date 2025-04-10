class_name Agent extends NPC


@export var goal : String = "Move to (30,0)."
@export var scenario_goal : String = "Move to (30,0)."
@export var max_memories: int = 20
@export var infinite_decisions: bool = false
@export var prompt_allowance: int = -1 #negative numbers mean infinite allowance
@export var visual_mode:bool = false
@onready var hash_id : int = hash(self)
@onready var debug_id : String = str(hash_id).substr(0, 3)
@onready var agent_controller = $AgentController
@onready var memories: Memory = Memory.new(max_memories)
@onready var _command_queue: Array[Command] = []
@onready var _is_processing_commands: bool = false
static var _command = preload("command.gd")

""" ============================================= GODOT FUNCTIONS ================================================== """

func _ready() -> void:
	super()

	# Register with message_broker
	MessageBroker.register_agent(self)
	MessageBroker.message.connect(_on_message_received)


func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	if _event is InputEventKey and _event.pressed:
		if _event.keycode == KEY_V:
			_command_queue.clear()
			add_command(Command.CommandType.SCRIPT, """
	select_nearest_entity_type("Player")
	attack_current_target(10)
			""")
			# select_nearest_target("Player")
			# get_closest_point_target()
		elif _event.keycode == KEY_C:
			give_to("Player", "Grass", 1)
		# elif _event.keycode == KEY_Z:
		# 	add_command(Command.CommandType.Script, """""")


func _physics_process(delta):
	super(delta)
	_process_command_queue()

	# Print debug information about commands in the queue
	if false:
		if not _command_queue.is_empty():
			for i in range(_command_queue.size()):
				var cmd = _command_queue[i]
				var status_text = "WAITING"
				if cmd.command_status == Command.CommandStatus.EXECUTING:
					status_text = "EXECUTING"
				elif cmd.command_status == Command.CommandStatus.DONE:
					status_text = "DONE"
					
				var type_text = "UNKNOWN"
				match cmd.command_type:
					Command.CommandType.GENERATE_GOAL:
						type_text = "GENERATE_GOAL"
					Command.CommandType.GENERATE_SCRIPT:
						type_text = "GENERATE_SCRIPT"
					Command.CommandType.SCRIPT:
						type_text = "SCRIPT"
				
				print_rich("[Agent %s] Cmd[%d]: [color=green]%s[/color] | %s" % [hash_id, i, type_text, status_text])


""" ============================================ AGENT FUNCTIONS =================================================== """


# Gets call-deferred in _ready of npc
func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true

	# Wait for websocket connection
	if not API.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		await API.connected

		# Debug
		set_goal(goal)


func _process_command_queue() -> void:
	# TODO: investigate using semaphore/Godot locks on _command_queue instead of _is_processing_commands
	if _is_processing_commands:
		return
		
	if len(_command_queue) > 0:
		_is_processing_commands = true

		var command_status = await _command_queue.front().execute(self)
		if command_status == Command.CommandStatus.DONE:
			_command_queue.pop_front()
			
			# If all are processed, make request to LLM
			if _command_queue.is_empty() and infinite_decisions:
				_generate_new_goal()
		
		_is_processing_commands = false


# Queues up the generation of a new goal from the LLM
func _generate_new_goal() -> void:
	if _command_queue.size() > 0:
		print("Debug: [Agent %s] NOT generating new goal, commands in queue")
		return
	add_command(Command.CommandType.GENERATE_GOAL, goal)


func set_goal(new_goal: String) -> void:
	print_rich("Debug: [Agent %s] [color=lime]%s[/color] (Goal Updated)" % [debug_id, new_goal])
	goal = new_goal
	add_command(Command.CommandType.GENERATE_SCRIPT, new_goal)


func add_command(command_type: Command.CommandType, input: String) -> void:
	var command_info = {
		"agent": self,
		"type": command_type,
		"input": input
	}
	_command_queue.push_back(_command.new().create_with(command_info))


func _on_message_received(msg: String, from_id: int, to_id: int):
	# to_id == -1, the message is for all agents
	# to_id == hash_id, the message is for this agent
	# TODO: Curently does not remember messages sent by self, but probably should do that
	if (to_id == -1 or to_id == hash_id) and from_id != hash_id:
		print("Debug: [Agent %s] Received message from [Agent %s]: %s" % [debug_id, from_id, msg])

		# Included this message in the agent's memory
		memories.add_message(msg, from_id, to_id)


func script_execution_completed():
	print_rich("Debug: [Agent %s] [color=lime]Script execution completed[/color]" % debug_id)


func build_prompt_context() -> String:
	var context = "Current situation\n"
	# context += "- Position: " + str(global_position) + "\n"
	
	context += scenario_goal + "\n"
	context += memories.format_recent_for_prompt(5) + "\n"
	context += inventory_manager.GetInventoryData()
	context += "Your name is " + self.name
	
	return context


func get_camera_view() -> String:
	"""
	Captures an image from the agent's camera and returns it as base64 encoded string.
	Returns empty string if camera is not available.
	"""
	if not camera:
		print_rich("[Agent %s] [color=red]Camera3D not found for visual mode[/color]" % debug_id)
		return ""
	
	# Create a viewport to render the camera view
	var viewport = SubViewport.new()
	add_child(viewport)
	viewport.size = Vector2i(1024, 512)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Set up the viewport camera to match the agent's camera
	var viewport_camera:Camera3D = Camera3D.new()
	viewport.add_child(viewport_camera)
	viewport_camera.global_transform = camera.global_transform
	viewport_camera.fov = camera.fov
	viewport_camera.near = camera.near
	viewport_camera.far = camera.far
	
	# Wait for the viewport to render DO NOT USE PROCESS_FRAME!
	await get_tree().physics_frame
	
	# Get the rendered image
	var viewport_texture = viewport.get_texture()
	var image: Image = viewport_texture.get_image()
	
	# Save the image to a file
	# var filename = "agent_view.png"
	# var err = image.save_png(filename)
	# if err != OK:
	# 	print_rich("[Agent %s] [color=red]Failed to save camera view to file: %s[/color]" % [debug_id, error_string(err)])
	# else:
	# 	print_rich("[Agent %s] [color=lime]Saved camera view to: %s[/color]" % [debug_id, filename])

	# Clean up
	viewport.queue_free()
	
	# Convert to base64
	return encode_image_to_base64(image)

func encode_image_to_base64(image: Image) -> String:
	"""
	Encodes an Image to base64 string
	"""
	# Save image to a buffer in PNG format
	var buffer = image.save_png_to_buffer()
	# Convert the buffer to base64
	return Marshalls.raw_to_base64(buffer)

# Get all memories of a specific type
func get_memories_by_type(memory_type: String) -> Array[MemoryItem]:
	return memories.get_by_type(memory_type)

# TODO: investigate effectiveness of recording actions taken by agent
# func record_action(action_description: String):
