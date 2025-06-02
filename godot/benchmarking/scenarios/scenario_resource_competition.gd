extends ScenarioManager


@export var animal_spawnable_scene: PackedScene
@export var zombie_spawnable_scene: PackedScene
@export var animal_spawn_timer: float = 10.0
@export var zombie_spawn_timer: float = 30.0

var agent1
var agent2
var raycast
var inventory1
var inventory2
var animal_timer: Timer
var zombie_timer: Timer

func spawn_animal():
	var animal_spawn = animal_spawnable_scene.instantiate() as CharacterBody3D
	# Scuffed way to deal with issue where every single node extending from NPC has the same detection range
	animal_spawn.detection_range = 100;

	var world = get_parent()
	world.add_child(animal_spawn)
	var animal_spawn_pos: Vector3 = Vector3(randi_range(-40, 40), 23, randi_range(-40, 40))
	animal_spawn.global_position = animal_spawn_pos

func spawn_zombie():
	var zombie_spawn = zombie_spawnable_scene.instantiate() as CharacterBody3D
	# Scuffed way to deal with issue where every single node extending from NPC has the same detection range
	zombie_spawn.detection_range = 100;
	var world = get_parent()
	world.add_child(zombie_spawn)
	var zombie_spawn_pos: Vector3 = Vector3(randi_range(-40, 40), 23, randi_range(-40, 40))
	zombie_spawn.global_position = zombie_spawn_pos

func _ready() -> void:
	super()
	_find_agent()

	animal_timer = Timer.new()
	animal_timer.timeout.connect(spawn_animal)
	add_child(animal_timer)
	animal_timer.start(animal_spawn_timer)

	zombie_timer = Timer.new()
	zombie_timer.timeout.connect(spawn_zombie)
	add_child(zombie_timer)
	zombie_timer.start(zombie_spawn_timer)



func _find_agent():
	agent1 = get_parent().get_node("Agent")
	agent2 = get_parent().get_node("Agent2")
	if agent1 and agent2:
		inventory1 = agent1.get_node("InventoryManager")
		inventory2 = agent2.get_node("InventoryManager")

func reset():
	await super()
	_find_agent()
