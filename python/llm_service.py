import asyncio
import json
import os
from abc import ABC, abstractmethod
from dotenv import load_dotenv
from typing import Optional

# Load environment variables
load_dotenv("./.env.development.local")
if not os.path.exists("./.env.development.local"):
    load_dotenv("./.env")

class LLMService(ABC):
    """Abstract base class for LLM services"""

    @abstractmethod
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script based on the prompt and optional image data"""
        pass

    @abstractmethod
    async def generate_goal(self, context: str, image_data: Optional[str] = None) -> str:
        """Generate a goal based on the context and optional image data"""
        pass

    @abstractmethod
    async def handle_websocket_message(self, message_obj: dict) -> str:
        """Handle a websocket message and return the appropriate response"""
        pass

    @property
    @abstractmethod
    def supports_vision(self) -> bool:
        """Return whether this LLM service supports vision/images"""
        pass

class LLMServiceFactory:
    """Factory for creating LLM service instances"""
    
    @staticmethod
    def create_service(config_path="llm_config.json") -> LLMService:
        """Create an LLM service based on the provided configuration file"""
        
        # Load the configuration
        try:
            with open(config_path, 'r') as f:
                config = json.load(f)
        except FileNotFoundError:
            print(f"Config file {config_path} not found. Using default OpenAI configuration.")
            config = {
                "service": "openai",
                "model": "gpt-4o"
            }
        
        service_type = config.get("service", "openai").lower()
        model = config.get("model", "")
        settings = config.get("settings", {})
        
        # Create the appropriate service
        if service_type == "openai":
            from openai_service_adapter import OpenAIServiceAdapter
            return OpenAIServiceAdapter(model=model, settings=settings)
        elif service_type == "gemini":
            from gemini_service_adapter import GeminiServiceAdapter
            return GeminiServiceAdapter(model=model, settings=settings)
        else:
            raise ValueError(f"Unknown service type: {service_type}")