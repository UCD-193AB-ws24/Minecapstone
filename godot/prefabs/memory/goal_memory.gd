class_name GoalMemory
extends MemoryItem

var goal: String

func _init(goal_description: String):
	super("GENERATE_SCRIPT")
	goal = goal_description
	
func format_for_prompt() -> String:
	return "*Completed: %s" % goal
