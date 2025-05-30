class_name Agent extends NPC


@export var goal : String = "Move to (30,0)."
@export var scenario_goal : String = "Move to (30,0)."
@export var max_memories: int = 20
@export var infinite_decisions: bool = false
@export var prompt_allowance: int = -1 #negative numbers mean infinite allowance
@export var visual_mode:bool = false
@export var self_fix_mode:bool = false
@onready var hash_id : int = hash(str(self) + str(Time.get_ticks_msec()))
@onready var agent_controller = $AgentController
@onready var memories: MemoryManager = MemoryManager.new(max_memories)
@onready var _command_queue: Array[Command] = []
@onready var _is_processing_commands: bool = false
static var _command = preload("command.gd")


@onready var debug_id : String = str(hash_id).substr(0, 3)
@onready var debug_color : String = Color.from_hsv(float(hash_id) / 1000.0, 0.8, 1).to_html(false)


signal out_of_prompts


""" ============================================= GODOT FUNCTIONS ================================================== """


func _ready() -> void:
	MessageBroker.message.connect(_on_message_received)
	super()


func _input(_event):
	# Override the default input function to prevent the NPC from being controlled by the player
	if _event is InputEventKey and _event.pressed:
		if _event.keycode == KEY_V:
			_command_queue.clear()
			add_command(Command.CommandType.SCRIPT, """
	await move_to_target("ScenarioBox")
	await give_to("ScenarioBox", "Dirt", 1)

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
				
				print_rich("[color=#%s][Agent %s][/color] Cmd[%d]: [color=green]%s[/color] | %s" % [debug_color, debug_id, i, type_text, status_text])


""" ============================================ AGENT FUNCTIONS =================================================== """


# Gets call-deferred in _ready of npc
func actor_setup():
	super()
	# Register with message_broker and agent_manager
	MessageBroker.register_agent(self)
	AgentManager.register_agent(self)

	# Wait for websocket connection
	if API.socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		await API.connected

	for i in range(16):
		await get_tree().physics_frame

	set_goal.call_deferred(goal)

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
			if _command_queue.is_empty() and (infinite_decisions or prompt_allowance > 0):
				#Agent consumes a prompt allowance
				if prompt_allowance > 0:
					prompt_allowance -= 1
				_generate_new_goal()
			elif prompt_allowance < 0 and not infinite_decisions:
				# No more prompt allowance, emit _out_of_prompts signal
				out_of_prompts.emit()
		
		_is_processing_commands = false


# Queues up the generation of a new goal from the LLM
func _generate_new_goal() -> void:
	if _command_queue.size() > 0:
		print_rich("Debug: [color=#%s][Agent %s][/color] NOT generating new goal, commands in queue" % [debug_color, debug_id])
		return
	add_command(Command.CommandType.GENERATE_GOAL, goal)


func set_goal(new_goal: String):
	print_rich("Debug: [color=#%s][Agent %s][/color] [color=lime]%s[/color] (Goal Updated)" % [debug_color, debug_id, new_goal])
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
		#get agents by id
		var from_agent =  MessageBroker.get_agent_by_id(from_id)
		var to_agent
		if to_id != -1:
			to_agent = MessageBroker.get_agent_by_id(to_id)
		else:
			to_agent = self

		# Convert from_id to a color
		var from_color = Color.from_hsv(float(from_id) / 1000.0, 0.8, 1).to_html(false)
		print_rich("Debug: [color=#%s][Agent %s][/color] said to [color=#%s][Agent %s][/color]: %s" % [from_color, from_agent.debug_id, debug_color, to_agent.debug_id, msg])

		# Included this message in the agent's memory
		var message_memory
		if to_id == -1:
			message_memory = MessageMemory.new(msg, from_agent.name)
		else:
			message_memory = MessageMemory.new(msg, from_agent.name, "You")
		memories.add_memory(message_memory)


func script_execution_completed():
	print_rich("Debug: [color=#%s][Agent %s][/color] [color=lime]Script execution completed[/color]" % [debug_color, debug_id])


func build_prompt_context() -> String:
	"""Provides context about the game state for the LLM
	"""

	var context = ""

	if scenario_goal != "":
		context += "Your prime directive is to complete the goal: " + scenario_goal + "\n"
	
	context += "The current goal you have set for yourself is to: " + goal + "\n"
	context += "Items in your inventory: " + inventory_manager.GetInventoryData() + "\n"
	context += "Your name is " + self.name + "\n"
	context += "Current Position: (" + str(snapped(global_position.x, 0.1)) + ", " + str(snapped(global_position.y, 0.1)) + ")\n"
	context += "You do " + str(self.attack_damage) + " damage per attack.\n"
	context += "Current Time: " + str(Time.get_ticks_msec() / 1000.0) + "\n"
	context += "- All detected entities:" + _get_all_detected_entities() + "\n"
	context += "- All detected items:\n" + _get_all_detected_items() + "\n"
	context += "- All detected interactables:\n" + _get_all_detected_interactables() + "\n"
	context += "- Recent memories: " + memories.format_recent_for_prompt(10) + "\n"

	get_node("context").text = context.replace("\t", "    ")

	return context


func get_camera_view() -> String:
	"""
	Captures an image from the agent's camera and returns it as base64 encoded string.
	Returns empty string if camera is not available.
	"""
	# Create a viewport to render the camera view
	var viewport = SubViewport.new()
	add_child(viewport)
	viewport.size = Vector2i(768, 512)
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
	if false:
		var filename = "agent_view.png"
		var err = image.save_png(filename)
		if err != OK:
			print_rich("[Agent %s] [color=red]Failed to save camera view to file: %s[/color]" % [debug_id, error_string(err)])
		else:
			print_rich("[Agent %s] [color=lime]Saved camera view to: %s[/color]" % [debug_id, filename])

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
func get_memories_by_type(memory_type: String) -> Array[Memory]:
	return memories.get_by_type(memory_type)


func wait(time: float) -> bool:
	if await get_tree().create_timer(time).timeout:
		return true
	else:
		return false


# TODO: investigate effectiveness of recording actions taken by agent
func save():
	var save_dict = super()
	save_dict["goal"] = goal
	save_dict["scenario_goal"] = scenario_goal
	save_dict["max_memories"] = max_memories
	save_dict["infinite_decisions"] = infinite_decisions
	save_dict["prompt_allowance"] = prompt_allowance
	save_dict["visual_mode"] = visual_mode
	return save_dict
	
