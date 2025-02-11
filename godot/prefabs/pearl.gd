class_name Pearl
extends RigidBody3D

# TODO: improve code for playing audio, sometimes sounds like it's inside the ground
@onready var player:Player


func throw_in_direction(thrower:Player, throw_position:Vector3, throw_direction:Vector3):
	self.player = thrower

	var player_audio = AudioStreamPlayer3D.new()
	get_parent().add_child(player_audio)
	player_audio.stream = load("res://assets/throw.mp3")
	player_audio.play()

	global_position = throw_position + throw_direction.normalized()
	linear_velocity = throw_direction.normalized() * 20


# Called on collision
func _on_body_entered(body: Node) -> void:
	if player and body is not Player and body is not Pearl:
		player.global_position = global_position
		var player_audio = AudioStreamPlayer3D.new()
		get_parent().add_child(player_audio)
		player_audio.stream = load("res://assets/teleport.mp3")
		player_audio.play()
		queue_free()
