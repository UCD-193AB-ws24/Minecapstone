class_name Memory
extends RefCounted


# Base properties for all memory items
var timestamp: float
var type: String


func _init(memory_type: String):
	timestamp = Time.get_ticks_msec() / 1000.0
	type = memory_type


func format_for_prompt() -> String:
	return "* Memory (%s): %s" % [type, str(timestamp)]
