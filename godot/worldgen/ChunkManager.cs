using Godot;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

// TODO: Optimize chunk loading to reduce frame drops, e.g. find places to put Thread sleeps

[Tool]
public partial class ChunkManager : Node
{
	public static ChunkManager Instance { get; private set; }

	private Dictionary<Chunk, Vector2I> _chunkToPosition = new();
	private Dictionary<Vector2I, Chunk> _positionToChunk = new();

	private List<Chunk> _chunks;

	[Export] public bool DoInfiniteGeneration { get; set; } = false;
	[Export] public PackedScene ChunkScene { get; set; }

	public NavigationMeshSourceGeometryData3D NavigationMeshSource { get; private set; }

	private int view_distance;
	private CharacterBody3D player;
	private Vector3 _playerPosition;
	private object _playerPositionlock = new();	// Semaphore used to lock access to the player position between threads
	private Node3D WorldGenerator;

	[Signal]
	public delegate void WorldLoadedEventHandler();

	public override void _Ready() {
		Instance = this;
		NavigationMeshSource = new NavigationMeshSourceGeometryData3D();

		WorldGenerator = GetNode<Node3D>("../../WorldGenerator");
		view_distance = (int)WorldGenerator.Get("VIEW_DISTANCE");

		// Connect to the world_generated signal
		WorldGenerator.Connect("world_generated", Callable.From(OnWorldGenerated));
		
		WorldGenerator.Call("generate");
		
		player = GetNodeOrNull<CharacterBody3D>("../../Player");
		_chunks = [.. GetChildren().Where(child => child is Chunk).Select(child => child as Chunk)];
	}
	
	// Chunk initialization code runs after world generation
	private void OnWorldGenerated() {
		// Ensure we have enough chunks
		for (int i = _chunks.Count; i < view_distance * view_distance; i++) {
			var chunk = ChunkScene.Instantiate<Chunk>();
			CallDeferred(Node.MethodName.AddChild, chunk);
			_chunks.Add(chunk);
		}
		
		for (int x = 0; x < view_distance; x++) {
			for (int z = 0; z < view_distance; z++) {
				// Get index of the chunk
				var index = (z * view_distance) + x;
				var halfWidth = Mathf.FloorToInt(view_distance / 2f);
				_chunks[index].SetChunkPosition(new Vector2I(x - halfWidth, z - halfWidth), WorldGenerator);
			}
		}

		// Generate the blocks within the chunk
		for (int x = 0; x < view_distance; x++) {
			for (int z = 0; z < view_distance; z++) {
				var index = (z * view_distance) + x;
				_chunks[index].Generate();
			}
		}

		// Create the mesh using the block data
		for (int x = 0; x < view_distance; x++) {
			for (int z = 0; z < view_distance; z++) {
				var index = (z * view_distance) + x;
				_chunks[index].Update();
			}
		}
		
		// Place trees before starting the chunk transition process
		PlaceTrees();
		
		// Start the chunk transition process in a separate thread
		if (!Engine.IsEditorHint()) {
			EmitSignal(SignalName.WorldLoaded);
			if (DoInfiniteGeneration) {
				new Thread(new ThreadStart(ThreadProcess)).Start();
			}
		}
	}

	// Generate the chunk at the desired position
	public void UpdateChunkPosition(Chunk chunk, Vector2I currentPosition, Vector2I previousPosition) {
		// if (_positionToChunk.TryGetValue(previousPosition, out var chunkAtPosition) && chunkAtPosition == chunk) {
		// 	_positionToChunk.Remove(previousPosition);
		// }

		_chunkToPosition[chunk] = currentPosition;
		_positionToChunk[currentPosition] = chunk;
	}

