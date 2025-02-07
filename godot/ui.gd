extends Control

@onready var label = $GridContainer/Label

func _physics_process(_delta: float) -> void:
	label.text = "FPS: " + str(Engine.get_frames_per_second())
	var chunk_manager = $"../NavigationMesher/ChunkManager"
	if chunk_manager:
		var player_chunk_position = chunk_manager.GetPlayerChunkPosition()
		label.text += "\nPlayer Chunk Position: " + str(player_chunk_position)

	var player = $"../Player"
	if player:
		label.text += "\nPlayer Global Position: " + str(round_vector(player.global_position))
		label.text += "\nPlayer Velocity: " + str(round(player.velocity.length() * 10) / 10.0)
		var healthbar:ProgressBar = $Health
		var hungerbar:ProgressBar = $Hunger
		var thirstbar:ProgressBar = $Thirst

		if player:
			healthbar.value = player.health
			hungerbar.value = player.hunger
			thirstbar.value = player.thirst

	var inventory_manager = $"../Player/InventoryManager"
	if inventory_manager:
		var item_amt_label = $"./ItemTemp/Amount"
		item_amt_label.text = str(inventory_manager.GetSelectedAmount())


func round_vector(vec: Vector3) -> Vector3:
	return Vector3(round(vec.x * 10) / 10.0, round(vec.y * 10) / 10.0, round(vec.z * 10) / 10.0)
