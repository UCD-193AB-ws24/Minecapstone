class_name Command
extends Node

enum CommandType {
	GOAL,
	SCRIPT,
}
enum CommandStatus {
	WAITING,
	EXECUTING,
	DONE,
}
var agent: Agent	# Used to access hash to send to API and agent_controller
var command_type: CommandType
var command_status: CommandStatus
var command: String


func create_with(command_info: Dictionary) -> Command:
	API.response.connect(_on_response)

	command_type = command_info["type"]
	command_status = CommandStatus.WAITING
	command = command_info["command"]
	return self


func execute(_agent: Agent):
	if command_status != CommandStatus.WAITING:
		return command_status

	command_status = CommandStatus.EXECUTING

	agent = _agent

	if command_type == CommandType.GOAL:
		API.prompt_llm(command, agent.hash_id)
		command_status = CommandStatus.DONE
		# API will emit response signal emit containing (key, response_string)
	elif command_type == CommandType.SCRIPT:
		# TODO: evaluate necessity of a "CommandType" if the script is always ran after generating a response from the goal
		agent.run_script(command)
		command_status = CommandStatus.DONE

	return command_status


# Handles the response from API
func _on_response(key: int, response: String):
	# Ensure the response is for this agent
	if !agent or key != agent.hash_id: return

	# Run dangerously set AI-generated code.
	if (await run_script(response)):
		print("Script created by agent successful.")
	else:
		print("Script created by agent failed.")


# Do not modify this function, it is used to run the script created by the LLM
func run_script(input: String):
	var source = agent.agent_controller.get_script().get_source_code().replace(
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
	var result = await instance.setup(agent).eval(0)

	return result
