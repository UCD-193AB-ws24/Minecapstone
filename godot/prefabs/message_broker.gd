class_name MessageBroker
extends Node

signal message_received(from_id: int, to_id: int, content: String)

# Store hash_ids of agents
var agents: Dictionary = {}

func register_agent(agent: Agent) -> void:
	agents[agent.hash_id] = agent
	print("Registered agent with hash_id ", agent.hash_id)
	
func unregister_agent(agent: Agent) -> void:
	agents.erase(agent.hash_id)

func send_message(from_id: int, to_id: int, content: String) -> bool:
	if not agents.has(to_id):
		print("Target agent not found")
		return false
	
	message_received.emit(from_id, to_id, content)
	return true
	
func get_agent_by_id(agent_id: int) -> Agent:
	return agents.get(agent_id)

func get_all_agent_ids() -> Array:
	return agents.keys()
