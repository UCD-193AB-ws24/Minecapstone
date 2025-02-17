using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[Tool]
public partial class BlockManager : Node {
	private readonly Dictionary<Texture2D, Vector2I> _atlasLookup = new();
	private int _gridWidth = 4;
	private int _gridHeight = 4;

	public Vector2I BlockTextureSize { get; } = new(16,16);

	public Vector2 TextureAtlasSize { get; private set; }

	public static BlockManager Instance { get; private set; }

	public StandardMaterial3D ChunkMaterial { get; set; }
	
	public Dictionary<Block, float> time_dictionary;

	public List<Block> oreList = new List<Block>{};

	public override void _Ready() {
		Instance = this;

		// TODO: Make this generalized for any number of blocks
		(Block Air, Block Stone, Block Dirt, Block Grass, Block IronOre, Block CopperOre, Block CoalOre, Block GoldOre, Block DiamondOre) = (
			(Block)ItemDictionary.Get("Air"),
			(Block)ItemDictionary.Get("Stone"),
			(Block)ItemDictionary.Get("Dirt"),
			(Block)ItemDictionary.Get("Grass"),
			(Block)ItemDictionary.Get("IronOre"),
			(Block)ItemDictionary.Get("CopperOre"),
			(Block)ItemDictionary.Get("CoalOre"),
			(Block)ItemDictionary.Get("GoldOre"),
			(Block)ItemDictionary.Get("DiamondOre")
		);

		// Array of all block textures
		var blockTextures = new Block[] { Air, Stone, Dirt, Grass, IronOre, CopperOre, CoalOre, GoldOre, DiamondOre }.
		SelectMany(block => block.Textures).Where(texture => texture != null).Distinct().ToArray();

		// Create a lookup table for the texture atlas
		for (int i = 0; i < blockTextures.Length; i++) {
			var texture = blockTextures[i];
			_atlasLookup.Add(texture, new Vector2I(i % _gridWidth, Mathf.FloorToInt(i / _gridWidth)));
		}

		// Calculate the size of the texture atlas
		_gridHeight = Mathf.CeilToInt(blockTextures.Length / (float)_gridWidth);

		// Create the texture atlas
		var image = Image.CreateEmpty(_gridWidth * BlockTextureSize.X, _gridHeight * BlockTextureSize.Y, false, Image.Format.Rgba8);

		for (var x = 0; x < _gridWidth; x++) {
			for (var y = 0; y < _gridHeight; y++) {
				var imgIndex = x + y * _gridWidth;

				if (imgIndex >= blockTextures.Length) continue;

				var currentImage = blockTextures[imgIndex].GetImage();
				currentImage.Convert(Image.Format.Rgba8);

				image.BlitRect(currentImage, new Rect2I(Vector2I.Zero, BlockTextureSize), new Vector2I(x, y) * BlockTextureSize);
			}
		}

		var textureAtlas = ImageTexture.CreateFromImage(image);

		ChunkMaterial = new() {
			AlbedoTexture = textureAtlas,
			TextureFilter = BaseMaterial3D.TextureFilterEnum.Nearest
		};

		TextureAtlasSize = new Vector2(_gridWidth, _gridHeight);

		GD.Print($"Done loading {blockTextures.Length} images to make {_gridWidth} x {_gridHeight} atlas");
		
		time_dictionary = new Dictionary<Block, float>{
			{Air, 0.0f},
			{Stone, 1.5f},
			{Dirt, 0.25f},
			{Grass, 0.25f},
			{CoalOre, 2.5f}, // in real minecraft coal is annoying and takes long to mine
			{CopperOre, 1.75f},
			{IronOre, 2.0f},
			{GoldOre, 2.5f},
			{DiamondOre, 5.0f}
		};
		
		oreList.Add(CoalOre);
		oreList.Add(CopperOre);
		oreList.Add(IronOre);
		oreList.Add(GoldOre);
		oreList.Add(DiamondOre);
	}

	public Vector2I GetTextureAtlasCoordinates(Texture2D texture) {
		if (_atlasLookup.TryGetValue(texture, out var coords)) {
			return coords;
		}

		return Vector2I.Zero;
	}
	
	// Gets the time needed to break a block
	public float GetTime(Block block) {
		return time_dictionary[block];
	}

	public Block GetBlock(String blockName) {
		return (Block)ItemDictionary.Get(blockName);
	}
}
