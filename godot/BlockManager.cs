using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[Tool]
public partial class BlockManager : Node
{
	[Export]
	public Block Air { get; set; }

	[Export]
	public Block Stone { get; set; }

	[Export]
	public Block Dirt { get; set; }

	[Export]
	public Block Grass { get; set; }

	private readonly Dictionary<Texture2D, Vector2I> _atlasLookup = new();

	private int _gridWidth = 4;
	private int _gridHeight = 4;

	public Vector2I BlockTextureSize { get; } = new(16,16);

	public Vector2 TextureAtlasSize { get; private set; }

	public static BlockManager Instance { get; private set; }

	public StandardMaterial3D ChunkMaterial { get; set; }

	public override void _Ready()
	{
		Instance  = this;

		// Array of all block textures
		var blockTextures = new Block[] { Air, Stone, Dirt, Grass }.Select(block => block.texture).Where(texture => texture != null).Distinct().ToArray();

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

		GD.Print($"Done loading {blockTextures.Length} textures into the texture atlas to make a {_gridWidth}x{_gridHeight} grid.");
	}

	public Vector2I GetTextureAtlasCoordinates(Texture2D texture)
	{
		if (_atlasLookup.TryGetValue(texture, out var coords)) {
			return coords;
		}

		return Vector2I.Zero;
	}
}
