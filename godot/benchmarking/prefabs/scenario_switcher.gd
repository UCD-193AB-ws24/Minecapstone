# Global Class: ScenarioSwitcher
extends Node


var enabled = false
var scene_list: Array[PackedScene] = []


func enable(_scene_list: Array[PackedScene]) -> void:
	scene_list = _scene_list
	enabled = true


func next_scene() -> void:
	for i in range(10):
		await get_tree().physics_frame
	
	if enabled:
		if scene_list.size() > 0:
			var scene = scene_list.pop_front()
			if scene.can_instantiate():
				get_tree().change_scene_to_packed(scene)
		else:
			enabled = false
