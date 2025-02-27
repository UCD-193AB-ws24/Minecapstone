class_name AgentController
extends Node

var agent: Agent
var position: Vector3
var label: Label3D
var message_broker = MessageBroker

func setup(target_agent: Agent):
	self.agent = target_agent
	self.position = target_agent.position
	self.label = agent.get_node("Label3D")
	return self

func _physics_process(delta: float) -> void:
	eval(delta)

func move_to_position(x: float, y: float):
	# print("Moving to position: ", x, " ", y)
	label.text = "Moving to position: " + str(x) + ", " + str(y)
	agent.set_movement_target(Vector3(x, 0, y))

	await agent.navigation_agent.target_reached
	return true

# func get_nearby_agents() -> Array:
# 	var message_broker = agent.get_node("/root/MessageHandler")
# 	var nearby_agents: Array[int] = []
	
# 	for agent_id in message_broker.get_all_agent_ids():
# 		if agent_id != agent.hash_id:
# 			var other_agent = message_broker.get_agent_by_id(agent_id)
# 			var distance = agent.global_position.distance_to(other_agent.global_position)
# 			if distance < 30: # Arbitrary distance
# 				nearby_agents.append(agent_id)
				
# 	return nearby_agents

func say(msg: String) -> void:
	message_broker.send_message(msg, agent.hash_id)

func say_to(msg: String, target_id: int) -> void:
	message_broker.send_message(msg, agent.hash_id, target_id)

func eval(delta):
	delta = delta
	return true