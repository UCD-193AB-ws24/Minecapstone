using Godot;
using System;

public partial class Tool : Item {
	public int ToolPower { get; set; }
	public int Durability { get; set; }
	public Proficency Proficency { get; set; }
}

public enum Proficency {
	STONE,
	WOOD,
	DIRT
}