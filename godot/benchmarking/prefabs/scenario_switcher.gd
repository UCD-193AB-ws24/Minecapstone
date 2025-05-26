# Global Class: ScenarioSwitcher
extends Node


var enabled = false
var metrics: Dictionary = {}
var scene_list: Array[PackedScene] = []
var _current_scene_name: String = ""


func enable(_scene_list: Array[PackedScene]) -> void:
	scene_list = _scene_list
	enabled = true


func get_scenario_type_name(scenario_type: int) -> String:
	match scenario_type:
		0: return "NONE"
		1: return "ENVIRONMENTAL_INTERACTION"
		2: return "VISUAL_UNDERSTANDING"
		3: return "SEQUENTIAL_REASONING"
		_: return "UNKNOWN"


func save_results(success_count, failure_count, error_count, scenario_type = 0) -> void:
	metrics[_current_scene_name] = {
		"success_count": success_count,
		"failure_count": failure_count,
		"error_count": error_count,
		"scenario_type": scenario_type
	}


func next_scene() -> void:
	await get_tree().physics_frame
	if enabled:
		if scene_list.size() > 0:
			var current_scene = scene_list.pop_front()
			_current_scene_name = current_scene.resource_path.get_file()
			print("Switching to scene: %s" % _current_scene_name)
			if current_scene.can_instantiate():
				get_tree().change_scene_to_packed(current_scene)
				await get_tree().scene_changed
				await get_tree().physics_frame
		else:
			enabled = false
			print("===============Benchmark Results===============")
			
			# Create an array of scene data for sorting
			var scene_results = []
			for scene_name in metrics.keys():
				var result = metrics[scene_name]
				scene_results.append({
					"scene_name": scene_name,
					"scenario_type": result.scenario_type,
					"scenario_type_name": get_scenario_type_name(result.scenario_type),
					"success_count": result.success_count,
					"failure_count": result.failure_count,
					"error_count": result.error_count
				})
			
			# Sort by scenario type first, then by scene name
			scene_results.sort_custom(func(a, b): 
				if a.scenario_type != b.scenario_type:
					return a.scenario_type < b.scenario_type
				return a.scene_name < b.scene_name
			)
			
			# Print sorted results with scenario type labels
			for result in scene_results:
				print("[%s] %s: Success: %d, Failure: %d, Error: %d" % [
					result.scenario_type_name,
					result.scene_name,
					result.success_count,
					result.failure_count,
					result.error_count
				])
					
			# TODO: probably out the results to a file? just quitting for now otherwise it repeats the last scene repeatedly
			get_tree().current_scene.queue_free()
			get_tree().quit()
