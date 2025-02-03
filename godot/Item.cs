using Godot;
using System;

// [Tool]
[GlobalClass]
public partial class Item : Resource {
	[Export] public string Name { get; set; }

	// This is separate from the Item's 3D model, if any
	public Texture2D Icon { get; set; }

	// Generic item properties
	public int MaxStackSize { get; set; }
	public bool IsConsumable { get; set; }

	// Item type
	public bool IsBlock { get; set; }
	public bool IsTool { get; set; }

	public Item(string Name, Texture2D Icon, int MaxStackSize, bool IsConsumable) {
		this.Name = Name;
		this.Icon = Icon;
		this.MaxStackSize = MaxStackSize;
		this.IsConsumable = IsConsumable;
	}

	public string PrintItem()
	{
		return Name;
	}

	public Node GenerateItem() {
		RigidBody3D droppedItem = new RigidBody3D();

		CollisionShape3D collisionShape = new CollisionShape3D();
		collisionShape.Shape = new BoxShape3D();
		droppedItem.AddChild(collisionShape);

		Sprite3D itemSprite = new Sprite3D();
		itemSprite.Texture = this.Icon;
		droppedItem.AddChild(itemSprite);	

		Area3D areaBox = new Area3D();
		collisionShape = new CollisionShape3D();
		areaBox.AddChild(collisionShape);


		return droppedItem;
	}
}
