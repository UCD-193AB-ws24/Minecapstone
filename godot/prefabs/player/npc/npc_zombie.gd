class_name NPC_Zombie
extends NPC_Wanderer


#@export var detection_range: float = 10.0
#@export var attack_range: float = 2.0
#@export var attack_damage: float = 25.0 # current 4 shots player
#@export var attack_cooldown: float = 2.0 
#@export var chase_speed: float = 2.0
enum ZombieState { WANDERING, CHASING, ATTACKING }
var current_state: ZombieState = ZombieState.WANDERING
var last_known_position: Vector3


func _init() -> void:
	set_meta("npc_zombie", true)


func _ready():
	super()
	#inventory_manager.AddItem(ItemDictionary.Get("Grass"), 64)
	#inventory_manager.AddItem(ItemDictionary.Get("Dirt"), 64)


func _physics_process(delta):
	# TODO: Update this line to use entity detector instead of first Player once multiple agents get implemented
	current_target = owner.find_children("Player")[0]

	var old_state = current_state
	var distance_to_player = global_position.distance_to(current_target.global_position)

	if distance_to_player <= detection_range:
		# TODO: maybe want to make attack_range a READONLY member variable
		var attack_range = raycast.target_position.length()
		if distance_to_player <= attack_range:
			current_state = ZombieState.ATTACKING
		else:
			current_state = ZombieState.CHASING
	else:
		if current_state != ZombieState.WANDERING:
			# When transitioning state, update the wander center
			last_known_position = current_target.global_position
			wander_center = last_known_position
			_generate_wander_target() # generate wander target based on where the player was last in chase range
		current_state = ZombieState.WANDERING

	if old_state != current_state:
		print("State changed to ", ZombieState.keys()[current_state])

	# Handle state
	match current_state:
		ZombieState.WANDERING:
			_speed = 1.25
			_set_wander_target_position(delta)
		ZombieState.CHASING:
			if !attack_disable:
				_set_chase_target_position()
		ZombieState.ATTACKING:
			if !attack_disable:
				print("npc_zombie.gd: Missing attack function. Implement attack function.")
				#_attack_current_target()
	
	_rotate_toward(navigation_agent.target_position)
	super(delta)


# note to ryan: don't call _handle_movement(delta) inside of handle_chasing and _handle attacking, 
# when it could be called externally or by a super class
# use descriptive function names instead of "_handle..." when possible
func _input(_event):
	pass
