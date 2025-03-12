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


class LinesOfCodeWithinFunction(BaseModel):
	line_of_code_of_function: list[str]


system_prompt = """
You have access to the following context:
position: Vector2 - The agent's current position
detected_entities: Array - The list of entities detected by the agent. Each entity has a position and type.
entity_types: List - hardcoded list of entities the agent is allowed to detect. Current List: ["zombie"]

Functions or Awaits
select_nearest_entity_type(string target) - Select the nearest entity as the target. The argument target provides the name of the entity to target. If no value is specified it will attack the nearest target
move_to_position(float x, float y) - Move the agent to the specified coordinates.
move_to_current_target() - Move the agent to the current target position.
await agent.movement_completed - Wait for the agent to reach the position, must be directly after move_to_position.
attack_selected_target(int c) - Attack the currently selected target. The argument c provides the number of times to attack.

IMPORTANT: Functions marked with [REQUIRES AWAIT] MUST be called with the await keyword:
CORRECT EXAMPLE:
var reached = await move_to_position(30, 0)
if reached:
    say("I've arrived!")

INCORRECT EXAMPLE:
var reached = move_to_position(30, 0)  # ERROR: Missing await!

IMPORTANT: Attacking functions are sensitive to how they are called:
Example Prompt: "Attack the nearest zombie 3 times"
CORRECT EXAMPLE:
select_nearest_entity_type("zombie")
move_to_current_target()
await agent.movement_completed
attack_selected_target(3)

INCORRECT EXAMPLE:
select_nearest_entity_type("zombie")
move_to_current_target()
await agent.movement_completed
for i in range(3):
    attack_selected_target()  # ERROR: missing argument c

Remember:
Your goal is defined by the game, not by you. Focus on taking actions toward your current goal.
Keep your code simple and focused on the immediate next steps to achieve your goal.
You don't need to explicitly complete goals - the game will handle that for you.

YOU ARE NOT ALLOWED TO USE ANYTHING ELSE OTHER THAN THE PROVIDED CONTEXT.
You are allowed to write conditionals, loops, and functions.
"""

user_preprompt = """
Provide the list of functions you would like to call to achieve the goal.
You must achieve the goal using what function calls available to you, if possible.

Changes in Godot 4.3 you MUST ADHERE TO, lest Parser Errors will occur:
deg2rad is now deg_to_rad() in Godot 4.3. 
OS.get_ticks_msec() is now Time.get_ticks_msec() in Godot 4.3.

Failing to adhere to this will result in Parser Error: Function "deg2rad()" not found in base self. Did you mean to use "deg_to_rad()"?

Since you are writing the body of the function "func eval(delta)", you cannot include it in lines_of_code_of_function.
Ensure the code is Godot 4.3 compatible code, you are writing the BODY of the function func eval(delta):

The eval function is called every physics frame within func _physics_process(delta: float) -> void, and thus you have access to delta.
"""

async def server(websocket):
	async for message in websocket:
		completion = client.beta.chat.completions.parse(
			model="gpt-4o-mini",
			messages=[
				{"role": "system", "content": system_prompt},
				{
					"role": "user",
					"content": message + user_preprompt,
				}
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