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


func move_to_position(x: float, y: float, distance_away:float=1.0):
	label.text = "Moving to position: " + str(x) + ", " + str(y)
	await agent.move_to_position(x, y, distance_away)


func move_to_target(target_name: String, distance_away:float=1.0):
	label.text = "Moving to target: " + target_name
	await agent.move_to_target(target_name, distance_away)


func look_at_target(target_name: String):
	label.text = "Looking at target: " + target_name
	agent.look_at_target_by_name(target_name)


func attack_target(target_name: String, num_attacks: int = 1):
	label.text = "Attacking entity " + target_name + " " + str(num_attacks) + " times."
	await agent.attack_target(target_name, num_attacks)


func discard(itemName: String, amount: int):
	label.text = "Discarding item: " + itemName + ", amount: " + str(amount)
	agent.discard_item(itemName, amount)

func give_to(agent_name:String, item_name:String, amount:int = 1):
	label.text = "Giving " + str(amount) + " "+ item_name + " to " + agent_name
	agent.give_to(agent_name, item_name, amount)


func say(msg: String) -> void:
	message_broker.send_message(msg, agent.hash_id)
	# agent.record_action("Said: " + msg)


func say_to(msg: String, target_agent: String) -> void:
	var target_id = AgentManager.get_agent(target_agent).agent_hash_id
	message_broker.send_message(msg, agent.hash_id, target_id)
	# agent.record_action("Said to " + str(target_id) + ": " + msg)


func eat_food():
	# Currently hardcoded to restore 10 hunger
	label.text = "Eating food, restored 10 hunger"
	agent.eat_food(10)


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
