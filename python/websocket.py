import asyncio
import websockets
import json
import os
import argparse
from llm_service import LLMServiceFactory

class WebSocketServer:
    """WebSocket server for handling LLM requests with visual support"""
    
    def __init__(self, config_path="llm_config.json", host="localhost", port=5000):
        """Initialize the WebSocket server"""
        self.config_path = config_path
        self.host = host
        self.port = port
        self.llm_service = None
    
    async def handle_client(self, websocket):
        """Handle a client connection"""
        try:
            async for message in websocket:
                # Parse the JSON message
                try:
                    message_obj = json.loads(message)
                    
                    # Check if this is the old format
                    if isinstance(message_obj, str):
                        # Old format: GOAL or SCRIPT prefix
                        if message_obj.startswith("GOAL "):
                            message_obj = {
                                "type": "GOAL",
                                "prompt": message_obj[len("GOAL "):]
                            }
                        elif message_obj.startswith("SCRIPT "):
                            message_obj = {
                                "type": "SCRIPT",
                                "prompt": message_obj[len("SCRIPT "):]
                            }
                        else:
                            await websocket.send("Error: Unknown message format")
                            continue
                except json.JSONDecodeError:
                    # Old format: GOAL or SCRIPT prefix
                    if message.startswith("GOAL "):
                        message_obj = {
                            "type": "GOAL",
                            "prompt": message[len("GOAL "):]
                        }
                    elif message.startswith("SCRIPT "):
                        message_obj = {
                            "type": "SCRIPT",
                            "prompt": message[len("SCRIPT "):]
                        }
                    else:
                        await websocket.send("Error: Unknown message format")
                        continue
                
                # Check if image is provided but not supported
                if (message_obj.get("image_data") and 
                    not self.llm_service.supports_vision):
                    print("Warning: Image provided but current LLM service doesn't support vision. Ignoring image.")
                
                # Process the request
                try:
                    response = await self.llm_service.handle_websocket_message(message_obj)
                    await websocket.send(response)
                except Exception as e:
                    print(f"Error processing request: {e}")
                    await websocket.send(f"Error: {str(e)}")
        except Exception as e:
            print(f"Error handling client: {e}")
            import traceback
            traceback.print_exc()
    
    async def start(self):
        """Start the WebSocket server"""
        # Create the LLM service based on configuration
        self.llm_service = LLMServiceFactory.create_service(self.config_path)
        
        # Log vision support
        vision_status = "supports" if self.llm_service.supports_vision else "does not support"
        print(f"LLM service {vision_status} vision/images")
        
        # Start the WebSocket server
        server = await websockets.serve(
            self.handle_client, 
            self.host, 
            self.port, 
            ping_interval=30, 
            ping_timeout=10, 
            max_size=1024*1024
        )
        
        print(f"WebSocket server started on {self.host}:{self.port}")
        print(f"Using LLM service from config: {self.config_path}")
        
        # Keep the server running
        await server.wait_closed()
    
    def reload_config(self):
        """Reload the configuration and update the LLM service"""
        self.llm_service = LLMServiceFactory.create_service(self.config_path)
        print(f"Configuration reloaded from: {self.config_path}")

async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="LLM WebSocket Server")
    parser.add_argument("--config", default="llm_config.json", help="Path to the configuration file")
    parser.add_argument("--host", default="localhost", help="Host to bind the server to")
    parser.add_argument("--port", type=int, default=5000, help="Port to bind the server to")
    args = parser.parse_args()
    
    server = WebSocketServer(config_path=args.config, host=args.host, port=args.port)
    await server.start()

if __name__ == "__main__":
    asyncio.run(main())