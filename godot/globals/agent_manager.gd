# Global Autoloaded Singleton Class: AgentManager
extends Node

class AgentEntry:
	var agent_ref: Node3D
	var agent_hash_id: int

	func get_ref():
		return agent_ref
	func get_id():
		return agent_hash_id

var agent_dict = {}


# func _ready() -> void:
# 	#find all agents placed through Godot editor
# 	for node in get_tree().current_scene.get_children():
# 		if not (node.has_meta("Name")):
# 			continue
# 		var node_meta_name = node.get_meta("Name")
# 		if node_meta_name == "agent":
# 			var agent_entry = AgentEntry.new()
# 			agent_entry.agent_ref = node as Agent
# 			# print("agent entry is ", agent_entry.agent_ref)
# 			if node.name != "Player":
# 				agent_entry.agent_hash_id = node.hash_id
# 			print("added " + node.name + " with id " + str(agent_entry.agent_hash_id) + " to agent_dict")
# 			agent_dict[node.name] = agent_entry
# 			# print(node.name, " is registered")


#func spawn_agent(agent_name:String):
	#var agent_instance = agent_scene.instantiate()
	#agent_instance.name = agent_name
	#agent_dict[agent_name] = agent_instance
	#world.add_child(agent_instance)

func register_agent(agent: Agent) -> void:
	"""Register an agent with the agent manager."""
	var agent_entry = AgentEntry.new()
	agent_entry.agent_ref = agent
	agent_entry.agent_hash_id = agent.hash_id
	agent_dict[agent.name] = agent_entry
	print("AgentManager: Registered agent " + agent.name + " with ID " + str(agent.hash_id))

func get_agent(agent_name:String):
	if agent_dict.has(agent_name):
		return agent_dict[agent_name]
	else:
		#name not found in agent_dict
		return null

func get_agent_name(agent_id:int):
	"""Get an agent by its ID."""
	return agent_dict.find_key(agent_id)

func clear_agents():
	"""Clears all agents from the agent manager."""
	agent_dict.clear()
