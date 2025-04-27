@tool
extends RigidBody3D

func _ready() -> void:
	var texture = $Sprite3D.texture
	$Sprite3D.position = Vector3.ZERO
	if texture:
		var target_width = 1024.0  # Set your desired width here
		var scale_factor = target_width / texture.get_width()
		$Sprite3D.scale = Vector3(scale_factor, scale_factor, scale_factor)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_meta("Name"):
		if body.get_meta("Name") == "agent" or body.get_meta("Name") == "storage":
			
			if body.has_node("InventoryManager"):
				var item_name = get_meta("ItemName");
				var inventory_node = body.get_node("InventoryManager")
				var block = ItemDictionary.Get(item_name)
				inventory_node.AddItem(block, 1)
				queue_free()
				#inventory_node.PrintInventory()
