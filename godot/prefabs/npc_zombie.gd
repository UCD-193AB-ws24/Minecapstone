class_name Zombie
extends NPC_Wanderer

# Declare Zombie state
enum ZombieState { WANDERING, CHASING, ATTACKING}
var current_state: ZombieState = ZombieState.WANDERING

# Declare Zombie properties
@export var detection_range: float = 10.0
@export var attack_range: float = 2.0
@export var attack_damage: float = 25.0 # current 4 shots player
@export var attack_cooldown: float = 1.0
@export var chase_speed: float = 2.0

var can_attack: bool = true
var target_player: Player = null
var last_known_position: Vector3


func _physics_process(delta):
	# Handle Zombie AI state
	if not target_player:
		target_player = get_node("../Player")
		_set_wander_target_position(delta)
		return

	var old_state = current_state
	var distance_to_player = global_position.distance_to(target_player.global_position)

	if distance_to_player <= detection_range:
		if distance_to_player <= attack_range:
			current_state = ZombieState.ATTACKING
		else:
			current_state = ZombieState.CHASING
	else:
		if current_state != ZombieState.WANDERING:
			# When transitioning state, update the wander center
			last_known_position = global_position
			spawn_position = global_position
			_generate_wander_target() # generate wander target based on spawn point
		current_state = ZombieState.WANDERING

	if old_state != current_state:
		print("State changed to ", ZombieState.keys()[current_state])

	# Handle state
	match current_state:
		ZombieState.WANDERING:
			_speed = 1.25
			_set_wander_target_position(delta)
		ZombieState.CHASING:
			_set_chase_target_position()
		ZombieState.ATTACKING:
			_handle_attacking()
	
	super(delta)

# note to ryan: don't call _handle_movement(delta) inside of handle_chasing and _handle attacking, when it could
# be called externally or by a super class
# use descriptive function names instead of "_handle..." when possible

func _set_chase_target_position():
	navigation_agent.target_position = target_player.global_position
	_speed = chase_speed


func _handle_attacking():
	navigation_agent.target_position = target_player.global_position
	if can_attack:
		_attack_player()
		can_attack = false
		# get_tree().create_timer(attack_cooldown).timeout.connect(func(): can_attack = true)
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true


func _attack_player():
	if target_player and global_position.distance_to(target_player.global_position) <= attack_range:
		target_player.damage(attack_damage)

# When player hits zombie
func take_damage(damage_amount: float):
	damage(damage_amount)
	if health <= 0:
		queue_free()


func _input(_event):
	pass
