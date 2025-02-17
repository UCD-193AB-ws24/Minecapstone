class_name Agent extends NPC

@onready var goal : String = ""


# Gets call-deferred in _ready of npc
func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	# Do not await inside ready.
	await get_tree().physics_frame
	navigation_ready = true
	
	# Wait for websocket connection
	if not API.socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		await API.connected
		set_goal("Walk in a circle of radius 5.")
	

func set_goal(new_goal:String):
	self.goal = new_goal
	print("Goal set to: ", new_goal)
	API.prompt_llm(self.goal)


func _physics_process(delta):
	super(delta)
