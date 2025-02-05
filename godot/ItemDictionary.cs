using Godot;
using System.Collections.Generic;

// [Tool]
public partial class ItemDictionary : Node
{
	private Dictionary<string, Item> ItemDict;
	string Path = "res://assets/icons/placeholder.jpg";
	
	public ItemDictionary() 
	{
		Texture2D Placeholder = GD.Load<Texture2D>(Path);
		ItemDict = new Dictionary<string, Item>()
		{
			{"Air", new Block("Air", Placeholder, 0, false, null, null, null)},
			{"Dirt", new Block("Dirt", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/dirt.png"))},
			{"Stone", new Block("Stone", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/stone.png"))},
			{"Grass", new Block("Grass", Placeholder, 64, false, 
				(Texture2D)GD.Load("res://assets/side_grass.png"), 
				(Texture2D)GD.Load("res://assets/grass.png"),
				(Texture2D)GD.Load("res://assets/dirt.png"))
			},
			{"IronOre", new Block("Iron Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/iron_ore.png"))},
			{"CopperOre", new Block("Copper Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/copper_ore.png"))},
			{"CoalOre", new Block("Coal Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/coal_ore.png"))},
			{"GoldOre", new Block("Gold Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/gold_ore.png"))},
			{"DiamondOre", new Block("Diamond Ore", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/diamond_ore.png"))},
		};

	}
	public Item Get(string BlockName) 
	{
		return ItemDict[BlockName];
	}

	//Block Dirt = new Block(<parameters here>);
	// instantiate more blocks types

	// store in dictionary here
}
