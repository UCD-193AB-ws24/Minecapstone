using Godot;
using Godot.NativeInterop;
using System;
using System.Collections.Generic;
using System.Linq;

[Tool]
public partial class Chunk : StaticBody3D
{
	[Export]
	public CollisionShape3D CollisionShape { get; set; }
	
	[Export]
	public MeshInstance3D MeshInstance { get; set; }

	public static Vector3I dimensions = new(16, 35, 16);

	private static readonly Vector3[] _vertices = [
		new Vector3I(0,0,0),
		new Vector3I(1,0,0),
		new Vector3I(0,1,0),
		new Vector3I(1,1,0),
		new Vector3I(0,0,1),
		new Vector3I(1,0,1),
		new Vector3I(0,1,1),
		new Vector3I(1,1,1)
	];

	private static readonly int[] _top = [2, 3, 7, 6];
	private static readonly int[] _bottom = [0, 4, 5, 1];
	private static readonly int[] _left = [6, 4, 0, 2];
	private static readonly int[] _right = [3, 1, 5, 7];
	private static readonly int[] _back = [7, 5, 4, 6];
	private static readonly int[] _front = [2, 0, 1, 3];

	private SurfaceTool _surfaceTool = new();
	private Node3D WorldGenerator;

	private Block[,,] _blocks = new Block[dimensions.X, dimensions.Y, dimensions.Z];
	
	// Dictionary to store terrain heights for each x,z coordinate in the chunk
	private Dictionary<Vector2I, int> _terrainHeights = new();

	public Vector2I ChunkPosition { get; protected set; }
	public List<Vector2I> SavedChunks = [];
	public Dictionary<Vector3I, Block> SavedBlocks = [];

	private Vector2I Offset { get; set; }

		// ore data
	private Dictionary<Block, int> maxVeinSize;
	private Dictionary<Block, float> oreSpawnRate;
	private List<Vector3I> skippableBlocks = new List<Vector3I>{};
	
	// transparency debug
	private List<Block> transparentBlocks = new List<Block>{};

	// Preloaded scene resources
	private static readonly PackedScene _interactableBlockScene = GD.Load<PackedScene>("res://benchmarking/prefabs/interactable_block.tscn");

	// Method to instantiate an interactable block
	public Node3D InstantiateInteractableBlock(Vector3 position)	{
		var interactableBlock = _interactableBlockScene.Instantiate<Node3D>();
		interactableBlock.Name = "Tree";
		AddChild(interactableBlock);
		interactableBlock.CallDeferred(Node3D.MethodName.SetGlobalPosition, position + new Vector3(0.5f, 0.5f, 0.5f));
		return interactableBlock;
	}

	// Sets the chunk position and generate and update the chunk at that position
	// Instead of generating new chunks, just move existing chunks to the desired position, updating blocks and mesh
	public void SetChunkPosition(Vector2I position, Node3D WorldGenerator, bool forceUpdate = false) {
		// Set chunk position as deferred to ensure the Chunk exists before setting its position
		ChunkManager.Instance.UpdateChunkPosition(this, position, ChunkPosition);
		ChunkPosition = position;
		this.WorldGenerator = WorldGenerator;

		int VIEW_DISTANCE = (int)WorldGenerator.Get("VIEW_DISTANCE");
		Offset = new Vector2I(VIEW_DISTANCE / 2 * 16, VIEW_DISTANCE / 2 * 16);

		CallDeferred(Node3D.MethodName.SetGlobalPosition, new Vector3(ChunkPosition.X * dimensions.X, 0, ChunkPosition.Y * dimensions.Z));

		if (forceUpdate) {
			Generate();
			Update();
		}

		// After making chunks, puts it into a list of already made chunks
		// SavedChunks.Add(ChunkPosition);
	}

