using Godot;
using System;

[Tool]
[GlobalClass]
public partial class Block : Item {

    [Export] public Texture2D Texture { get; set; }
	[Export] public Texture2D TopTexture { get; set; }
	[Export] public Texture2D BottomTexture { get; set; }

	public Texture2D[] Textures => [Texture, TopTexture, BottomTexture];
	public Block(string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable, bool IsBlock, bool IsTool) 
	: base(Name, Icon, MaxStackSize, IsConsumable, IsBlock, IsTool)
    {
		base.Name = Name;
		base.Icon = Icon;
		base.MaxStackSize = MaxStackSize;
		base.IsConsumable = IsConsumable;
		base.IsBlock = IsBlock;
		base.IsTool = IsTool;
    }
}