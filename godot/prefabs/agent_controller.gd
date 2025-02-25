class_name AgentController
extends Node

var agent: Agent
var position: Vector3
var label: Label3D

func setup(target_agent: Agent):
	self.agent = target_agent
	self.position = target_agent.position
	self.label = agent.get_node("Label3D")
	return self

func _physics_process(delta: float) -> void:
	eval(delta)

# Helper function for LLM movement and waiting
func move_and_wait (x: float, y: float):
	move_to_position(x,y)
	# Return signal
	return agent.movement_completed
	
func move_to_position(x: float, y: float):
	# print("Moving to position: ", x, " ", y)
	if label:
		label.text = "Moving to position: " + str(x) + ", " + str(y)
	agent.set_movement_target(Vector3(x, 0, y))
	
func send_message(target_id: int, content: String) -> void:
	var message_broker = agent.get_node("/root/MessageHandler")
	message_broker.send_message(agent.hash_id, target_id, content)
	
func get_nearby_agents() -> Array:
	var message_broker = agent.get_node("/root/MessageHandler")
	var nearby_agents: Array[int] = []
	
	for agent_id in message_broker.get_all_agent_ids():
		if agent_id != agent.hash_id:
			var other_agent = message_broker.get_agent_by_id(agent_id)
			var distance = agent.global_position.distance_to(other_agent.global_position)
			if distance < 30: # Arbitrary distance
				nearby_agents.append(agent_id)
				
	return nearby_agents
	
func move_with_timeout(x: float, y:float, timeout_seconds: float = 3.0):
	move_to_position(x,y)
	
	var timer = get_tree().create_timer(timeout_seconds)
	
	var completed = false
	
	var movement_conn = agent.movement_completed.connect(func(): completed = true)
	
	await timer.timeout
	
	if not completed:
		print("Movement timed out")
	
	if movement_conn.is_valid():
		agent.movement_completed.disconnect(movement_conn)
	
	return completed

func eval(delta):
	delta = delta
	return true
