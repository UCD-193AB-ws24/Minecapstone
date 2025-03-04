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
var start_time: float = 0.0
@export var timeout_seconds: float = 15.0 # 15 second time out


func create_with(command_info: Dictionary) -> Command:
	command_type = command_info["type"]
	command_status = CommandStatus.WAITING
	command = command_info["command"]
	agent = command_info["agent"]
	
	# Only connect if GOAL command
	if command_type == CommandType.GOAL:
		API.response.connect(_on_response)
		
	return self


func execute(_agent: Agent):
	if command_status != CommandStatus.WAITING:
		return command_status

	command_status = CommandStatus.EXECUTING
	start_time = Time.get_ticks_msec() / 1000.0 

	if command_type == CommandType.GOAL:
		API.prompt_llm(command, agent.hash_id)
		command_status = CommandStatus.DONE
		# API will emit response signal emit containing (key, response_string)
	elif command_type == CommandType.SCRIPT:
		# TODO: evaluate necessity of a "CommandType" if the script is always ran after generating a response from the goal
		agent.run_script(command)
		command_status = CommandStatus.DONE
		
	# Timeout functionality
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - start_time > timeout_seconds:
		print("Command timed out")
		command_status = CommandStatus.DONE

	return command_status


# Handles the response from API
func _on_response(key: int, response: String):
	# Ensure the response is for this agent
	if !agent or key != agent.hash_id: return
	
	if API.response.is_connected(_on_response):
		API.response.disconnect(_on_response)
		
	# Create new script
	var script_command = Command.new().create_with({
		"agent": agent,
		"type": CommandType.SCRIPT,
		"command": response
	})
	
	agent._command_queue.append(script_command)
	
	command_status = CommandStatus.DONE


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
