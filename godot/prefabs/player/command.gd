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

# TODO: find a way to just get the string from agent_controller.gd, using FileAccess returns null and using the object.get_script is broken on packaged builds
var agent_controller_str = "class_name AgentController\nextends Node\nvar agent: Agent\nvar position: Vector3\nvar label: Label3D\nvar message_broker = MessageBroker\nfunc setup(target_agent: Agent):\n\tself.agent = target_agent\n\tself.position = target_agent.position\n\tself.label = agent.get_node(\"Label3D\")\n\treturn self\nfunc get_position() -> Vector3:\n\treturn agent.global_position\nfunc move_to_position(x: float, y: float):\n\tlabel.text = \"Moving to position: \" + str(x) + \", \" + str(y)\n\tvar result = await agent.move_to_position(x, y, 2)\n\tif result == true:\n\t\tvar memory = Memory.new(\"You moved to position \" + str(x) + \", \" + str(y))\n\t\tagent.memories.add_memory(memory)\n\telse:\n\t\tvar memory = Memory.new(\"You failed to move to position \" + str(x) + \", \" + str(y))\n\t\tagent.memories.add_memory(memory)\n\treturn result\nfunc move_to_target(target_name: String, distance_away: float = 2.0):\n\tlabel.text = \"Moving to target: \" + target_name\n\tvar result = await agent.move_to_target(target_name, distance_away)\n\tif result == true:\n\t\tvar memory = Memory.new(\"You moved to the target \" + target_name)\n\t\tagent.memories.add_memory(memory)\n\telse:\n\t\tvar memory = Memory.new(\"You failed to move to the target \" + target_name)\n\t\tagent.memories.add_memory(memory)\n\treturn result\nfunc look_at_target(target_name: String):\n\tlabel.text = \"Looking at target: \" + target_name\n\tagent.look_at_target_by_name(target_name)\nfunc attack_target(target_name: String, num_attacks: int = 1):\n\tlabel.text = \"Attacking entity \" + target_name + \" \" + str(num_attacks) + \" times.\"\n\treturn await agent.attack_target(target_name, num_attacks)\nfunc discard(itemName: String, amount: int):\n\tlabel.text = \"Discarding item: \" + itemName + \", amount: \" + str(amount)\n\tagent.discard_item(itemName, amount)\nfunc give_to(agent_name: String, item_name: String, amount: int = 1):\n\tlabel.text = \"Giving \" + str(amount) + \" \" + item_name + \" to \" + agent_name\n\tagent.give_to(agent_name, item_name, amount)\nfunc wait(time: float):\n\tlabel.text = \"Waiting for \" + str(time) + \" seconds.\"\n\tawait agent.wait(time)\nfunc say(msg: String) -> void:\n\tmessage_broker.send_message(msg, agent.hash_id)\n\tvar message_memory = MessageMemory.new(msg, \"You\")\n\tagent.memories.add_memory(message_memory)\nfunc say_to(msg: String, target_agent: String) -> void:\n\tvar target_id = AgentManager.get_agent(target_agent).agent_hash_id\n\tmessage_broker.send_message(msg, agent.hash_id, target_id)\n\tvar message_memory = MessageMemory.new(msg, \"You\", target_agent)\n\tagent.memories.add_memory(message_memory)\nfunc pick_up_item(item_name: String):\n\tlabel.text = \"Picking up item: \" + item_name\n\tagent.pick_up_item(item_name)\nfunc break_block(coordinates: Vector3i):\n\tlabel.text = \"Breaking block at: \" + str(coordinates)\n\tagent.break_block(coordinates)\nfunc place_block(coordinates: Vector3i):\n\tlabel.text = \"Placing block at: \" + str(coordinates)\n\tagent.place_block(coordinates)\nfunc eat_food(food_name: String = \"\") -> void:\n\tfor i in range(16):\n\t\tawait agent.get_tree().physics_frame\n\tagent.call_deferred(\"eat_food\", food_name)\n\nfunc eval():\n\treturn true"

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
	# This line has an issue not sure how to fix :/
	
	#var agent_file = FileAccess.open("res://globals/agent_controller.gd", FileAccess.READ)
	var source = agent_controller_str.replace(
	#var source = agent.agent_controller.get_script().get_source_code().replace(
		"class_name AgentController\nextends Node",
		"extends RefCounted").replace(
		"func eval():\n\treturn true",
		"func eval():\n%s\n\treturn true" % input)

	print_rich("Debug: [color=#%s][Agent %s][/color] performing [color=cornflower_blue]%s[/color]" % [agent.debug_color, agent.debug_id, input])
	#print("Has source " + str(agent.agent_controller.get_script().has_source_code()))

	# Dangerously created script
	var script = GDScript.new()
	script.set_source_code(source)

	var start_pattern = "performing"
	var end_pattern = "An error has occurred. Attempting to fix self..."

	var err = script.reload()
	if err != OK:
		print_rich("[color=#FF786B]%s %s[/color]" % [end_pattern, err])
		# Log the error to the system log
		var file:FileAccess = FileAccess.open("user://logs/godot.log", FileAccess.READ)
		var content = file.get_as_text()

		var start = content.rfind(start_pattern) + len(start_pattern)
		var end = content.rfind(end_pattern)
		content = content.substr(start, end - start)
		content = content.strip_edges()
		printerr(content)

		if agent.self_fix_mode:
			agent.add_command(CommandType.GENERATE_SCRIPT, content)

		var sm:ScenarioManager = agent.get_parent().find_child("ScenarioManager")
		if sm: 
			sm.track_error()

		return false

	var instance = RefCounted.new()
	instance.set_script(script)
	var result = await instance.setup(agent).eval()

	return result
