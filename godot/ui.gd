extends Control

@onready var label = $FlowContainer/Label

func _physics_process(_delta: float) -> void:
	label.text = "FPS: " + str(Engine.get_frames_per_second())