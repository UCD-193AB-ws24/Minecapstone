class_name GoalMemory
extends MemoryItem

var goal: String

func _init(goal_description: String):
	super("goal_update")
	goal = goal_description
	
func format_for_prompt() -> String:
	return "* Previous goal: %s" % goal
