import asyncio
import websockets
import json
import os
import argparse
from llm_service_factory import LLMServiceFactory

class WebSocketServer:
    """WebSocket server for handling LLM requests with visual support"""
    
    def __init__(self, config_path, host, port):
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
                message_obj = json.loads(message)
                message = message_obj.get("prompt", "")
                image_data = message_obj.get("image_data", None)

                # Check if image is provided but not supported
                if (image_data and not self.llm_service.supports_vision):
                    print("Warning: Image provided but current LLM service doesn't support vision. Ignoring image.")
                
                # Send the prompt to the LLM and get the response
                try:
                    if message_obj.get("type") == "GOAL":
                        goal = await self.llm_service.generate_goal(message, image_data)
                        await websocket.send(goal)
                    elif message_obj.get("type") == "SCRIPT":
                        script = await self.llm_service.generate_script(message, image_data)
                        await websocket.send(script)
                    else:
                        response = "Error: Unknown message type"
                        await websocket.send(response)
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
        self.llm_service = LLMServiceFactory.get_service(self.config_path)
        print(f"Configuration reloaded from: {self.config_path}")

async def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="LLM WebSocket Server")
    parser.add_argument("--config", default="./llm_config.json", help="Path to the configuration file")
    parser.add_argument("--host", default="localhost", help="Host to bind the server to")
    parser.add_argument("--port", type=int, default=5000, help="Port to bind the server to")
    args = parser.parse_args()
    
    server = WebSocketServer(config_path=args.config, host=args.host, port=args.port)
    await server.start()

if __name__ == "__main__":
    asyncio.run(main())