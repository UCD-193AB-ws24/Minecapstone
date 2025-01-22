using Godot;
using System;

[GlobalClass]
public partial class ItemDictionary : Resource
{
	[Export] public Item[] Items { get; set; }

	public ItemDictionary()
	{
		Items = [
			new Block {
				Name = "Stone",
				Icon = GD.Load<Texture2D>("res://textures/stone.png"),
				MaxStackSize = 64,
				IsConsumable = false,
				IsBlock = true,
				IsTool = false,
				Texture = GD.Load<Texture2D>("res://textures/stone.png"),
			},
			new Block {
				Name = "Dirt",
				Icon = GD.Load<Texture2D>("res://textures/dirt.png"),
				MaxStackSize = 64,
				IsConsumable = false,
				IsBlock = true,
				IsTool = false,
				Texture = GD.Load<Texture2D>("res://textures/dirt.png"),
			},
			new Tool {
				Name = "Stone Pickaxe",
				Icon = GD.Load<Texture2D>("res://textures/stone_pickaxe.png"),
				MaxStackSize = 1,
				IsConsumable = false,
				IsBlock = false,
				IsTool = true,
				ToolPower = 2,
				Durability = 100,
				Proficency = Proficency.STONE
			},
			new Tool {
				Name = "Wooden Pickaxe",
				Icon = GD.Load<Texture2D>("res://textures/wooden_pickaxe.png"),
				MaxStackSize = 1,
				IsConsumable = false,
				IsBlock = false,
				IsTool = true,
				ToolPower = 1,
				Durability = 50,
				Proficency = Proficency.WOOD
			}
		];
	}
}
