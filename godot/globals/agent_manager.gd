# Global Autoloaded Singleton Class: AgentManager
extends Node

class AgentEntry:
	var agent_ref: Agent
	var agent_hash_id: int

	func get_ref():
		return agent_ref
	func get_id():
		return agent_hash_id

var agent_dict = {}

func register_agent(agent: Agent) -> void:
	"""Register an agent with the agent manager."""
	var agent_entry = AgentEntry.new()
	agent_entry.agent_ref = agent
	agent_entry.agent_hash_id = agent.hash_id
	agent_dict[agent.name] = agent_entry
	# print("AgentManager: Registered agent " + agent.name + " with ID " + str(agent.hash_id))

func get_agent(agent_name:String):
	if agent_dict.has(agent_name):
		return agent_dict[agent_name]
	else:
		#name not found in agent_dict
		return null

# darroll: added to get all agents for memory provision
func get_agents():
	return agent_dict.values()

func give_all_agents_memory(memory: Memory):
	"""Give a memory to all agents."""
	for agent_entry in agent_dict.values():
		var agent = agent_entry.get_ref()
		if agent:
			agent.memories.add_memory(memory)

func get_agent_name(agent_id:int):
	"""Get an agent by its ID."""
	return agent_dict.find_key(agent_id)

func clear_agents():
	"""Clears all agents from the agent manager."""
	agent_dict.clear()
