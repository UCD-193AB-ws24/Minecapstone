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

func move_to_position(x: float, y: float):
	# print("Moving to position: ", x, " ", y)
	label.text = "Moving to position: " + str(x) + ", " + str(y)
	agent.set_movement_target(Vector3(x, 0.0, y))

func move_to_current_target():
	# print("Moving to position: ", x, " ", y)
	label.text = "Moving to position of target: " + agent.target_entity.name 
	agent.set_movement_target(agent.target_entity.global_position)

func select_nearest_target_type(target: String):
	label.text = "Selecting nearest target of type: " + target
	agent._select_nearest_target(target)

func attack_selected_entity(count: int = 1):
	label.text = "Attacking entity " + str(count) + "times."
	for i in range(count):
		agent._attack_entity()

# Need to implement attacking specific entities
#func attack_target_entity():
	#label.text = "Attacking entity: " + entity
	#agent._attack_entity()


func eval(delta):
	delta = delta
	return true
