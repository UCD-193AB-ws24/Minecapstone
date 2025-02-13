import asyncio
import websockets
from openai import OpenAI

client = OpenAI()

async def server(websocket):
	async for message in websocket:
		completion = client.chat.completions.create(
			model="gpt-4o-mini",
			messages=[
				{"role": "system", "content": "Answer extremely concisely."},
				{
					"role": "user",
					"content": message,
				}
			]
		)

		response = completion.choices[0].message.content
		print(message, "-->", response)
		await websocket.send(response)

async def main():
	start_server = await websockets.serve(server, "localhost", 5000)
	print("Server started on port 5000")
	await start_server.wait_closed()

asyncio.run(main())