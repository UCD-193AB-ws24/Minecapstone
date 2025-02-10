class_name npc_animal
extends NPC

enum BehaviorModes {Wandering, Scared, Curious}
@onready var behavior:BehaviorModes = BehaviorModes.Wandering
@onready var player = $"../Player"

# Scuffed timers since I couldn't figure out a proper way :c
var wandering_timer = 0
var scared_timer = 0
var scared_duration = 300
var detection_range = 25
	
func set_movement_target(movement_target: Vector3):
	navigation_agent.set_target_position(movement_target)
	_rotate_toward(movement_target)
	
func _behavior_logic():
	var distanceToPlayer = global_position.distance_to(player.global_position)
	
	if distanceToPlayer < detection_range:
		if player.inventory_manager.GetSelectedItem() == block_manager.ItemDict.Get("Grass"):
			# Eventually change from grass to certain items once those are implemented
			behavior = BehaviorModes.Curious
		elif distanceToPlayer < 2:
			# Eventually change to if loses health
			behavior = BehaviorModes.Scared
	else:
		behavior = BehaviorModes.Wandering
	
	
func _target_logic():
		
	_behavior_logic()
	
	match behavior:
		BehaviorModes.Curious:
			set_movement_target(player.global_position)
			_speed = 2
			_rotate_toward(player.global_position)
		BehaviorModes.Wandering:
			_wandering_movement()
			wandering_timer += 1
		BehaviorModes.Scared:
			_scared_movement()
			scared_timer += 1

func _scared_movement():
		_speed = 3.3
		if scared_timer == 0:
			# Set random coordinates to run towards
			var x_offset = randf_range(-10, 10)
			# Exclude coordinates too close to player
			while abs(x_offset) < 3:
				x_offset = randf_range(-10, 10)
				
			var z_offset = randf_range(-10, 10)
			while abs(x_offset) < 3:
				z_offset = randf_range(-10, 10)
				
			var random_offset = Vector3(x_offset, global_position.y + 1, z_offset)
			set_movement_target(global_position + random_offset)
			
		elif scared_timer >= scared_duration:
			behavior = BehaviorModes.Wandering;
			scared_timer = 0;
		else:
			var chance = randf_range(0, 1)
			# Randomly changes direction similar to minecraft
			if chance < 0.02:
				var x_offset = randf_range(-10, 10)
				while abs(x_offset) < 3:
					x_offset = randf_range(-10, 10)
					
				var z_offset = randf_range(-10, 10)
				while abs(x_offset) < 3:
					z_offset = randf_range(-10, 10)
					
				var random_offset = Vector3(x_offset, global_position.y + 1, z_offset)
				set_movement_target(global_position + random_offset)

func _wandering_movement():
		_speed = 1.5
		if wandering_timer == 0:
			var random_offset = Vector3(randf_range(-10, 10), global_position.y + 1, randf_range(-10, 10))
			set_movement_target(global_position + random_offset)
		elif wandering_timer > 300:
			var random_offset = Vector3(randf_range(-10, 10), global_position.y + 1, randf_range(-10, 10))
			set_movement_target(global_position + random_offset)
			wandering_timer = 0
		else:
			var chance = randf_range(0, 1)
			# randomly idle
			if chance < 0.02:
				set_movement_target(global_position)


func _rotate_toward(movement_target: Vector3):
	var direction = (movement_target - global_position).normalized()
	var angle = atan2(direction.x, direction.z)
	rotation.y = angle