	// Creates and sets the block at the desired global position
	public void SetBlock(Vector3I globalPosition, Block block) {
		// Calculate which chunk contains this global position
		var chunkX = Mathf.FloorToInt(globalPosition.X / (float)Chunk.dimensions.X);
		var chunkZ = Mathf.FloorToInt(globalPosition.Z / (float)Chunk.dimensions.Z);
		var chunkPos = new Vector2I(chunkX, chunkZ);
		
		// Calculate local coordinates within the chunk
		var localX = Mathf.PosMod(globalPosition.X, Chunk.dimensions.X);
		var localZ = Mathf.PosMod(globalPosition.Z, Chunk.dimensions.Z);
		var localY = globalPosition.Y; // Y coordinate remains the same
		
		// Local position within the chunk
		var localPosition = new Vector3I(localX, localY, localZ);
		
		// Lock the position to the chunk in the event that the chunk is being updated
		lock (_positionToChunk) {
			if (_positionToChunk.TryGetValue(chunkPos, out var chunk)) {
				// Only set blocks that are within the valid Y range
				if (localY >= 0 && localY < Chunk.dimensions.Y) {
					try {
						chunk.SetBlock(localPosition, block);
					}
					catch (System.Exception e) {
						GD.PrintErr($"Error setting block at global {globalPosition}, local {localPosition}: {e.Message}");
					}
				}
			}
		}
	}

	// Updates the player position to help determine the current chunk the player is in.
	public override void _PhysicsProcess(double delta)
	{
		// This class is a [Tool], do not run this if in Editor
		if (Engine.IsEditorHint()) return;

		lock (_playerPositionlock) {
			_playerPosition = player.GlobalPosition;
		}
	}

	// Performs infinite generation, relies on DoInfiniteGeneration being true
	// Checks for chunk position transitions, and updates the chunk position if possible
	// TODO: This is very laggy due to the new world generation. Needs optimization
	private void ThreadProcess() {
		// Run constantly only if the object hasn't been deleted
		while (IsInstanceValid(this)) {
			int playerChunkX, playerChunkZ;
			lock(_playerPositionlock) {
				playerChunkX = Mathf.FloorToInt(_playerPosition.X / Chunk.dimensions.X);
				playerChunkZ = Mathf.FloorToInt(_playerPosition.Z / Chunk.dimensions.Z);
			}
			foreach (var chunk in _chunks) {
				var chunkPosition = _chunkToPosition[chunk];
				var chunkX = chunkPosition.X;
				var chunkZ = chunkPosition.Y;

				var newChunkX = (int)(Mathf.PosMod(chunkX - playerChunkX + view_distance / 2, view_distance) + playerChunkX - view_distance / 2);
				var newChunkZ = (int)(Mathf.PosMod(chunkZ - playerChunkZ + view_distance / 2, view_distance) + playerChunkZ - view_distance / 2);

				// Move the chunk position, moving all chunks, if player is in a new chunk
				if (newChunkX != chunkX || newChunkZ != chunkZ) {
					lock (_positionToChunk){
						if (_positionToChunk.ContainsKey(chunkPosition)) {
							_positionToChunk.Remove(chunkPosition);
						}
						var newPosition = new Vector2I(newChunkX, newChunkZ);
						_chunkToPosition[chunk] = newPosition;
						_positionToChunk[newPosition] = chunk;
						// Move an already existing chunk to the new posiiton
						chunk.CallDeferred(nameof(Chunk.SetChunkPosition), newPosition, WorldGenerator, true);
						
						// Do not update chunk positons as fast as possible to reduce frame drops
						Thread.Sleep(10);
					}
				}
			}
			// This sleep didn't do much
			Thread.Sleep(1000);
		}
	}

	// New helper method to retrieve a chunk at the given position.
	public Chunk GetChunkAtPosition(Vector2I pos) {
		if (_positionToChunk.ContainsKey(pos))
			return _positionToChunk[pos];
		return null;
	}

	// Debug
	public Vector2I GetPlayerChunkPosition() {
		lock (_playerPositionlock) {
			int playerChunkX = Mathf.FloorToInt(_playerPosition.X / Chunk.dimensions.X);
			int playerChunkZ = Mathf.FloorToInt(_playerPosition.Z / Chunk.dimensions.Z);
			return new Vector2I(playerChunkX, playerChunkZ);
		}
	}

