# Benchmarker
extends Node3D


# Set the list of desired scenarios to run in the Inspector
@export var scene_list: Array[PackedScene] = []


func _ready() -> void:
	# Enable the ScenarioSwitcher global
	ScenarioSwitcher.enable(scene_list)
	ScenarioSwitcher.next_scene()
	print(ScenarioSwitcher.enabled)
