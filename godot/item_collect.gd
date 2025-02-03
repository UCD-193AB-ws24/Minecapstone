extends RigidBody3D


func _on_area_3d_body_entered(body: Node) -> void:
	# body detected should be the CharacterBody3D. It should also have the metadata of Name with the value "agent"
	var meta_name = body.get_meta("Name")
	if(meta_name == "agent"):
		print("It's touching me!!!")
		if(body.has_node("InventoryManager")):
			var body_node = body.get_node("InventoryManager")
			#Your IDE might mark body_node with a red squiggle but the code works fine
			body_node.PrintInventory()

	
