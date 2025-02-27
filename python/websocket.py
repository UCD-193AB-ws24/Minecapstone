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
- position: Vector2 - The agent's current position

Functions or Awaits
- await move_to_position(float x, float y) - Move the agent to the specified coordinates. 
- say(string message) - Send a global message.

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
		print("The fucking message:" + message)
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