	// Place trees in the world using positions from the world generator
	public void PlaceTrees() {
		// Get the world generator node
		if (WorldGenerator == null) {
			GD.PrintErr("WorldGenerator reference is null");
			return;
		}
		
		// Get the tree positions from the world generator
		var treePositions = WorldGenerator.Call("get_tree_positions").AsGodotArray<Vector2>();
		if (treePositions == null || treePositions.Count == 0) {
			GD.Print("No tree positions found");
			return;
		}
		
		GD.Print($"Placing {treePositions.Count} trees in the world");
		var woodBlock = (Block)ItemDictionary.Get("Wood");
		
		// Set seed for consistent tree generation
		var random = new System.Random(42);
		
		// Get the offset (used by Chunk to map local positions to global)
		int worldSize = (int)WorldGenerator.Get("VIEW_DISTANCE") * 16;
		Vector2I offset = new Vector2I(worldSize/2, worldSize/2);
		
		// Place wood blocks at each tree position
		int placedTrees = 0;
		foreach (var pos in treePositions) {
			// Convert tree position from WorldGenerator space to global world space
			var globalX = (int)pos.X - offset.X;
			var globalZ = (int)pos.Y - offset.Y;
			
			GD.Print($"Placing tree at generator pos {pos.X},{pos.Y} -> global {globalX},{globalZ}");
			
			// Find the height to place the tree at this XZ position
			int height = FindHighestTerrainAtPosition(globalX, globalZ);
			if (height < 0) {
				GD.Print($"No suitable ground at {globalX},{globalZ}");
				continue; // Skip if no suitable ground found
			}
			
			// Generate tree
			int treeHeight = 3 + random.Next(4); // Random height between 3-6 blocks
			
			// Ensure there's enough space above for the tree
			if (height + treeHeight >= Chunk.dimensions.Y) {
				treeHeight = Chunk.dimensions.Y - height - 1;
				if (treeHeight <= 2) continue; // Skip if not enough height for a proper tree
			}
			
			// Place trunk
			for (int h = 1; h <= treeHeight; h++) {
				var globalBlockPos = new Vector3I(
					globalX,
					height + h,
					globalZ
				);
				SetBlock(globalBlockPos, woodBlock);
			}
			
			// // Add leaves (simple cross pattern at top + crown)
			// int leavesStart = height + treeHeight - 2;
			// for (int ly = 0; ly <= 2; ly++) {
			// 	int radius = ly == 2 ? 1 : 2; // Top layer has smaller radius
				
			// 	for (int lx = -radius; lx <= radius; lx++) {
			// 		for (int lz = -radius; lz <= radius; lz++) {
			// 			// Skip corners for a more rounded shape
			// 			if (Mathf.Abs(lx) == radius && Mathf.Abs(lz) == radius) {
			// 				continue;
			// 			}
						
			// 			// Place leaves
			// 			var leafPos = new Vector3I(
			// 				(int)pos.X + lx,
			// 				leavesStart + ly,
			// 				(int)pos.Y + lz
			// 			);
						
			// 			// Only place leaves in air blocks
			// 			var currentBlock = GetBlockAt(leafPos);
			// 			if (currentBlock == null || currentBlock.Name == "Air") {
			// 				// We don't have a leaf block type, so skip for now
			// 				// If we had leaf blocks: SetBlock(leafPos, leafBlock);
			// 			}
			// 		}
			// 	}
			// }
			
			placedTrees++;
		}
		
		GD.Print($"Placed {placedTrees} trees in the world");
		
		// Force chunk updates to display the new tree blocks
		foreach (var chunk in _chunks) {
			chunk.Update();
		}
	}
	
