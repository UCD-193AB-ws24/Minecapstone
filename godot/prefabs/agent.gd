class_name Agent extends NPC


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
		set_goal("Walk in a circle of radius 5.")


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

	if (run_script(response)):  # Pass raw code directly
		print("True")
	else:
		print("False")


func run_script(input: String):
	var script : Script = agent_controller.get_script()
	
	var source = script.get_source_code() + """
func eval():
%s
	return true
""" % ("\t" + input.replace("\n", "\n\t"))

# 	var script = GDScript.new()
# 	var source = """
# extends RefCounted

# var agent: Agent
# var position: Vector2

# func setup(target_agent: Agent):
# 	self.agent = target_agent
# 	self.position = target_agent.position
# 	return self

# func move_to_position(x: float, y: float):
# 	agent.navigate_to(Vector2(x, y))



# 	script.set_source_code(source)
# 	var err = script.reload()
# 	if err != OK:
# 		print("Script error: ", err)
# 		return false

# 	var instance = RefCounted.new()
# 	instance.set_script(script)
# 	return instance.setup(self).eval()


# func _physics_process(delta):
# 	super(delta)
