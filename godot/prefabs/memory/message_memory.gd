class_name MessageMemory
extends MemoryItem


var message: String
var from_id: int
var to_id: int


func _init(msg: String, sender_id: int, recipient_id: int):
	super("message")
	message = msg
	from_id = sender_id
	to_id = recipient_id


func format_for_prompt() -> String:
	return "* Message from agent %s: %s" % [str(from_id), message]
