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
	"""return agent's global position"""
	return agent.global_position



func move_to_position(x: float, y: float, distance_away:float=1.0):
	"""moves agent to the given x, y coordinates at a distance determined by distance_away"""
	label.text = "Moving to position: " + str(x) + ", " + str(y)
	#await agent.move_to_position(x, y, distance_away)
	await check_and_exec("agent.move_to_position(x, y, distance_away)", ["x", "y", "distance_away"], [x, y, distance_away])


func move_to_target(target_name: String, distance_away:float=1.0):
	"""moves agent to the given target at a distance determined by distance_away"""
	label.text = "Moving to target: " + target_name
	#await agent.move_to_target(target_name, distance_away)
	await check_and_exec("agent.move_to_target(target_name, distance_away)", ["target_name", "distance_away"], [target_name, distance_away])


func look_at_target(target_name: String):
	"""agent looks at the given target. NOTE: agent will be looking at the target's feet when using this function"""
	label.text = "Looking at target: " + target_name
	#agent.look_at_target_by_name(target_name)
	await check_and_exec("agent.look_at_target_by_name(target_name)", ["target_name"], [target_name])


func attack_target(target_name: String, num_attacks: int = 1):
	"""agent attacks the given target a number of times as determined by num_attacks"""
	label.text = "Attacking entity " + target_name + " " + str(num_attacks) + " times."
	#await agent.attack_target(target_name, num_attacks)
	await check_and_exec("agent.attack_target(target_name, num_attacks)", ["target_name", "num_attacks"], [target_name, num_attacks])

func discard(itemName: String, amount: int):
	"""agent discards the item in its inventory in the specified amount"""
	label.text = "Discarding item: " + itemName + ", amount: " + str(amount)
	#agent.discard_item(itemName, amount)
	await check_and_exec("agent.discard_item(itemName, amount)", ["itemName", "amount"], [itemName, amount])

func give_to(agent_name:String, item_name:String, amount:int = 1):
	"""agent moves to agent called agent_name and gives the item in the specified amount"""
	label.text = "Giving " + str(amount) + " "+ item_name + " to " + agent_name
	#agent.give_to(agent_name, item_name, amount)
	await check_and_exec("agent.give_to(agent_name, item_name, amount)", ["agent_name", "item_name", "amount"], [agent_name, item_name, amount])


func say(msg: String) -> void:
	"""agent broadcast its message for all other agents to hear"""
	#message_broker.send_message(msg, agent.hash_id)
	await check_and_exec("message_broker.send_message(msg, agent.hash_id)", ["msg"], [msg])
	# agent.record_action("Said: " + msg)


func say_to(msg: String, target_agent: String) -> void:
	"""agent sends a message to the target agent"""
	#var target_id = AgentManager.get_agent(target_agent).agent_hash_id
	var target_id = await check_and_exec("AgentManager.get_agent(target_agent).agent_hash_id", ["target_agent"], [target_agent])
	#message_broker.send_message(msg, agent.hash_id, target_id)
	await check_and_exec("message_broker.send_message(msg, agent.hash_id, target_id)", ["msg", "agent.hash_id", "target_id"], [msg, agent.hash_id, target_id])
	# agent.record_action("Said to " + str(target_id) + ": " + msg)


func eat_food():
	"""agent eats food to restore hunger"""
	# Currently hardcoded to restore 10 hunger
	label.text = "Eating food, restored 10 hunger"
	agent.eat_food(10)

func check_and_exec(func_name, parameter_names = [], parameter_values = []):
	"""Check for errors in func_name send any errors to error handler
	check_and_exec is considered a coroutine so it must be used with await
	"""
	var expression = Expression.new()
	#parse function and check for errors
	var error = expression.parse(func_name, parameter_names)
	if error != OK:
		print("Parsing: Error in function call: ", func_name, " with parameters: ", parameter_names)
		print("parse error text:", expression.get_error_text())
		return 
	
	#execute function and check for errors
	var result = await expression.execute(parameter_values, self)
	if expression.has_execute_failed():
		print("Execution: Error in function call: ", func_name, " with parameters: ", parameter_names)
		print("execute error text:", expression.get_error_text())
		return 
	
	#no parsing or execution errors so just return the result of the execution if there is one
	return result


func eval():
	return true

# func set_goal(goal_description: String):
# 	agent.set_goal(goal_description)
# 	return true
