using Godot;
using System.Collections.Generic;

public partial class ItemDictionary : Node
{
	private static ItemDictionary instance = null;
	private static string Path = "res://assets/placeholder.jpg";
	private static Texture2D Placeholder = GD.Load<Texture2D>(Path);
	private static Dictionary<string, Item> ItemDict = new Dictionary<string, Item>() {
		{"Air", new Block("Air", Placeholder, 0, false, null, null, null)},
		{"Dirt", new Block("Dirt", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/dirt.png"))},
		{"Stone", new Block("Stone", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/stone.png"), HarvestLevel: 1, Proficency: Proficency.STONE)},
		{"Grass", new Block("Grass", Placeholder, 64, false, 
			(Texture2D)GD.Load("res://assets/side_grass.png"), 
			(Texture2D)GD.Load("res://assets/grass.png"),
			(Texture2D)GD.Load("res://assets/dirt.png"))
		},
		{"Sand", new Block("Sand", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/sand.png"))},
		{"Wood", new Block("Wood", Placeholder, 64, false, 
			(Texture2D)GD.Load("res://assets/side_wood.png"), 
			(Texture2D)GD.Load("res://assets/wood.png"), 
			(Texture2D)GD.Load("res://assets/side_wood.png"), 
			HarvestLevel: 1, Proficency: Proficency.WOOD)},
		{"Wood Pickaxe", new Tool("Wood Pickaxe", Placeholder, 1, true, 1, 0, Proficency.STONE)},
		{"Iron Ore", new Block("Iron Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/iron_ore.png"), HarvestLevel: 2, Proficency: Proficency.STONE)},
		{"Copper Ore", new Block("Copper Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/copper_ore.png"),  HarvestLevel: 1, Proficency: Proficency.STONE)},
		{"Coal Ore", new Block("Coal Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/coal_ore.png"),  HarvestLevel: 1, Proficency: Proficency.STONE)},
		{"Gold Ore", new Block("Gold Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/gold_ore.png"),  HarvestLevel: 3, Proficency: Proficency.STONE)},
		{"Diamond Ore", new Block("Diamond Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/diamond_ore.png"),  HarvestLevel: 3, Proficency: Proficency.STONE)},
		{"Meat", new Food("Meat", Placeholder, 64, true, 10)},
	};
	
	
	// Prevent instantiation
	private ItemDictionary(){}
	
	public static ItemDictionary GetInstance() {
		instance ??= new ItemDictionary();
		return instance;
	}

	public static Item Get(string BlockName) {
		return ItemDict[BlockName];
	}
}
