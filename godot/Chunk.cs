using Godot;
using Godot.NativeInterop;
using System;
using System.Collections.Generic;

[Tool]
[GlobalClass]
public partial class Chunk : StaticBody3D
{
	[Export]
	public CollisionShape3D CollisionShape { get; set; }
	
	[Export]
	public MeshInstance3D MeshInstance { get; set; }

	public static Vector3I dimensions = new Vector3I(16, 50, 16);

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

	private Block[,,] _blocks = new Block[dimensions.X, dimensions.Y, dimensions.Z];
	
	// ore data
	private Dictionary<Block, int> maxVeinSize;
	private Dictionary<Block, float> oreSpawnRate;
	private List<Vector3I> skippableBlocks = new List<Vector3I>{};
	
	// transparency debug
	private List<Block> transparentBlocks = new List<Block>{};

	public Vector2I ChunkPosition { get; private set; }
	public List<Vector2I> SavedChunks = [];
	public Dictionary<Vector3I, Block> SavedBlocks = [];

	[Export]
	public FastNoiseLite Noise { get; set; }

	// Sets the chunk position and generate and update the chunk at that position
	// Instead of generating new chunks, just move existing chunks to the desired position, updating blocks and mesh
	public void SetChunkPosition(Vector2I position) {
		// Set chunk position as deferred to ensure the Chunk exists before setting its position
		ChunkManager.Instance.UpdateChunkPosition(this, position, ChunkPosition);
		ChunkPosition = position;
		CallDeferred(Node3D.MethodName.SetGlobalPosition, new Vector3(ChunkPosition.X * dimensions.X, 0, ChunkPosition.Y * dimensions.Z));
		
		Generate();
		Update();
		
		// After making chunks, puts it into a list of already made chunks
		SavedChunks.Add(ChunkPosition);
	}

	public override void _Ready() {
		SetMeta("is_chunk", true);

		
		// TODO: Remove and only use air
		transparentBlocks.Add(BlockManager.Instance.CoalOre);
		transparentBlocks.Add(BlockManager.Instance.CopperOre);
		transparentBlocks.Add(BlockManager.Instance.GoldOre);
		transparentBlocks.Add(BlockManager.Instance.IronOre);
		transparentBlocks.Add(BlockManager.Instance.DiamondOre);


	}

