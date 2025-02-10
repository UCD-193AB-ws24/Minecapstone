using Godot;
using System;

public partial class Tool : Item {
	public int ToolPower { get; set; }
	public int Durability { get; set; }
	public Proficency Proficency { get; set; }

	public Tool(string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable) : base(Name, Icon, MaxStackSize, IsConsumable)
	{
		SetMeta("is_tool", true);
		base.Name = Name;
		base.Icon = Icon;
		base.MaxStackSize = MaxStackSize;
		base.IsConsumable = IsConsumable;
	}
	
	public int GetHarvestLevel() {
		return ToolPower;
	}

	public Proficency GetProficency() {
		return Proficency;
	}

}

public enum Proficency {
	STONE,
	WOOD,
	DIRT
}
