using Godot;
using System.Collections.Generic;

// [Tool]
public static  class ItemDictionary
{
	//private static Dictionary<string, Item> ItemDict;
	private static string Path = "res://assets/icons/placeholder.jpg";
	private static Texture2D Placeholder = GD.Load<Texture2D>(Path);
	private static Dictionary<string, Item> ItemDict = new Dictionary<string, Item>()
	{
		{"Air", new Block("Air", Placeholder, 0, false, null, null, null)},
		{"Dirt", new Block("Dirt", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/dirt.png"))},
		{"Stone", new Block("Stone", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/stone.png"))},
		{"Grass", new Block("Grass", Placeholder, 64, false, 
			(Texture2D)GD.Load("res://assets/side_grass.png"), 
			(Texture2D)GD.Load("res://assets/grass.png"),
			(Texture2D)GD.Load("res://assets/dirt.png"))
		},
	};
	
	// public static ItemDictionary() 
	// {
	// 	Texture2D Placeholder = GD.Load<Texture2D>(Path);
	// 	ItemDict = new Dictionary<string, Item>()
	// 	{
	// 		{"Air", new Block("Air", Placeholder, 0, false, null, null, null)},
	// 		{"Dirt", new Block("Dirt", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/dirt.png"))},
	// 		{"Stone", new Block("Stone", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/stone.png"))},
	// 		{"Grass", new Block("Grass", Placeholder, 64, false, 
	// 			(Texture2D)GD.Load("res://assets/side_grass.png"), 
	// 			(Texture2D)GD.Load("res://assets/grass.png"),
	// 			(Texture2D)GD.Load("res://assets/dirt.png"))
	// 		},
	// 	};

	// }
	public static Item Get(string BlockName) 
	{
		return ItemDict[BlockName];
	}

	//Block Dirt = new Block(<parameters here>);
	// instantiate more blocks types

	// store in dictionary here
}
