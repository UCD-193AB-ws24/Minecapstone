extends RigidBody3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_meta("Name"):
		if body.get_meta("Name") == "agent":
			print("It's touching me!!!")
			# TODO: Add item to inventory
			# if(body.has_node("InventoryManager")):
			# 	var body_node = body.get_node("InventoryManager")
			# 	body_node.PrintInventory()
