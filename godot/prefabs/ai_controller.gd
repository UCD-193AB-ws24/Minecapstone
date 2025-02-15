class_name AIController
extends Node

@onready var player: CharacterBody3D = get_parent()
@onready var movement_direction: Vector2 = Vector2.ZERO
@onready var is_jumping: bool = false
@export var ai_control_enabled = false

#func _physics_process(_delta):
	#if ai_control_enabled:
		#var current_speed = player._speed
		#player.move_to(movement_direction.normalized(), is_jumping, current_speed, _delta)
