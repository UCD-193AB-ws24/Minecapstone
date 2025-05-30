import asyncio
import websockets
import json
import os
import argparse
from api_adapters.llm_service_factory import LLMServiceFactory
from prompts import SYSTEM_PROMPT, USER_PREPROMPT
import copy

messages = {}

# hash_id and key are used interchangeably
def add_to_context(messages, hash_id, message_type: str = "user", message: str = ""):
    """Add a message to the context history"""
    if hash_id not in messages:
        messages[hash_id] = [{
            "role": "system", \
            "content": SYSTEM_PROMPT
        }]

    messages[hash_id].append({
        "role": message_type,
        "content": message
    })

class WebSocketServer:
    """WebSocket server for handling LLM requests with visual support"""
    
    def __init__(self, config_path, host, port):
        """Initialize the WebSocket server"""
        self.config_path = config_path
        self.host = host
        self.port = port
        self.llm_service = None
    async def handle_client(self, websocket):
        global messages
        """Handle a client connection"""
        try:
            async for message in websocket:
                # Parse the JSON message
                message_obj = json.loads(message)
                prompt = message_obj.get("prompt", "")
                prompt_type = message_obj.get("type", "").upper()
                key = message_obj.get("key", None)
                image_data = message_obj.get("image_data", None)

                # Check if image is provided but not supported
                if (image_data and not self.llm_service.supports_vision):
                    print("Warning: Image provided but current LLM service doesn't support vision. Ignoring image.")

                # Send the prompt to the LLM and get the response
                try:
                    payload = {"contents": "Unexpected prompt type."}

                    temp_messages = copy.deepcopy(messages)
                    add_to_context(temp_messages, key, "user", f"{USER_PREPROMPT}\n\n{prompt}")

                    first_key = list(temp_messages.keys())[0] if temp_messages else None
                    if first_key:
                        print("\n\n=========================================================")
                        for i in temp_messages[first_key]:
                            print(json.dumps(i, indent=2))
                        print("=========================================================\n\n")
                        

                    if prompt_type == "GOAL":
                        goal = await self.llm_service.generate_goal(temp_messages[key], image_data)
                        add_to_context(messages, key, "system", "You set your goal to: " + goal)
                        
                        payload = {
                            "key": key,
                            "type": "GOAL",
                            "contents": goal,
                        }
                        await websocket.send(json.dumps(payload))

                    elif prompt_type == "SCRIPT":
                        script = await self.llm_service.generate_script(temp_messages[key], image_data)
                        add_to_context(messages, key, "assistant", script)

                        payload = {
                            "key": key,
                            "type": "SCRIPT",
                            "contents": script,
                        }

                        await websocket.send(json.dumps(payload))
                        
                    elif prompt_type == "CLEAR":
                        messages.clear()
                except Exception as e:
                    print(f"Error generating response: {e}")
                    response = f"Error: {str(e)}"
        except Exception as e:
            print(f"Client closed the connection with an error: {e}")
            # import traceback
            # traceback.print_exc()
    
    async def start(self):
        """Start the WebSocket server"""
        # Create the LLM service based on configuration
        self.llm_service = LLMServiceFactory.get_service(self.config_path)
        
        # Log vision support
        print(f"LLM service {'supports' if self.llm_service.supports_vision else 'does not support'} vision/images")

        # Start the WebSocket server
        server = await websockets.serve(
            self.handle_client, 
            self.host, 
            self.port, 
            ping_interval=120,
            ping_timeout=120,
            max_size=1024*1024
        )
        
        print(f"WebSocket server started on {self.host}:{self.port}")
        
        # Keep the server running
        await server.wait_closed()
    
    def reload_config(self):
        """Reload the configuration and update the LLM service"""
        self.llm_service = LLMServiceFactory.get_service(self.config_path)
        print(f"Configuration reloaded from: {self.config_path}")

async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="LLM WebSocket Server")
    parser.add_argument("--config", default="./python/llm_config.json", help="Path to the configuration file")
    parser.add_argument("--host", default="localhost", help="Host to bind the server to")
    parser.add_argument("--port", type=int, default=5000, help="Port to bind the server to")
    args = parser.parse_args()
    
    server = WebSocketServer(config_path=args.config, host=args.host, port=args.port)
    await server.start()

if __name__ == "__main__":
    asyncio.run(main())