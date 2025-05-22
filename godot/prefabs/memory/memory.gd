class_name Memory
extends RefCounted


# Base properties for all memory items
var timestamp: float
var content: String


func _init(memory_content: String = ""):
	timestamp = Time.get_ticks_msec() / 1000.0
	content = memory_content


func format_for_prompt() -> String:
	return "		* Event (time = %s seconds): %s" % [timestamp, content]
