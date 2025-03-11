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


func get_position() -> Vector3:
	return agent.global_position


func move_to_position(x: float, y: float):
	# print("Moving to position: ", x, " ", y)
	label.text = "Moving to position: " + str(x) + ", " + str(y)
	agent.set_movement_target(Vector3(x,0,y))

	await agent.navigation_agent.target_reached
	return true

func discard(itemName: String, amount: int):
	# TODO: remove debug print
	print("dropping ", amount , " ", itemName, )
	agent.discard_item(itemName, amount)


func get_nearby_agents() -> Array:
	var nearby = []
	var all_ids = message_broker.get_all_agent_ids()
	
	for id in all_ids:
		if id != agent.hash_id:
			var other_agent = message_broker.get_agent_by_id(id)
			if other_agent:
				var distance = agent.global_position.distance_to(other_agent.global_position)
				if distance < 30:
					nearby.append(id)

	return nearby


func say(msg: String) -> void:
	message_broker.send_message(msg, agent.hash_id)
	# agent.record_action("Said: " + msg)


func say_to(msg: String, target_id: int) -> void:
	message_broker.send_message(msg, agent.hash_id, target_id)
	# agent.record_action("Said to " + str(target_id) + ": " + msg)


func eval():
	return true


# ============================== Goal management================================


func set_goal(goal_description: String):
	agent.set_goal(goal_description)
	return true


# TODO: We should automatically determine whether a goal is completed or failed
# not the agent, somehow.
# func set_goal(goal_description: String):
# 	agent.set_goal_status(Agent.GoalStatus.IN_PROGRESS, goal_description)
# 	agent.record_action("Set new goal: " + goal_description)
# 	return true
	
# func complete_goal():
# 	agent.set_goal_status(Agent.GoalStatus.COMPLETED)
# 	agent.record_action("Completed goal: " + agent.goal)
# 	return true
	
# func fail_goal():
# 	agent.set_goal_status(Agent.GoalStatus.FAILED)
# 	agent.record_action("Failed goal: " + agent.goal)
# 	return true
