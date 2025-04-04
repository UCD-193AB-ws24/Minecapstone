using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[Tool]
public partial class InventoryManager : Node 
{
	[Export]
	public float DropVelocity { get; set; } = 5;
	
	private readonly Dictionary<string, List<int>> _nameToSlots = [];
	private readonly Dictionary<int, InventoryItem> _slotsToItems = [];
	private int _selectedSlot = 0;
	private bool[] _inventorySlots;
	// TODO, using an export here doesn't work on InventorySlots. 
	// set this up in player's ready function instead.
	public int InventorySlots { get; set; } = 9;
	public int SelectedSlot => _selectedSlot;

	public InventoryManager() {
		_inventorySlots = new bool[InventorySlots];
	}

	public int GetSpace() => Array.IndexOf(_inventorySlots, false);
	
	public Item GetSelectedItem() => 
		_inventorySlots[_selectedSlot] ? _slotsToItems[_selectedSlot].item : null;

	public int GetSelectedAmount() => 
		_inventorySlots[_selectedSlot] ? _slotsToItems[_selectedSlot].count : 0;

	public void CycleUp() => 
		_selectedSlot = _selectedSlot > 0 ? _selectedSlot - 1 : _inventorySlots.Length - 1;
	
	public void CycleDown() => 
		_selectedSlot = _selectedSlot < _inventorySlots.Length - 1 ? _selectedSlot + 1 : 0;

	public void ConsumeSelectedItem() {
		if (!_inventorySlots[_selectedSlot]) return;
		DecrementItemInSlot(_selectedSlot);
	}

	public bool DropItem(String itemName, int amount) {
		int currentAmount = amount;
		if(!_nameToSlots.ContainsKey(itemName))
		{
			return false;
		}
		List<int> slotNums = _nameToSlots[itemName];
		//check starting from the most recent slotnum 
		for(int i = slotNums.Count - 1; i >= 0; i--) {
			InventoryItem items = _slotsToItems[slotNums[i]];
			if(items.count >= currentAmount) 
			{
				//spawn items equal to currentAmount
				for (int j = 0; j < currentAmount; j++) {
					SpawnDroppedItem(items.item);
				}
				items.count -= currentAmount;
				if(items.count > 0)
				{
					//leftover amounts in item
					return true;
				}
				// _inventorySlots[slotNums[i]] = false;
				// _slotsToItems.Remove(slotNums[i]);
				// _nameToSlots[itemName].Remove(slotNums[i]);
				// //Check if there is anymore slots that contain the item
				// if(_nameToSlots[itemName].Count <= 0)
				// {
				// 	_nameToSlots.Remove(itemName);
				// }
				ReleaseItemSlot(itemName, slotNums[i]);
				return true;
			} else 
			{
				//items.count < amount
				//spawn items equal to currentAmount
				for (int j = 0; j < items.count; j++) {
					SpawnDroppedItem(items.item);
				}
				//subtract amount from item.count
				amount -= items.count;
				// _inventorySlots[slotNums[i]] = false;
				// _slotsToItems.Remove(slotNums[i]);
				// _nameToSlots[itemName].Remove(slotNums[i]);
				ReleaseItemSlot(itemName, slotNums[i]);
			}
		}
		//if the loop exits here, then the agent still has more it wants to drop but there's no more of the item to drop
		//return true because the agent drops all quantities of the item 
		return true;
	}
	
	//FUNCTION FOR PLAYER: Drop one of the item currently selected in the hotbar
	public bool DropSelectedItem() {
		if (!_inventorySlots[_selectedSlot]) return false;
		var item = _slotsToItems[_selectedSlot];
		SpawnDroppedItem(item.item);
		DecrementItemInSlot(_selectedSlot);
		return true;
	}
	
