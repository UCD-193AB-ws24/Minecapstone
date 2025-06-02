using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[Tool]
public partial class InventoryManager : Node 
{
	// ============================= PROPERTIES =================================

	[Export]
	public float DropVelocity { get; set; } = 5;
	
	// TODO: Using an export here doesn't work on InventorySlots. 
	// Set this up in player's ready function instead.
	public int InventorySlots { get; set; } = 9;
	public int SelectedSlot => _selectedSlot;
	
	private readonly Dictionary<string, List<int>> _nameToSlots = [];
	private readonly Dictionary<int, InventoryItem> _slotsToItems = [];
	private int _selectedSlot = 0;
	private bool[] _inventorySlots;
	
	// ============================= SIGNALS ===================================
	
	[Signal]
	public delegate void ItemAddedEventHandler(string signalName, Item[] items);
	
	public InventoryManager() 
	{
		_inventorySlots = new bool[InventorySlots];
	}

	// =========================== INVENTORY ACCESS ============================
	
	public int GetSpace() => Array.IndexOf(_inventorySlots, false);
	
	public Item GetSelectedItem() => 
		_inventorySlots[_selectedSlot] ? _slotsToItems[_selectedSlot].item : null;

	public int GetSelectedAmount() => 
		_inventorySlots[_selectedSlot] ? _slotsToItems[_selectedSlot].count : 0;
	
	public int GetItemCount(string itemName) 
	{
		if (!_nameToSlots.ContainsKey(itemName)) return 0;
		
		int totalAmount = 0;
		foreach (int slotNum in _nameToSlots[itemName])
		{
			totalAmount += _slotsToItems[slotNum].count;
		}
		return totalAmount;
	}
	
	public string GetInventoryData() 
	{
		string inventory_str = "";
		for (int i = 0; i < InventorySlots; i++)
		{
			if (_inventorySlots[i])
			{
				inventory_str += $"{_slotsToItems[i].PrintInventoryItem()} ({_slotsToItems[i].PrintAmount()}x)";
			}
		}
		return inventory_str;
	}
	
	public void PrintInventory() 
	{
		for (int i = 0; i < InventorySlots; i++) 
		{
			if (_inventorySlots[i])
				GD.Print($"{i} {_slotsToItems[i].PrintInventoryItem()} {_slotsToItems[i].PrintAmount()}");
		}
	}
	
	// ========================= INVENTORY MANIPULATION ========================
	
	public void CycleUp() => 
		_selectedSlot = _selectedSlot > 0 ? _selectedSlot - 1 : _inventorySlots.Length - 1;
	
	public void CycleDown() => 
		_selectedSlot = _selectedSlot < _inventorySlots.Length - 1 ? _selectedSlot + 1 : 0;

	public bool AddItem(Item item, int amount) 
	{
		bool added = TryAddToExistingStack(item, amount) || TryAddToNewSlot(item, amount);

		if (added)
		{
			// Item[] items = [item];
			EmitSignal("ItemAdded", item);
		}
		
		return added;
	}
	
	public void ConsumeSelectedItem() 
	{
		if (!_inventorySlots[_selectedSlot]) return;
		DecrementItemInSlot(_selectedSlot);
	}
	
	public void ConsumeItem(string itemName) 
	{
		if (!_nameToSlots.ContainsKey(itemName)) return;
		DecrementItemInSlot(_nameToSlots[itemName][0]);
	}
	
	// ============================= ITEM DROPPING =============================
	
	public bool DropItem(string itemName, int amount) 
	{
		if (!_nameToSlots.ContainsKey(itemName)) return false;
		
		int remainingAmount = amount;
		List<int> slotNums = _nameToSlots[itemName];
		
		for (int i = slotNums.Count - 1; i >= 0; i--) 
		{
			int slotNum = slotNums[i];
			InventoryItem items = _slotsToItems[slotNum];
			
			if (items.count >= remainingAmount) 
			{
				SpawnMultipleDroppedItems(items.item, remainingAmount);
				items.count -= remainingAmount;
				
				if (items.count > 0)
				{
					_slotsToItems[slotNum] = items;
					return true;
				}
				
				ReleaseItemSlot(itemName, slotNum);
				return true;
			} 
			else 
			{
				SpawnMultipleDroppedItems(items.item, items.count);
				remainingAmount -= items.count;
				ReleaseItemSlot(itemName, slotNum);
			}
		}
		
		return true;
	}
	
