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
	[Export]
	public float DropVelocity { get; private set; } = 5;
	
	public InventoryManager() {
		selectedSlot = 0;
		name_to_slots = [];
		slots_to_items = [];
		inventorySlots = new bool[InventorySlots];
	}

	// Returns list of slot numbers that have items named itemName
	private List<int> ItemInInventory(string itemName) {
		if (name_to_slots.TryGetValue(itemName, out List<int> value)) {
			List<int> existingSlots = value;
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
	
	public bool DropSelectedItem() {
		if (!inventorySlots[selectedSlot]) return false;
		
		InventoryItem item = slots_to_items[selectedSlot];
		item.count -= 1;
		RigidBody3D droppedItem = (RigidBody3D) item.item.GenerateItem(); //returns item as Node3D but the scene it instantiates is a Rigidbody3D
		Node agent = GetParent();
		Node world = agent.GetParent();
		//set timer till activating monitoring on dropped item
		Node collectTimer = droppedItem.FindChild("CollectTimer");
		world.AddChild(droppedItem); // add to world node
		collectTimer.Call("pick_up_cooldown");
		//drop item forward
		Node3D head = (Node3D) agent.FindChild("Head"); // Head is a Node3D so cast should be fine
		Vector3 facingDir = -head.GlobalTransform.Basis.Z;
		Vector3 genPos = head.GlobalPosition;
		droppedItem.GlobalPosition = genPos;
		//Vector3 throwDir = genPos + facingDir;
		droppedItem.LinearVelocity = facingDir.Normalized() * DropVelocity;
		
		if (item.count == 0) {
			inventorySlots[selectedSlot] = false;
			slots_to_items.Remove(selectedSlot);
			name_to_slots[item.item.Name].Remove(selectedSlot);
		}
		return true;
	}
	
	public void CycleUp() 
	{
		selectedSlot -= 1;
		if (selectedSlot < 0) {
			selectedSlot = inventorySlots.Length - 1;
		}
	}
	
	public void CycleDown() 
	{
		selectedSlot += 1;
		if (selectedSlot > inventorySlots.Length - 1) {
			selectedSlot = 0;
		}
	}
}
