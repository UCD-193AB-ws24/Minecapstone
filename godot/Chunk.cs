using Godot;
using System;

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

	public Vector2I ChunkPosition { get; private set; }

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
	}

	public override void _Ready() {
		SetMeta("is_chunk", true);
	}

	// Create and set block in the chunk
	public void Generate() {
		for (int x = 0; x < dimensions.X; x++) {
			for (int y = 0; y < dimensions.Y; y++) {
				for (int z = 0; z < dimensions.Z; z++) {
					Block block;

					// Set layer heights based on random noise
					var globalBlockPosition = ChunkPosition * new Vector2I(dimensions.X, dimensions.Z) + new Vector2(x, z);
					var groundHeight = (int)(dimensions.Y * ((Noise.GetNoise2D(globalBlockPosition.X, globalBlockPosition.Y) + 1f) / 2f));
					
					// Super basic terrain generation
					if (y < groundHeight / 2) {
						block = BlockManager.Instance.Stone;
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

	// Create the mesh for a block
	private void CreateBlockMesh(Vector3I blockPosition) {
		// Temporary fix for air blocks
		var block = _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z];

		if (block == BlockManager.Instance.Air) return;

		// Use the appropriate textures for each face
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

		_surfaceTool.AddTriangleFan(triangle1, uvTriangle1, normals: normals);
		_surfaceTool.AddTriangleFan(triangle2, uvTriangle2, normals: normals);
	}

	// Check if a block is transparent
	private bool CheckTransparent(Vector3I blockPosition) {
		if (blockPosition.X < 0 || blockPosition.X >= dimensions.X) return true;
		if (blockPosition.Y < 0 || blockPosition.Y >= dimensions.Y) return true;
		if (blockPosition.Z < 0 || blockPosition.Z >= dimensions.Z) return true;

		// TODO: support for other transparent blocks
		return _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z] == BlockManager.Instance.Air;
	}
	
	// Set a block in the chunk
	public void SetBlock(Vector3I blockPosition, Block block) {
		_blocks[blockPosition.X, blockPosition.Y, blockPosition.Z] = block;
		Update();
	}
	
	// Get a block in the chunk
	public Block GetBlock(Vector3I blockPosition) {
		return _blocks[blockPosition.X, blockPosition.Y, blockPosition.Z];
	}
}
