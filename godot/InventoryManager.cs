using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[GlobalClass]
public partial class InventoryManager : Resource
{
	//[Export] public Item[] Items { get; set; }
	private Dictionary<String, List<int>> itemDict;
	private Dictionary<int, InventoryItem> slotDict;
	private bool[] inventorySlots;
	private int availableSlot;
	public InventoryManager()
	{
		itemDict = new Dictionary<string, List<int>>();
		slotDict = new Dictionary<int, InventoryItem>();
		inventorySlots = new bool[3];
		availableSlot = 0;
		// Items = [
		// 	new Block {
		// 		Name = "Stone",
		// 		Icon = GD.Load<Texture2D>("res://textures/stone.png"),
		// 		MaxStackSize = 64,
		// 		IsConsumable = false,
		// 		IsBlock = true,
		// 		IsTool = false,
		// 		Texture = GD.Load<Texture2D>("res://textures/stone.png"),
		// 	},
		// 	new Block {
		// 		Name = "Dirt",
		// 		Icon = GD.Load<Texture2D>("res://textures/dirt.png"),
		// 		MaxStackSize = 64,
		// 		IsConsumable = false,
		// 		IsBlock = true,
		// 		IsTool = false,
		// 		Texture = GD.Load<Texture2D>("res://textures/dirt.png"),
		// 	},
		// 	new Tool {
		// 		Name = "Stone Pickaxe",
		// 		Icon = GD.Load<Texture2D>("res://textures/stone_pickaxe.png"),
		// 		MaxStackSize = 1,
		// 		IsConsumable = false,
		// 		IsBlock = false,
		// 		IsTool = true,
		// 		ToolPower = 2,
		// 		Durability = 100,
		// 		Proficency = Proficency.STONE
		// 	},
		// 	new Tool {
		// 		Name = "Wooden Pickaxe",
		// 		Icon = GD.Load<Texture2D>("res://textures/wooden_pickaxe.png"),
		// 		MaxStackSize = 1,
		// 		IsConsumable = false,
		// 		IsBlock = false,
		// 		IsTool = true,
		// 		ToolPower = 1,
		// 		Durability = 50,
		// 		Proficency = Proficency.WOOD
		// 	}
		// ];
	}
	// returns list of slot numbers that have items named itemName
	private List<int> ItemInInventory(string itemName) 
	{
		if(itemDict.ContainsKey(itemName))
		{
			List<int> existSlots = itemDict[itemName];
			return existSlots;
			
		}  else {
			return null;
		}
	}
	// Returns first slot that has room in its stack
	private int CanStack(List<int> slots) 
	{
		foreach (int slot in slots) 
		{
			InventoryItem existingItem = slotDict[slot];
			if (existingItem.count >= existingItem.item.MaxStackSize) 
			{
				return slot; //this slot number has room in its stack
			}
		}
		return -1;
	}
	public bool AddItem(Item item) 
	{
		int selectedSlot;
		//check if item is already in inventory
		List<int> slotNums = ItemInInventory(item.Name);
		if(slotNums != null) 
		{
			//check if there is room in the stack of each slot
			int stackable = CanStack(slotNums);
			if(stackable != -1) 
			{
				selectedSlot = stackable;
				InventoryItem itemStack = slotDict[selectedSlot];
				itemStack.count += 1;
				return true;
			} else 
			{
				selectedSlot = GetSpace();
			}
		} else 
		{
			selectedSlot = GetSpace();
		}
		if(selectedSlot == -1) 
		{
			return false; //Inventory full!
		}
		
		InventoryItem itemStruct = new InventoryItem(item, 0, selectedSlot);
		return true;

	}
	public int GetSpace() 
	{
		for(int i = 0; i < inventorySlots.Length; i++) 
		{
			if (!inventorySlots[i]) 
			{
				return i;
			}
		}
		return -1; // -1 means all slots are filled
	}
}
