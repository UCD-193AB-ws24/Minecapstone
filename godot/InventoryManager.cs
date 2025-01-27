using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[GlobalClass]
public partial class InventoryManager : Node
{
	//[Export] public Item[] Items { get; set; }
	private Dictionary<String, List<int>> name2SlotsDict;
	private Dictionary<int, InventoryItem> slot2ItemsDict;
	private bool[] inventorySlots;
	private int selectedSlot;
	public InventoryManager()
	{
		selectedSlot = 0;
		name2SlotsDict = new Dictionary<string, List<int>>();
		slot2ItemsDict = new Dictionary<int, InventoryItem>();
		inventorySlots = new bool[3];

	}
	// returns list of slot numbers that have items named itemName
	private List<int> ItemInInventory(string itemName) 
	{
		if(name2SlotsDict.ContainsKey(itemName))
		{
			List<int> existingSlots = name2SlotsDict[itemName];
			return existingSlots;
			
		}  else {
			return null;
		}
	}
	public bool AddItem(Item item) 
	{
		
		//check if item is already in inventory
		List<int> slotNums = ItemInInventory(item.Name);
		if(slotNums != null) 
		{
			
			//check each slot to see if there is room in the stack
			foreach (int slot in slotNums) 
			{
				InventoryItem existingItem = slot2ItemsDict[slot];
				if (existingItem.count < existingItem.item.MaxStackSize) 
				{
					//this slot number has room in its stack
					int itemCount = existingItem.count;
					existingItem.count += 1;
					slot2ItemsDict[slot] = existingItem;
					if(itemCount + 1 == slot2ItemsDict[slot].count) //testing
					{
						return true;
					} else {
						throw new InvalidOperationException("itemCount + 1: " + (itemCount + 1) + " and slotDict[slot].count: " + slot2ItemsDict[slot].count + " don't match");
					}
					
				}
			}
			GD.Print("no room in stack");
			//At this point, we know there is no room in any of the slots. Find a new slot and add to the slotNums list
			int selectedSlot = GetSpace();

			//Check if inventory is full
			if(selectedSlot == -1) 
			{
				return false; //inventory is full!
			}
			InventoryItem itemStruct = new InventoryItem(item, 1);
			slotNums.Add(selectedSlot); //add selectedSlot to list of slots that contain item
			slot2ItemsDict.Add(selectedSlot, itemStruct); // map selectedSlot to itemStruct
			inventorySlots[selectedSlot] = true;
			return true;

		} else {
			// there are no inventory slots that contain item. Make a new entry in itemDict and slotDict 
			int selectedSlot = GetSpace();
			//Check if inventory is full
			if(selectedSlot == -1) 
			{
				return false; //inventory is full!
			}
			InventoryItem itemStruct = new InventoryItem(item, 1);
			List<int> newSlotList = new List<int>();
			newSlotList.Add(selectedSlot);
			name2SlotsDict.Add(item.Name, newSlotList);
			slot2ItemsDict.Add(selectedSlot, itemStruct);
			inventorySlots[selectedSlot] = true;
			return true;
		}

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
	public void CycleUp() 
	{
		selectedSlot -= 1;
		if(selectedSlot < 0) 
		{
			selectedSlot = inventorySlots.Length - 1;
		}
	}
	public void CycleDown() 
	{
		selectedSlot += 1;
		if(selectedSlot > inventorySlots.Length - 1)
		{
			selectedSlot = 0;
		}
	}
	public void PrintSelected() {
		GD.Print("Slot: " + selectedSlot);
		if(inventorySlots[selectedSlot]) 
		{
			
			GD.Print(slot2ItemsDict[selectedSlot].PrintInventoryItem() + " " + slot2ItemsDict[selectedSlot].PrintAmount());
		}else
		{
			GD.Print("Nothing");
		}
		
	}
	public void PrintItem(Item item)
	{
		GD.Print(item.Name);
	}
	public void PrintInventory() 
	{
		for(int i =0; i < inventorySlots.Length; i++) 
		{
			if(inventorySlots[i])
			{
				GD.Print(slot2ItemsDict[i].PrintInventoryItem() + " " + slot2ItemsDict[i].PrintAmount());
			} else 
			{
				GD.Print("Nothing");
			}
		}
	}
}
