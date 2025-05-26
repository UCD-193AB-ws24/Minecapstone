class_name ScenarioManager
extends Node


signal scenario_complete(success_count: int, failure_count: int, error_count: int)
var success_count: int = 0
var failure_count: int = 0
var error_count: int = 0
var save_data : String = ""
var current_iteration: int = 0
var MAX_ITERATIONS: int = 30


enum ScenarioType {
	NONE,
	ENVIRONMENTAL_INTERACTION,
	VISUAL_UNDERSTANDING,
	SEQUENTIAL_REASONING,
}
@export var scenario_type: ScenarioType = ScenarioType.NONE


var timeout_timer:Timer
@export var scenario_duration_seconds: float = 10.0


func _ready() -> void:
	_capture_initial_state()
	timeout_timer = Timer.new()
	timeout_timer.one_shot = true
	timeout_timer.timeout.connect(track_failure)

	#TODO: connect agent out_of_prompts to track_failure

	add_child(timeout_timer)
	reset_timer()


func track_success():
	timeout_timer.stop()
	success_count += 1
	current_iteration += 1
	await next_iteration()


func track_failure():
	timeout_timer.stop()
	failure_count += 1
	current_iteration += 1
	await next_iteration()


func track_error():
	timeout_timer.stop()
	error_count += 1
	current_iteration += 1
	await next_iteration()


func reset():
	#Clear data from global classes
	MessageBroker.clear_agents()
	AgentManager.clear_agents()
	# Restore the environment to its original state
	print("Environment reset. Successes:", success_count, ", Failures:", failure_count, ", Errors:", error_count)
	await _restore_initial_state()
	reset_timer()


func reset_timer():
	"""Function is to be triggered by the reset_timer signal of the scenario box adapter.
	Function resets the timer."""
	print("This scenario has a timeout of ", scenario_duration_seconds)
	timeout_timer.start(scenario_duration_seconds)


func get_results(debug = false):
	""" This function MUST BE CALLED at the end of the scenario to get the results and for the scene switcher to work."""
	if debug:
		print("============== Scenario complete. ==============")
		print("Success count:", success_count)
		print("Failure count:", failure_count)
		print("Error count:", error_count)
	scenario_complete.emit(success_count, failure_count, error_count)
	return [success_count, failure_count, error_count]


func next_iteration():
	if current_iteration < MAX_ITERATIONS:
		await reset()
	else:
		var results = get_results(true)
		var success = results[0]
		var failure = results[1]
		var error = results[2]
		ScenarioSwitcher.save_results(success, failure, error, scenario_type)
		ScenarioSwitcher.next_scene()
	

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		_restore_initial_state()


func _capture_initial_state():
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.scene_file_path.is_empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		# Check the node has a save function.
		if !node.has_method("save"):
			print("persistent node '%s' is missing a save() function, skipped" % node.name)
			continue

		# Call the node's save function.
		var node_data = node.call("save")

		# JSON provides a static method to serialized JSON string.
		var json_string = JSON.stringify(node_data)

		save_data += json_string + "\n"
	print("Saved the scene")
	

func _restore_initial_state():
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		node.queue_free()
	#free nodes from Clear group
	var clear_nodes = get_tree().get_nodes_in_group("Clear")
	for node in clear_nodes:
		node.queue_free()

	# Wait for full removal to prevent name collisions
	if not get_tree():
		return
		
	for i in range(16): await get_tree().physics_frame

	for json_string in save_data.split("\n"):
		if json_string.strip_edges() == "":
			continue

		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		var node_data = json.data

		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object = load(node_data["filename"]).instantiate()

		# Build version temp fix
		if (node_data["parent"] == "/root/World"):
			get_parent().add_child(new_object)
		else:
			get_node(node_data["parent"]).add_child(new_object)
			
		new_object.position = Vector3(node_data["pos_x"], node_data["pos_y"], node_data["pos_z"])
		new_object.rotation_degrees = Vector3(node_data["rot_x"], node_data["rot_y"], node_data["rot_z"])
		new_object.name = node_data["name"]
		
		# Now we set the remaining variables.
		for i in node_data.keys():
			if i in ["filename", "parent", "pos_x", "pos_y", "pos_z", "rot_x", "rot_y", "rot_z", "name"]:
				continue
			new_object.set(i, node_data[i])

	for i in range(16): await get_tree().physics_frame
