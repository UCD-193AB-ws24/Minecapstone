# COMPLEX PUZZLE SCENARIO
extends ScenarioManager


var red_touched = false
var blue_touched = false
var door_unlocked = false
@onready var door = $"../NavigationMesher/Door"
@onready var navmesher = $"../NavigationMesher"
@onready var num_agents_on_green: int = 0


func _ready() -> void:
	super()
	scenario_duration_seconds = 90.0
	reload()


func reload():
	var red_platform = get_parent().find_child("RedPlatform").get_node("Area3D")
	var blue_platform = get_parent().find_child("BluePlatform").get_node("Area3D")
	var green_platform = get_parent().find_child("GreenPlatform").get_node("Area3D")
	
	red_platform.connect("body_entered", _on_touch_platform.bind("RedPlatform"))
	blue_platform.connect("body_entered", _on_touch_platform.bind("BluePlatform"))
	red_platform.connect("body_exited", _on_touch_platform_exit.bind("RedPlatform"))
	blue_platform.connect("body_exited", _on_touch_platform_exit.bind("BluePlatform"))

	success_count = 0
	failure_count = 0
	green_platform.connect("body_entered", _on_touch_platform.bind("GreenPlatform"))
	green_platform.connect("body_exited", _on_touch_platform_exit.bind("GreenPlatform"))


func _on_touch_platform(_body: Node3D, platform_name: String) -> void:
	if platform_name == "RedPlatform":
		red_touched = true
		# print("Red platform touched")
	elif platform_name == "BluePlatform":
		blue_touched = true
		# print("Blue platform touched")
	elif platform_name == "GreenPlatform":
		num_agents_on_green += 1
		# print("Green platform touched")

	if num_agents_on_green == 2:
		# print("YES! Two agents on the green platform!")
		track_success()

	if red_touched and blue_touched and !door_unlocked:
		door_unlocked = true
		# print("Door unlocked!")
		door.visible = false
		door.use_collision = false
		
		# Update the navigation mesh, the door is now open
		for i in range(16):	await get_tree().physics_frame
		navmesher.BakeNavmesh()


func _on_touch_platform_exit(_body: Node3D, platform_name: String) -> void:
	if platform_name == "RedPlatform":
		red_touched = false
		# print("Red platform exited")
	elif platform_name == "BluePlatform":
		blue_touched = false
		# print("Blue platform exited")
	elif platform_name == "GreenPlatform":
		num_agents_on_green -= 1
		# print("Green platform exited")