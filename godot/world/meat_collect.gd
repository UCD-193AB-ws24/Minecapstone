extends Node

@export var spawnable_scene: PackedScene

#spawn animals at random and at random locations

func spawn_scene():
	print("spawning an animal")
	#create instance of spawnable
	var spawn = spawnable_scene.instantiate() as CharacterBody3D

	#add to world hierarchy
	var world = get_parent()
	world.add_child(spawn)

	#generate spawn location
	var spawn_pos: Vector3 = Vector3(randi_range(-40, 40), 21, randi_range(-40, 40))
	spawn.global_position = spawn_pos
