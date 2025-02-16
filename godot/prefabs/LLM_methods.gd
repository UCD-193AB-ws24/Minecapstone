class_name LLM_Methods extends NPC


#test
func _ready() -> void:
	super()
	set_movement_target(Vector3(1,0,10))


func call_move_to(dest: Vector3):
	set_movement_target(dest)
