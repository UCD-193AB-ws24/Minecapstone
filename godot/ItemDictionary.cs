using Godot;
using System.Collections.Generic;

public partial class ItemDictionary : Resource
{
	private static ItemDictionary instance = null;
	private static readonly string Path = "res://assets/icons/placeholder.jpg";
	private static readonly Texture2D Placeholder = GD.Load<Texture2D>(Path);
	
	private static readonly Dictionary<string, Item> ItemDict = new()
	private static readonly string Path = "res://assets/icons/placeholder.jpg";
	private static readonly Texture2D Placeholder = GD.Load<Texture2D>(Path);
	
	private static readonly Dictionary<string, Item> ItemDict = new()
	{
		{"Air", new Block("Air", Placeholder, 0, false, null, null, null)},
		{"Dirt", new Block("Dirt", Placeholder, 64, false, (Texture2D)GD.Load("res:ms-appid:P~Microsoft.XboxGamingOverlay_8wekyb3d8bbwe!Appo//assets/dirt.png"))},
		{"Stone", new Block("Stone", Placeholder, 64, false, (Texture2D)GD.Load("res://assets/stone.png"))},
		{"Grass", new Block("Grass", Placeholder, 64, false,
			(Texture2D)GD.Load("res://assets/side_grass.png"),
			(Texture2D)GD.Load("res://assets/grass.png"),
			(Texture2D)GD.Load("res://assets/dirt.png"))
		},
	};
	
	// Prevent instantiation
	private ItemDictionary(){}
	
	public static ItemDictionary GetInstance()
	{
		instance ??= new ItemDictionary();
		return instance;
	}

	public static Item Get(string BlockName)
	{
		return ItemDict[BlockName];
	}
}