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
		
		// Place trees on a per-chunk basis before starting the chunk transition process
		for (int x = 0; x < view_distance; x++) {
			for (int z = 0; z < view_distance; z++) {
				var index = (z * view_distance) + x;
				_chunks[index].PlaceTrees();
			}
		}

		// Create the mesh using the block data
		for (int x = 0; x < view_distance; x++)
		{
			for (int z = 0; z < view_distance; z++)
			{
				var index = (z * view_distance) + x;
				_chunks[index].Update();
			}
		}
		
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
		_chunkToPosition[chunk] = currentPosition;
		_positionToChunk[currentPosition] = chunk;
	}

	// Creates and sets the block at the desired global position
	public void SetBlock(Vector3I globalPosition, Block block) {
		// Calculate which chunk contains this global position
		var chunkPos = new Vector2I(
			Mathf.FloorToInt(globalPosition.X / (float)Chunk.dimensions.X),
			Mathf.FloorToInt(globalPosition.Z / (float)Chunk.dimensions.Z)
		);
		
		// Lock the position to the chunk in the event that the chunk is being updated
		lock (_positionToChunk) {
			if (_positionToChunk.TryGetValue(chunkPos, out var chunk)) {
				// Only set blocks that are within the valid Y range
				var localPosition = new Vector3I(
					Mathf.PosMod(globalPosition.X, Chunk.dimensions.X),
					globalPosition.Y,
					Mathf.PosMod(globalPosition.Z, Chunk.dimensions.Z)
				);
				chunk.SetBlock(localPosition, block);
			}
		}
	}

	// Updates the player position to help determine the current chunk the player is in.
	public override void _PhysicsProcess(double delta)
	{
		// This class is a [Tool], do not run this if in Editor
		if (Engine.IsEditorHint()) return;

		lock (_playerPositionlock)
		{
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