	public bool DropSelectedItem() 
	{
		if (!_inventorySlots[_selectedSlot]) return false;
		
		SpawnDroppedItem(_slotsToItems[_selectedSlot].item);
		DecrementItemInSlot(_selectedSlot);
		return true;
	}
	
	public bool DropSelectedStack() 
	{
		if (!_inventorySlots[_selectedSlot]) return false;
		
		var item = _slotsToItems[_selectedSlot];
		SpawnMultipleDroppedItems(item.item, item.count);
		RemoveItemInSlot(_selectedSlot);
		return true;
	}
	
	public void DropAllItems() 
	{
		for (int i = 0; i < _inventorySlots.Length; i++) 
		{
			if (_inventorySlots[i]) RemoveItemInSlot(i);
		}
	}
	
	// ============================= PRIVATE METHODS ===========================
	
	private List<int> ItemInInventory(string itemName) => 
		_nameToSlots.TryGetValue(itemName, out List<int> slots) ? slots : null;

	private bool TryAddToExistingStack(Item item, int amount) 
	{
		var slotNums = ItemInInventory(item.Name);
		if (slotNums == null) return false;

		foreach (int slot in slotNums) 
		{
			var existingItem = _slotsToItems[slot];
			if (existingItem.count >= existingItem.item.MaxStackSize) continue;
			
			existingItem.count += amount;
			_slotsToItems[slot] = existingItem;
			return true;
		}
		return false;
	}

	private bool TryAddToNewSlot(Item item, int amount) 
	{
		int slot = GetSpace();
		if (slot == -1) return false;

		if (!_nameToSlots.ContainsKey(item.Name)) 
			_nameToSlots[item.Name] = [slot];
		else 
			_nameToSlots[item.Name].Add(slot);
		
		_slotsToItems[slot] = new InventoryItem(item, amount);
		_inventorySlots[slot] = true;
		return true;
	}

	private RigidBody3D SpawnDroppedItem(Item item) 
	{
		var droppedItem = (RigidBody3D)item.GenerateItem();
		var agent = GetParent();
		var world = agent.GetParent();
		var head = (Node3D)agent.FindChild("Head");
		
		world.AddChild(droppedItem);
		droppedItem.FindChild("CollectTimer").Call("pick_up_cooldown");
		
		Vector3 facingDir = -head.GlobalTransform.Basis.Z;
		droppedItem.GlobalPosition = head.GlobalPosition;
		droppedItem.LinearVelocity = facingDir.Normalized() * DropVelocity;
		
		return droppedItem;
	}
	
	private void SpawnMultipleDroppedItems(Item item, int count) 
	{
		for (int i = 0; i < count; i++) SpawnDroppedItem(item);
	}
	
	private void RemoveItemInSlot(int slot) 
	{
		var item = _slotsToItems[slot];
		SpawnMultipleDroppedItems(item.item, item.count);
		
		_inventorySlots[slot] = false;
		_slotsToItems.Remove(slot);
		
		string itemName = item.item.Name;
		_nameToSlots[itemName].Remove(slot);
		
		if (_nameToSlots[itemName].Count <= 0)
			_nameToSlots.Remove(itemName);
	}
	
	private void DecrementItemInSlot(int slot) 
	{
		var item = _slotsToItems[slot];
		item.count--;
		
		if (item.count > 0) 
		{
			_slotsToItems[slot] = item;
			return;
		}
		
		_inventorySlots[slot] = false;
		_slotsToItems.Remove(slot);
		
		string itemName = item.item.Name;
		_nameToSlots[itemName].Remove(slot);
		
		if (_nameToSlots[itemName].Count <= 0)
			_nameToSlots.Remove(itemName);
	}

	private void ReleaseItemSlot(string itemName, int slotNum)
	{
		_inventorySlots[slotNum] = false;
		_slotsToItems.Remove(slotNum);
		_nameToSlots[itemName].Remove(slotNum);
		
		if (_nameToSlots[itemName].Count <= 0)
			_nameToSlots.Remove(itemName);
	}
}
