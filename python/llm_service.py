from abc import ABC, abstractmethod
from typing import Optional
import os
from dotenv import load_dotenv
from prompts import SYSTEM_PROMPT, USER_PREPROMPT


class LLMService(ABC):
    """Abstract base class for models to be used in the LLM service"""

    def __init__(self, model, settings=None):
        global SYSTEM_PROMPT, USER_PREPROMPT
        """Initialize the OpenAI service adapter"""
        self.settings = settings or {}
        self.model = model

        # Get API key from settings or environment
        api_key = settings.get("api_key")
        if not api_key:
            api_keys = self.load_api_keys()

            if "gpt" in model:
                api_key = api_keys["openai"]
                if not api_key:
                    raise ValueError("OpenAI API key not found! Please set it in the .env.development.local file or provide it in the settings.")
            elif "gemini" in model:
                api_key = api_keys["gemini"]
                if not api_key:
                    raise ValueError("Gemini API key not found! Please set it in the .env.development.local file or provide it in the settings.")
        self.api_key = api_key

        # System prompt
        self.system_prompt = SYSTEM_PROMPT
        
        # User preprompt for script generation
        self.user_preprompt = USER_PREPROMPT

    @abstractmethod
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script based on the prompt and optional image data"""
        pass

    @abstractmethod
    async def generate_goal(self, context: str, image_data: Optional[str] = None) -> str:
        """Generate a goal based on the context and optional image data"""
        pass

    @property
    @abstractmethod
    def supports_vision(self) -> bool:
        """Return whether this LLM service supports vision/images"""
        pass

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