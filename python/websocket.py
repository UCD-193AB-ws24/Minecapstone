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

class Goal(BaseModel):
	plaintext_goal: str


system_prompt = """
You are an autonomous agent in a 3D world. You'll be called after completing previous actions to decide what to do next.

FUNCTION REFERENCE:
- get_position() -> Vector3 - Get your current position
- move_to_position(x, y) [REQUIRES AWAIT] - Move to coordinates, returns true when reached
- say(message) - Broadcast a message to all nearby agents
- say_to(message, target_id) - Send a message to a specific agent
- get_nearby_agents() -> Array[int] - Get IDs of nearby agents
- eat_food() - Restore your hunger by 10 points

IMPORTANT: Functions marked with [REQUIRES AWAIT] MUST be called with the await keyword:
CORRECT EXAMPLE:
var reached = await move_to_position(30, 0)
if reached:
	say("I've arrived!")

INCORRECT EXAMPLE:
var reached = move_to_position(30, 0)  # ERROR: Missing await!

Distances are meters, so anything within 1 meter is considered "nearby".

Remember:
1. Your goal is defined by you, and can be anything given your constraints and abilities.
2. Keep your code simple and focused on the immediate next steps to achieve your goal.
3. Your code will execute fully before you're called again for the next action.
4. You don't need to explicitly complete goals - the game will handle that for you.
5. If you receive messages from other agents, you can choose how to respond based on your current goal.
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
	try:
		async for message in websocket:
			prompt = ""

			# TODO: make this look prettier
			if message.startswith("GOAL "):
				prompt = message[len("GOAL "):]
				goal = generate_goal(context=prompt)
				await websocket.send(goal)
				print(f"Generated goal: {goal}")
			elif message.startswith("SCRIPT "):
				prompt = message[len("SCRIPT "):]
				code = generate_script(prompt=prompt)
				await websocket.send(code)  # Send raw code, no JSON wrapping
				# print(f"Generated code.")
	except Exception as e:
		print(f"Error: {e}")


def generate_script(prompt: str):
	response = LLM_generate(
		messages=[
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": prompt + "\n" + user_preprompt},
		],
		response_format=LinesOfCodeWithinFunction,
	)
	response = json.loads(response)

	# Format the lines with proper indentation and join them
	code_lines = response["line_of_code_of_function"]
	code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
 
	# Add a newline and tab to the beginning of each line
	formatted_code = "\n\t" + "\n\t".join(code_lines)
	return formatted_code


def generate_goal(context: str):
	response = LLM_generate(
		messages=[
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": context},
		],
		response_format=Goal,
	)
	response = json.loads(response)
	return response["plaintext_goal"]


def LLM_generate(messages: list[dict[str, str]], response_format: BaseModel):
	completion = client.beta.chat.completions.parse(
		model="gpt-4o-mini",
		messages=messages,
		response_format=response_format,
	)

	return completion.choices[0].message.content


async def main():
	start_server = await websockets.serve(server, "localhost", 5000, ping_interval = 30, ping_timeout = 10, max_size = 1024*1024)
	print("Server started on port 5000")
	await start_server.wait_closed()


asyncio.run(main())