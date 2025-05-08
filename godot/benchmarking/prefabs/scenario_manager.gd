class_name ScenarioManager
extends Node


var success_count: int = 0
var failure_count: int = 0
var error_count: int = 0
var save_data : String = ""
var current_iteration: int = 0
var MAX_ITERATIONS: int = 10

var timer:Timer
@export var scenario_duration_seconds: int = 15


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = get_node("ScenarioTimer")
	timer.timeout.connect(_out_of_time)
	_capture_initial_state()
	reset_timer()


func track_success():
	success_count += 1
	current_iteration += 1
	# print("Success count:", success_count)


func track_failure():
	failure_count += 1
	current_iteration += 1
	# print("Failure count:", failure_count)
	

func track_error():
	error_count += 1
	current_iteration += 1
	# print("Error count:", error_count)
	reset()


func reset():
	# Restore the environment to its original state
	_restore_initial_state()
	print("Environment reset. Successes:", success_count, ", Failures:", failure_count)
	#reset timer
	reset_timer()

func _out_of_time():
	"""Function is to be triggered by the out_of_time signal of an agent.
	Function check if agent is out of time and if so, log failure and reset the scenario"""
	print("out of time")
	track_failure()
	reset()

	for i in range(10):
		await get_tree().physics_frame

func reset_timer():
	"""Function is to be triggered by the reset_timer signal of the scenario box adapter.
	Function resets the timer."""
	print("reset timer")
	timer.start(scenario_duration_seconds)


func get_results(debug = false):
	if debug:
		print("============== Scenario complete. ==============")
		print("Success count:", success_count)
		print("Failure count:", failure_count)
		print("Error count:", error_count)
	return [success_count, failure_count, error_count]
	

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_L:
		_restore_initial_state()
		print("State loaded.")


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
	# Wait for full removal to prevent name collisions
	for i in range(8):	await get_tree().physics_frame

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
		get_node(node_data["parent"]).add_child(new_object)
		new_object.position = Vector3(node_data["pos_x"], node_data["pos_y"], node_data["pos_z"])

		# Now we set the remaining variables.
		for i in node_data.keys():
			if i == "filename" or i == "parent" or i == "pos_x" or i == "pos_y":
				continue
			new_object.set(i, node_data[i])
	pass
