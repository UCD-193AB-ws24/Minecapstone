using Godot;
using System;

public partial class NavigationMesher : NavigationRegion3D {
	// TODO: this has to be called, probably dangerously, every time the chunk mesh is updated.
	// Need to fix this by use and parse collision shapes as source geometry or create geometry data procedurally in scripts.
	// Source geometry parsing for navigation mesh baking had to parse RenderingServer meshes at runtime. This poses a significant performance issues as visual meshes store geometry data on the GPU and transferring this data back to the CPU blocks the rendering. For runtime (re)baking navigation meshes use and parse collision shapes as source geometry or create geometry data procedurally in scripts.
	public override void _Ready() {
		var chunkManager = GetNode("ChunkManager");
		if (chunkManager != null) {
			CallDeferred(nameof(GenerateNavmesh));
		}
		else {
			GD.Print("ChunkManager node not found");
		}
	}

	public void GenerateNavmesh() {
		this.BakeNavigationMesh(true);
	}

	private void OnBakeFinished() {
		var navmesh = (NavigationMesh)this.NavigationMesh;
		GD.Print("Navmesh baked --> ", navmesh.GetVertices().Length);
	}

	// NavigationMeshGenerator::bake() is deprecated due to core threading changes. 
	// To upgrade existing code, first create a NavigationMeshSourceGeometryData3D resource
	// Use this resource with method parse_source_geometry_data() to parse the SceneTree for nodes 
	// that should contribute to the navigation mesh baking. The SceneTree parsing needs to happen on the main thread.
	// After the parsing is finished use the resource with method bake_from_source_geometry_data() to bake a navigation mesh..
}
