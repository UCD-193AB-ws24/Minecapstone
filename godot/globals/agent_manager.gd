# Global Autoloaded Singleton Class: AgentManager
extends Node

var agent_dict = {}
var world
var agent_scene = preload("res://prefabs/player/agent.tscn")

func _ready() -> void:
	world = self.get_parent()
	#find all agents placed through Godot editor
	for node in world.get_children():
		if not (node.has_meta("Name")):
			continue
		var node_meta_name = node.get_meta("Name")
		if node_meta_name == "agent":
			agent_dict[node.name] = node

func spawn_agent(agent_name:String):
	
	var agent_instance = agent_scene.instantiate()
	agent_instance.name = agent_name
	agent_dict[agent_name] = agent_instance
	world.add_child(agent_instance)

func get_agent(agent_name:String):
	return agent_dict[agent_name]
