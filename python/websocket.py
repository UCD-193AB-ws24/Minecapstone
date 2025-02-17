import asyncio
import websockets
from openai import OpenAI
from pydantic import BaseModel
from dotenv import load_dotenv
import json
import os


load_dotenv()
client = OpenAI()


# TODO: split websocket & LLM into separate files
# TODO: expand these to be more general


class Function(BaseModel):
	line_of_code: list[str]


system_prompt = """
You have access to the following context:
- position: Vector2 - The agent's current position
- move_to_position(x,y) - Move the agent to the specified coordinates

Write the Godot 4.x function body for the function: eval().
Your code will be executed in a context where these variables and functions are available.
"""

async def server(websocket):
	async for message in websocket:
		# completion = client.beta.chat.completions.parse(
		# 	model="gpt-4o-mini",
		# 	messages=[
		# 		{"role": "system", "content": system_prompt},
		# 		{
		# 			"role": "user",
		# 			"content": message
		# 		}
		# 	],
		# 	response_format=Function,
		# )
		# response = completion.choices[0].message.content
		
		response = {
			"line_of_code": [
				"var center_x = position.x",
				"var center_y = position.y",
				"var radius = 5",
				"var num_steps = 100",
				"var angle_step = (2 * PI) / num_steps",
				"for i in range(num_steps):",
				"    var angle = angle_step * i",
				"    var x = center_x + radius * cos(angle)",
				"    var y = center_y + radius * sin(angle)",
				"    move_to_position(x, y)"
			]
		}

		# Format the lines with proper indentation and join them
		code_lines = response["line_of_code"]
		code_lines = [line.replace("    ", "\t") for line in code_lines]
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