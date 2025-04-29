class_name NPC_Animal
extends NPC


enum BehaviorModes {Wandering, Scared, Curious}
@onready var oldBehavior = BehaviorModes.Scared
@onready var behavior:BehaviorModes = BehaviorModes.Curious
# TODO: Remove this line and update logic to use entity detector for players
@onready var player = $"../Player"
@onready var oldHealth = health


var _wandering_timer : Timer
var _scared_timer : Timer
var _wandering_duration: float = 5
var _scared_duration: float = 7
#var detection_range = 25

var drop_list:Array = ["Meat"]

func _ready():
	max_health = 50
	health = 50
	# Made it jump higher so it can go up 1 block heights while following navmesh meant for taller agents
	_jump_velocity = 12.0
	super()
	_wandering_timer = Timer.new()
	_wandering_timer.one_shot = true
	_wandering_timer.wait_time = _wandering_duration
	_wandering_timer.timeout.connect(_on_wandering_timer_timeout)
	add_child(_wandering_timer)
	
	_scared_timer = Timer.new()
	_scared_timer.one_shot = true
	_scared_timer.wait_time = _scared_duration
	_scared_timer.timeout.connect(_on_scared_timer_timeout)
	add_child(_scared_timer)

	#inventory
	inventory_manager.AddItem(ItemDictionary.Get("Meat"), 1)


func _physics_process(delta):
	_target_logic()
	super(delta)
	oldHealth = health


func set_target_position(movement_target: Vector3, _distance_away: float = 1.0):
	_rotate_toward(movement_target)
	super(movement_target)


func _behavior_logic():
	var distanceToPlayer = global_position.distance_to(player.global_position)
	
	oldBehavior = behavior
	
	if distanceToPlayer < detection_range:
		if oldHealth > health:
			behavior = BehaviorModes.Scared
			_scared_timer.start()
		if player.inventory_manager.GetSelectedItem() == ItemDictionary.Get("Grass") and _scared_timer.is_stopped():
			# Eventually change from grass to certain items once those are implemented
			behavior = BehaviorModes.Curious
		elif _scared_timer.is_stopped():
			behavior = BehaviorModes.Wandering
	else:
		behavior = BehaviorModes.Wandering
	
	
func _target_logic():
	_behavior_logic()
	
	match behavior:
		BehaviorModes.Curious:
			set_target_position(player.global_position)
			#_speed = 2
			_rotate_toward(player.global_position)
		BehaviorModes.Wandering:
			if _wandering_timer.is_stopped():
					_wandering_timer.start()
			_wandering_movement()
		BehaviorModes.Scared:
			if oldBehavior != behavior:
				_generate_scared_target()
			_scared_movement()


func _scared_movement():
		#_speed = 3
		# While scared, want to randomly change direction while running around
		var chance = randf_range(0, 1)
		if chance < 0.02:
			_generate_scared_target()


func _generate_scared_target():
		# Want them to run away, so ensure the coordinates aren't too close to original position
		var x_offset = randf_range(-10, 10)
		while abs(x_offset) < 4:
			x_offset = randf_range(-10, 10)
			
		var z_offset = randf_range(-10, 10)
		while abs(z_offset) < 4:
			z_offset = randf_range(-10, 10)
		
		var random_offset = Vector3(x_offset, global_position.y, z_offset)
		set_target_position(global_position + random_offset)


func _wandering_movement():
		#_speed = 1.5
		var chance = randf_range(0, 1)
		# randomly change direction
		if chance < 0.02:
			set_target_position(global_position + Vector3(randf_range	(-10, 10), 0, randf_range(-10, 10)))


func _on_wandering_timer_timeout():
	# Wandering is an endless behavior, so just finds somewhere new to wander towards on timer end.
	if behavior == BehaviorModes.Wandering:
		var random_offset = Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
		set_target_position(global_position + random_offset)
		_wandering_timer.start()


func _on_scared_timer_timeout():
	if behavior == BehaviorModes.Scared:
		behavior = BehaviorModes.Wandering


func _rotate_toward(movement_target: Vector3):
	var direction = (movement_target - global_position).normalized()
	# Removing the PI fixes raycast emitted by animal
	rotation.y = atan2(direction.x, direction.z)

func _on_player_death():
	super()
	queue_free()
