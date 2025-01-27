using Godot;
using System;

[Tool]
[GlobalClass]
public partial class Block : Item {

    public Texture2D Texture { get; set; }
	public Texture2D TopTexture { get; set; }
	public Texture2D BottomTexture { get; set; }
	public Texture2D[] Textures => [Texture, TopTexture, BottomTexture];
	
	// TODO: check if can use primary constructor
	public Block(string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable, Texture2D Texture = null, Texture2D TopTexture = null, Texture2D BottomTexture = null) 
	: base(Name, Icon, MaxStackSize, IsConsumable)
	{
		base.Name = Name;
		base.Icon = Icon;
		base.MaxStackSize = MaxStackSize;
		base.IsConsumable = IsConsumable;
		this.Texture = Texture;
		this.TopTexture = TopTexture;
		this.BottomTexture = BottomTexture;
	}
}