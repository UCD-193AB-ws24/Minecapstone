import asyncio
import websockets
from openai import OpenAI
from pydantic import BaseModel
from dotenv import load_dotenv
import json
import os


load_dotenv("./.env.development.local")
client = OpenAI()


# TODO: split websocket & LLM into separate files
# TODO: expand these to be more general


class LinesOfCodeWithinFunction(BaseModel):
	line_of_code_of_function: list[str]


system_prompt = """
You are an autonomous agent in a 3D world. You'll be called after completing previous actions to decide what to do next.

FUNCTION REFERENCE:
- get_position() -> Vector3 - Get your current position
- move_to_position(x, y) [REQUIRES AWAIT] - Move to coordinates, returns true when reached
- say(message) - Broadcast a message to all nearby agents
- say_to(message, target_id) - Send a message to a specific agent
- set_goal(goal_description) - Update your current goal 
- get_nearby_agents() -> Array[int] - Get IDs of nearby agents

IMPORTANT: Functions marked with [REQUIRES AWAIT] MUST be called with the await keyword:
CORRECT EXAMPLE:
var reached = await move_to_position(30, 0)
if reached:
say("I've arrived!")
Copy
INCORRECT EXAMPLE:
var reached = move_to_position(30, 0)  # ERROR: Missing await!
Copy
Remember:
1. If a goal is COMPLETED or FAILED, set a new goal
2. Keep your code simple and focused
3. Your code will execute fully before you're called again
"""

user_preprompt = """
Provide the list of functions you would like to call to achieve the goal.
Remember that you're a persistent agent in an ongoing simulation - you'll be recalled after your code completes.

Your responses should focus on immediate actions. For a PENDING goal, work toward completing it. For a COMPLETED or FAILED goal, set a new goal based on the situation.

Changes in Godot 4.3 you MUST ADHERE TO:
- deg2rad is now deg_to_rad() in Godot 4.3
- OS.get_ticks_msec() is now Time.get_ticks_msec() in Godot 4.3
- yield() is deprecated in Godot 4.3, don't use it at all

You are writing the body of the function "func eval()", which is called only once.
Ensure the code is Godot 4.3 compatible.
"""

async def server(websocket):
	async for message in websocket:
		print(message)

		completion = client.beta.chat.completions.parse(
			model="gpt-4o-mini",
			messages=[
				{"role": "system", "content": system_prompt},
				{
					"role": "user",
					"content": message + "\n" + user_preprompt,
				}
			],
			response_format=LinesOfCodeWithinFunction,
		)
		response = json.loads(completion.choices[0].message.content)

		# Format the lines with proper indentation and join them
		code_lines = response["line_of_code_of_function"]
		code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
		formatted_code = "\n\t" + "\n\t".join(code_lines)  # Add initial tab

		await websocket.send(formatted_code)  # Send raw code, no JSON wrapping


async def main():
	start_server = await websockets.serve(server, "localhost", 5000, ping_interval = 30, ping_timeout = 10, max_size = 1024*1024)
	print("Server started on port 5000")
	await start_server.wait_closed()


asyncio.run(main())