extends NavigationRegion3D

var navmesh_baker: NavigationMeshSourceGeometryData3D = NavigationMeshSourceGeometryData3D.new()

# TODO: this has to be called, probably dangerously, ever time the chunk mesh is updated.
# Need to fix this by use and parse collision shapes as source geometry or create geometry data procedurally in scripts.
# Source geometry parsing for navigation mesh baking had to parse RenderingServer meshes at runtime. This poses a significant performance issues as visual meshes store geometry data on the GPU and transferring this data back to the CPU blocks the rendering. For runtime (re)baking navigation meshes use and parse collision shapes as source geometry or create geometry data procedurally in scripts.
func _ready() -> void:
	var chunk_manager = get_node("../ChunkManager")
	if chunk_manager:
		call_deferred("_generate_navmesh")
	else:
		print("ChunkManager node not found")

func _generate_navmesh() -> void:
	NavigationServer3D.parse_source_geometry_data(self.navigation_mesh, navmesh_baker, $/root/World, _finish_navmesh_baking)

func _finish_navmesh_baking() -> void:
	NavigationServer3D.bake_from_source_geometry_data(self.navigation_mesh, navmesh_baker)
	
# NavigationMeshGenerator::bake() is deprecated due to core threading changes. 
# To upgrade existing code, first create a NavigationMeshSourceGeometryData3D resource
# Use this resource with method parse_source_geometry_data() to parse the SceneTree for nodes 
# that should contribute to the navigation mesh baking. The SceneTree parsing needs to happen on the main thread.
# After the parsing is finished use the resource with method bake_from_source_geometry_data() to bake a navigation mesh..
