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
	agent.set_movement_target(Vector3(x, 0, y))

func discard_here(itemName: String, amount: int):
	# TODO: remove debug print
	print("dropping ", amount , " ", itemName, )
	agent.discard_item(itemName, amount)


func eval(delta):
	delta = delta
	return true
