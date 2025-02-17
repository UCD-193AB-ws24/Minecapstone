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


class FunctionCall(BaseModel):
	function_name: list[str]
	function_args: list[str]


async def server(websocket):
	async for message in websocket:
		completion = client.beta.chat.completions.parse(
			model="gpt-4o-mini",
			messages=[
				{"role": "system", "content": "The functions you have access to are: move_to_position(x,y). You can also do "},
				{
					"role": "user",
					"content": message
				}
			],
			# response_format=FunctionCall,
		)
		response = completion.choices[0].message.content
		print(message, "--> function_name: ", completion.choices[0].message.parsed.function_name, "function_args: ", completion.choices[0].message.parsed.function_args)
		await websocket.send(response)


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