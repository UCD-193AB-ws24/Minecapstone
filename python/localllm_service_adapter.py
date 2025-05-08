from llm_service import LLMService
import requests
import json
import re
from typing import Optional, Dict, Any

class LocalLLMService(LLMService):
    """Adapter for any locally run LLM"""

    def __init__(self, model="default", settings = None):
        super().__init__(model = model, settings = settings)

        # Config
        local_config = {}
        local_config_path = settings.get("config_path", "./python/llm_config.json")

        try:
            with open(local_config_path, 'r') as f:
                local_config = json.load(f)
                print(f"Loaded local LLM configuration from {local_config_path}")
        except FileNotFoundError:
            print(f"No local LLM config found at {local_config_path}, using defaults")

        self.config = {**local_config, **settings}
        
        # Get basic configuration
        self.api_endpoint = self.config.get("api_endpoint", "http://localhost:8000/api/generate")
        self.model_name = model or self.config.get("model", "")
        self.timeout = self.config.get("timeout", 30)  # seconds
        
        print(f"Initialized Local LLM service with endpoint: {self.api_endpoint}")
        if self.model_name:
            print(f"Using model: {self.model_name}")

    @property
    def supports_vision(self) -> bool:
        """Check if model supports vision"""
        return self.settings.get("support_vision", False)
    
    async def generate_script(self, prompt: str, image_data: Optional[str] = None) -> str:
        """Generate a script using local LLM with optional image data"""
        full_prompt = f"{self.system_prompt}\n\n{prompt}\n\n{self.user_preprompt}"

        try:
            import asyncio
            response_text = await asyncio.to_thread(
                self.make_api_request,
                full_prompt,
                image_data
            )

            code = self._extract_code(response_text)

            # Format the code for Godot
            code_lines = code.split("\n")
            code_lines = [line.replace("    ", "\t").replace("deg2rad", "deg_to_rad") for line in code_lines]
            formatted_code = "\n\t" + "\n\t".join(code_lines)

            return formatted_code

        except Exception as e:
            print(f"Error generating script with Local LLM: {e}")
            return "\n\t# Error generating script with Local LLM"

    async def generate_goal(self, context: str, image_data: Optional[str] = None) -> str:
        """Generate a goal using local LLM with optional image data"""
        full_prompt = f"""{self.system_prompt}

{context}

Based on the situation described, provide a single plain text goal that you will pursue. 
Be creative and ambitious while staying within your capabilities.
Your response should be a single sentence or short paragraph goal only.
"""
        
        try:
            import asyncio
            response_text = await asyncio.to_thread(
                self.make_api_request,
                full_prompt,
                image_data
            )

            goal = self._extract_goal(response_text)
            print(f"Local LLM generated goal: {goal}")
        
            return goal
        

        except Exception as e:
            print(f"Error generating goal with Local LLM: {e}")