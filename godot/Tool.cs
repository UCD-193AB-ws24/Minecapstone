using Godot;
using System;

public partial class Tool : Item {
	public int ToolPower { get; set; }
	public int Durability { get; set; }
	public Proficency Proficency { get; set; }

	public Tool(string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable) : base(Name, Icon, MaxStackSize, IsConsumable)
	{
		base.Name = Name;
		base.Icon = Icon;
		base.MaxStackSize = MaxStackSize;
		base.IsConsumable = IsConsumable;
		base.IsBlock = IsBlock;
		base.IsTool = IsTool;
	}

}

public enum Proficency {
	STONE,
	WOOD,
	DIRT
}
