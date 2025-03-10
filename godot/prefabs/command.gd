class_name Command
extends Node

enum CommandType {
	LLM_REQUEST,
	SCRIPT,
	GOAL_UPDATE,
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
	command_type = command_info["type"]
	command_status = CommandStatus.WAITING
	command = command_info["command"]
	agent = command_info["agent"]
	
	# Only connect if GOAL command
	if command_type == CommandType.LLM_REQUEST:
		API.response.connect(_LLM_set_goal)
		
	return self


func execute(_agent: Agent):
	if command_status != CommandStatus.WAITING:
		return command_status

	command_status = CommandStatus.EXECUTING
	
	match command_type:
		CommandType.LLM_REQUEST:
			var context = agent._build_prompt_context()
			API.prompt_llm(context, agent.hash_id)
			
		CommandType.SCRIPT:
			_execute_script()
		
		CommandType.GOAL_UPDATE:
			agent.goal = command
			agent._memory.add_goal_update(command)
			print("Debug: [Agent %s] Goal updated to: %s" % [agent.hash_id, command])
			command_status = CommandStatus.DONE
		
	return command_status
			

func _execute_script() -> void:
	# print("Debug: [Agent %s] Executing script: %s" % [agent.hash_id, command])
	
	# Run script
	await self.run_script(command)
	
	# Mark command as done and notify agent
	command_status = CommandStatus.DONE
	agent.script_execution_completed()

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


# Do not modify this function, it is used to run the script created by the LLM
func run_script(input: String):
	var source = agent.agent_controller.get_script().get_source_code().replace(
		"class_name AgentController\nextends Node", 
		"extends RefCounted").replace(
		"func eval():\n\treturn true",
		"func eval():\n%s\n\treturn true" % input)

	# TODO: remove debug print
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
