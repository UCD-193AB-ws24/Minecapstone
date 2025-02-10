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
			{"Stone", new Block("Stone", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/stone.png"), HarvestLevel: 1, Proficency: Proficency.STONE)},
			{"Grass", new Block("Grass", Placeholder, 64, false, 
				(Texture2D)GD.Load("res://assets/side_grass.png"), 
				(Texture2D)GD.Load("res://assets/grass.png"),
				(Texture2D)GD.Load("res://assets/dirt.png"))
			},
			{"WoodPick", new Tool("Wood Pickaxe", Placeholder, 1, true, 1, 0, Proficency.STONE)},
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
