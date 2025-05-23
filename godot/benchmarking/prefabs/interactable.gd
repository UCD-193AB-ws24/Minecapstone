class_name Interactable
extends StaticBody3D

var category: String
var function: String

func _ready() -> void:
	category = get_meta("Category")
	function = get_meta("Function")
