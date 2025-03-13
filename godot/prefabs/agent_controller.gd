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

	# TODO: replace with a loop that checks if the agent has reached the target, instead of waiting for a signal
	# Waiting for signal blocks the agent from doing anything else?... i had a better reason... it's 12 am..
	await agent.navigation_agent.target_reached
	return true

func move_to_current_target():
	# print("Moving to position: ", x, " ", y)
	label.text = "Moving to position of target: " + agent.target_entity.name 
	agent.set_movement_target(agent.target_entity.global_position)

func select_nearest_entity_type(target: String):
	label.text = "Selecting nearest target of type: " + target
	agent._select_nearest_target(target)

func attack_selected_target(count: int = 1):
	label.text = "Attacking entity " + str(count) + " times."
	
	await agent._handle_attacking(count)

# Need to implement attacking specific entities
#func attack_target_entity():
	#label.text = "Attacking entity: " + entity
	#agent._attack_entity()


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
	
func eat_food():
	# Currently hardcoded to restore 10 hunger
	agent.eat_food(10)
	label.text = "Eating food, restored 10 hunger"
	return true


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
