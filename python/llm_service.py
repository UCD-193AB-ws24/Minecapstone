import asyncio
import json
import os
from abc import ABC, abstractmethod
from dotenv import load_dotenv
from typing import Optional

def load_api_keys():
    """
    Load API keys from environment files and return them.
    Prints status messages to help with debugging.
    """
    # Try to load from .env.development.local first
    local_loaded = load_dotenv("./.env.development.local")
    if local_loaded:
        print("Loaded environment variables from .env.development.local")
    else:
        print("Could not find .env.development.local")
        
        # Fallback to .env
        env_loaded = load_dotenv("./.env")
        if env_loaded:
            print("Loaded environment variables from .env")
        else:
            print("Could not find .env either")
    
    # Get API keys
    openai_key = os.environ.get("OPENAI_API_KEY")
    gemini_key = os.environ.get("GEMINI_API_KEY")
    
    # Print status (with limited visibility for security)
    if openai_key:
        masked_key = openai_key[:4] + '*' * (len(openai_key) - 8) + openai_key[-4:]
        print(f"Found OpenAI API key")
    else:
        print("WARNING: OpenAI API key not found in environment variables!")
        
    if gemini_key:
        masked_key = gemini_key[:4] + '*' * (len(gemini_key) - 8) + gemini_key[-4:]
        print(f"Found Gemini API key")
    else:
        print("WARNING: Gemini API key not found in environment variables!")
    
    return {
        "openai": openai_key,
        "gemini": gemini_key
    }

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