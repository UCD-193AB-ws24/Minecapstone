class_name Command
extends Node


enum CommandType {
	GENERATE_GOAL,		# Generates a new goal using current context
	GENERATE_SCRIPT,	# Generates a script using the given goal
	SCRIPT,				# Executes the script
}
enum CommandStatus {
	WAITING,
	EXECUTING,
	DONE,
}
var agent: Agent	# Used to access hash to send to API and agent_controller
var command_type: CommandType
var command_status: CommandStatus
var command_input: String


func execute(_agent: Agent):
	"""This function is called by the agent to execute the command.
		It will call the appropriate function based on the command type.
	"""
	if command_status != CommandStatus.WAITING:
		return command_status

	command_status = CommandStatus.EXECUTING
	
	match command_type:
		CommandType.GENERATE_GOAL:
			"""Will call _LLM_set_goal when response is received"""
			var context = agent.build_prompt_context()

			# Generate goal using LLM, passing context and image data if visual mode is enabled
			if agent.visual_mode:
				var image_data = await agent.get_camera_view()
				API.generate_goal(context, agent.hash_id, image_data)
			else:
				API.generate_goal(context, agent.hash_id)
		CommandType.GENERATE_SCRIPT:
			"""Will call _LLM_execute_script when response is received"""
			var context = agent.build_prompt_context()
			var goal = command_input
			var full_prompt = "Goal: " + goal + "\n" + context
			
			# Generate script using LLM, passing context and image data if visual mode is enabled
			if agent.visual_mode:
				var image_data = await agent.get_camera_view()
				API.generate_script(full_prompt, agent.hash_id, image_data)
			else:
				API.generate_script(full_prompt, agent.hash_id)
		CommandType.SCRIPT:
			_execute_script()

	return command_status


func create_with(command_info: Dictionary) -> Command:
	""" Creates a new command with the given information.
		Used to create a command from the agent's command queue.
		- command_info: a dictionary containing the command information
			- agent: the agent that created this command
			- type: the type of command (CommandType)
			- input: the input for the command (String)
	"""
	command_type = command_info["type"]
	command_status = CommandStatus.WAITING
	command_input = command_info["input"]
	agent = command_info["agent"]
	
	match command_type:
		CommandType.GENERATE_GOAL:
			API.response.connect(_LLM_set_goal)
		CommandType.GENERATE_SCRIPT:
			API.response.connect(_LLM_execute_script)
		
	return self


func _LLM_set_goal(key: int, response: String):
	""" Handles the response from API, used only if this command is a GENERATE_GOAL
		- key: the agent's hash_id
		- response: the generated goal
	"""
	# Ensure the response is for this agent
	if !agent or key != agent.hash_id: return

	if API.response.is_connected(_LLM_set_goal):
		API.response.disconnect(_LLM_set_goal)

	# Then, set the goal to the LLM generated one
	agent.set_goal(response)
	agent.memories.add_goal_update(response)

	command_status = CommandStatus.DONE


func _LLM_execute_script(key: int, response: String):
	""" Handles the response from API, used only if this command is a GENERATE_SCRIPT
		- key: the agent's hash_id
		- response: the generated script
	"""
	# Ensure the response is for this agent
	if !agent or key != agent.hash_id: return

	if API.response.is_connected(_LLM_execute_script):
		API.response.disconnect(_LLM_execute_script)

	# Then, run the generated script
	agent.add_command(CommandType.SCRIPT, response)

	command_status = CommandStatus.DONE


func _execute_script() -> void:
	""" Executes the generated script where command_input is the script to be executed.
		- command_input: the script to be executed
	"""
	# Run script
	await self.run_script(command_input)
	
	# Mark command as done and notify agent
	command_status = CommandStatus.DONE
	agent.script_execution_completed()


func run_script(input: String):
	""" Runs the script created by the LLM.
		Do not modify this function unless you know what you are doing.
		- input: the script to be executed
	"""
	# TODO: replace RefCounted replacement with something that extends AgentController,
	# so that the debugger works properly on AgentController
	var source = agent.agent_controller.get_script().get_source_code().replace(
		"class_name AgentController\nextends Node", 
		"extends RefCounted").replace(
		"func eval():\n\treturn true",
		"func eval():\n%s\n\treturn true" % input)

	print_rich("Debug: Agent performing [color=cornflower_blue]%s[/color]" % input)

	# Dangerously created script
	var script = GDScript.new()
	script.set_source_code(source)

	var err = script.reload()
	if err != OK:
		print("Script error: ", err)
		return false

	var instance = RefCounted.new()
	instance.set_script(script)
	var result = await instance.setup(agent).eval()

	return result
