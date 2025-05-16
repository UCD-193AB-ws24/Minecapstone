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
	label.text = "Moving to position: " + str(x) + ", " + str(y)
	return await agent.move_to_position(x, y, 1.5)


func move_to_target(target_name: String, distance_away: float = 2.0):
	label.text = "Moving to target: " + target_name
	return await agent.move_to_target(target_name, distance_away)


func look_at_target(target_name: String):
	label.text = "Looking at target: " + target_name
	agent.look_at_target_by_name(target_name)


func attack_target(target_name: String, num_attacks: int = 1):
	label.text = "Attacking entity " + target_name + " " + str(num_attacks) + " times."
	await agent.attack_target(target_name, num_attacks)


func discard(itemName: String, amount: int):
	label.text = "Discarding item: " + itemName + ", amount: " + str(amount)
	agent.discard_item(itemName, amount)


func give_to(agent_name: String, item_name: String, amount: int = 1):
	label.text = "Giving " + str(amount) + " " + item_name + " to " + agent_name
	agent.give_to(agent_name, item_name, amount)


func say(msg: String) -> void:
	message_broker.send_message(msg, agent.hash_id)


func say_to(msg: String, target_agent: String) -> void:
	var target_id = AgentManager.get_agent(target_agent).agent_hash_id
	message_broker.send_message(msg, agent.hash_id, target_id)


func pick_up_item(item_name: String):
	label.text = "Picking up item: " + item_name
	agent.pick_up_item(item_name)


func break_block(coordinates: Vector3i):
	label.text = "Breaking block at: " + str(coordinates)
	agent.break_block(coordinates)


func place_block(coordinates: Vector3i):
	label.text = "Placing block at: " + str(coordinates)
	agent.place_block(coordinates)


func eat_food(food_name: String = "") -> void:
	var success = agent.eat_food(food_name)
	if success:
		label.text = "Successfully ate food"
	else:
		label.text = "Failed to eat food"


func eval():
	return true

# func set_goal(goal_description: String):
# 	agent.set_goal(goal_description)
# 	return true
