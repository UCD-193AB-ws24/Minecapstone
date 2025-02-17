class_name AgentController
extends RefCounted

var agent: Agent
var position: Vector3

func setup(target_agent: Agent):
	self.agent = target_agent
	self.position = target_agent.position
	return self

func move_to_position(x: float, y: float):
	agent.navigate_to(Vector2(x, y))
