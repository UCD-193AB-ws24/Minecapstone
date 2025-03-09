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
	
	if command_type == CommandType.GOAL:
		API.response.connect(_LLM_set_goal)
		
	return self


# Handles the response from API, used only if this command is a GOAL
func _LLM_set_goal(key: int, response: String):
	# Ensure the response is for this agent
	if !agent or key != agent.hash_id: return

	if API.response.is_connected(_LLM_set_goal):
		API.response.disconnect(_LLM_set_goal)

	# Next command after goal is to run the SCRIPT
	var command_info = {
		"agent": agent,
		"type": CommandType.SCRIPT,
		"command": response
	}
	agent.add_command(command_info)

	command_status = CommandStatus.DONE


func execute(_agent: Agent):
	if command_status != CommandStatus.WAITING:
		return command_status

	command_status = CommandStatus.EXECUTING
	start_time = Time.get_ticks_msec() / 1000.0 

	match command_type:
		CommandType.GOAL:
			print("Debug: [Agent " + str(agent.hash_id) + "] prompting LLM with goal: ", command)
			API.prompt_llm(command, agent.hash_id)
			command_status = CommandStatus.EXECUTING
			# API will emit response signal emit containing (key, response_string)
		CommandType.SCRIPT:
			var script_result = await self.run_script(command)
			agent.script_execution_completed()
			command_status = CommandStatus.DONE

	# Timeout functionality
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - start_time > timeout_seconds:
		print("Command timed out")
		command_status = CommandStatus.DONE

	return command_status


# Do not modify this function, it is used to run the script created by the LLM
# Asynchronously completes when the script is done running
func run_script(input: String):
	var source = agent.agent_controller.get_script().get_source_code().replace(
		"class_name AgentController\nextends Node", 
		"extends RefCounted").replace(
		"func eval():\n\treturn true",
		"func eval():\n%s\n\treturn true" % input)

	# TODO: remove debug print
	print("Debug: [Agent " + str(agent.hash_id) + "] performing script.")

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
