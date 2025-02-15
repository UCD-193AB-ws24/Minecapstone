using Godot;
using System;

[Tool]
public partial class NavigationMesher : NavigationRegion3D {
	// TODO: this has to be called, probably dangerously, every time the chunk mesh is updated.
	// Need to fix this by use and parse collision shapes as source geometry or create geometry data procedurally in scripts.
	// Source geometry parsing for navigation mesh baking had to parse RenderingServer meshes at runtime. This poses a significant performance issues as visual meshes store geometry data on the GPU and transferring this data back to the CPU blocks the rendering. For runtime (re)baking navigation meshes use and parse collision shapes as source geometry or create geometry data procedurally in scripts.
	
	
	public void GenerateNavmesh() {
		var chunkManager = GetNode("ChunkManager");
		if (chunkManager != null) {
			CallDeferred(nameof(BakeNavmesh));
		}
		else {
			GD.Print("ChunkManager node not found");
		}
		// TODO: otherwise, queue a bake so the bake occurs once IsFInishedBaking signal is emitted
	}

	private void BakeNavmesh() {
		GD.Print("Generating navmesh...");
		if (!IsBaking()) {
			BakeNavigationMesh(true);
		}
	}

	private void OnBakeFinished() {
		int NumVertices = NavigationMesh.GetVertices().Length;
		GD.Print("Navmesh baked with ", NumVertices, " vertices.");
	}

	// NavigationMeshGenerator::bake() is deprecated due to core threading changes. 
	// To upgrade existing code, first create a NavigationMeshSourceGeometryData3D resource
	// Use this resource with method parse_source_geometry_data() to parse the SceneTree for nodes 
	// that should contribute to the navigation mesh baking. The SceneTree parsing needs to happen on the main thread.
	// After the parsing is finished use the resource with method bake_from_source_geometry_data() to bake a navigation mesh..
}