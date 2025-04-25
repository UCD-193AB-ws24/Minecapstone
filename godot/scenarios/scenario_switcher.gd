class_name ScenarioSwitcher
extends Node

@export var scene_list: Array[PackedScene] = []

func _ready() -> void:
	print(scene_list[0].can_instantiate())
	get_tree().change_scene_to_packed(scene_list[0])
