using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[Tool]
public partial class InventoryManager : Node {
	private Dictionary<string, List<int>> name_to_slots;
	private Dictionary<int, InventoryItem> slots_to_items;
	private bool[] inventorySlots;
	private int selectedSlot;
	
	[Export]
	public int InventorySlots { get; private set; } = 3;
	
	public InventoryManager() {
		selectedSlot = 0;
		name_to_slots = [];
		slots_to_items = [];
		inventorySlots = new bool[InventorySlots];
	}

	// Returns list of slot numbers that have items named itemName
	private List<int> ItemInInventory(string itemName) {
		if (name_to_slots.ContainsKey(itemName)) {
			List<int> existingSlots = name_to_slots[itemName];
			return existingSlots;
		} 
		else {
			return null;
		}
	}

	public bool AddItem(Item item, int amount) {
		List<int> slotNums = ItemInInventory(item.Name);

		// Check if item is already in inventory
		if (slotNums != null) {
			// Check each slot to see if there is room in the stack
			foreach (int slot in slotNums) {
				InventoryItem existingItem = slots_to_items[slot];
				if (existingItem.count < existingItem.item.MaxStackSize) {
					//this slot number has room in its stack
					int itemCount = existingItem.count;
					existingItem.count += amount;
					slots_to_items[slot] = existingItem;

					// Debug
					if (itemCount + 1 == slots_to_items[slot].count) {
						return true;
					} 
					else {
						throw new InvalidOperationException("itemCount + 1: " + (itemCount + 1) + " and slotDict[slot].count: " + slots_to_items[slot].count + " don't match");
					}
				}
			}
			
			GD.Print("no room in stack");
			//At this point, we know there is no room in any of the slots. Find a new slot and add to the slotNums list
			int selectedSlot = GetSpace();

			// Return false if inventory is full
			if (selectedSlot == -1) {
				return false;
			}

			InventoryItem itemStruct = new InventoryItem(item, amount);
			slotNums.Add(selectedSlot); //add selectedSlot to list of slots that contain item
			slots_to_items.Add(selectedSlot, itemStruct); // map selectedSlot to itemStruct
			inventorySlots[selectedSlot] = true;
			return true;
		}
		else 
		{
			// there are no inventory slots that contain item. Make a new entry in itemDict and slotDict 
			int selectedSlot = GetSpace();
			
			// Return false if inventory is full
			if (selectedSlot == -1) {
				return false;
			}
			
			InventoryItem itemStruct = new InventoryItem(item, amount);
			List<int> newSlotList = [selectedSlot];
			name_to_slots.Add(item.Name, newSlotList);
			slots_to_items.Add(selectedSlot, itemStruct);
			inventorySlots[selectedSlot] = true;
			
			return true;
		}
	}
	
	public int GetSpace() {
		return Array.IndexOf(inventorySlots, false);
		// for (int i = 0; i < inventorySlots.Length; i++) {
		// 	if (!inventorySlots[i]) {
		// 		return i;
		// 	}
		// }
		// return -1; // -1 means all slots are filled
	}

	public Item GetSelectedItem() {
		if (inventorySlots[selectedSlot]) {
			return slots_to_items[selectedSlot].item;
		}
		else {
			return null;
		}
	}

	public int GetSelectedAmount() {
		if (inventorySlots[selectedSlot]) {
			return slots_to_items[selectedSlot].count;
		}
		else {
			return 0;
		}
	}

	public void ConsumeSelectedItem() {
		if (!inventorySlots[selectedSlot]) return;

		InventoryItem item = slots_to_items[selectedSlot];
		item.count -= 1;
		if (item.count == 0) {
			inventorySlots[selectedSlot] = false;
			slots_to_items.Remove(selectedSlot);
			name_to_slots[item.item.Name].Remove(selectedSlot);
		}
	}
	
	public void CycleUp() {
		selectedSlot -= 1;
		if (selectedSlot < 0) {
			selectedSlot = inventorySlots.Length - 1;
		}
	}
	
	public void CycleDown() {
		selectedSlot += 1;
		if (selectedSlot > inventorySlots.Length - 1) {
			selectedSlot = 0;
		}
	}
	
	public void PrintSelected() {
		GD.Print("Slot: " + selectedSlot);
		if (inventorySlots[selectedSlot]) {
			GD.Print(slots_to_items[selectedSlot].PrintInventoryItem() + " " + slots_to_items[selectedSlot].PrintAmount());
		}
		else {
			GD.Print("Nothing");
		}
	}
	
	public void PrintItem(Item item) {
		GD.Print(item.Name);
	}
	
	public void PrintInventory() {
		for (int i=0; i < inventorySlots.Length; i++) {
			if (inventorySlots[i]) {
				GD.Print(slots_to_items[i].PrintInventoryItem() + " " + slots_to_items[i].PrintAmount());
			}
			else {
				GD.Print("Nothing");
			}
		}
	}
}
