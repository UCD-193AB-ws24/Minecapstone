class_name Agent extends NPC

signal movement_completed

@onready var goal : String = ""
@onready var hash_id : int = hash(self)
@onready var agent_controller = $AgentController


func _ready() -> void:
	super()
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
		set_goal("Move to (-15, 0). Then, move back to (0,0).")


# Prompts the LLM based on the agent's goal
func set_goal(new_goal:String):
	self.goal = new_goal
	print("Goal set to: ", new_goal)

	# Prompt the LLM with the goal, and passing the identifier of this agent
	API.prompt_llm(self.goal, self.hash_id)


# Handles the response from the LLM
func _on_response(key, response: String):
	# Ensure the response is for this agent
	if key != self.hash_id: return

	# Run dangerously set AI-generated code.
	if (await run_script(response)):
		print("Script created by agent successful.")
	else:
		print("Script created by agent failed.")

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
	return await instance.setup(self).eval(0)


# Use this function to emit signals
func _physics_process(delta):
	super(delta)
	if navigation_agent.is_navigation_finished():
		movement_completed.emit()