	public bool DropSelectedStack() {
		if (!_inventorySlots[_selectedSlot]) return false;
		
		var item = _slotsToItems[_selectedSlot];
		SpawnMultipleDroppedItems(item.item, item.count);
		RemoveItemInSlot(_selectedSlot);
		return true;
	}
	public void DropAllItems() {
		for (int i = 0; i < _inventorySlots.Length; i++) {
			if (_inventorySlots[i]) {
				RemoveItemInSlot(i);
			}
		}
	}

	public bool AddItem(Item item, int amount) {
		if (TryAddToExistingStack(item, amount)) return true;
		return TryAddToNewSlot(item, amount);
	}
	
	// Returns list of slot numbers that have items named itemName
	private List<int> ItemInInventory(string itemName) => 
		_nameToSlots.TryGetValue(itemName, out List<int> slots) ? slots : null;

	private bool TryAddToExistingStack(Item item, int amount) {
		var slotNums = ItemInInventory(item.Name);
		if (slotNums == null) return false;

		foreach (int slot in slotNums) {
			var existingItem = _slotsToItems[slot];
			if (existingItem.count >= existingItem.item.MaxStackSize) continue;
			
			int itemCount = existingItem.count;
			existingItem.count += amount;
			_slotsToItems[slot] = existingItem;
			
			if (itemCount + 1 != _slotsToItems[slot].count) {
				throw new InvalidOperationException($"Count mismatch: {itemCount + 1} vs {_slotsToItems[slot].count}");
			}
			return true;
		}
		return false;
	}

	private bool TryAddToNewSlot(Item item, int amount) {
		// At this point, we know there is no room in any of the slots. Find a new slot and add to the slotNums list
		int slot = GetSpace();

		// Return false if inventory is full
		if (slot == -1) return false;

		if (!_nameToSlots.ContainsKey(item.Name)) {
			_nameToSlots[item.Name] = [slot];
		}
		else {
			_nameToSlots[item.Name].Add(slot);
		}
		
		var itemStruct = new InventoryItem(item, amount);
		_slotsToItems[slot] = itemStruct;
		_inventorySlots[slot] = true;
		return true;
	}

	private RigidBody3D SpawnDroppedItem(Item item) {
		var droppedItem = (RigidBody3D)item.GenerateItem();
		var agent = GetParent();
		var world = agent.GetParent();
		var head = (Node3D)agent.FindChild("Head");
		
		world.AddChild(droppedItem);

		// Set timer till activating monitoring on dropped item
		droppedItem.FindChild("CollectTimer").Call("pick_up_cooldown");
		
		// Drop item forward
		Vector3 facingDir = -head.GlobalTransform.Basis.Z;
		droppedItem.GlobalPosition = head.GlobalPosition;
		droppedItem.LinearVelocity = facingDir.Normalized() * DropVelocity;
		
		return droppedItem;
	}
	
	private void SpawnMultipleDroppedItems(Item item, int count) {
		for(int i = 0; i < count; i++) {
			var droppedItem = SpawnDroppedItem(item);
		}
	}
	
	private void RemoveItemInSlot(int slot) {
		var item = _slotsToItems[slot];
		SpawnMultipleDroppedItems(item.item, item.count);
		item.count = 0;
		
		_inventorySlots[slot] = false;
		_slotsToItems.Remove(slot);
		_nameToSlots[item.item.Name].Remove(slot);
	}
	
	private void DecrementItemInSlot(int slot) {
		var item = _slotsToItems[slot];
		item.count--;
		if (item.count > 0) return;
		
		_inventorySlots[slot] = false;
		_slotsToItems.Remove(slot);
		_nameToSlots[item.item.Name].Remove(slot);
	}

	private void ReleaseItemSlot(String itemName, int slotNum)
	{
		_inventorySlots[slotNum] = false;
		_slotsToItems.Remove(slotNum);
		_nameToSlots[itemName].Remove(slotNum);
		//Check if there is anymore slots that contain the item
		if(_nameToSlots[itemName].Count <= 0)
		{
			_nameToSlots.Remove(itemName);
		}
	}
}
