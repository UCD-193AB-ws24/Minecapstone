# Global Class: ScenarioSwitcher
extends Node


var enabled = false
var metrics: Dictionary = {}
var scene_list: Array[PackedScene] = []
var _current_scene_name: String = ""


func enable(_scene_list: Array[PackedScene]) -> void:
	scene_list = _scene_list
	enabled = true


func save_results(success_count, failure_count, error_count) -> void:
	metrics[_current_scene_name] = {
		"success_count": success_count,
		"failure_count": failure_count,
		"error_count": error_count
	}


func next_scene() -> void:
	await get_tree().physics_frame
	if enabled:
		if scene_list.size() > 0:
			var current_scene = scene_list.pop_front()
			_current_scene_name = current_scene.to_string()
			print("Switching to scene: %s" % _current_scene_name)
			if current_scene.can_instantiate():
				get_tree().change_scene_to_packed(current_scene)
				await get_tree().scene_changed
				#var sm = get_tree().current_scene.get_node("ScenarioManager")
				#await get_tree().physics_frame
		else:
			enabled = false
			print("===============Benchmark Results===============")
			for scene_name in metrics.keys():
				if scene_name in metrics:
					var result = metrics[scene_name]
					print("%s: Success: %d, Failure: %d, Error: %d" % [
						scene_name,
						result.success_count,
						result.failure_count,
						result.error_count
					])
					
			# TODO: probably out the results to a file? just quitting for now otherwise it repeats the last scene repeatedly
			get_tree().current_scene.queue_free()
			get_tree().quit()
