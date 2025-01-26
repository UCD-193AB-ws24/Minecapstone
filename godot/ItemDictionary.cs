using Godot;
using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Reflection.Metadata.Ecma335;

public partial class ItemDictionary : Node
{
    Dictionary<string, Item> ItemDict;
    string Path = "res://assets/icons/placeholder.jpg";
    
    public ItemDictionary() 
    {
        Texture2D Placeholder = GD.Load<Texture2D>(Path);
        ItemDict = new Dictionary<string, Item>()
        {
            {"Air", new Block("Air", Placeholder, 0, false, true, false)},
            {"Dirt", new Block("Dirt", Placeholder, 64, false, true, false)},
            {"Stone", new Block("Stone", Placeholder, 64, false, true, false)},
            {"Grass", new Block("Grass", Placeholder, 64, false, true, false)},
        };

    }
    public Item Get(string BlockName) 
    {
        return ItemDict[BlockName];
    }

    //Block Dirt = new Block(<parameters here>);
    // instantiate more blocks types

    // store in dictionary here
}
