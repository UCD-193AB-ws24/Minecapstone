using Godot;
using System;


public partial class Food: Item 
{
    public int satiety {get;}
    public Food (string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable, int satiety) : base(Name, Icon, MaxStackSize, IsConsumable)
    {
        base.Name = Name;
		base.Icon = Icon;
		base.MaxStackSize = MaxStackSize;
		base.IsConsumable = IsConsumable;
        this.satiety = satiety;
    }
}