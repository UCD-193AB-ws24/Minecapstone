extends Node

@onready var player = $"/root/World/Player"

func _ready():
	# Enable AI control
	player.ai_control_enabled = true
	print("AI control now enabled")
	
func _process(_delta):
	# test some stuff
	var ai_direction = Vector2(-1,1) # move forward
	var ai_jump = true
	
	player._set_ai_movement(ai_direction)
	player._set_ai_jump(ai_jump)
