# COMPLEX PUZZLE SCENARIO
extends ScenarioManager


var red_touched = false
var blue_touched = false
var door_unlocked = false
@onready var door = $"../NavigationMesher/Door"
@onready var navmesher = $"../NavigationMesher"


func _ready() -> void:
	super()
	reload()


func reload():
	var red_platform = get_parent().find_child("RedPlatform").get_node("Area3D")
	var blue_platform = get_parent().find_child("BluePlatform").get_node("Area3D")
	
	success_count = 0
	failure_count = 0
	red_platform.connect("body_entered", _on_touch_platform.bind("RedPlatform"))
	blue_platform.connect("body_entered", _on_touch_platform.bind("BluePlatform"))
	red_platform.connect("body_exited", _on_touch_platform_exit.bind("RedPlatform"))
	blue_platform.connect("body_exited", _on_touch_platform_exit.bind("BluePlatform"))


func _on_touch_platform(_body: Node3D, platform_name: String) -> void:
	if platform_name == "RedPlatform":
		red_touched = true
		print("Red platform touched")
	else:
		blue_touched = true
		print("Blue platform touched")

	if red_touched and blue_touched and !door_unlocked:
		door_unlocked = true
		print("Door unlocked!")
		door.visible = false
		door.use_collision = false
		
		for i in range(16):
			await get_tree().physics_frame

		navmesher.BakeNavmesh()


func _on_touch_platform_exit(_body: Node3D, platform_name: String) -> void:
	if platform_name == "RedPlatform":
		red_touched = false
		print("Red platform exited")
	else:
		blue_touched = false
		print("Blue platform exited")
