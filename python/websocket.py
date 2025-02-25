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
You are controlling an agent in a virtual world. YOu have access to these functions:

Functions Available:
- move_to_position(float x, float y) - Move the agent to specified coordinates
- move_with_timeout(float x, float y) - Move to position with a safety timeout
- get_nearby_agents() -> Array[int] - Get IDs of agents within range
- send_message(int target_id, String content) - Send a message to another agent

YOU ARE NOT ALLOWED TO USE ANYTHING ELSE OTHER THAN THE PROVIDED FUNCTIONS.
IMPORTANT: Always use move_with_timeout instead of directly awaiting movement_completed.
Example of correct movement:
await move_with_timeout(10, 10)
DO NOT use await agent.movement_completed directly as it may cause the game to freeze.

You can write conditionals and loops.

When you receive a message, you should:
1. Process the message content
2. Use get_nearby_agents() to find other agents if needed
3. Respond using send_message() if appropriate
4. Move to a new position if the message requests it

Remember: Your code will only run once per prompt, so include all necessary actions in your response.
"""

user_preprompt = """
Provide the list of functions you would like to call to achieve the goal.
Include ALL necessary function calls in your response, as you won't get another chance to respond.

Example of good response:
```
var nearby = get_nearby_agents()
if nearby.size() > 0:
    send_message(nearby[0], "Hello!")
move_to_position(10, 10)
await agent.movement_completed  # Proper way to wait for movement to finish
```

Example of INCORRECT response (do not use):
```
move_to_position(10, 10)
yield()  # Wrong! yield() is deprecated in Godot 4.3
```

Changes in Godot 4.4 you MUST ADHERE TO:
- deg2rad is now deg_to_rad() in Godot 4.3
- OS.get_ticks_msec() is now Time.get_ticks_msec() in Godot 4.3
- yield() is deprecated in Godot 4.3, use 'await signal_name' instead
- To wait for movement to complete, use 'await agent.movement_completed'

You are writing the body of the function "func eval(delta)".
Ensure the code is Godot 4.3 compatible.
"""

async def server(websocket):
	async for message in websocket:
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
		formatted_code = "\n\t" + "\n\t".join(code_lines)  # Add initial tab

		await websocket.send(formatted_code)  # Send raw code, no JSON wrapping


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