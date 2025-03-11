class_name Memory
extends RefCounted

# Config 
@export var max_memories: int = 20

var memories: Array[MemoryItem] = []

func _init(max_capacity: int = 20) -> void:
	max_memories = max_capacity

# Add new memory
func add(memory: MemoryItem) -> void:
	memories.append(memory)
	
	# Maintain size
	if memories.size() > max_memories:
		memories.pop_front()
		
# Add message memory
func add_message(message: String, from_id: int, to_id: int) -> void:
	add(MessageMemory.new(message, from_id, to_id))
	
# Add a goal update memory
func add_goal_update(goal: String) -> void:
	add(GoalMemory.new(goal))
	
# Get all memories
func get_all() -> Array[MemoryItem]:
	return memories
	
# Get most recent memories, up to whatever count
func get_recent(count: int = 5) -> Array[MemoryItem]:
	return memories.slice(max(0, memories.size() - count), memories.size())

# Get memories of specific type
func get_by_type(memory_type: String) -> Array[MemoryItem]:
	var filtered: Array[MemoryItem] = []
	
	for memory in memories:
		if memory.type == memory_type:
			filtered.append(memory)
	
	return filtered
	
# Clear all memories
func clear() -> void:
	memories.clear()
	
# Return the last recent memories into a string for prompting LLM
func format_recent_for_prompt(count: int = 5) -> String:
	var context = ""
	
	if memories.size() > 0:
		context += "- Recent events:\n"
		var recent_memories = get_recent(count)
		
		for memory in recent_memories:
			context += memory.format_for_prompt() + "\n"
		
	return context
