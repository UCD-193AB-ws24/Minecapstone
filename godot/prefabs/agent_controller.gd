class_name AgentController
extends Node

var agent: Agent
var position: Vector3

func setup(target_agent: Agent):
	self.agent = target_agent
	self.position = target_agent.position
	return self

func _physics_process(delta: float) -> void:
	eval(delta)

func move_to_position(x: float, y: float):
	# TODO: remove debug print
	print("Moving to position: ", x, " ", y)
	agent.set_movement_target(Vector3(x, 0, y))

func discard(itemName: String, amount: int):
	# TODO: remove debug print
	print("dropping ", amount , " ", itemName, )
	agent.discard_item(itemName, amount)



func eval(delta):
	delta = delta
	return true
