class_name Agent extends NPC


func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true


func _physics_process(delta):
	set_movement_target(Vector3(-10,0,-10))
	super(delta)
