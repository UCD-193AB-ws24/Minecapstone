using Godot;
using System.Collections.Generic;

public partial class ItemDictionary : Resource
{
	private static ItemDictionary instance = null;
	private static string Path = "res://assets/icons/placeholder.jpg";
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
		{"Wood Pickaxe", new Tool("Wood Pickaxe", Placeholder, 1, true, 1, 0, Proficency.STONE)},
		{"IronOre", new Block("Iron Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/iron_ore.png"), HarvestLevel: 2, Proficency: Proficency.STONE)},
			{"CopperOre", new Block("Copper Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/copper_ore.png"),  HarvestLevel: 1, Proficency: Proficency.STONE)},
			{"CoalOre", new Block("Coal Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/coal_ore.png"),  HarvestLevel: 1, Proficency: Proficency.STONE)},
			{"GoldOre", new Block("Gold Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/gold_ore.png"),  HarvestLevel: 3, Proficency: Proficency.STONE)},
			{"DiamondOre", new Block("Diamond Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/diamond_ore.png"),  HarvestLevel: 3, Proficency: Proficency.STONE)},
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
