import asyncio
import websockets
from openai import OpenAI
from pydantic import BaseModel
from dotenv import load_dotenv
import json
import os


load_dotenv("../.env.development")
client = OpenAI()


# TODO: split websocket & LLM into separate files
# TODO: expand these to be more general


class LinesOfCodeWithinFunction(BaseModel):
	line_of_code_of_function: list[str]


system_prompt = """
You control an agent in a virtual world. You can use these functions:

- move_and_continue(float x, float y) - Move to coordinates
- get_nearby_agents() -> Array[int] - Get IDs of nearby agents
- send_message(int target_id, String content) - Send a message

IMPORTANT:
1. DO NOT use 'await' with any function
2. DO NOT use infinite loops

Example of good code:
```
var nearby = get_nearby_agents()
if nearby.size() > 0:
    send_message(nearby[0], "Hello!")
move_and_continue(10, 10)
```
"""

user_preprompt = """
Provide the list of functions you would like to call to achieve the goal.
Remember to follow the rules about not using await or infinite loops.

Changes in Godot 4.3 you MUST ADHERE TO:
- deg2rad is now deg_to_rad() in Godot 4.3
- OS.get_ticks_msec() is now Time.get_ticks_msec() in Godot 4.3
- yield() is deprecated in Godot 4.3, don't use it at all

You are writing the body of the function "func eval(delta)", which is called every physics frame.
Ensure the code is Godot 4.3 compatible. Ensure that the code will compile. Pay attention to indentations, spelling, spacing, syntax, and formatting.a
"""

def validate_indentation(code_lines):
	"""Validate and fix indentation in code"""
	fixed_lines = []
	in_block = False

	for i, line in enumerate(code_lines):
		# Skip empty lines
		if not line.strip():
			fixed_lines.append(line)
			continue
        
        # Check if we're entering a new block
		if line.strip().endswith(":"):
			in_block = True
			fixed_lines.append(line)
			continue
        
        # If we're in a block and this line isn't indented but should be
		if in_block and i > 0 and not line.startswith("\t") and line.strip():
            # This is a line that should be indented but isn't
			fixed_line = "\t" + line
			fixed_lines.append(fixed_line)
		else:
			fixed_lines.append(line)
            
            # If this line is not indented, we're no longer in a block
			if not line.startswith("\t"):
				in_block = False
    
	return fixed_lines


async def server(websocket):
	async for message in websocket:
		try:
			goal = message

			completion = client.beta.chat.completions.parse(
				model="gpt-4o-mini",
				messages=[
					{"role": "system", "content": system_prompt},
					{"role": "user", "content": goal + "\n" + user_preprompt}
				],
				response_format=LinesOfCodeWithinFunction,
			)
			response = json.loads(completion.choices[0].message.content)
			print(response)

			# Format the lines with proper indentation and join them
			code_lines = response["line_of_code_of_function"]
			code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]

			# Validate and fix indentation
			fixed_code_lines = validate_indentation(code_lines)

			formatted_code = "\n\t" + "\n\t".join(fixed_code_lines)  # Add initial tab

			await websocket.send(formatted_code)  # Send raw code, no JSON wrapping
		except Exception as e:
			print(f"Error handling message: {e}")
			await websocket.send("\n\tmove_and_continue(0,0)") # Send a default response in case of error


async def main():
	start_server = await websockets.serve(server, "localhost", 5000)
	print("Server started on port 5000")
	await start_server.wait_closed()


asyncio.run(main())

# {
#     "id": "chatcmpl-B0o9oS5AyZ2w1BmfccRXTkhoFTvqo",
#     "choices": [
#         {
#             "finish_reason": "stop",
#             "index": 0,
#             "logprobs": null,
#             "message": {
#                 "content": "{\"function_name\":[\"move_to_position\"],\"function_args\":[\"5\",\"3\"]}",
#                 "refusal": null,
#                 "role": "assistant",
#                 "audio": null,
#                 "function_call": null,
#                 "tool_calls": null,
#                 "parsed": {
#                     "function_name": [
#                         "move_to_position"
#                     ],
#                     "function_args": [
#                         "5",
#                         "3"
#                     ]
#                 }
#             }
#         }
#     ],
#     "created": 1739532504,
#     "model": "gpt-4o-mini-2024-07-18",
#     "object": "chat.completion",
#     "service_tier": "default",
#     "system_fingerprint": "fp_72ed7ab54c",
#     "usage": {
#         "completion_tokens": 18,
#         "prompt_tokens": 90,
#         "total_tokens": 108,
#         "completion_tokens_details": {
#             "accepted_prediction_tokens": 0,
#             "audio_tokens": 0,
#             "reasoning_tokens": 0,
#             "rejected_prediction_tokens": 0
#         },
#         "prompt_tokens_details": {
#             "audio_tokens": 0,
#             "cached_tokens": 0
#         }
#     }
# }