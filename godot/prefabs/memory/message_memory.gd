class_name MessageMemory
extends Memory


var message: String
var from_agent: String
var to_agent: String


func _init(msg: String, sender_name: String, recipient_name: String):
	super("message")
	message = msg
	from_agent = sender_name
	to_agent = recipient_name


func format_for_prompt() -> String:
	return "		* %s said (time = %s): %s" % [from_agent, timestamp, message]
