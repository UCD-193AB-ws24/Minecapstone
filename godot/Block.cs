using Godot;
using System;

[Tool]
[GlobalClass]
public partial class Block : Item {
	[Export] public Texture2D Texture { get; set; }
	[Export] public Texture2D TopTexture { get; set; }
	[Export] public Texture2D BottomTexture { get; set; }

	public Texture2D[] Textures => [Texture, TopTexture, BottomTexture];
}