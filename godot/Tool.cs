using Godot;
using System;

public partial class Tool : Item {
    public int ToolPower { get; set; }
	public int Durability { get; set; }
	public Proficency Proficency { get; set; }

	public Tool(string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable, bool IsBlock, bool IsTool) : base(Name, Icon, MaxStackSize, IsConsumable, IsBlock, IsTool)
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