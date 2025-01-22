using Godot;
using System;

public struct InventoryItem
{
    public Item item;
    public int count;
    public int inventoryPos;

    public InventoryItem(Item item, int count, int inventoryPos) {
        this.item = item;
        this.count = count;
        this.inventoryPos = inventoryPos;
    } 
}
