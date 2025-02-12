extends RigidBody3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_meta("Name"):
		if body.get_meta("Name") == "agent":
			if body.has_node("InventoryManager"):
				var item_name = get_meta("ItemName");
				var inventory_node = body.get_node("InventoryManager")
				# TODO: fix
				var itemdict_instance = load("res://world/ItemDictionary.cs").new()
				#print(itemdict_instance.Get(item_name).PrintItem())
				var block = itemdict_instance.Get(item_name)
				inventory_node.AddItem(block, 1)
				queue_free()
				#inventory_node.PrintInventory()
