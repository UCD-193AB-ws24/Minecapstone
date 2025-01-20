class_name AIController
extends Node

# Only works when attached as child to a Player object

@onready var player: Player = get_parent()
@onready var movement_direction: Vector2 = Vector2.ZERO
@onready var is_jumping: bool = false
@onready var ai_control_enabled = false

func _physics_process(_delta):
	if ai_control_enabled:
		movement_direction = Vector2(-1,-1)
		is_jumping = true
		var current_speed = player.speed
		player._move_player(movement_direction.normalized(), is_jumping, current_speed, _delta)
