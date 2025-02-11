using Godot;
using Godot.NativeInterop;
using System;
using System.Collections.Generic;

[Tool]
public partial class ChunkWorldGen : StaticBody3D
{
	[Export]
	public CollisionShape3D CollisionShape { get; set; }
	
	[Export]
	public MeshInstance3D MeshInstance { get; set; }

	public static Vector3I dimensions = new Vector3I(16, 35, 16);

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

	public Vector2I ChunkPosition { get; protected set; }
	public List<Vector2I> SavedChunks = [];
	public Dictionary<Vector3I, Block> SavedBlocks = [];

	const int VIEW_DISTANCE = 64;
	public Vector2I Offset { get; set; } = new Vector2I((VIEW_DISTANCE/2)*16, (VIEW_DISTANCE/2)*16);

	// Sets the chunk position and generate and update the chunk at that position
	// Instead of generating new chunks, just move existing chunks to the desired position, updating blocks and mesh
	public void SetChunkPosition(Vector2I position, Node3D WorldGenerator) {
		// Set chunk position as deferred to ensure the Chunk exists before setting its position
		ChunkManagerWorldGen.Instance.UpdateChunkPosition(this, position, ChunkPosition);
		ChunkPosition = position;
		this.WorldGenerator = WorldGenerator;

		CallDeferred(Node3D.MethodName.SetGlobalPosition, new Vector3(ChunkPosition.X * dimensions.X, 0, ChunkPosition.Y * dimensions.Z));
		
		// After making chunks, puts it into a list of already made chunks
		// SavedChunks.Add(ChunkPosition);
	}

	public override void _Ready() {
		SetMeta("is_chunk", true);
	}

	// Create and set block in the chunk
	public void Generate() {
		if (SavedChunks.Contains(ChunkPosition)) {
			LoadChunk();
			return;
		}

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
				float noiseValue = isLand ? detailedValue : smoothValue;
				int terrainHeight = (int)(dimensions.Y * ((noiseValue + 1f) * 0.5f));
				int stoneHeight = isLand ? 20 : 10;

				for (int y = 0; y < dimensions.Y; y++) {
					Block block;
					if (isLand) {
						if (y < terrainHeight) {
							block = BlockManager.Instance.GetBlock("Dirt");
						}
						else if (y == terrainHeight) {
							block = BlockManager.Instance.GetBlock("Grass");
						}
						else if (y < stoneHeight) {
							block = BlockManager.Instance.GetBlock("Stone");
						}
						else {
							block = BlockManager.Instance.GetBlock("Air");
						}
					}
					else {
						if (y < stoneHeight ) {
							block = BlockManager.Instance.GetBlock("Stone");
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
		ShaderMaterial shaderMaterial = new ShaderMaterial { 
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
		// Temporary fix for air blocks
		var block = _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z];

		if (block == BlockManager.Instance.GetBlock("Air")) return;

		// TODO: also check adjacent chunks for transparent blocks
		// Use the appropriate textures for each face
		if (CheckTransparent(blockPosition + Vector3I.Up)) CreateFaceMesh(_top, blockPosition, block.TopTexture ?? block.Texture, color);
		if (CheckTransparent(blockPosition + Vector3I.Down)) CreateFaceMesh(_bottom, blockPosition, block.BottomTexture ?? block.Texture, color);
		if (CheckTransparent(blockPosition + Vector3I.Left)) CreateFaceMesh(_left, blockPosition, block.Texture, color);
		if (CheckTransparent(blockPosition + Vector3I.Right)) CreateFaceMesh(_right, blockPosition, block.Texture, color);
		if (CheckTransparent(blockPosition + Vector3I.Forward)) CreateFaceMesh(_front, blockPosition, block.Texture, color);
		if (CheckTransparent(blockPosition + Vector3I.Back)) CreateFaceMesh(_back, blockPosition, block.Texture, color);
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
		var colors = new Color[] { color, color, color };

		_surfaceTool.AddTriangleFan(triangle1, uvTriangle1, normals: normals, colors: colors);
		_surfaceTool.AddTriangleFan(triangle2, uvTriangle2, normals: normals, colors: colors);
	}

	// Modified CheckTransparent to query adjacent chunks on the four horizontal sides.
	private bool CheckTransparent(Vector3I blockPosition) {
		if (blockPosition.Y < 0 || blockPosition.Y >= dimensions.Y) return true;
		// Check adjacent chunks for transparent blocks
		if (blockPosition.X < 0) {
			var neighbor = ChunkManagerWorldGen.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(-1, 0));
			if (neighbor != null)
				return neighbor.GetBlock(new Vector3I(dimensions.X - 1, blockPosition.Y, blockPosition.Z)) == BlockManager.Instance.GetBlock("Air");
			else
				return true;
		}
		if (blockPosition.X >= dimensions.X) {
			var neighbor = ChunkManagerWorldGen.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(1, 0));
			if (neighbor != null)
				return neighbor.GetBlock(new Vector3I(0, blockPosition.Y, blockPosition.Z)) == BlockManager.Instance.GetBlock("Air");
			else
				return true;
		}
		if (blockPosition.Z < 0) {
			var neighbor = ChunkManagerWorldGen.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(0, -1));
			if (neighbor != null)
				return neighbor.GetBlock(new Vector3I(blockPosition.X, blockPosition.Y, dimensions.Z - 1)) == BlockManager.Instance.GetBlock("Air");
			else
				return true;
		}
		if (blockPosition.Z >= dimensions.Z) {
			var neighbor = ChunkManagerWorldGen.Instance.GetChunkAtPosition(ChunkPosition + new Vector2I(0, 1));
			if (neighbor != null)
				return neighbor.GetBlock(new Vector3I(blockPosition.X, blockPosition.Y, 0)) == BlockManager.Instance.GetBlock("Air");
			else
				return true;
		}

		return _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z] == BlockManager.Instance.GetBlock("Air");
	}
	
	// Set a block in the chunk
	public void SetBlock(Vector3I blockPosition, Block block) {
		_blocks[blockPosition.X, blockPosition.Y, blockPosition.Z] = block;
		Update();
		
		var globalCoordinates = new Vector3I((ChunkPosition.X * 16) + blockPosition.X, blockPosition.Y, (ChunkPosition.Y * 16) + blockPosition.Z);
		
		// TODO: May need to fix this to account for Offset
		
		if (block == BlockManager.Instance.GetBlock("Air")) {
			SavedBlocks.Remove(globalCoordinates);
		} 
		else {
			SavedBlocks[globalCoordinates] = block;
		}
	}
	
	// Get a block in the chunk
	public Block GetBlock(Vector3I blockPosition) {
		return _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z];
	}
}