	// Helper method to get a block at a global position
	private Block GetBlockAt(Vector3I globalPosition) {
		// Calculate which chunk contains this global position
		var chunkX = Mathf.FloorToInt(globalPosition.X / (float)Chunk.dimensions.X);
		var chunkZ = Mathf.FloorToInt(globalPosition.Z / (float)Chunk.dimensions.Z);
		var chunkPos = new Vector2I(chunkX, chunkZ);
		
		// Check if the chunk exists
		if (!_positionToChunk.ContainsKey(chunkPos)) {
			return null;
		}
		
		var chunk = _positionToChunk[chunkPos];
		
		// Calculate local coordinates within the chunk
		var localX = Mathf.PosMod(globalPosition.X, Chunk.dimensions.X);
		var localZ = Mathf.PosMod(globalPosition.Z, Chunk.dimensions.Z);
		var localY = globalPosition.Y; // Y coordinate remains the same
		
		// Boundary check to avoid out-of-range exceptions
		if (localX < 0 || localX >= Chunk.dimensions.X || 
			localY < 0 || localY >= Chunk.dimensions.Y || 
			localZ < 0 || localZ >= Chunk.dimensions.Z) {
			return null;
		}
		
		// Get the block from the chunk
		try {
			return chunk.GetBlock(new Vector3I(localX, localY, localZ));
		}
		catch (System.Exception e) {
			GD.PrintErr($"Error getting block at {globalPosition} (local: {localX},{localY},{localZ}): {e.Message}");
			return null;
		}
	}

	// Helper method to find the highest suitable terrain block at a global position
	private int FindHighestTerrainAtPosition(int globalX, int globalZ) {
		// Calculate which chunk contains this global position
		var chunkX = Mathf.FloorToInt(globalX / (float)Chunk.dimensions.X);
		var chunkZ = Mathf.FloorToInt(globalZ / (float)Chunk.dimensions.Z);
		var chunkPos = new Vector2I(chunkX, chunkZ);
		
		// Check if the chunk exists
		if (!_positionToChunk.ContainsKey(chunkPos)) {
			GD.PrintErr($"Chunk at {chunkPos} doesn't exist for tree position");
			return -1;
		}
		
		var chunk = _positionToChunk[chunkPos];
		
		// Calculate local coordinates within the chunk
		var localX = Mathf.PosMod(globalX, Chunk.dimensions.X);
		var localZ = Mathf.PosMod(globalZ, Chunk.dimensions.Z);
		
		// Search from top to bottom for the first non-air block
		for (int y = Chunk.dimensions.Y - 1; y >= 0; y--) {
			try {
				var block = chunk.GetBlock(new Vector3I(localX, y, localZ));
				if (block != null && block.Name != "Air" && 
					(block.Name == "Grass" || block.Name == "Dirt")) {
					GD.Print($"Found suitable ground at {globalX},{globalZ} (local: {localX},{y},{localZ}) in chunk {chunkPos}");
					return y;
				}
			}
			catch (System.Exception e) {
				GD.PrintErr($"Error getting block at {localX},{y},{localZ}: {e.Message}");
			}
		}
		
		return -1; // No suitable block found
	}

	// public void UpdateNavMesh(Vector3[] triangles, Transform3D Transform) {
	// 	// // god-awful way i used to check that all the vertices are properly being added to the navmesh
	// 	// foreach (var vertex in triangles)	
	// 	// {
	// 	// 	var sphere = new SphereMesh();
	// 	// 	sphere.Radius = 0.1f;
	// 	// 	var random = new Random();
	// 	// 	var rotation = new Vector3(
	// 	// 		(float)(random.NextDouble() * Math.PI * 2),
	// 	// 		(float)(random.NextDouble() * Math.PI * 2),
	// 	// 		(float)(random.NextDouble() * Math.PI * 2)
	// 	// 	);
	// 	// 	var sphereInstance = new MeshInstance3D
	// 	// 	{
	// 	// 		Mesh = sphere,
	// 	// 		Transform = new Transform3D(Basis.Identity, vertex)
	// 	// 	};
	// 	// 	sphereInstance.RotateObjectLocal(Vector3.Right, rotation.X);
	// 	// 	sphereInstance.RotateObjectLocal(Vector3.Up, rotation.Y);
	// 	// 	sphereInstance.RotateObjectLocal(Vector3.Forward, rotation.Z);
	// 	// 	AddChild(sphereInstance);
	// 	// }
	// 	NavigationMeshSource.AddFaces(faces: triangles, xform: Transform);
	// }
}
