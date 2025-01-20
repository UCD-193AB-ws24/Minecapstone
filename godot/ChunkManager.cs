using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Numerics;

[Tool]
public partial class ChunkManager : Node
{
	public static ChunkManager Instance { get; private set; }

	private Dictionary<Chunk, Vector2I> _chunkToPosition = new();
	private Dictionary<Vector2I, Chunk> _positionToChunk = new();

	private List<Chunk> _chunks;

	public override void _Ready()
	{
		Instance = this;

		_chunks = GetParent().GetChildren().Where(child => child is Chunk).Select(child => child as Chunk).ToList();
	}

	public void UpdateChunkPosition(Chunk chunk, Vector2I currentPosition, Vector2I previousPosition)
	{
		if (_positionToChunk.TryGetValue(previousPosition, out var chunkAtPosition) && chunkAtPosition == chunk)
		{
			_positionToChunk.Remove(previousPosition);
		}

		_chunkToPosition[chunk] = currentPosition;
		_positionToChunk[currentPosition] = chunk;
	}

	public void SetBlock(Vector3I globalPosition, Block block)
	{
		var chunkTilePosition = new Vector2I(Mathf.FloorToInt(globalPosition.X / (float)Chunk.dimensions.X), Mathf.FloorToInt(globalPosition.Z / (float)Chunk.dimensions.Z));
		if (_positionToChunk.TryGetValue(chunkTilePosition, out var chunk))
		{
			chunk.SetBlock((Vector3I)(globalPosition - chunk.GlobalPosition), block);
		}
	}
}
