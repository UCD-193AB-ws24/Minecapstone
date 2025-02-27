class_name MessageBroker
extends Node

signal message_received(from_id: int, to_id: int, content: String)

# Store hash_ids of agents
var agents: Dictionary = {}

@export var min_time_between_messages: float = 2.0
var last_message_time: float = 0.0
var waiting: bool = false

func register_agent(agent: Agent) -> void:
	agents[agent.hash_id] = agent
	print("Registered agent with hash_id ", agent.hash_id)
	
func unregister_agent(agent: Agent) -> void:
	agents.erase(agent.hash_id)

func send_message(from_id: int, to_id: int, content: String) -> bool:
	if not agents.has(to_id):
		print("Target agent not found")
		return false
		
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_since_last = current_time - last_message_time
	
	if time_since_last < min_time_between_messages and not waiting:
		var wait_time = min_time_between_messages - time_since_last
		
		waiting = true
		
		await get_tree().create_timer(wait_time).timeout
		waiting = false
	
	last_message_time = Time.get_ticks_msec() / 1000.0
	
	message_received.emit(from_id, to_id, content)
	return true
	
func get_agent_by_id(agent_id: int) -> Agent:
	return agents.get(agent_id)

func get_all_agent_ids() -> Array:
	return agents.keys()