	public override void _Ready() {
		SetMeta("is_chunk", true);

		// TODO: Remove and only use air
		transparentBlocks.Add(BlockManager.Instance.GetBlock("Coal Ore"));
		transparentBlocks.Add(BlockManager.Instance.GetBlock("Copper Ore"));
		transparentBlocks.Add(BlockManager.Instance.GetBlock("Gold Ore"));
		transparentBlocks.Add(BlockManager.Instance.GetBlock("Iron Ore"));
		transparentBlocks.Add(BlockManager.Instance.GetBlock("Diamond Ore"));
	}

	// Create and set block in the chunk
	public void Generate() {
		if (SavedChunks.Contains(ChunkPosition)) {
			LoadChunk();
			return;
		}

		// set the max vein size for each type of ore
		maxVeinSize = new Dictionary<Block, int>{
			{BlockManager.Instance.GetBlock("Coal Ore"), 8},
			{BlockManager.Instance.GetBlock("Copper Ore"), 8},
			{BlockManager.Instance.GetBlock("Iron Ore"), 6},
			{BlockManager.Instance.GetBlock("Gold Ore"), 6},
			{BlockManager.Instance.GetBlock("Diamond Ore"), 5}
		};

		oreSpawnRate = new Dictionary<Block, float>{
			{BlockManager.Instance.GetBlock("Coal Ore"), 0.25f},
			{BlockManager.Instance.GetBlock("Copper Ore"), 0.2f},
			{BlockManager.Instance.GetBlock("Iron Ore"), 0.15f},
			{BlockManager.Instance.GetBlock("Gold Ore"), 0.075f},
			{BlockManager.Instance.GetBlock("Diamond Ore"), 0.025f},
		};

		Random rng = new Random();
		// generate anywhere from 20 to 30 veins per chunk
		int maxVeinCount = rng.Next(20, 30);
		// max distance between veins 5 to 10
		int oreDistance = rng.Next(5, 10);

		// Obtain noise instances from the world generator
		var gdHeightNoise = WorldGenerator.Get("height_noise").As<FastNoiseLite>();
		var gdSmoothHeightNoise = WorldGenerator.Get("smooth_height_noise").As<FastNoiseLite>();

		// Loop over each horizontal column (x,z) then fill vertical blocks
		for (int x = 0; x < dimensions.X; x++) {
			for (int z = 0; z < dimensions.Z; z++) {
				Vector2I globalPos = ChunkPosition * new Vector2I(dimensions.X, dimensions.Z) + new Vector2I(x, z) + Offset;
				float detailedValue = gdHeightNoise.GetNoise2D(globalPos.X, globalPos.Y);
				float smoothValue = gdSmoothHeightNoise.GetNoise2D(globalPos.X, globalPos.Y);
				bool isLand = detailedValue > 0.0f;
				float noiseValue = isLand ? detailedValue : smoothValue + 0.2f;
				int terrainHeight = (int)(dimensions.Y * ((noiseValue + 2f) * 0.25f));
				var stoneHeight = terrainHeight / 1.25;
					
				// TODO: tweak values
				var coalHeight = stoneHeight / 1.25;
				var copperHeight = stoneHeight / 1.5;
				var ironHeight = stoneHeight / 2;
				var goldHeight = stoneHeight / 3;
				var diamondHeight = stoneHeight / 5;

				// Store the calculated terrain height for this x,z coordinate
				_terrainHeights[new Vector2I(x, z)] = terrainHeight;

				for (int y = 0; y < dimensions.Y; y++) {
					if (IsSkippable(new Vector3I(x,y,z))){
						continue;
					}

					Block block;
					if (isLand) {
						if (y < stoneHeight) {
							float oreRandNum = (float) rng.NextDouble();
							
						// random vein generation
						// order based on rarity (diamond -> coal)
						// TODO: find a better way to choose random number
						if (y < diamondHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.GetBlock("Diamond Ore")]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.GetBlock("Air"), oreDistance)) {
								block = BlockManager.Instance.GetBlock("Stone");
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.GetBlock("Diamond Ore"), rng.Next(1, maxVeinSize[BlockManager.Instance.GetBlock("Diamond Ore")]));
								continue;	
							}
						} 
						else if (y < goldHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.GetBlock("Gold Ore")]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.GetBlock("Air"), oreDistance)) {
								block = BlockManager.Instance.GetBlock("Stone");
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.GetBlock("Gold Ore"), rng.Next(1, maxVeinSize[BlockManager.Instance.GetBlock("Gold Ore")]));
								continue;
							}
						} 
						else if (y < ironHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.GetBlock("Iron Ore")]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.GetBlock("Air"), oreDistance)) {
								block = BlockManager.Instance.GetBlock("Stone");
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.GetBlock("Iron Ore"), rng.Next(1, maxVeinSize[BlockManager.Instance.GetBlock("Iron Ore")]));
								continue;
							}
						} 
						else if (y < copperHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.GetBlock("Copper Ore")]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.GetBlock("Air"), oreDistance)) {
								block = BlockManager.Instance.GetBlock("Stone");
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.GetBlock("Copper Ore"), rng.Next(1, maxVeinSize[BlockManager.Instance.GetBlock("Copper Ore")]));
								continue;
							}
						}
						else if (y < coalHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.GetBlock("Coal Ore")]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.GetBlock("Air"), oreDistance)) {
								block = BlockManager.Instance.GetBlock("Stone");
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.GetBlock("Coal Ore"), rng.Next(1, maxVeinSize[BlockManager.Instance.GetBlock("Coal Ore")]));
								continue;
							}
						} else {
							block = BlockManager.Instance.GetBlock("Stone");
						}
						}
						else if (y == terrainHeight) {
							block = BlockManager.Instance.GetBlock("Grass");
						}
						else if (y < terrainHeight) {
							block = BlockManager.Instance.GetBlock("Dirt");
						}
						else {
							block = BlockManager.Instance.GetBlock("Air");
						}
					}
					else {
						if (y <= terrainHeight - 7 || y == 0) {
							block = BlockManager.Instance.GetBlock("Sand");
						}
						else {
							block = BlockManager.Instance.GetBlock("Air");
						}
					}
					
					_blocks[x, y, z] = block;

					if (block != BlockManager.Instance.GetBlock("Air")) {
						var globalCoordinates = new Vector3I(globalPos.X, y, globalPos.Y);
						SavedBlocks[globalCoordinates] = block;
					}
				}
			}
		}

		skippableBlocks.Clear();
	}

	private void LoadChunk(){
		for (int x = 0; x < dimensions.X; x++) {
			for (int y = 0; y < dimensions.Y; y++) {
				for (int z = 0; z < dimensions.Z; z++) {
					var globalBlockPosition = ChunkPosition * new Vector2I(dimensions.X, dimensions.Z) + new Vector2(x, z) + Offset;
					var globalCoordinates = new Vector3I((int)  globalBlockPosition.X, y, (int)  globalBlockPosition.Y);
					if(SavedBlocks.TryGetValue(globalCoordinates, out Block value)) {
						_blocks[x, y, z] = value;
					} 
					else {
						_blocks[x, y, z] = BlockManager.Instance.GetBlock("Air");
					}
				}
			}
		}
	}

	// Update the mesh and collision shape of the chunk
	public void Update() {
		_surfaceTool.Begin(Mesh.PrimitiveType.Triangles);

		for (int x = 0; x < dimensions.X; x++) {
			for (int y = 0; y < dimensions.Y; y++) {
				for (int z = 0; z < dimensions.Z; z++) {
					// TODO: investigate preloading instead of continuously quering for biome color
					var globalPos = ChunkPosition * new Vector2I(dimensions.X, dimensions.Z) + new Vector2I(x, z) + Offset;
					Color biomeColor = (Color)WorldGenerator.Call("get_biome_color", globalPos.X, globalPos.Y);
					CreateBlockMesh(new Vector3I(x, y, z), biomeColor);
				}
			}
		}

		// Load the shader material
		StandardMaterial3D material = BlockManager.Instance.ChunkMaterial;
		ShaderMaterial shaderMaterial = new() {
			Shader = GD.Load<Shader>("res://shaders/vertex_color_shader.gdshader")
		};
		material.NextPass = shaderMaterial;
		_surfaceTool.SetMaterial(material);

		var mesh = _surfaceTool.Commit();
		MeshInstance.Mesh = mesh;
		CollisionShape.Shape = mesh.CreateTrimeshShape();
	}

	// public void UpdateNavMesh() {
	// 	for (int x = 0; x < dimensions.X; x++) {
	// 		for (int y = 0; y < dimensions.Y; y++) {
	// 			for (int z = 0; z < dimensions.Z; z++) {
	// 				CreateBlockMesh(new Vector3I(x, y, z));
	// 			}
	// 		}
	// 	}
	// }

	// Create the mesh for a block
	private void CreateBlockMesh(Vector3I blockPosition, Color color) {
		var block = _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z];

		if (block == BlockManager.Instance.GetBlock("Air")) return;

		// Only apply biome color to grass and dirt blocks
		Color blockColor = (block.Name == "Grass" || block.Name == "Dirt") ? color : Colors.White;

		// TODO: also check adjacent chunks for transparent blocks
		// Use the appropriate textures for each face
		if (CheckTransparent(blockPosition) && block != BlockManager.Instance.GetBlock("Air")) {
			CreateFaceMesh(_top, blockPosition, block.Texture, blockColor);
			CreateFaceMesh(_bottom, blockPosition, block.Texture, blockColor);
			CreateFaceMesh(_left, blockPosition, block.Texture, blockColor);
			CreateFaceMesh(_right, blockPosition, block.Texture, blockColor);
			CreateFaceMesh(_front, blockPosition, block.Texture, blockColor);
			CreateFaceMesh(_back, blockPosition, block.Texture, blockColor);
		} 
		if (CheckTransparent(blockPosition + Vector3I.Up)) CreateFaceMesh(_top, blockPosition, block.TopTexture ?? block.Texture, blockColor);
		if (CheckTransparent(blockPosition + Vector3I.Down)) CreateFaceMesh(_bottom, blockPosition, block.BottomTexture ?? block.Texture, blockColor);
		if (CheckTransparent(blockPosition + Vector3I.Left)) CreateFaceMesh(_left, blockPosition, block.Texture, blockColor);
		if (CheckTransparent(blockPosition + Vector3I.Right)) CreateFaceMesh(_right, blockPosition, block.Texture, blockColor);
		if (CheckTransparent(blockPosition + Vector3I.Forward)) CreateFaceMesh(_front, blockPosition, block.Texture, blockColor);
		if (CheckTransparent(blockPosition + Vector3I.Back)) CreateFaceMesh(_back, blockPosition, block.Texture, blockColor);
	}

	// Create the mesh for a face
	private void CreateFaceMesh(int[] face, Vector3I blockPosition, Texture2D texture, Color color) {
		var texturePosition = BlockManager.Instance.GetTextureAtlasCoordinates(texture);
		var textureAtlasSize = BlockManager.Instance.TextureAtlasSize;

		var uvOffset = texturePosition / textureAtlasSize;
		var uvWidth = 1f / textureAtlasSize.X;
		var uvHeight = 1f / textureAtlasSize.Y;

		// UV corners
		var uvA = uvOffset + new Vector2(0, 0);
		var uvB = uvOffset + new Vector2(0, uvHeight);
		var uvC = uvOffset + new Vector2(uvWidth, uvHeight);
		var uvD = uvOffset + new Vector2(uvWidth, 0);

		// Corner vertices
		var a = _vertices[face[0]] + blockPosition;
		var b = _vertices[face[1]] + blockPosition;
		var c = _vertices[face[2]] + blockPosition;
		var d = _vertices[face[3]] + blockPosition;

		// Define UV triangles
		var uvTriangle1 = new Vector2[] { uvA, uvB, uvC };
		var uvTriangle2 = new Vector2[] { uvA, uvC, uvD };

		// Define physical triangles
		var triangle1 = new Vector3[] { a, b, c };
		var triangle2 = new Vector3[] { a, c, d };

		// Normal vector using cross product
		var normal = (c - a).Cross(b - a).Normalized();
		var normals = new Vector3[] { normal, normal, normal };

		// Define colors for the vertices
		var colors = new Color[] { color };

		_surfaceTool.AddTriangleFan(triangle1, uvTriangle1, normals: normals, colors: colors);
		_surfaceTool.AddTriangleFan(triangle2, uvTriangle2, normals: normals, colors: colors);
	}

	private bool CheckTransparent(Vector3I blockPosition) {
		if (blockPosition.Y < 0 || blockPosition.Y >= dimensions.Y) return true;
		if (!transparentBlocks.Contains(BlockManager.Instance.GetBlock("Air"))) {
			transparentBlocks.Add(BlockManager.Instance.GetBlock("Air"));
		}
		/*
			If blockPosition is at the edge of the chunk
			Query adjacent chunks on the four horizontal sides for transparent blocks
		*/
		if (blockPosition.X < 0) {
			var neighbor = ChunkManager.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(-1, 0));
			if (neighbor != null)
				return transparentBlocks.Contains(neighbor.GetBlock(new Vector3I(dimensions.X - 1, blockPosition.Y, blockPosition.Z)));
			else
				return true;
		}
		if (blockPosition.X >= dimensions.X) {
			var neighbor = ChunkManager.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(1, 0));
			if (neighbor != null)
				return transparentBlocks.Contains(neighbor.GetBlock(new Vector3I(0, blockPosition.Y, blockPosition.Z)));
			else
				return true;
		}
		if (blockPosition.Z < 0) {
			var neighbor = ChunkManager.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(0, -1));
			if (neighbor != null)
				return transparentBlocks.Contains(neighbor.GetBlock(new Vector3I(blockPosition.X, blockPosition.Y, dimensions.Z - 1)));
			else
				return true;
		}
		if (blockPosition.Z >= dimensions.Z) {
			var neighbor = ChunkManager.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(0, 1));
			if (neighbor != null)
				return transparentBlocks.Contains(neighbor.GetBlock(new Vector3I(blockPosition.X, blockPosition.Y, 0)));
			else
				return true;
		}

		return transparentBlocks.Contains(_blocks[blockPosition.X, blockPosition.Y, blockPosition.Z]);
	}
	
	// Set a block in the chunk at the specified local position
	public void SetBlock(Vector3I blockPosition, Block block) {
		// Set the block in the array
		_blocks[blockPosition.X, blockPosition.Y, blockPosition.Z] = block;
		
		// Convert to global coordinates for the SavedBlocks dictionary
		var globalCoordinates = new Vector3I(
			(ChunkPosition.X * dimensions.X) + blockPosition.X,
			blockPosition.Y,
			(ChunkPosition.Y * dimensions.Z) + blockPosition.Z
		);
		
		// Update the saved blocks dictionary
		if (block == BlockManager.Instance.GetBlock("Air")) {
			if (SavedBlocks.ContainsKey(globalCoordinates)) {
				SavedBlocks.Remove(globalCoordinates);
			}
		}
		else {
			SavedBlocks[globalCoordinates] = block;
		}

		// Force update for this chunk and adjacent chunks if needed
		Update();
		
		// Force update for adjacent chunks if an air block is set at the chunk edge
		if (block == BlockManager.Instance.GetBlock("Air")) {
			// Check left edge
			if (blockPosition.X == 0) {
				var leftNeighbor = ChunkManager.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(-1, 0));
				leftNeighbor?.Update();
			}
			// Check right edge
			if (blockPosition.X == dimensions.X - 1) {
				var rightNeighbor = ChunkManager.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(1, 0));
				rightNeighbor?.Update();
			}
			// Check front edge (assuming front corresponds to Z == 0)
			if (blockPosition.Z == 0) {
				var frontNeighbor = ChunkManager.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(0, -1));
				frontNeighbor?.Update();
			}
			// Check back edge (assuming back corresponds to Z == dimensions.Z - 1)
			if (blockPosition.Z == dimensions.Z - 1) {
				var backNeighbor = ChunkManager.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(0, 1));
				backNeighbor?.Update();
			}
		}
	}
	
	// Get a block in the chunk at the specified local position
	public Block GetBlock(Vector3I blockPosition) {
		// Bounds checking
		if (blockPosition.X < 0 || blockPosition.X >= dimensions.X ||
			blockPosition.Y < 0 || blockPosition.Y >= dimensions.Y ||
			blockPosition.Z < 0 || blockPosition.Z >= dimensions.Z) {
			// Return null for out-of-bounds requests
			return null;
		}
		
		return _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z];
	}

		// Generates an Ore Vein
	public void GenerateVein(Vector3I position, Block ore, int veinSize) {
		skippableBlocks.Add(position);
		_blocks[position.X, position.Y, position.Z] = ore;

		Random rng = new Random();
		var globalBlockPosition = ChunkPosition * new Vector2I(dimensions.X, dimensions.Z) + new Vector2(position.X, position.Z);
		
		// try again counter for generation (specifically for ore checking), max 3 tries
		var againCount = 0;

		
		// add rest of vein in random directions
		for (int i = 1; i < veinSize; i++) {
			int next_x = rng.Next(-1, 1);
			int next_y = rng.Next(-1, 1);
			int next_z = rng.Next(-1, 1);

			if (next_x == 0 && next_z == 0 && next_y == 0) {
				next_y = 1;
			}

			Vector3I next_pos = new Vector3I(position.X + next_x, position.Y + next_y, position.Z + next_z);
			
						
			if (next_pos.X < 0) {
				next_pos.X = 0; 
			} else if (next_pos.X > dimensions.X) {
				next_pos.X = dimensions.X;
			}

			
			if (next_pos.Y < 0) {
				next_pos.Y = 0; 
			} else if (next_pos.Y > dimensions.Y) {
				next_pos.Y = dimensions.Y;
			}

			
			if (next_pos.Z < 0) {
				next_pos.Z = 0; 
			} else if (next_pos.Z > dimensions.Z) {
				next_pos.Z = dimensions.Z;
			}



			if (IsSkippable(next_pos)) {
				continue;
			}

			if (CheckOreWithinXBlock(next_pos, ore, 5)) {
				// try again
				if (againCount < 3) {
					i--;
					againCount++;
				} else {
					//skipping so we reset counter
					againCount = 0;
				}
				continue;
			}

			_blocks[next_pos.X, next_pos.Y, next_pos.Z] = ore;

			// Save blocks
			if (ore != BlockManager.Instance.GetBlock("Air")){
				// Only save non air blocks to save space
				var globalCoordinates = new Vector3I((int) globalBlockPosition.X, next_pos.Y, (int)  globalBlockPosition.Y);
				SavedBlocks[globalCoordinates] = ore;
			}

			// reset counter, was a successful generation
			againCount = 0;
			
		}
		
	}

	public bool IsSkippable(Vector3I pos) {
		for (int i = 0; i < skippableBlocks.Count; i++) {
			if (skippableBlocks[i].X == pos.X && skippableBlocks[i].Y == pos.Y && skippableBlocks[i].Z == pos.Z) {
				return true;
			}
		}

		return false;
	}

	// checks if theres an ore within X amount of block on the x, y, or z
	// this is to help spread out ore vein generation 
	public bool CheckOreWithinXBlock(Vector3I pos, Block ore, int distance) {
		for (int x = -distance/2; x < distance/2; x++) {
			for (int y = -distance/2; y < distance/2; y++) {
				for (int z = -distance/2; z < distance/2; z++){
					if (pos.X + x < 0 || pos.X + x >= dimensions.X) {
						continue;
					}
					if (pos.Y + y < 0 || pos.Y + y >= dimensions.Y) {
						continue;
					}
					if (pos.Z + z < 0 || pos.Z + z >= dimensions.Z) {
						continue;
					}
					
					
					if (BlockManager.Instance.oreList.Contains(_blocks[pos.X + x, pos.Y + y, pos.Z + z])){
						if (_blocks[pos.X + x, pos.Y + y, pos.Z + z] == ore) {
							continue;
						}
						return true;
					}
				}
			}
		}

		return false;
	}
	
	// Place trees within this chunk
	public void PlaceTrees() {
		if (WorldGenerator == null) {
			GD.PrintErr("WorldGenerator reference is null");
			return;
		}
		
		// Get all tree positions from the world generator
		var allTreePositions = WorldGenerator.Call("get_tree_positions").AsGodotArray<Vector2>();
		if (allTreePositions == null || allTreePositions.Count == 0) {
			return;
		}

		// Convert tree positions to global world space coordinates
		int worldSize = (int)WorldGenerator.Get("VIEW_DISTANCE") * 16;
		Vector2I worldOffset = new(worldSize/2, worldSize/2);
		
		// Get the wood block for tree trunks
		var woodBlock = (Block)ItemDictionary.Get("Wood");
		
		// Set seed for consistent tree generation
		var random = new Random(42 + ChunkPosition.X * 100 + ChunkPosition.Y); // Unique seed per chunk
		
		// Check each tree position to see if it falls within this chunk
		foreach (var pos in allTreePositions) {
			// Convert from world generator space to global coordinates
			var globalX = (int)pos.X - worldOffset.X;
			var globalZ = (int)pos.Y - worldOffset.Y;

			// Check if this tree position belongs to this chunk
			int chunkX = (int)Math.Floor((float)globalX / dimensions.X);
			int chunkZ = (int)Math.Floor((float)globalZ / dimensions.Z);
			if (chunkX != ChunkPosition.X || chunkZ != ChunkPosition.Y) {
				continue; // Skip if not in this chunk
			}

			// Convert to local coordinates within this chunk
			var localX = Mathf.PosMod(globalX, dimensions.X);
			var localZ = Mathf.PosMod(globalZ, dimensions.Z);

			// Get terrain height from the stored dictionary
			var localPos = new Vector2I(localX, localZ);
			if (!_terrainHeights.TryGetValue(localPos, out int terrainHeight)) {
				continue; // Skip if terrain height not found
			}

			// Skip if the terrain is not suitable (e.g., water)
			var surfaceBlock = _blocks[localX, terrainHeight, localZ];
			if (surfaceBlock == null ||
				!(surfaceBlock.Name == "Grass" || surfaceBlock.Name == "Dirt")) {
				continue;
			}

			// Generate tree
			int treeHeight = 3 + random.Next(4); // Random height between 3-6 blocks

			// GD.Print("Placing tree at: " + new Vector3(globalX, terrainHeight + 1, globalZ) + " in chunk " + ChunkPosition + " Debug: " + chunkX + " " + chunkZ);
			InstantiateInteractableBlock(new Vector3(globalX, terrainHeight + 1, globalZ));

			// Ensure there's enough space above for the tree
			if (terrainHeight + treeHeight >= dimensions.Y) {
				treeHeight = dimensions.Y - terrainHeight - 1;
				if (treeHeight <= 2) continue; // Skip if not enough height
			}

			// Place trunk
			for (int h = 1; h <= treeHeight; h++) {
				var blockPos = new Vector3I(localX, terrainHeight + h, localZ);

				// Skip if there's already a block here
				if (_blocks[blockPos.X, blockPos.Y, blockPos.Z] != BlockManager.Instance.GetBlock("Air")) {
					continue;
				}

				_blocks[blockPos.X, blockPos.Y, blockPos.Z] = woodBlock;

				// Save to the SavedBlocks dictionary
				var globalCoordinates = new Vector3I(
					globalX,
					terrainHeight + h,
					globalZ
				);
				SavedBlocks[globalCoordinates] = woodBlock;
			}
			// Future enhancement: Add leaves
		}
	}
}
