extends Node3D

var multi_mesh_instance: MultiMeshInstance3D
var static_body: StaticBody3D

func _ready():


	# Create a MultiMeshInstance3D node
	multi_mesh_instance = MultiMeshInstance3D.new()

	# Create a MultiMesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.mesh = BoxMesh.new()  # Use BoxMesh for the cube
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D  # Use full 3D transforms
	
	var chunk_size = Vector3(16, 384, 16)
	multi_mesh.instance_count = chunk_size.x * chunk_size.y * chunk_size.z

	for i in range(multi_mesh.instance_count):
		var x = i % int(chunk_size.x)
		var y = int(i / chunk_size.x) % int(chunk_size.y)
		var z = i / (chunk_size.x * chunk_size.y)
		
		var instance_transform = Transform3D(Basis(), Vector3(x, y, z))
		multi_mesh.set_instance_transform(i, instance_transform)
		get_cube_collision(Vector3(x,y,z))
	
	# Assign the MultiMesh to the instance and add it to the scene
	multi_mesh_instance.multimesh = multi_mesh
	add_child(multi_mesh_instance)


func get_cube_collision(pos: Vector3):
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	collision_shape.shape = box_shape
	collision_shape.shape.extents = Vector3(0.5, 0.5, 0.5)
	var body = StaticBody3D.new()
	body.add_child(collision_shape)
	add_child(body)
	body.global_transform.origin = pos
