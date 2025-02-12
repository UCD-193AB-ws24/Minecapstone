using Godot;
using System;

public partial class Tool : Item {
	public int ToolPower { get; set; }
	public int Durability { get; set; }
	public Proficency Proficency { get; set; }

	public Tool(string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable, int ToolPower, int Durability, Proficency proficency) : base(Name, Icon, MaxStackSize, IsConsumable) {
		SetMeta("is_tool", true);
		base.Name = Name;
		base.Icon = Icon;
		base.MaxStackSize = MaxStackSize;
		base.IsConsumable = IsConsumable;
		this.ToolPower = ToolPower;
		this.Durability = Durability;
		this.Proficency = Proficency;
	}
	
	public int GetHarvestLevel() {
		return ToolPower;
	}

	public Proficency GetProficency() {
		return Proficency;
	}

	public Tool() : base("Unnamed tool", null, 1, false) {
		// TODO: Investigate where this is getting called
		GD.Print("This is not supposed to happen.");
	}
}

public enum Proficency {
	STONE,
	WOOD,
	DIRT
}
