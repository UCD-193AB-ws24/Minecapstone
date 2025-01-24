extends Control

@onready var label = $FlowContainer/Label

func _physics_process(_delta: float) -> void:
	label.text = "FPS: " + str(Engine.get_frames_per_second())
	var chunk_manager = get_node("/root/World/NavigationMesher/ChunkManager")
	if chunk_manager:
		var player_chunk_position = chunk_manager.GetPlayerChunkPosition()
		label.text += "\nPlayer Chunk Position: " + str(player_chunk_position)

	var player = get_node("/root/World/Player")
	if player:
		label.text += "\nPlayer Global Position: " + str(round_vector(player.global_position))
		label.text += "\nPlayer Velocity: " + str(round(player.velocity.length() * 10) / 10.0)

func round_vector(vec: Vector3) -> Vector3:
	return Vector3(round(vec.x * 10) / 10.0, round(vec.y * 10) / 10.0, round(vec.z * 10) / 10.0)
