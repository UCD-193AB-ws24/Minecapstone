from abc import ABC, abstractmethod
from typing import Optional
import json
import os
from dotenv import load_dotenv
from prompts import SYSTEM_PROMPT, USER_PREPROMPT


class LLMService(ABC):
    """Abstract base class for models to be used in the LLM service"""

    def __init__(self, model, config_path: Optional[str] = ''):
        global SYSTEM_PROMPT, USER_PREPROMPT
        """Initialize the OpenAI service adapter"""
        self.model = model

        # Get API key from environment
        api_keys = self.load_api_keys()
        api_key = None
        if "gpt" in model:
            api_key = api_keys["openai"]
            if not api_key:
                raise ValueError("OpenAI API key not found! Please set it in .env.development.local.")
        elif "gemini" in model:
            api_key = api_keys["gemini"]
            if not api_key:
                raise ValueError("Gemini API key not found! Please set it in .env.development.local.")
        self.api_key = api_key

        # System prompt
        self.system_prompt = SYSTEM_PROMPT
        
        # User preprompt for script generation
        self.user_preprompt = USER_PREPROMPT

        if config_path:
            self.config = self.load_config(config_path)

    @property
    @abstractmethod
    def supports_vision(self) -> bool:
        """Return whether this LLM service supports vision/images"""
        pass

    @abstractmethod
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script based on the prompt and optional image data"""
        pass

    @abstractmethod
    async def generate_goal(self, context: str, image_data: Optional[str] = None) -> str:
        """Generate a goal based on the context and optional image data"""
        pass

    def load_config(self, config_path: str) -> dict:
        with open(config_path, 'r') as f:
            config = json.load(f)
        print(f"Configuration loaded from {config_path}")
        return config

    def load_api_keys(self) -> dict:
        """
        Load API keys from environment files and return them.
        Prints status messages to help with debugging.
        """
        # Try to load from .env.development.local first
        if not load_dotenv("./.env.development.local"):
            load_dotenv("./.env")
        
        # Get API keys
        openai_key = os.environ.get("OPENAI_API_KEY")
        gemini_key = os.environ.get("GEMINI_API_KEY")
        
        # Print status (with limited visibility for security)
        if not openai_key:
            print("WARNING: OpenAI API key not found in environment variables!")
            
        if not gemini_key:
            print("WARNING: Gemini API key not found in environment variables!")
        
        return {
            "openai": openai_key,
            "gemini": gemini_key
        }