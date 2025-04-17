# Global Singleton Class_Name: MessageBroker
extends Node


signal message(msg: String, from_id: int, to_id: int)


# Store hash_ids of agents
var agents: Dictionary = {}


@export var min_time_between_messages: float = 2.0
var last_message_time: float = 0.0
var waiting: bool = false


func register_agent(agent: Agent) -> void:
	if agent.process_mode == Node.PROCESS_MODE_INHERIT:
		agents[agent.hash_id] = agent
		# Assign a consistent color based on hash_id
		print_rich("[color=#%s][Agent %s][/color] registered as %s" % [agent.debug_color, agent.debug_id, agent.name])


func unregister_agent(agent: Agent) -> void:
	agents.erase(agent.hash_id)


func send_message(msg: String, from_id: int, to_id: int = -1) -> bool:
	# TODO: check if to_id is a valid agent, inform source agent if failed

	if to_id == -1:
		print_rich("[color=yellow][%s]: %s[/color]" % [from_id, msg])
	else:	
		print_rich("[color=yellow][%s] to [%s]: %s[/color]" % [from_id, to_id, msg])

	message.emit(msg, from_id, to_id)
	return true


func get_agent_by_id(agent_id: int) -> Agent:
	return agents.get(agent_id)

func get_all_agent_ids() -> Array:
	return agents.keys()
