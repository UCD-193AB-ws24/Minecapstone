using Godot;
using System;

// [Tool]
[GlobalClass]
public partial class Item : Resource {
	[Export] public string Name { get; set; }

	// This is separate from the Item's 3D model, if any
	public Texture2D Icon { get; set; }

	// Generic item properties
	public int MaxStackSize { get; set; }
	public bool IsConsumable { get; set; }

	// Item type
	public bool IsBlock { get; set; }
	public bool IsTool { get; set; }

	public Item(string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable) {
		this.Name = Name;
		this.Icon = Icon;
		this.MaxStackSize = MaxStackSize;
		this.IsConsumable = IsConsumable;
	}

	public string PrintItem()
	{
		return Name;
	}
}
