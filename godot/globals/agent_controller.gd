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


func select_nearest_entity_type(target: String=""):
	label.text = "Selecting nearest target of type: " + target
	agent.select_nearest_target(target)


func move_to_current_target(distance_away:float=1.0):
	label.text = "Moving to position of target: " + agent.current_target.name 
	await agent.move_to_current_target(distance_away)


func look_at_current_target():
	agent.look_at_current_target()


func attack_current_target(num_attacks: int = 1):	
	label.text = "Attacking entity " + str(num_attacks) + " times."
	await agent._attack_current_target(num_attacks)


func discard(itemName: String, amount: int):
	label.text = "Discarding item: " + itemName + ", amount: " + str(amount)
	agent.discard_item(itemName, amount)


func say(msg: String) -> void:
	message_broker.send_message(msg, agent.hash_id)
	# agent.record_action("Said: " + msg)


func say_to(msg: String, target_id: int) -> void:
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