	// Create and set block in the chunk
	public void Generate() {
		if (SavedChunks.Contains(ChunkPosition)) {
			LoadChunk();
			return;
		}
		
		// set the max vein size for each type of ore
		maxVeinSize = new Dictionary<Block, int>{
			{BlockManager.Instance.CoalOre, 8},
			{BlockManager.Instance.CopperOre, 8},
			{BlockManager.Instance.IronOre, 6},
			{BlockManager.Instance.GoldOre, 6},
			{BlockManager.Instance.DiamondOre, 5}
		};

		oreSpawnRate = new Dictionary<Block, float>{
			{BlockManager.Instance.CoalOre, 0.05f},
			{BlockManager.Instance.CopperOre, 0.025f},
			{BlockManager.Instance.IronOre, 0.01f},
			{BlockManager.Instance.GoldOre, 0.005f},
			{BlockManager.Instance.DiamondOre, 0.001f},
		};
		
		Random rng = new Random();
		// generate anywhere from 20 to 30 veins per chunk
		int maxVeinCount = rng.Next(20, 30);
		// max distance between veins 10 to 20
		int oreDistance = rng.Next(10, 20);
		int veinCount = 0;

		for (int x = 0; x < dimensions.X; x++) {
			for (int y = 0; y < dimensions.Y; y++) {
				for (int z = 0; z < dimensions.Z; z++) {
					
					if (IsSkippable(new Vector3I(x,y,z))){
						continue;
					}
					
					Block block;

					// Set layer heights based on random noise
					var globalBlockPosition = ChunkPosition * new Vector2I(dimensions.X, dimensions.Z) + new Vector2(x, z);
					var groundHeight = (int)(dimensions.Y * ((Noise.GetNoise2D(globalBlockPosition.X, globalBlockPosition.Y) + 1f) / 2f));
					var stoneHeight = groundHeight / 1.25;
					
					// TODO: tweak values
					var coalHeight = stoneHeight / 1.25;
					var copperHeight = stoneHeight / 1.5;
					var ironHeight = stoneHeight / 2;
					var goldHeight = stoneHeight / 5;
					var diamondHeight = stoneHeight / 10;

					
					// Super basic terrain generation
					if (y < stoneHeight) {
						// used to determine whether an ore vein should spawn
						float oreRandNum = (float) rng.NextDouble();
							
						// random vein generation
						// order based on rarity (diamond -> coal)
						// TODO: find a better way to choose random number
						if (y < diamondHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.DiamondOre]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.DiamondOre, oreDistance)) {
								block = BlockManager.Instance.Stone;
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.DiamondOre, rng.Next(1, maxVeinSize[BlockManager.Instance.	DiamondOre]));
								veinCount++;
								continue;	
							}
						} 
						else if (y < goldHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.GoldOre]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.GoldOre, oreDistance)) {
								block = BlockManager.Instance.Stone;
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.GoldOre, rng.Next(1, maxVeinSize[BlockManager.Instance.GoldOre]));
								veinCount++;
								continue;
							}
						} 
						else if (y < ironHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.IronOre]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.IronOre, oreDistance)) {
								block = BlockManager.Instance.Stone;
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.IronOre, rng.Next(1, maxVeinSize[BlockManager.Instance.IronOre]));
								veinCount++;
								continue;
							}
						} 
						else if (y < copperHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.CopperOre]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.CopperOre, oreDistance)) {
								block = BlockManager.Instance.Stone;
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.CopperOre, rng.Next(1, maxVeinSize[BlockManager.Instance.CopperOre]));
								veinCount++;
								continue;
							}
						}
						else if (y < coalHeight && oreRandNum < oreSpawnRate[BlockManager.Instance.CoalOre]) {
							if (CheckOreWithinXBlock(new Vector3I(x,y,z), BlockManager.Instance.DiamondOre, oreDistance)) {
								block = BlockManager.Instance.Stone;
							} else {
								GenerateVein(new Vector3I(x, y, z), BlockManager.Instance.CoalOre, rng.Next(1, maxVeinSize[BlockManager.Instance.CoalOre]));
								veinCount++;
								continue;
							}
						} else {
							block = BlockManager.Instance.Stone;
						}
						
					}
					else if (y < groundHeight) {
						block = BlockManager.Instance.Dirt;
					}
					else if (y == groundHeight) {
						block = BlockManager.Instance.Grass;
					}
					else {
						block = BlockManager.Instance.Air;
					}

					_blocks[x, y, z] = block;

					// Save blocks
					if (block != BlockManager.Instance.Air){
						// Only save non air blocks to save space
						var globalCoordinates = new Vector3I((int) globalBlockPosition.X, y, (int)  globalBlockPosition.Y);
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
					var globalBlockPosition = ChunkPosition * new Vector2I(dimensions.X, dimensions.Z) + new Vector2(x, z);
					var globalCoordinates = new Vector3I((int)  globalBlockPosition.X, y, (int)  globalBlockPosition.Y);
					if(SavedBlocks.TryGetValue(globalCoordinates, out Block value)) {
						_blocks[x, y, z] = value;
					} 
					else {
						_blocks[x, y, z] = BlockManager.Instance.Air;
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
					CreateBlockMesh(new Vector3I(x, y, z));
				}
			}
		}

		_surfaceTool.SetMaterial(BlockManager.Instance.ChunkMaterial);
		var mesh = _surfaceTool.Commit();
		
		MeshInstance.Mesh = mesh;
		CollisionShape.Shape = mesh.CreateTrimeshShape();
	}

	public void UpdateNavMesh() {


		for (int x = 0; x < dimensions.X; x++) {
			for (int y = 0; y < dimensions.Y; y++) {
				for (int z = 0; z < dimensions.Z; z++) {
					CreateBlockMesh(new Vector3I(x, y, z));
				}
			}
		}
	}

	// Create the mesh for a block
	private void CreateBlockMesh(Vector3I blockPosition) {
		// Temporary fix for air blocks
		var block = _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z];

		if (block == BlockManager.Instance.Air) return;

		// TODO: also check adjacent chunks for transparent blocks
		// Use the appropriate textures for each face
		if (CheckTransparent(blockPosition) && block != BlockManager.Instance.Air) {
			CreateFaceMesh(_top, blockPosition, block.Texture);
			CreateFaceMesh(_bottom, blockPosition, block.Texture);
			CreateFaceMesh(_left, blockPosition, block.Texture);
			CreateFaceMesh(_right, blockPosition, block.Texture);
			CreateFaceMesh(_front, blockPosition, block.Texture);
			CreateFaceMesh(_back, blockPosition, block.Texture);
		} 
		if (CheckTransparent(blockPosition + Vector3I.Up)) CreateFaceMesh(_top, blockPosition, block.TopTexture ?? block.Texture);
		if (CheckTransparent(blockPosition + Vector3I.Down)) CreateFaceMesh(_bottom, blockPosition, block.BottomTexture ?? block.Texture);
		if (CheckTransparent(blockPosition + Vector3I.Left)) CreateFaceMesh(_left, blockPosition, block.Texture);
		if (CheckTransparent(blockPosition + Vector3I.Right)) CreateFaceMesh(_right, blockPosition, block.Texture);
		if (CheckTransparent(blockPosition + Vector3I.Forward)) CreateFaceMesh(_front, blockPosition, block.Texture);
		if (CheckTransparent(blockPosition + Vector3I.Back)) CreateFaceMesh(_back, blockPosition, block.Texture);
	}

	// Create the mesh for a face
	private void CreateFaceMesh(int[] face, Vector3I blockPosition, Texture2D texture) {
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
		var normal = ((Vector3)(c-a)).Cross((Vector3)(b-a)).Normalized();
		var normals = new Vector3[] { normal, normal, normal };

		ChunkManager chunkManager = ChunkManager.Instance;
		chunkManager.UpdateNavMesh(triangle1, Transform);
		chunkManager.UpdateNavMesh(triangle2, Transform);

		_surfaceTool.AddTriangleFan(triangle1, uvTriangle1, normals: normals);
		_surfaceTool.AddTriangleFan(triangle2, uvTriangle2, normals: normals);
	}

	// Check if a block is transparent
	private bool CheckTransparent(Vector3I blockPosition) {
		if (blockPosition.X < 0 || blockPosition.X >= dimensions.X) return true;
		if (blockPosition.Y < 0 || blockPosition.Y >= dimensions.Y) return true;
		if (blockPosition.Z < 0 || blockPosition.Z >= dimensions.Z) return true;


		if (!transparentBlocks.Contains(BlockManager.Instance.Air)) {
			transparentBlocks.Add(BlockManager.Instance.Air);
		}
		// TODO: support for other transparent blocks
		return transparentBlocks.Contains(_blocks[blockPosition.X, blockPosition.Y, blockPosition.Z]);
	}
	
	// Set a block in the chunk
	public void SetBlock(Vector3I blockPosition, Block block) {
		_blocks[blockPosition.X, blockPosition.Y, blockPosition.Z] = block;
		Update();
		
		var globalCoordinates = new Vector3I((ChunkPosition.X * 16) + blockPosition.X, blockPosition.Y, (ChunkPosition.Y * 16) + blockPosition.Z);
		if(block == BlockManager.Instance.Air){
			SavedBlocks.Remove(globalCoordinates);
		} else {
			SavedBlocks[globalCoordinates] = block;
		}
	}
	
	// Get a block in the chunk
	public Block GetBlock(Vector3I blockPosition) {
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

			if (CheckOreWithinXBlock(next_pos, ore, 1)) {
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
			if (ore != BlockManager.Instance.Air){
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
}
