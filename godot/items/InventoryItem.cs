using Godot;
using System;

public class InventoryItem {
	public Item item;
	public int count;

	public InventoryItem(Item item, int count) {
		this.item = item;
		this.count = count;
	}

	public string PrintInventoryItem() {
		return item.PrintItem();
	}
	
	public int PrintAmount() {
		return count;
	}
}
