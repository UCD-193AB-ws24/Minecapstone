class_name Memory
extends RefCounted

@export var max_memories: int = 20
var memories: Array[MemoryItem] = []


func _init(max_capacity: int = 20) -> void:
	max_memories = max_capacity


func add_memory(memory: MemoryItem) -> void:
	memories.append(memory)
	
	# Maintain size
	if memories.size() > max_memories:
		memories.pop_front()


# Add message memory
func add_message(message: String, from_id: int, to_id: int) -> void:
	add_memory(MessageMemory.new(message, from_id, to_id))


# Add a goal update memory
func add_goal_update(goal: String) -> void:
	add_memory(GoalMemory.new(goal))


# Get all memories
func get_all_memories() -> Array[MemoryItem]:
	return memories


# Get memories of specific type
func get_by_type(memory_type: String) -> Array[MemoryItem]:
	return memories.filter(func(memory): return memory.type == memory_type)
	

# Clear all memories
func clear() -> void:
	memories.clear()


# Get most recent memories, up to whatever count
func get_recent_memories(count: int = 5) -> Array[MemoryItem]:
	return memories.slice(max(0, memories.size() - count), memories.size())


# Return the last recent memories into a string for prompting LLM
func format_recent_for_prompt(count: int = 5) -> String:
	var context = ""
	
	if memories.size() > 0:
		context += "- Recent events:\n"
		var recent_memories = get_recent_memories(count)
		
		for memory in recent_memories:
			context += memory.format_for_prompt() + "\n"
		
	return context
